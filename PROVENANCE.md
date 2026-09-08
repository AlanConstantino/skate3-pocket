# Build input provenance

Recorded on 2026-09-08. Pocket builds its Android application and custom driver proxy from source, then packages an unchanged engine from Andrew Nakas's official v0.1.19 APK. **This is not a full source rebuild of the game engine.** No retail disc image or extracted retail game assets are included. The engine nevertheless contains the upstream project's recompiled game code; it should not be described as containing no game code.

## Directly verified inputs

| Input | Origin / identity | SHA-256 |
| --- | --- | --- |
| Official APK | [Skate3-Android-v0.1.19.apk](https://github.com/andrewnakas/skate3-android/releases/download/v0.1.19/Skate3-Android-v0.1.19.apk), 90,414,506 bytes | `cd9eacda621828a9e9bfe93b80749253bd33a59af14d64ab3e615ccfbcee900f` |
| Preserved engine | `lib/arm64-v8a/libmain.so` extracted from the official APK, 85,759,392 bytes | `5c952868cf4e5b15a6e6d6b228adf83c6b3633884ba0237f28264af4e5796a39` |
| Android application source archive | [v0.1.19 source](https://github.com/andrewnakas/skate3-android/archive/refs/tags/v0.1.19.tar.gz), 166,080 bytes; tag tree `7941aed3a0b39cf78f54f8c6ea5ca6ee7430bf5c` | `3a9232bf404bef9bf80dbf4ab9405ea9325b5d57524889f441287191279ad6bb` |
| SDL source archive | [8bf3b7215ad9fc3deb583c6a3a37c6c67f2e24e4](https://github.com/libsdl-org/SDL/archive/8bf3b7215ad9fc3deb583c6a3a37c6c67f2e24e4.tar.gz), 15,977,394 bytes | `bb4f83f5d6041c3a22186cdac4e15ed71e4127a1a8532dbb382f4b730a334b61` |
| Bundled T30 ZIP | [turnip_mrpurple_T30-toasted.adpkg.zip](https://github.com/MrPurple666/purple-turnip/releases/download/vturnip_mrpurple_T30-toasted.adpkg/turnip_mrpurple_T30-toasted.adpkg.zip), 3,713,730 bytes | `f65b2d3353fd4aa7190bb5426b94468e99ffea7a58a830bc0c4651db89353227` |
| T30 library | `vulkan.purple.so` from that ZIP, 18,869,912 bytes | `1d80dfa019659b008e4669311db5b1e4a02af59ff1d5458a98e2f5fe18ed013b` |

Archive hashes identify the downloaded inputs used in this build; remotely regenerated source archives are not guaranteed to retain the same byte representation. Source commit identifiers establish the pinned source identity.

SDL Java source was taken from the pinned SDL commit. The native engine reports `SDL-3.5.0-release-3.4.0-428-g8bf3b7215`, matching this source revision. The engine also contains `2.6.0.24-dev.g05a60fa` and `Skate 3 [v2.6.0.24-dev.g05a60fa-Release]` build strings.

The proxy and hook libraries are compiled from Pocket's `driver_proxy.cpp` plus libadrenotools commit `8fae8ce254dfc1344527e05301e43f37dea2df80` and its liblinkernsbypass commit `aa3975893d83ef1bc84c321ec60c65fbf1287887`. This path uses the custom-driver loading facility; it does not enable unrelated GPU turbo, mapping, or BCn options. The exact corresponding dependency license texts are included in [licenses](licenses/).

The preserved T30 archive has schema version 1, package version `T30`, minimum Android API 30, library name `vulkan.purple.so`, and driver version `26.3.0-T30-1.4.359`. The embedded Mesa build identifier is `62ac221a33`. The ZIP contains only `meta.json` and that library.

## Verified source lineage, with a limited engine-source match

The Android application's GitHub repository is not itself marked as a GitHub fork. Andrew's public [rexglue-skate3 repository](https://github.com/andrewnakas/rexglue-skate3) is a fork of [mchughalex/rexglue-skate3](https://github.com/mchughalex/rexglue-skate3). This is the verified runtime lineage; it does not establish an Andrew-to-Buku application lineage.

The public runtime source reference inspected was commit `7eb0faf7787f5e01333c228b8e3f03c32f7295ea` on Andrew's `skate3-sdk-clean` branch. It pins SDL to the exact embedded engine revision and FFmpeg to `0604b464c7cb4ebc94940cf1f324a3b26b87717c` from `wmarti/FFmpeg`, branch `xenia-ffmpeg-canary-full`. The runtime also contains `thirdparty/ffmpeg-overlay` sources. Matching the SDL revision is strong evidence for that one component; it does **not** prove the complete runtime or FFmpeg source matches the preserved engine.

The engine contains FFmpeg codec and utility source-name/assertion strings. No standalone FFmpeg version, configure, or license string was identified, and no separate FFmpeg shared dependency is declared. The public runtime reference builds `libavcodec` and `libavutil` as static libraries. Its pinned FFmpeg Android ARM64 configuration declares LGPL 2.1-or-later with `CONFIG_STATIC=1`, `CONFIG_GPL=0`, `CONFIG_NONFREE=0`, `CONFIG_VERSION3=0`, and `CONFIG_GPLV3=0`. The configuration enables a restricted audio codec/demuxer set. The stored `FFMPEG_CONFIGURATION` string describes that FFmpeg configuration, not a verified command for building Andrew's complete engine.

## Evidence retained

[evidence/verified-inputs.json](evidence/verified-inputs.json) contains measured input sizes, hashes, embedded identifiers, and the source-match limitation. The evidence directory also retains primary release metadata, complete upstream tree listings, the runtime's `.gitmodules` and dependency CMake file, and exact committed FFmpeg license/configuration files. License texts were copied from their identified source revisions; no license text was reconstructed from memory.
