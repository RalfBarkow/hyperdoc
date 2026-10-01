"""Contract test for a built Catalog, without nix develop or repository cwd.

Run: python3 tests/test_catalog_executable.py /nix/store/.../bin/hyperdoc-catalog
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


class CatalogExecutableTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="catalog-contract-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        # Ambient runtime and personal Lisp/ASDF state must not supply the app.
        poison = self.root / "poison"
        poison.mkdir()
        for name in ("sbcl", "nix"):
            file = poison / name
            file.write_text("#!/bin/sh\nexit 97\n")
            file.chmod(0o755)
        (poison / "dreyeck.asd").write_text('(error "Personal ASDF registry used")')
        (self.root / ".sbclrc").write_text('(error "Personal SBCL init used")')
        config = self.root / ".config/common-lisp/source-registry.conf.d"
        config.mkdir(parents=True)
        (config / "10-poison.conf").write_text(f'(:tree "{poison}/")')
        self.env = {
            "HOME": str(self.root), "PATH": str(poison),
            "CL_SOURCE_REGISTRY": str(poison) + "//",
            "HYPERDOC_CATALOG_SYSTEM": "dreyeck/catalog",
            "HYPERDOC_CATALOG_HOST": "127.0.0.1",
            "HYPERDOC_FEDWIKI_SITE_ROOT": str(FIXTURE),
        }
        # Preserve only Darwin's temp location for the platform runtime.
        if "TMPDIR" in os.environ:
            self.env["TMPDIR"] = os.environ["TMPDIR"]

    def test_invalid_port(self):
        result = subprocess.run([EXECUTABLE, "65536"], cwd=self.root,
                                env=self.env, capture_output=True, text=True,
                                timeout=180)
        self.assertNotEqual(0, result.returncode)
        self.assertIn("Port must be an integer", result.stderr)

    def test_foreground_http_and_shutdown(self):
        for stop_signal in (signal.SIGTERM, signal.SIGINT):
            with self.subTest(signal=stop_signal):
                with socket.socket() as probe:
                    probe.bind(("127.0.0.1", 0))
                    port = probe.getsockname()[1]
                # Positional port must override the environment.
                self.env["HYPERDOC_CATALOG_PORT"] = "0"
                with tempfile.TemporaryFile(mode="w+b") as log:
                    process = subprocess.Popen([EXECUTABLE, str(port)], cwd=self.root,
                                               env=self.env, stdout=log, stderr=log)
                    try:
                        deadline = time.monotonic() + 180
                        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
                        while True:
                            if process.poll() is not None:
                                log.seek(0)
                                self.fail(log.read().decode(errors="replace"))
                            try:
                                with opener.open(f"http://127.0.0.1:{port}/", timeout=1) as response:
                                    self.assertEqual(200, response.status)
                                    self.assertIn(b'/js/boot.js', response.read())
                                break
                            except (OSError, urllib.error.URLError):
                                if time.monotonic() >= deadline:
                                    log.seek(0)
                                    self.fail("Catalog not ready:\n" + log.read().decode(errors="replace"))
                                time.sleep(0.1)
                        # /view responds through the same actual CLOG listener.
                        with opener.open(f"http://127.0.0.1:{port}/view/reading-java-source-as-data",
                                         timeout=5) as response:
                            self.assertEqual(200, response.status)
                        self.assertIsNone(process.poll())
                        process.send_signal(stop_signal)
                        self.assertEqual(0, process.wait(timeout=15))
                        log.seek(0)
                        output = log.read().decode(errors="replace")
                        self.assertIn(f"HyperBook Catalog listening on 127.0.0.1:{port}", output)
                        self.assertIn("Stopping HyperBook Catalog", output)
                        with socket.socket() as probe:
                            self.assertNotEqual(0, probe.connect_ex(("127.0.0.1", port)))
                        with socket.socket() as probe:
                            probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                            probe.bind(("127.0.0.1", port))
                    finally:
                        if process.poll() is None:
                            process.kill()
                            process.wait(timeout=10)


if __name__ == "__main__":
    unittest.main()
