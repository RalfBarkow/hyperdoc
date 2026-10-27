"""Positive controls for scripts/topic-maps-snapshot.py verify: each change of the archive or manifest must fail.

Run: python3 tests/test_topic_maps_snapshot.py REPO COMMIT ARCHIVE MANIFEST
Reads the repository only; every altered copy is made in a temporary directory.
"""
import hashlib
import io
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/topic-maps-snapshot.py"
REPO, COMMIT, ARCHIVE, MANIFEST = sys.argv[1:5]
del sys.argv[1:5]


def verify(archive, manifest, directory):
    return subprocess.run([sys.executable, "-I", str(SCRIPT), "verify", REPO, COMMIT, str(archive), str(manifest),
                           str(Path(directory) / "evidence.json")], capture_output=True, text=True).returncode


def rewrite(directory, change):
    """A copy of the archive with CHANGE applied to its member list; returns the copy's path."""
    with tarfile.open(ARCHIVE) as source:
        members = [(info, source.extractfile(info).read() if info.isfile() else None) for info in source.getmembers()]
    members = change(members)
    path = Path(directory) / "altered.tar.gz"
    with tarfile.open(path, "w:gz", format=tarfile.PAX_FORMAT) as target:
        for info, data in members:
            target.addfile(info, io.BytesIO(data) if data is not None else None)
    return path


def manifest_with(directory, old, new):
    text = Path(MANIFEST).read_text(encoding="utf-8")
    assert old in text
    path = Path(directory) / "altered.manifest"
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    return path


def file_member(name, data, mode=0o644, template=None):
    info = tarfile.TarInfo(name)
    info.size, info.mode, info.mtime = len(data), mode, template.mtime if template else 0
    return info, data


class SnapshotVerifierControls(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="topic-maps-snapshot-control-")
        self.addCleanup(self.directory.cleanup)
        self.prefix = Path(ARCHIVE).name.removesuffix("-runtime.tar.gz")

    def assertRefused(self, archive=ARCHIVE, manifest=MANIFEST):
        self.assertNotEqual(0, verify(archive, manifest, self.directory.name))

    def test_unaltered_archive_verifies(self):
        self.assertEqual(0, verify(ARCHIVE, MANIFEST, self.directory.name))

    def altered(self, change):
        # The manifest names the archive's digest, so an altered archive is checked against a manifest naming it:
        # the refusal must come from the content checks, not from the digest alone.
        path = rewrite(self.directory.name, change)
        data = path.read_bytes()
        text = Path(MANIFEST).read_text(encoding="utf-8")
        start = text.index(':sha256 "') + 9
        old_digest = text[start:start + 64]
        manifest = manifest_with(self.directory.name, old_digest, hashlib.sha256(data).hexdigest())
        text = manifest.read_text(encoding="utf-8")
        start = text.index(":octets ") + 8
        end = text.index(")", start)
        manifest.write_text(text[:start] + str(len(data)) + text[end:], encoding="utf-8")
        return path, manifest

    def test_one_byte_changed(self):
        def change(members):
            for index, (info, data) in enumerate(members):
                if info.name.endswith("/src/ctm/lexer.lisp"):
                    info.size += 1
                    members[index] = (info, data + b" ")
            return members
        self.assertRefused(*self.altered(change))

    def test_mode_changed(self):
        def change(members):
            for info, _ in members:
                if info.name.endswith("/topic-maps.asd"):
                    info.mode = 0o755
            return members
        self.assertRefused(*self.altered(change))

    def test_extra_file(self):
        self.assertRefused(*self.altered(lambda m: m + [file_member(f"{self.prefix}/extra", b"x")]))

    def test_missing_file(self):
        self.assertRefused(*self.altered(lambda m: [(i, d) for i, d in m if not i.name.endswith("/examples/project-work.lisp")]))

    def test_symlink_member(self):
        def change(members):
            link = tarfile.TarInfo(f"{self.prefix}/LICENSE")
            link.type, link.linkname = tarfile.SYMTYPE, "README.md"
            return [(i, d) for i, d in members if not i.name.endswith(f"{self.prefix}/LICENSE")] + [(link, None)]
        self.assertRefused(*self.altered(change))

    def test_excluded_entry_shipped(self):
        self.assertRefused(*self.altered(lambda m: m + [file_member(f"{self.prefix}/reports/x.log", b"x")]))

    def test_manifest_with_another_nar_hash(self):
        text = Path(MANIFEST).read_text(encoding="utf-8")
        start = text.index(':nar-hash "') + 11
        self.assertRefused(manifest=manifest_with(self.directory.name, text[start:start + 8], "sha256-A"))

    def test_manifest_excluding_more(self):
        self.assertRefused(manifest=manifest_with(self.directory.name, ':excluded ("reports")', ':excluded ("reports" "docs")'))

    def test_manifest_with_another_commit_object(self):
        self.assertRefused(manifest=manifest_with(self.directory.name, "slice 22U", "slice 22V"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
