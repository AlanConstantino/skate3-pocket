Skate 3 running as native ARM64 code on Android. This is not an emulator: the
Xbox 360 executable was translated ahead of time into C++ and compiled for the
phone, so the skating, physics and career mode are the retail game's own code
running natively. During gameplay the Xbox GPU is not emulated either, a native
renderer reads the game's scene state and draws it through Vulkan directly.

**No game content is included and none is bundled in the APK.** You supply your
own Skate 3 Xbox 360 disc image.

## What you need

- An arm64 Android phone, Android 9 or newer, with Vulkan. Built and measured on
  a Galaxy S23 FE.
- Your own Skate 3 Xbox 360 disc image, on the phone or a USB drive.
- About 7 GB free. Roughly 6 GB is extracted from the image and stays on the phone.

## Setting it up

1. Install the APK and open **Skate 3 Android**.
2. Choose **Install from a disc image** and pick your image. It is read where it
   lies and extracted, which takes a while.
3. Choose **Download title update**. The game cannot boot without Title Update 3
   and it is not shipped here. You can also pick your own copy of the package
   instead. Either way the engine verifies both patch payloads by hash and
   refuses anything that does not match.
4. Press **Play**.

## Controls

On-screen controls appear when no controller is attached and hide themselves
when one is. Bluetooth and USB controllers work through SDL.

## Tuning

The engine reads `files/user/android_args.txt` at startup, one setting per line.
The `android_args/` folder in the repository has profiles to start from, and
its README explains which of the iOS settings deliberately did not carry over.
`diagnostics.txt` turns on the frame pacing lines, and `scripts/perf.sh` reads
them back.

Defaults are inherited from a 4 GB iPhone and are conservative for a recent
phone. `quality.txt` spends that headroom on shadows, ambient occlusion and
antialiasing. Change one setting at a time.

## Known rough edges

- Several on-screen buttons draw a question mark instead of a label. The touch
  overlay is missing glyphs for the d-pad and Back/Start.
- The runtime logs a thread priority permission denial at startup. Android
  refuses the real-time scheduler to apps; it is harmless.
- It looks for a controller mapping database in a system path that does not
  exist on Android, and says so once.
- Custom map packs are wired to the same locations the iOS build scans, but the
  in-game picker has not been confirmed on a phone yet.

## Building it yourself

`scripts/build_native.sh` builds the native library from the engine tree, then
`scripts/build_apk.sh` packages it. The native build takes hours and needs your
own game files, since the recompiler consumes them. See the repository README.

## Credits

Built on the Skate 3 native recompilation and the rexglue SDK, which is derived
from Xenia's Xbox 360 research. The Android shell, platform work and tuning in
this release are new; the iOS port shares the same engine.
