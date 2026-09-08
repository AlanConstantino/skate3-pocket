# Skate 3 Pocket 0.1.0

First public release of Skate 3 Pocket, an unofficial fork of Andrew Nakas's Skate 3 Android v0.1.19 with a GPU driver manager and Retroid Pocket 6 controller fixes.

- Import compatible Android ARM64 Turnip driver ZIPs, keep multiple drivers, and switch with **Apply and restart**.
- Bundled MrPurple T30 and the device's System GPU driver remain available.
- Includes the controller input and driver restart fixes from the private RP6 builds.
- Adds an About screen with upstream credits and third-party notices.
- Preserves Andrew's v0.1.19 native game engine.

## Install

Download **Skate3-Pocket-0.1.0-arm64.apk** and install it on an ARM64 Android device. Open **Skate 3 Pocket** and supply your own Xbox 360 Skate 3 disc image and the supported Title Update 3. No retail game files are bundled. Allow about 7 GB for extracted data.

The public app uses `io.github.alanconstantino.skate3pocket` and a dedicated release signing key. It installs alongside Andrew's app and earlier private test builds; their game data, saves, and driver selections do not transfer automatically. Keep your existing installation until you have transferred the data you need.

## Verification

The driver manager's production backend passed 25 cases and 428 assertions on a 12 GB Retroid Pocket 6 running Android 13. The signed public APK successfully imported R7 and switched among MrPurple T30, Mesa Turnip R7, and the System driver on that device; all three passed native Vulkan initialization checks. The About and third-party notice screens were also checked. This establishes those import and initialization paths, not comparative frame rates or compatibility with every driver.

Final release packaging and identity checks are recorded in the attached release manifest. All 48 SDL and game-activity classes match the working driver-manager build after DEX index normalization. No new gameplay session or FPS benchmark was run for this renamed APK. The complete native engine is reused from the upstream release; the public build scripts compile the Android shell and driver loader around the hash-verified binary.

## Credits

Thanks to [Andrew Nakas](https://github.com/andrewnakas/skate3-android), [Alex McHugh / Skate3Recomp](https://github.com/mchughalex/skate3recomp), the [Skate-specific ReXGlue runtime](https://github.com/mchughalex/rexglue-skate3), [ReXGlue](https://github.com/rexglue/rexglue-sdk), Xenia, SDL, Mesa/Turnip, MrPurple, and Billy Laws's libadrenotools and linker namespace support. Full credits and the optional PayPal support link for Alan's work on this fork are in the README.
