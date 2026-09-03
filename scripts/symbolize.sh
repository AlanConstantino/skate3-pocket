#!/bin/bash
# Turn a native crash in logcat into function names.
set -euo pipefail
. "$(dirname "$0")/env.sh"
adb -s "$SERIAL" logcat -d | "$ANDROID_NDK_HOME/ndk-stack" -sym "$ENGINE/out/build/$PRESET"
