#!/bin/bash
# Shared environment for the Skate 3 Android scripts. Source it: `. scripts/env.sh`
export JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export NDK_VER="${NDK_VER:-28.2.13676358}"
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_HOME/ndk/$NDK_VER}"
export ANDROID_NDK_ROOT="$ANDROID_NDK_HOME"
export ENGINE="${ENGINE:-$HOME/skate3/skate3recomp-dev}"
export PRESET="${PRESET:-android-arm64-release}"
export BUILD_DIR="$ENGINE/out/build/$PRESET"
# Whatever single device is plugged in, rather than one hardcoded phone -
# testing happens across several now. Set SERIAL yourself when more than one
# is attached. A device listed as "unauthorized" has not had the USB debugging
# prompt accepted on its screen yet, and is reported rather than silently
# skipped, because every later command would otherwise fail with a confusing
# "device not found".
# Whatever single device is plugged in, rather than one hardcoded phone -
# testing happens across several now. Set SERIAL yourself when more than one
# is attached. Written to never fail: this file is sourced by scripts running
# under `set -e`, and a device being absent must not abort a build that does
# not need one.
if [ -z "${SERIAL:-}" ]; then
  _ready=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}')
  _pending=$(adb devices 2>/dev/null | awk 'NR>1 && NF==2 && $2!="device" {print $1" ("$2")"}')
  # grep -c already prints 0 when it matches nothing; it just exits 1 while
  # doing it. A fallback that prints as well yields "00", which is neither 0
  # nor 1, and made an empty list report as several devices attached.
  _count=$(printf '%s\n' "$_ready" | grep -c . || true)
  if [ "$_count" = "1" ]; then
    SERIAL="$_ready"
  elif [ "$_count" != "0" ]; then
    echo "several devices attached; set SERIAL to one of:" >&2
    printf '  %s\n' $_ready >&2
  fi
  if [ -n "$_pending" ]; then
    printf 'not usable yet: %s\n' "$_pending" >&2
  fi
fi
export SERIAL="${SERIAL:-}"
export PKG="${PKG:-io.github.alanconstantino.skate3pocket}"
export FILES="/sdcard/Android/data/$PKG/files"
export APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
adbs() { adb -s "$SERIAL" "$@"; }
