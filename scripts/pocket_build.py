#!/usr/bin/env python3
"""Build Skate 3 Pocket with the pinned official engine and reviewed Vulkan proxy."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

from pocket_prepare import ROOT, BUILD, add_arguments, prepare, sha256

SIGNING = ("POCKET_KEYSTORE", "POCKET_KEY_ALIAS", "POCKET_STORE_PASSWORD", "POCKET_KEY_PASSWORD")
LIBRARIES = ("libvulkan.so", "libmain_hook.so", "libhook_impl.so")


def run(command, **kwargs):
    # Signing passwords remain in the environment; never print them in commands.
    print("Running:", " ".join(str(item) for item in command), flush=True)
    return subprocess.run([str(item) for item in command], check=True, **kwargs)


def tool(name, sdk):
    override = os.environ.get(name.upper())
    candidate = shutil.which(override or name)
    if candidate:
        return Path(candidate)
    suffix = ".exe" if os.name == "nt" else ""
    versions = sorted((sdk / "cmake").glob("*/bin/" + name + suffix), reverse=True)
    if versions:
        return versions[0]
    raise ValueError(f"{name} is missing. Install CMake and Ninja and add them to PATH.")


def sdk_path():
    value = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if not value:
        raise ValueError("Set ANDROID_HOME to your Android SDK directory.")
    sdk = Path(value).expanduser().resolve()
    if not sdk.is_dir():
        raise ValueError("ANDROID_HOME does not name an Android SDK directory.")
    return sdk


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    add_arguments(parser)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--prepare-only", action="store_true", help="Only fetch, verify and stage pinned inputs")
    mode.add_argument("--native-only", action="store_true", help="Prepare inputs and compile/stage the Vulkan proxy; skip Gradle")
    parser.add_argument("--variant", choices=("release", "debug"), default="release")
    parser.add_argument("--unsigned", action="store_true", help="Explicitly permit an unsigned release artifact (not installable)")
    parser.add_argument("--jobs", type=int, default=min(os.cpu_count() or 4, 6))
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    signing = {name: os.environ.get(name, "") for name in SIGNING}
    needs_apk = not (args.prepare_only or args.native_only)
    if needs_apk and args.variant == "release":
        if any(signing.values()) and not all(signing.values()):
            raise ValueError("Release signing configuration is incomplete; set all four POCKET_* signing variables.")
        if not all(signing.values()) and not args.unsigned:
            raise ValueError("Release builds require POCKET_KEYSTORE, POCKET_KEY_ALIAS, POCKET_STORE_PASSWORD and POCKET_KEY_PASSWORD. Use --unsigned explicitly for an unsigned APK.")
        if all(signing.values()) and not Path(signing["POCKET_KEYSTORE"]).expanduser().is_file():
            raise ValueError("POCKET_KEYSTORE does not name an existing keystore.")
    lock = prepare(args.input_dir, args.offline, args.download_cache)
    if args.prepare_only:
        return
    sdk = sdk_path()
    config = lock["toolchain"]
    ndk = Path(os.environ.get("ANDROID_NDK_HOME", str(sdk / "ndk" / config["ndk"]))).expanduser().resolve()
    properties = ndk / "source.properties"
    if not properties.is_file() or not re.search(r"^Pkg\.Revision\s*=\s*" + re.escape(config["ndk"]) + r"\s*$", properties.read_text(), re.MULTILINE):
        raise ValueError(f"Install the pinned Android NDK {config['ndk']} under ANDROID_HOME/ndk (or set ANDROID_NDK_HOME).")
    cmake = tool("cmake", sdk)
    ninja = tool("ninja", sdk)
    native_build = BUILD / "native"
    stage = BUILD / "stage"
    run([cmake, "-S", ROOT / "native", "-B", native_build, "-G", "Ninja",
         f"-DCMAKE_MAKE_PROGRAM={ninja}", f"-DCMAKE_TOOLCHAIN_FILE={ndk / 'build/cmake/android.toolchain.cmake'}",
         f"-DANDROID_ABI={config['android_abi']}", f"-DANDROID_PLATFORM=android-{config['android_api']}",
         "-DANDROID_STL=c++_static", "-DCMAKE_BUILD_TYPE=Release", f"-DCMAKE_INSTALL_PREFIX={stage}"])
    run([cmake, "--build", native_build, "--target", "vulkan", "main_hook", "hook_impl", "--parallel", args.jobs])
    run([cmake, "--install", native_build])
    jni = ROOT / "app/src/main/jniLibs/arm64-v8a"
    strip_name = "llvm-strip.exe" if os.name == "nt" else "llvm-strip"
    strip_tools = list((ndk / "toolchains/llvm/prebuilt").glob("*/bin/" + strip_name))
    if len(strip_tools) != 1:
        raise ValueError("Could not identify the pinned NDK llvm-strip executable.")
    for name in LIBRARIES:
        # Keep the original stage files for symbolization. Never strip the official engine.
        shutil.copyfile(stage / "lib/arm64-v8a" / name, jni / name)
        run([strip_tools[0], "--strip-debug", jni / name])
    manifest = {"sources_lock_sha256": sha256(ROOT / "sources.lock.json"), "toolchain": config,
                "packaged_native_inputs": {name: sha256(jni / name) for name in ("libmain.so",) + LIBRARIES},
                "proxy_debug_sections_removed": True, "engine_rebuilt": False}
    (BUILD / "build-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    if args.native_only:
        print("Native proxy staged; official engine is unchanged.")
        return
    java = Path(os.environ["JAVA_HOME"]) / "bin/java" if os.environ.get("JAVA_HOME") else shutil.which("java")
    if not java:
        raise ValueError("Install JDK 17 and set JAVA_HOME.")
    version = subprocess.run([str(java), "-version"], capture_output=True, text=True, check=True)
    if not re.search(r'version "17(?:[.\"]|$)', version.stderr + version.stdout):
        raise ValueError("This build requires JDK 17. Set JAVA_HOME to a JDK 17 installation.")
    variant = args.variant.title()
    wrapper = ["cmd", "/c", str(ROOT / "gradlew.bat")] if os.name == "nt" else ["sh", ROOT / "gradlew"]
    gradle_options = ["--no-daemon", "--console=plain"]
    if args.offline:
        gradle_options.append("--offline")
    run(wrapper + gradle_options + [f":app:assemble{variant}", f":app:lint{variant}"], cwd=ROOT)
    filename = "app-release-unsigned.apk" if args.variant == "release" and not all(signing.values()) else f"app-{args.variant}.apk"
    apk = ROOT / "app/build/outputs/apk" / args.variant / filename
    command = [sys.executable, ROOT / "scripts/pocket_verify.py", apk]
    if not (args.variant == "release" and not all(signing.values())):
        command.append("--signed")
    run(command)
    print(f"Built and verified: {apk}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        sys.exit(f"Build failed: {error}")
