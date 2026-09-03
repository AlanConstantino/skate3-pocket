#!/bin/bash
# One-time: install the Android command-line tools, SDK platform, build tools and NDK.
# Idempotent - sdkmanager skips packages that are already installed.
set -euo pipefail
. "$(dirname "$0")/env.sh"

if ! command -v sdkmanager >/dev/null 2>&1 && [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo "== installing Android command-line tools via Homebrew"
  brew install --cask android-commandlinetools
fi
SDKMANAGER="$(command -v sdkmanager || true)"
[ -n "$SDKMANAGER" ] || SDKMANAGER="/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager"
echo "== sdkmanager: $SDKMANAGER"
mkdir -p "$ANDROID_HOME"

echo "== accepting licenses"
yes 2>/dev/null | "$SDKMANAGER" --sdk_root="$ANDROID_HOME" --licenses >/dev/null || true

echo "== installing packages"
"$SDKMANAGER" --sdk_root="$ANDROID_HOME" \
  "platform-tools" "platforms;android-36" "build-tools;36.0.0" "ndk;$NDK_VER" "cmdline-tools;latest"

echo "== done"
ls "$ANDROID_HOME"
ls "$ANDROID_HOME/ndk"
"$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/clang" --version | head -1
du -sh "$ANDROID_HOME"
df -h / | tail -1
