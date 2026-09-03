#!/bin/bash
# Follow the live log, or with --pull collect the files the engine wrote.
set -euo pipefail
. "$(dirname "$0")/env.sh"
if [ "${1:-}" = "--pull" ]; then
  STAMP=$(date +%Y%m%d-%H%M%S)
  DEST="$APP_DIR/logs/$STAMP"; mkdir -p "$DEST"
  for f in skate3.log stderr.log skate3.log.crash; do
    adb -s "$SERIAL" pull "$FILES/$f" "$DEST/" 2>/dev/null || true
  done
  adb -s "$SERIAL" logcat -d -v time > "$DEST/logcat.txt" || true
  echo "== $DEST"; ls -la "$DEST"
  exit 0
fi
adb -s "$SERIAL" logcat -c 2>/dev/null || true
adb -s "$SERIAL" logcat -v time skate3:V SDL:V DEBUG:E libc:E AndroidRuntime:E "*:S"
