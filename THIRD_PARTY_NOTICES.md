# Third-party notices

This file records identified components and preserves the available notices for the pinned inputs described in [PROVENANCE.md](PROVENANCE.md). It does not place an umbrella license on upstream application code, the upstream engine, or the packaged driver.

## SDL

Android Java sources are taken from [SDL commit 8bf3b7215ad9fc3deb583c6a3a37c6c67f2e24e4](https://github.com/libsdl-org/SDL/tree/8bf3b7215ad9fc3deb583c6a3a37c6c67f2e24e4). This matches the SDL revision string embedded in the preserved upstream engine.

Copyright (C) 1997-2026 Sam Lantinga <slouken@libsdl.org>.

The exact upstream zlib license is reproduced in [licenses/SDL-zlib.txt](licenses/SDL-zlib.txt). Original source notices are retained. Pocket's application changes are not represented as original SDL source.

## libadrenotools and liblinkernsbypass

The custom Vulkan loader uses source from:

- [libadrenotools, commit 8fae8ce254dfc1344527e05301e43f37dea2df80](https://github.com/bylaws/libadrenotools/tree/8fae8ce254dfc1344527e05301e43f37dea2df80).
- [liblinkernsbypass, commit aa3975893d83ef1bc84c321ec60c65fbf1287887](https://github.com/bylaws/liblinkernsbypass/tree/aa3975893d83ef1bc84c321ec60c65fbf1287887).

Both carry Copyright (c) 2021 Billy Laws and the BSD 2-Clause license. The exact texts are reproduced in [licenses/libadrenotools-BSD-2-Clause.txt](licenses/libadrenotools-BSD-2-Clause.txt) and [licenses/liblinkernsbypass-BSD-2-Clause.txt](licenses/liblinkernsbypass-BSD-2-Clause.txt). These notices accompany the source-built proxy and hook binaries.

## ReXGlue and Xenia source reference

Andrew's public [ReXGlue runtime reference at 7eb0faf7787f5e01333c228b8e3f03c32f7295ea](https://github.com/andrewnakas/rexglue-skate3/tree/7eb0faf7787f5e01333c228b8e3f03c32f7295ea) carries the notice reproduced verbatim in [licenses/ReXGlue-runtime-reference-LICENSE.txt](licenses/ReXGlue-runtime-reference-LICENSE.txt): Copyright (c) 2026 Tom Clay; portions derived from Xenia, Copyright (c) 2022 Ben Vanik and the Xenia contributors. Its text includes the BSD three-clause redistribution conditions and no-endorsement condition.

This is a notice from the available runtime source reference. The reference has not been established as the exact complete source revision used to build Andrew's v0.1.19 engine, and this notice is not a license declaration for every component in that engine.

## FFmpeg

FFmpeg codec and utility code is identifiable in the preserved upstream engine. Andrew's available runtime source reference pins [wmarti/FFmpeg commit 0604b464c7cb4ebc94940cf1f324a3b26b87717c](https://github.com/wmarti/FFmpeg/tree/0604b464c7cb4ebc94940cf1f324a3b26b87717c). Its Android ARM64 configuration declares **LGPL version 2.1 or later** and disables GPL, GPLv3, version-3, and nonfree options. The available SDK CMake builds the codec and utility libraries statically.

The exact LGPL 2.1 text from that commit is reproduced in [licenses/FFmpeg-LGPL-2.1.txt](licenses/FFmpeg-LGPL-2.1.txt). The source's license overview and Android configuration are retained under [evidence](evidence/). Those files describe the identified source reference; the exact FFmpeg revision and complete configuration of the preserved binary have not been independently established. Including this notice and a source reference does not itself establish that all requirements for distributing the combined binary have been met.

## Mesa/Turnip T30

The optional bundled driver is the unchanged [MrPurple T30 release](https://github.com/MrPurple666/purple-turnip/releases/tag/vturnip_mrpurple_T30-toasted.adpkg). Its metadata identifies Mesa, Mr_Purple_666, and driver version 26.3.0-T30-1.4.359. Its binary identifies `PurpleVK 26.3.0-devel (git-62ac221a33)`.

Mesa's [license documentation](https://docs.mesa3d.org/license.html) explains that most Mesa code uses MIT terms, while individual components can have other licenses. The downloaded T30 archive contains metadata and one driver library, with no license file. Its public release description identifies upstream Mesa plus patches. An exact source and notice inventory for this particular patched binary has not been located, so this file does not assign a blanket MIT license to the archive.

## Upstream Android application and engine

The application source is based on [andrewnakas/skate3-android v0.1.19](https://github.com/andrewnakas/skate3-android/tree/v0.1.19), and the native engine is preserved from its [v0.1.19 APK release](https://github.com/andrewnakas/skate3-android/releases/tag/v0.1.19). No LICENSE, COPYING, or NOTICE file was found in that tag's complete source tree. No license for that application or the whole native engine is invented here.

This is a targeted notice inventory for the native and Android input inputs audited for this release. It is not a claim that a complete transitive dependency or legal compliance audit has been performed.
