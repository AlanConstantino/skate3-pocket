#!/bin/bash
# Development shortcut: push the already-extracted disc dump straight to the
# phone instead of installing it from an image on the device. About 6 GB over
# USB, and the destination is a FUSE mount, so it is not quick.
#
# The player-facing route is the setup screen, which reads the image through
# the system document picker and lets the engine extract it at storage speed.
set -euo pipefail
. "$(dirname "$0")/env.sh"
GAME="${1:-$HOME/skate3/game}"
TU="${2:-$HOME/skate3/TU_12K2276_000000C000000.00000000000O3}"

[ -d "$GAME" ] || { echo "no game dump at $GAME"; exit 1; }
echo "== $(du -sh "$GAME" | cut -f1) -> $FILES/game"
adb -s "$SERIAL" shell mkdir -p "$FILES/game" "$FILES/user"
time adb -s "$SERIAL" push "$GAME/." "$FILES/game/"
if [ -f "$TU" ]; then
  adb -s "$SERIAL" push "$TU" "$FILES/$(basename "$TU")"
  echo "== title update pushed; the engine stages it from:"
  echo "   --skate3_install_tu=$FILES/$(basename "$TU")"
fi
adb -s "$SERIAL" shell ls -la "$FILES/game" | head
