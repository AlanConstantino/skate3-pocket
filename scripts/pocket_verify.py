#!/usr/bin/env python3
"""Verify a Pocket APK's native inputs, bundled driver, alignment and optional signature."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import zipfile

from pocket_prepare import ROOT, BUILD, load_lock, sha256


def member_hash(archive, member):
    digest = hashlib.sha256()
    with archive.open(member) as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--signed", action="store_true", help="Also require a valid APK signature")
    args = parser.parse_args()
    lock = load_lock()
    build = json.loads((BUILD / "build-manifest.json").read_text(encoding="utf-8"))
    if build["sources_lock_sha256"] != sha256(ROOT / "sources.lock.json"):
        raise ValueError("Native build manifest belongs to a different source lock; rebuild the proxy.")
    expected = {"lib/arm64-v8a/" + name: digest for name, digest in build["packaged_native_inputs"].items()}
    expected[lock["engine"]["archive_member"]] = lock["engine"]["sha256"]
    expected["assets/drivers/turnip-t30.zip"] = lock["downloads"]["bundled_turnip"]["sha256"]
    with zipfile.ZipFile(args.apk) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError("APK contains duplicate ZIP entries")
        native = {name for name in names if name.startswith("lib/") and name.endswith(".so")}
        if native != {name for name in expected if name.startswith("lib/")}:
            raise ValueError("APK native library set is not the four reviewed ARM64 libraries")
        for name, digest in expected.items():
            if member_hash(archive, name) != digest:
                raise ValueError(f"APK altered or omitted pinned input: {name}")
    sdk_value = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if not sdk_value:
        raise ValueError("Set ANDROID_HOME for zipalign/apksigner verification.")
    tools = Path(sdk_value).expanduser() / "build-tools/35.0.0"
    align = tools / ("zipalign.exe" if os.name == "nt" else "zipalign")
    subprocess.run([str(align), "-c", "-P", "16", "4", str(args.apk)], check=True)
    if args.signed:
        signer = tools / ("apksigner.bat" if os.name == "nt" else "apksigner")
        subprocess.run([str(signer), "verify", "--verbose", "--print-certs", str(args.apk)], check=True)
    report = {"apk": args.apk.name, "bytes": args.apk.stat().st_size, "sha256": sha256(args.apk),
              "verified_entries": expected, "signature_verified": args.signed, "alignment_verified": True,
              "sources_lock_sha256": build["sources_lock_sha256"], "gameplay_tested_by_this_script": False}
    (BUILD / "apk-verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"APK contents and alignment verified; SHA-256 {report['sha256']}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, zipfile.BadZipFile, subprocess.CalledProcessError) as error:
        sys.exit(f"Verification failed: {error}")
