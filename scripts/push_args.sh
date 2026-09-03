#!/bin/bash
# Replace the tuning file the engine reads at startup. One argument per line,
# '#' comments allowed; any key here beats the compiled-in default without a
# rebuild. Mirrors ~/skate3/ios_args/ on the iOS side.
set -euo pipefail
. "$(dirname "$0")/env.sh"
SRC="${1:?usage: push_args.sh <file>   (or: push_args.sh --clear)}"
if [ "$SRC" = "--clear" ]; then
  adb -s "$SERIAL" shell rm -f "$FILES/user/android_args.txt"
  echo "cleared"; exit 0
fi
adb -s "$SERIAL" shell mkdir -p "$FILES/user"
adb -s "$SERIAL" push "$SRC" "$FILES/user/android_args.txt"
echo "== now on the phone:"; adb -s "$SERIAL" shell cat "$FILES/user/android_args.txt"
