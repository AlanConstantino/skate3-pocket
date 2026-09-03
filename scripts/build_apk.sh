#!/bin/bash
# Package the APK. Seconds, not hours: the native library is already built.
set -euo pipefail
. "$(dirname "$0")/env.sh"
cd "$APP_DIR"
[ -f app/src/main/jniLibs/arm64-v8a/libmain.so ] || {
  echo "no libmain.so staged - run scripts/build_native.sh first"; exit 1; }
./gradlew "${1:-assembleRelease}"
find app/build/outputs/apk -name '*.apk' -exec ls -lh {} \;
