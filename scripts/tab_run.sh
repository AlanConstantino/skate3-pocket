#!/bin/bash
# Drive the Tab A7 Lite from cold to gameplay and measure, unattended.
#
# The tablet takes ~100s to reach the world, and a measurement taken before
# that lands in a menu, which runs at 56 fps and means nothing. So this waits
# for the game's own surface AND for the frame time to settle into the
# gameplay range before it samples.
#
# usage: tab_run.sh <label> [apk]
set -uo pipefail
SERIAL=R83X303S5ZL
PKG=com.nakas.skate3
FILES=/sdcard/Android/data/$PKG/files
LABEL="${1:?usage: tab_run.sh <label> [apk]}"
APK="${2:-}"

a() { adb -s "$SERIAL" "$@"; }

if [ -n "$APK" ]; then
  a install -r "$APK" >/dev/null 2>&1 || { echo "$LABEL: INSTALL FAILED"; exit 1; }
fi

a shell am force-stop $PKG
# Wait for the process to actually be gone before touching its logs.
# Deleting a file the engine still holds open does not empty it - the writes
# keep going to the unlinked inode and the new run appears to log nothing,
# which reads exactly like "the game never started". That cost three
# measurements before I spotted it.
for _ in $(seq 1 20); do
  a shell pidof $PKG >/dev/null 2>&1 || break
  sleep 1
done
# Both logs: a stale "slow guest frame" from the previous run makes the
# in-world check below fire while this one is still in the menus, which
# measures a 56 fps menu and reports it as gameplay.
a shell rm -f $FILES/stderr.log $FILES/skate3.log
a shell input keyevent KEYCODE_WAKEUP >/dev/null
# NEW_TASK|CLEAR_TASK: stale task records otherwise resume the game activity
# instead of the launcher and the Play tap lands on nothing.
a shell am start -S -f 0x10008000 -n $PKG/.SetupActivity >/dev/null 2>&1
sleep 6
# Find PLAY rather than assuming where it is - a missed tap leaves the
# launcher up and the whole run measures nothing.
a shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
PLAY=$(a shell cat /sdcard/ui.xml 2>/dev/null | tr '<' '\n' | grep 'text="PLAY"' \
       | sed -E 's/.*bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]".*/\1 \2 \3 \4/' \
       | awk '{print int(($1+$3)/2), int(($2+$4)/2)}')
if [ -n "$PLAY" ]; then
  a shell input tap $PLAY >/dev/null
else
  echo "$LABEL: could not find PLAY on the launcher"; exit 1
fi

# Wait for the game's own BLAST surface, then for the world to actually load.
for i in $(seq 1 40); do
  sleep 5
  a shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
  n=$(a shell dumpsys SurfaceFlinger --list 2>/dev/null | grep -ci "skate3.*BLAST")
  [ "${n:-0}" -ge 1 ] || continue
  # in-world when the guest is reporting slow frames (menus are 16.7ms)
  # In the world, not the frontend: the menus hold a steady 16.7 ms, so a
  # guest frame slow enough to be logged only happens once the map is live.
  n2=$(a shell "grep -c 'slow guest frame' $FILES/skate3.log" 2>/dev/null | tr -d '\r')
  if [ "${n2:-0}" -ge 20 ]; then break; fi
done

a shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
SERIAL=$SERIAL ./scripts/bench.sh $PKG 20 "$LABEL" 2>&1 \
  | grep -E 'fps \(presented\)|frame interval|over 20 ms|cpu |TOTAL PSS'
echo "   -- guest breakdown --"
a shell "grep 'slow guest frame' $FILES/skate3.log | tail -3" 2>/dev/null \
  | sed -E 's/.*native-scene: /   /'
