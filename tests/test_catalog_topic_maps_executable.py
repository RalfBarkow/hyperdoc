"""Contract test for a built hyperdoc-catalog-topic-maps, without nix develop or repository cwd.

Run: python3 tests/test_catalog_topic_maps_executable.py /nix/store/.../bin/hyperdoc-catalog-topic-maps
"""
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
import tempfile
import time
import unittest
import urllib.request

EXECUTABLE = str(Path(sys.argv.pop(1)).resolve())
FIXTURE = Path(__file__).resolve().parents[1] / "dreyeck/tests/fixtures/local-fedwiki-view-site"


class CatalogTopicMapsExecutableTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # One HOME for the class: the first start compiles into its cache, later starts reuse it.
        cls.temporary = tempfile.TemporaryDirectory(prefix="catalog-topic-maps-contract-")
        cls.root = Path(cls.temporary.name)
        # Ambient runtime and personal Lisp/ASDF state must not supply the app.
        poison = cls.root / "poison"
        poison.mkdir()
        for name in ("sbcl", "nix"):
            file = poison / name
            file.write_text("#!/bin/sh\nexit 97\n")
            file.chmod(0o755)
        for name in ("dreyeck.asd", "topic-maps.asd"):
            (poison / name).write_text('(error "Personal ASDF registry used")')
        (cls.root / ".sbclrc").write_text('(error "Personal SBCL init used")')
        config = cls.root / ".config/common-lisp/source-registry.conf.d"
        config.mkdir(parents=True)
        (config / "10-poison.conf").write_text(f'(:tree "{poison}/")')
        cls.env = {"HOME": str(cls.root), "PATH": str(poison), "CL_SOURCE_REGISTRY": str(poison) + "//",
                   "HYPERDOC_FEDWIKI_SITE_ROOT": str(FIXTURE)}
        if "TMPDIR" in os.environ:
            cls.env["TMPDIR"] = os.environ["TMPDIR"]

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def run_executable(self, *arguments, **environment):
        return subprocess.run([EXECUTABLE, *arguments], cwd=self.root, env={**self.env, **environment},
                              capture_output=True, text=True, timeout=600)

    def test_public_hosts_refused_before_loading(self):
        for host in ("0.0.0.0", "::", "localhost", "dreyeck.ch"):
            with self.subTest(host=host):
                result = self.run_executable(HYPERDOC_CATALOG_HOST=host)
                self.assertEqual(2, result.returncode)
                self.assertIn("serves loopback only", result.stderr)
                self.assertNotIn("Topic Maps snapshot verified", result.stdout)

    def test_project_workspace_refused(self):
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", 0))
            port = probe.getsockname()[1]
        result = self.run_executable(str(port), HYPERDOC_CATALOG_SYSTEM="dreyeck/work/project")
        self.assertNotEqual(0, result.returncode)
        self.assertIn("Topic Maps snapshot verified without .git", result.stdout)
        self.assertIn("which this runtime does not admit", result.stderr)
        with socket.socket() as probe:
            self.assertNotEqual(0, probe.connect_ex(("127.0.0.1", port)))

    def test_loopback_staging_http_and_shutdown(self):
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", 0))
            port = probe.getsockname()[1]
        environment = {**self.env, "HYPERDOC_CATALOG_SYSTEM": "dreyeck/work/topic-maps-ctm-review"}
        with tempfile.TemporaryFile(mode="w+b") as log:
            process = subprocess.Popen([EXECUTABLE, str(port)], cwd=self.root, env=environment, stdout=log, stderr=log)
            try:
                deadline = time.monotonic() + 600
                opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
                while True:
                    if process.poll() is not None:
                        log.seek(0)
                        self.fail(log.read().decode(errors="replace"))
                    try:
                        with opener.open(f"http://127.0.0.1:{port}/", timeout=1) as response:
                            self.assertEqual(200, response.status)
                            self.assertIn(b"/js/boot.js", response.read())
                        break
                    except (OSError, urllib.error.URLError):
                        if time.monotonic() >= deadline:
                            log.seek(0)
                            self.fail("Catalog not ready:\n" + log.read().decode(errors="replace"))
                        time.sleep(0.2)
                self.assertIsNone(process.poll())
                process.send_signal(signal.SIGTERM)
                self.assertEqual(0, process.wait(timeout=15))
                log.seek(0)
                output = log.read().decode(errors="replace")
                self.assertIn("Topic Maps snapshot verified without .git", output)
                self.assertIn(f"HyperBook Catalog listening on 127.0.0.1:{port}", output)
                self.assertIn("Stopping HyperBook Catalog", output)
                with socket.socket() as probe:
                    self.assertNotEqual(0, probe.connect_ex(("127.0.0.1", port)))
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait(timeout=10)


if __name__ == "__main__":
    unittest.main(verbosity=2)
