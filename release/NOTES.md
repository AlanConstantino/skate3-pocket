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

## Fixed since the first builds

Three separate reasons the app closed or refused to install, all found by
people testing on hardware the author does not own.

**It was built for one phone's CPU.** The recompiled game code carried ARMv8.3
instructions, which fault on anything older - a Cortex-A78, A76 or A55, which
is most Android hardware. The app closed the instant guest code ran, which
looked like the setup buttons failing because each one starts the game. It now
targets the common ARMv8 baseline and picks its atomics at run time, so recent
phones keep the fast path and older ones still work.

**It demanded GPU features it does not use.** Geometry shaders were required
by the emulated pipeline this build replaces. Adreno has them; PowerVR and
many Mali parts do not, and those devices exited during graphics setup.

**The title update could not be downloaded from inside the installer.** The
engine's wizard shelled out to curl, which Android does not ship, so it failed
on every device and reported it as a connection problem. It now downloads
through the app.

**It could not open a disc image from a USB drive.** The file picker returns an
open descriptor; naming it by path and re-opening it fails for anything under
system-only storage. It now reads the descriptor directly.

Also fixed: the app's own folder is created wherever it is needed rather than
only when starting the game, which is what made the title update download fail
with a missing-file error and free space read as 0.0 GB.

## Low-memory devices

`android_args/tiny.txt` in the repository puts every memory and distance
setting at its floor, for devices with around 3 GB of RAM. It quarters the
memory the largest textures take, quarters how much of the world is drawn, and
turns off every effect that carries its own full-screen target.

It cannot lower the 3D scene's resolution: the render scales only multiply
upward from 1, so there is no fractional setting to give. And it cannot help a
device whose CPU is the limit - the emulated game code is what costs the frame,
and no setting reduces how much the game simulates.

## Known rough edges

- Several on-screen buttons draw a question mark instead of a label. The touch
  overlay is missing glyphs for the d-pad and Back/Start.
- The runtime logs a thread priority permission denial at startup. Android
  refuses the real-time scheduler to apps; it is harmless.
- It looks for a controller mapping database in a system path that does not
  exist on Android, and says so once.
- Custom map packs work. Drop a pack folder, the data file and its header
  together, into the app's own folder alongside `game`. Confirmed on a phone
  with two packs installed.
- Suspending and resuming has been reported as freezing on at least one device.
  It has not reproduced here across repeated background and resume cycles, so
  if it happens to you the details are worth reporting.

## Building it yourself

`scripts/build_native.sh` builds the native library from the engine tree, then
`scripts/build_apk.sh` packages it. The native build takes hours and needs your
own game files, since the recompiler consumes them. See the repository README.

## Credits

Built on the Skate 3 native recompilation and the rexglue SDK, which is derived
from Xenia's Xbox 360 research. The Android shell, platform work and tuning in
this release are new; the iOS port shares the same engine.
