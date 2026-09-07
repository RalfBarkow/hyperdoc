"""Run with: nix develop --command python3 tests/test_hyperdoc_sly.py"""
import importlib.util
import os
from pathlib import Path
import shlex
import shutil
import socket
import subprocess
import tempfile
import threading
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("launcher", ROOT / "scripts/hyperdoc-sly.py")
launcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(launcher)


class EndpointTests(unittest.TestCase):
    def test_handoff_validation(self):
        for data in (b"", b"127.0.0.1\t0\tSBCL\t1\n",
                     b"0.0.0.0\t1234\tSBCL\t1\n", b"garbage\n"):
            reader, writer = os.pipe()
            try:
                os.write(writer, data)
                os.close(writer)
                with self.assertRaises((RuntimeError, ValueError)):
                    launcher.read_endpoint(reader, timeout=1)
            finally:
                os.close(reader)

    def test_fragmented_endpoint(self):
        reader, writer = os.pipe()
        def deliver():
            try:
                os.write(writer, b"127.0.0.1\t")
                os.write(writer, b"54321\tSBCL\t2.4.10\n")
            finally:
                os.close(writer)
        thread = threading.Thread(target=deliver)
        thread.start()
        try:
            self.assertEqual(launcher.read_endpoint(reader),
                             ("127.0.0.1", 54321, "SBCL", "2.4.10"))
        finally:
            thread.join()
            os.close(reader)

    def test_dynamic_port_request(self):
        # Combine the allocation request with the real socket inspection below:
        # the returned positive port is allocated by the kernel, never guessed.
        source = (ROOT / "scripts/hyperdoc-slynk.lisp").read_text()
        self.assertRegex(source, r'slynk:create-server :interface "127\.0\.0\.1" :port 0')

    def test_startup_timeout(self):
        reader, writer = os.pipe()
        try:
            with self.assertRaisesRegex(RuntimeError, "Timed out"):
                launcher.read_endpoint(reader, timeout=0)
        finally:
            os.close(reader)
            os.close(writer)

    def test_real_launcher(self):
        # Wrappers count every SBCL invocation and turn only the GUI invocation
        # into a batch Emacs running the unchanged production attachment file.
        with tempfile.TemporaryDirectory() as directory:
            tmp = Path(directory)
            sbcl = shutil.which("sbcl")
            emacs = shutil.which("emacs")
            self.assertTrue(sbcl and emacs, "Run inside nix develop")
            (tmp / "sbcl").write_text(
                '#!/bin/sh\necho "$$" >> "$HYPERDOC_TEST_PIDS"\nexec '
                + shlex.quote(sbcl) + ' "$@"\n')
            (tmp / "emacs").write_text(
                '#!/bin/sh\ncase " $* " in\n*" --batch "*) exec '
                + shlex.quote(emacs) + ' "$@" ;;\n*) exec '
                + shlex.quote(emacs) + ' --batch "$@" --load '
                + shlex.quote(str(ROOT / "tests/hyperdoc-sly-clients.el"))
                + ' ;;\nesac\n')
            for name in ("sbcl", "emacs"):
                (tmp / name).chmod(0o755)
            env = dict(os.environ, PATH=str(tmp) + os.pathsep + os.environ["PATH"],
                       HYPERDOC_TEST_PIDS=str(tmp / "pids"),
                       HYPERDOC_TEST_RESULT=str(tmp / "result"))
            # Repeat to prove each startup is fresh; each run checks absence of
            # the previous witness before creating its own.
            for _ in range(2):
                (tmp / "pids").write_text("")
                process = subprocess.Popen(["bash", "scripts/hyperdoc-sly.sh"],
                    cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT)
                try:
                    output, _ = process.communicate(timeout=180)
                finally:
                    launcher.stop(process)
                result = subprocess.CompletedProcess(process.args, process.returncode, output)
                self.assertEqual(result.returncode, 0, result.stdout)
                pid, port = map(int, (tmp / "result").read_text().splitlines())
                self.assertEqual((tmp / "pids").read_text().splitlines(), [str(pid)])
                self.assertIn(f"Repository: {ROOT}", result.stdout)
                for label, args in (("Branch:     ", ["branch", "--show-current"]),
                                    ("Commit:     ", ["rev-parse", "--short=12", "HEAD"])):
                    value = subprocess.check_output(["git"] + args, cwd=ROOT, text=True).strip()
                    self.assertIn(label + value, result.stdout)
                self.assertIn("implementation/version: SBCL", result.stdout)
                self.assertIn("Slynk host: 127.0.0.1", result.stdout)
                self.assertIn(f"Slynk port: {port}", result.stdout)
                self.assertIn(f"Port: {port}", result.stdout)
                self.assertIn(f"Spacemacs -> M-x sly-connect -> 127.0.0.1 -> {port}", result.stdout)
                with self.assertRaises(ProcessLookupError):
                    os.kill(pid, 0)
                with socket.socket() as connection:
                    self.assertNotEqual(connection.connect_ex(("127.0.0.1", port)), 0)

            # Startup failure must not print attachment instructions or start
            # the initial editor. The discovery invocation is still permitted.
            (tmp / "sbcl").write_text('#!/bin/sh\nexit 17\n')
            failed = subprocess.run(["bash", "scripts/hyperdoc-sly.sh"],
                cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, timeout=30)
            self.assertNotEqual(failed.returncode, 0)
            self.assertNotIn("Attach another SLY client:", failed.stdout)
            self.assertIn("invalid endpoint", failed.stdout)


if __name__ == "__main__":
    unittest.main()
