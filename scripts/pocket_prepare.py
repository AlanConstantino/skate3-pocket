#!/usr/bin/env python3
"""Prepare checksum-pinned binary inputs; never download game data or build the engine."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / ".pocket-build"


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def load_lock():
    lock = json.loads((ROOT / "sources.lock.json").read_text(encoding="utf-8"))
    if lock["schema_version"] != 1:
        raise ValueError("Unsupported sources.lock.json schema")
    return lock


def verified(path, spec):
    path = Path(path)
    if not path.is_file() or path.stat().st_size != spec["bytes"]:
        raise ValueError(f"Missing file or unexpected size: {path}")
    if sha256(path) != spec["sha256"]:
        raise ValueError(f"SHA-256 mismatch: {path}")


def copy_checked(source, destination, spec):
    """Stream at most the pinned size, verify, then publish with an atomic rename."""
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    pending = None
    try:
        with tempfile.NamedTemporaryFile(dir=destination.parent, prefix=".pocket-", delete=False) as output:
            pending = Path(output.name)
            count = 0
            digest = hashlib.sha256()
            while True:
                block = source.read(min(1024 * 1024, spec["bytes"] - count + 1))
                if not block:
                    break
                count += len(block)
                if count > spec["bytes"]:
                    raise ValueError(f"Input exceeds its pinned size: {destination.name}")
                digest.update(block)
                output.write(block)
            if count != spec["bytes"] or digest.hexdigest() != spec["sha256"]:
                raise ValueError(f"Input size or SHA-256 mismatch: {destination.name}")
            output.flush()
            os.fsync(output.fileno())
        pending.chmod(0o644)
        os.replace(pending, destination)
        pending = None
    finally:
        if pending is not None:
            pending.unlink(missing_ok=True)


def fetch(spec, cache, input_dir=None, offline=False):
    destination = cache / spec["filename"]
    if destination.exists():
        verified(destination, spec)
        return destination
    candidate = input_dir / spec["filename"] if input_dir else None
    if candidate is not None and candidate.is_file():
        with candidate.open("rb") as source:
            copy_checked(source, destination, spec)
        return destination
    if offline:
        raise ValueError(f"Offline input missing: {destination}. Supply --input-dir with {spec['filename']}.")
    print(f"Downloading {spec['filename']} ({spec['bytes']:,} bytes)", flush=True)
    request = urllib.request.Request(spec["url"], headers={"User-Agent": "Skate3Pocket-build/1"})
    with urllib.request.urlopen(request, timeout=60) as response:
        if not response.geturl().startswith("https://"):
            raise ValueError("Refusing a download redirected outside HTTPS")
        copy_checked(response, destination, spec)
    return destination


def verify_sources(lock):
    for relative, expected in lock["vendored_files_sha256"].items():
        path = ROOT / relative
        if not path.is_file() or sha256(path) != expected:
            raise ValueError(f"Pinned native/SDL source changed or is missing: {relative}. Review and update sources.lock.json intentionally.")


def prepare(input_dir=None, offline=False, cache=None):
    lock = load_lock()
    verify_sources(lock)
    cache = Path(cache).expanduser().resolve() if cache else BUILD / "downloads"
    input_dir = Path(input_dir).expanduser().resolve() if input_dir else None
    cache.mkdir(parents=True, exist_ok=True)
    apk = fetch(lock["downloads"]["official_engine_apk"], cache, input_dir, offline)
    driver = fetch(lock["downloads"]["bundled_turnip"], cache, input_dir, offline)
    engine = lock["engine"]
    with zipfile.ZipFile(apk) as archive:
        matches = [item for item in archive.infolist() if item.filename == engine["archive_member"]]
        if len(matches) != 1 or matches[0].file_size != engine["bytes"]:
            raise ValueError("Official APK does not contain exactly the pinned ARM64 game library")
        with archive.open(matches[0]) as source:
            copy_checked(source, ROOT / engine["destination"], engine)
    with driver.open("rb") as source:
        copy_checked(source, ROOT / lock["bundled_turnip"]["destination"], lock["downloads"]["bundled_turnip"])
    print("Verified and prepared the official v0.1.19 engine, bundled T30 ZIP, native sources, and SDL Java.")
    return lock


def add_arguments(parser):
    parser.add_argument("--offline", action="store_true", help="Do not access the network; require cached inputs")
    parser.add_argument("--input-dir", type=Path, help="Optional directory containing official-v0.1.19.apk and mrpurple-t30.zip")
    parser.add_argument("--download-cache", type=Path, help="Optional shared input cache; every cached file is still verified")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    add_arguments(parser)
    args = parser.parse_args()
    prepare(args.input_dir, args.offline, args.download_cache)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        sys.exit(f"Preparation failed: {error}")
