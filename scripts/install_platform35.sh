#!/bin/bash
set -euo pipefail
. "$(dirname "$0")/env.sh"
SDKM="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
[ -x "$SDKM" ] || SDKM=/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager
"$SDKM" --sdk_root="$ANDROID_HOME" "platforms;android-35"
ls "$ANDROID_HOME/platforms"
