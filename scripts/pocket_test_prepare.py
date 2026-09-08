#!/usr/bin/env python3
"""Offline regression tests for verified input preparation; no SDK or network needed."""
import hashlib
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import pocket_prepare as prepare


class PreparationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.payload = b"verified fixture input"
        self.spec = {"bytes": len(self.payload), "sha256": hashlib.sha256(self.payload).hexdigest(),
                     "filename": "input.bin", "url": "https://invalid.example/not-used"}

    def test_valid_copy_is_verified(self):
        target = self.root / "output"
        prepare.copy_checked(io.BytesIO(self.payload), target, self.spec)
        prepare.verified(target, self.spec)
        self.assertEqual(target.read_bytes(), self.payload)

    def test_bad_streams_preserve_existing_file_and_remove_temporary_files(self):
        target = self.root / "output"
        target.write_bytes(b"prior data")
        for bad in (self.payload[:-1], b"x" * len(self.payload), self.payload + b"x"):
            with self.subTest(size=len(bad)):
                with self.assertRaises(ValueError):
                    prepare.copy_checked(io.BytesIO(bad), target, self.spec)
                self.assertEqual(target.read_bytes(), b"prior data")
                self.assertEqual(list(self.root.iterdir()), [target])

    def test_interrupted_stream_does_not_publish_partial_file(self):
        class Interrupted(io.BytesIO):
            def read(self, size=-1):
                if self.tell():
                    raise OSError("fixture read interrupted")
                return super().read(3)
        with self.assertRaises(OSError):
            prepare.copy_checked(Interrupted(self.payload), self.root / "output", self.spec)
        self.assertEqual(list(self.root.iterdir()), [])

    def test_valid_cached_input_never_downloads(self):
        cached = self.root / self.spec["filename"]
        cached.write_bytes(self.payload)
        with patch.object(prepare.urllib.request, "urlopen", side_effect=AssertionError("network used")):
            self.assertEqual(prepare.fetch(self.spec, self.root), cached)

    def test_corrupt_cache_fails_without_silent_replacement(self):
        cached = self.root / self.spec["filename"]
        cached.write_bytes(b"damaged")
        with patch.object(prepare.urllib.request, "urlopen", side_effect=AssertionError("network used")):
            with self.assertRaises(ValueError):
                prepare.fetch(self.spec, self.root)
        self.assertEqual(cached.read_bytes(), b"damaged")

    def test_offline_miss_never_downloads(self):
        with patch.object(prepare.urllib.request, "urlopen", side_effect=AssertionError("network used")):
            with self.assertRaises(ValueError):
                prepare.fetch(self.spec, self.root, offline=True)

    def test_supplied_input_is_verified_before_cache_publication(self):
        inputs = self.root / "inputs"
        cache = self.root / "cache"
        inputs.mkdir(); cache.mkdir()
        candidate = inputs / self.spec["filename"]
        candidate.write_bytes(b"wrong")
        with self.assertRaises(ValueError):
            prepare.fetch(self.spec, cache, inputs, offline=True)
        self.assertEqual(list(cache.iterdir()), [])
        candidate.write_bytes(self.payload)
        result = prepare.fetch(self.spec, cache, inputs, offline=True)
        self.assertEqual(result.read_bytes(), self.payload)

    def test_locked_source_hash_rejects_modification(self):
        source = self.root / "native.cpp"
        source.write_bytes(self.payload)
        lock = {"vendored_files_sha256": {source.name: self.spec["sha256"]}}
        with patch.object(prepare, "ROOT", self.root):
            prepare.verify_sources(lock)
            source.write_bytes(b"changed source")
            with self.assertRaises(ValueError):
                prepare.verify_sources(lock)


if __name__ == "__main__":
    unittest.main()
