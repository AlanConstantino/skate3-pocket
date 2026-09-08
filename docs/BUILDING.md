# Building Skate 3 Pocket

Use the `scripts/pocket_*.py` entry points for this fork. The older upstream
scripts remain in the repository for reference; they target a separately built
engine and are not this fork's build path.

The build preserves the native engine from the official **Skate 3 Android
v0.1.19** APK. It compiles the Vulkan loader proxy, then packages that proxy with
the Pocket Android app, the matching SDL Java classes, and the original
MrPurple Turnip T30 ZIP. It does **not** rebuild the game engine or download game
files, saves, title updates, or other game assets.

## Prerequisites

The documented host environments are macOS and Linux. Install:

- Python 3.9 or newer, JDK 17, CMake 3.22 or newer, and Ninja.
- Android SDK command-line tools, platform `android-35`, build tools `35.0.0`,
  and NDK `27.2.12479018`.
- The repository's Gradle wrapper downloads Gradle 8.12 and the dependencies
  declared by the app on the first build.

Set `JAVA_HOME` to your JDK 17 installation and `ANDROID_HOME` to your SDK.
Put `cmake` and `ninja` on `PATH`; alternatively, the scripts can find them in
the SDK's `cmake/*/bin` directories. `CMAKE` and `NINJA` can specify executable
paths. An optional `ANDROID_NDK_HOME` must still point to the exact pinned NDK.

Using an installed `sdkmanager`:

```sh
sdkmanager "platforms;android-35" "build-tools;35.0.0" "ndk;27.2.12479018"
```

No Android device is needed to build or verify an APK.

## Signed release build

Keep your signing key outside the repository. To create your own key, run
`keytool -genkeypair` with your chosen keystore path and alias, then answer its
interactive prompts. Reuse the same key for updates to your installed app.

Set all four release-signing variables before building:

| Variable | Value |
| --- | --- |
| `POCKET_KEYSTORE` | Absolute path to your keystore |
| `POCKET_KEY_ALIAS` | Alias inside that keystore |
| `POCKET_STORE_PASSWORD` | Keystore password |
| `POCKET_KEY_PASSWORD` | Key password |

The scripts do not include signing values in command arguments or build
manifests. No private key or credentials are provided by this repository.

From the repository root:

```sh
python3 scripts/pocket_build.py
```

The result is `app/build/outputs/apk/release/app-release.apk`. The script runs
the release lint task, verifies the four packaged ARM64 libraries against the
staged build, checks the pinned engine and bundled driver checksums, and runs
`zipalign` and `apksigner` verification. A build is not a gameplay test; test the
APK on the intended device before publishing claims about performance.

For a local debug APK with Android's debug signing configuration:

```sh
python3 scripts/pocket_build.py --variant debug
```

For an explicitly unsigned release, omit all four signing variables and use
`--unsigned`. Its filename is `app-release-unsigned.apk`; sign it separately
before installation. Partial signing configurations are rejected.

## Pinned downloads and offline inputs

`sources.lock.json` records the release URLs, SHA-256 values, sizes, native
dependency revisions, and hashes of the vendored native/SDL sources. The two
binary downloads total about 94 MB and are stored under
`.pocket-build/downloads/`:

- `official-v0.1.19.apk`: the official Nakas release; only
  `lib/arm64-v8a/libmain.so` is extracted.
- `mrpurple-t30.zip`: the original MrPurple driver archive, copied unchanged
  to `app/src/main/assets/drivers/turnip-t30.zip`.

Every reuse checks the size and SHA-256. A changed upstream release or damaged
cache fails the build. There is no fallback to a newer release or another
driver. Only the two explicitly named files are staged from a supplied input
directory.

To reuse existing downloads with those filenames:

```sh
python3 scripts/pocket_build.py --offline --input-dir /path/to/pinned-inputs
```

`--offline` prevents downloading inputs and also passes `--offline` to Gradle.
A complete offline build needs the Gradle distribution and app dependencies
already cached. The wrapper may still need to download Gradle itself if its
distribution is absent. You can also use `--download-cache` to share a verified
download cache between checkouts.

Useful partial steps:

```sh
python3 scripts/pocket_prepare.py
python3 scripts/pocket_build.py --native-only --offline
python3 scripts/pocket_verify.py app/build/outputs/apk/release/app-release.apk --signed
python3 scripts/pocket_test_prepare.py
```

The build writes local provenance reports to
`.pocket-build/build-manifest.json` and `.pocket-build/apk-verification.json`.
The reports contain checksums, not credentials. Native binaries, downloaded
archives, generated APKs, SDK paths, and signing keys are excluded from Git.
The pinned NDK's `llvm-strip --strip-debug` removes debug sections from the
three newly built proxy/helper libraries before packaging. Their unstripped
copies remain under `.pocket-build/stage/` for local symbolization. The official
game library is never stripped or otherwise altered.

## Native sources and intentional changes

`native/driver_proxy.cpp`, `native/CMakeLists.txt`, and `native/exports.map` are
the reviewed proxy used by the working T30 build. `native/vendor/` contains
libadrenotools and its linkernsbypass dependency with their licenses. The proxy
build uses the custom-driver loader path; optional GPU mapping, redirection,
and BCn patch features are not enabled. See `native/PROVENANCE.md`.

The app must preload and initialize the proxy before the original native
engine. Changing drivers requires restarting the process. The native probe
requires Mesa Turnip identity for a selected custom driver; a failed check
does not silently select the system driver.

When intentionally editing native or SDL Java source, update the relevant
`vendored_files_sha256` entries in `sources.lock.json` after review and testing.
The preparation script otherwise refuses to build from unexpected source
bytes. Build tools may produce different binary bytes across host environments;
the lock pins inputs and the APK check proves which native bytes were actually
packaged, rather than claiming that all signed APKs are bit-for-bit identical.
