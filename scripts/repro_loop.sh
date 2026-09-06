#!/bin/bash
# Hammer the boot-to-gameplay path until the guest fault fires.
#
# The fault is a race, and playing for ten minutes hoping is a poor way to
# catch one. This device's own crash history has it at 45 s, 80 s and 833 s of
# uptime, so a good share of them land during load rather than deep in a
# session - which means restarting is a far denser way to hit it than playing.
#
# Each cycle boots through the demo path to gameplay, waits, and restarts.
# It stops the moment the crash log grows, and reports which cycle did it.
#
# usage: repro_loop.sh <serial> [cycles] [seconds_per_cycle]
set -uo pipefail
S="${1:?usage: repro_loop.sh <serial> [cycles] [secs]}"
CYCLES="${2:-20}"
DWELL="${3:-90}"
PKG=com.nakas.skate3
F=/sdcard/Android/data/$PKG/files
a() { adb -s "$S" "$@"; }

BASE=$(a shell "stat -c %s $F/skate3.log.crash 2>/dev/null" | tr -d '\r')
BASE=${BASE:-0}
echo "baseline crash log: $BASE bytes"

for i in $(seq 1 "$CYCLES"); do
  a shell am force-stop $PKG
  for _ in $(seq 1 15); do a shell pidof $PKG >/dev/null 2>&1 || break; sleep 1; done
  a shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
  a shell am start -S -f 0x10008000 -n $PKG/.SetupActivity >/dev/null 2>&1
  sleep 5
  # demo_path drives itself to gameplay; tap Play only if the launcher is up
  a shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  P=$(a shell cat /sdcard/ui.xml 2>/dev/null | tr '<' '\n' | grep 'text="PLAY"' \
      | sed -E 's/.*bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]".*/\1 \2 \3 \4/' \
      | awk '{print int(($1+$3)/2), int(($2+$4)/2)}')
  [ -n "$P" ] && a shell input tap $P >/dev/null 2>&1

  for _ in $(seq 1 "$DWELL"); do
    sleep 1
    SZ=$(a shell "stat -c %s $F/skate3.log.crash 2>/dev/null" | tr -d '\r')
    if [ -n "$SZ" ] && [ "$SZ" != "$BASE" ]; then
      echo "FIRED on cycle $i ($BASE -> $SZ bytes)"
      exit 0
    fi
  done
  echo "  cycle $i: no fault"
done
echo "no fault in $CYCLES cycles"
