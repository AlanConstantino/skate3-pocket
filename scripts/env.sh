#!/bin/bash
# Shared environment for the Skate 3 Android scripts. Source it: `. scripts/env.sh`
export JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export NDK_VER="${NDK_VER:-28.2.13676358}"
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_HOME/ndk/$NDK_VER}"
export ANDROID_NDK_ROOT="$ANDROID_NDK_HOME"
export ENGINE="${ENGINE:-/Users/nakas/skate3/skate3recomp-dev}"
export PRESET="${PRESET:-android-arm64-release}"
export BUILD_DIR="$ENGINE/out/build/$PRESET"
export SERIAL="${SERIAL:-R5CX13SPC2J}"
export PKG="${PKG:-com.nakas.skate3}"
export FILES="/sdcard/Android/data/$PKG/files"
export APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
adbs() { adb -s "$SERIAL" "$@"; }
