#!/bin/bash
# Build libmain.so (the recompiled game plus the rexglue runtime) for arm64
# and stage it where Gradle will package it.
#
# This is the long one: 7.7 million lines of recompiled PowerPC. polite_build
# keeps it to three jobs and pauses it whenever the machine runs short of
# memory, because the final link alone wants several gigabytes.
#
# usage: build_native.sh [preset]   (default android-arm64-release)
set -euo pipefail
. "$(dirname "$0")/env.sh"
PRESET="${1:-$PRESET}"
BUILD_DIR="$ENGINE/out/build/$PRESET"
NDK_BIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin"

[ -d "$ANDROID_NDK_HOME" ] || { echo "no NDK at $ANDROID_NDK_HOME - run scripts/setup_sdk.sh"; exit 1; }

if [ ! -f "$BUILD_DIR/CMakeCache.txt" ]; then
  echo "== configuring $PRESET"
  (cd "$ENGINE" && cmake --preset "$PRESET")
fi

echo "== building (this takes hours; safe to leave)"
"$HOME/skate3/polite_build.sh" "$BUILD_DIR" skate3 "${JOBS:-3}"

SO="$BUILD_DIR/libmain.so"
[ -f "$SO" ] || { echo "no libmain.so at $SO"; exit 1; }

echo "== checks"
# Both must be exported or SDL cannot find the entry point after dlopen.
"$NDK_BIN/llvm-nm" -D --defined-only "$SO" | grep -E ' (SDL_main|JNI_OnLoad)$' || {
  echo "!! SDL_main or JNI_OnLoad is not exported - the static link hid it"; exit 1; }
# Android 15+ devices ship 16 KB pages and refuse to load a 4 KB-aligned library.
"$NDK_BIN/llvm-readelf" -lW "$SO" | awk '$1=="LOAD"{print $NF}' | while read -r a; do
  [ $((a)) -ge 16384 ] || { echo "!! LOAD segment aligned to $a, below 16 KB"; exit 1; }
done
echo "   exports and 16 KB alignment ok"

DEST="$APP_DIR/app/src/main/jniLibs/arm64-v8a/libmain.so"
mkdir -p "$(dirname "$DEST")"
"$NDK_BIN/llvm-strip" --strip-unneeded -o "$DEST" "$SO"
echo "== staged $(du -h "$DEST" | cut -f1) -> $DEST"
echo "   unstripped copy kept at $SO for ndk-stack"
