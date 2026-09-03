#!/bin/bash
# Pull a run's log and read the frame pacing, memory and thermal state out of
# it. The analyzer is the one written for the iOS port; the [pace] lines it
# parses are produced by the same code.
set -euo pipefail
. "$(dirname "$0")/env.sh"
STAMP=$(date +%Y%m%d-%H%M%S)
DEST="$APP_DIR/logs/$STAMP"; mkdir -p "$DEST"
adb -s "$SERIAL" pull "$FILES/skate3.log" "$DEST/" 2>/dev/null || echo "(no skate3.log yet)"
adb -s "$SERIAL" pull "$FILES/stderr.log" "$DEST/" 2>/dev/null || true

if [ -f "$DEST/skate3.log" ]; then
  python3 "$HOME/skate3/tools/analyze_ios_log.py" "$DEST/skate3.log" || true
  echo; echo "== last pace lines"; grep '\[pace\]' "$DEST/skate3.log" | tail -5 || true
fi
echo; echo "== memory"
adb -s "$SERIAL" shell dumpsys meminfo "$PKG" | head -25 || true
echo; echo "== thermal"
adb -s "$SERIAL" shell dumpsys thermalservice | grep -A6 -i 'current temp' | head -20 || true
