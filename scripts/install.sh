#!/bin/bash
# Install the APK on the phone and start it.
set -euo pipefail
. "$(dirname "$0")/env.sh"
APK=$(find "$APP_DIR/app/build/outputs/apk" -name '*.apk' | sort | tail -1)
[ -n "$APK" ] || { echo "no APK built"; exit 1; }
echo "== installing $(basename "$APK")"
adb -s "$SERIAL" install -r "$APK"
adb -s "$SERIAL" shell am start -n "$PKG/.SetupActivity"
