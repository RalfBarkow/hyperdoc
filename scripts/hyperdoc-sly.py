"""Own a fresh SBCL and attach Emacs to its reported Slynk endpoint."""

import os
from pathlib import Path
import queue
import selectors
import signal
import subprocess
import tempfile
import threading
import time


def read_endpoint(fd, timeout=120):
    # Dedicated pipe: neither compiler output nor Emacs output is a protocol.
    with selectors.DefaultSelector() as ready:
        ready.register(fd, selectors.EVENT_READ)
        deadline = time.monotonic() + timeout
        data = b""
        while b"\n" not in data:
            if not ready.select(max(0, deadline - time.monotonic())):
                raise RuntimeError("Timed out waiting for Slynk startup")
            chunk = os.read(fd, 4096)
            if not chunk:
                break
            data += chunk
            if len(data) > 4096:
                raise RuntimeError("Oversized Slynk endpoint")
        message = data.decode("utf-8")
    fields = message.rstrip("\n").split("\t")
    if len(fields) != 4 or not message.endswith("\n"):
        raise RuntimeError("SBCL exited or sent an invalid endpoint")
    host, port, implementation, version = fields
    if host != "127.0.0.1" or not 0 < int(port) < 65536:
        raise RuntimeError("Invalid Slynk address")
    return host, int(port), implementation, version


def banner(repo, endpoint):
    host, port, implementation, version = endpoint
    branch = subprocess.check_output(["git", "branch", "--show-current"],
                                     cwd=repo, text=True).strip()
    commit = subprocess.check_output(["git", "rev-parse", "--short=12", "HEAD"],
                                     cwd=repo, text=True).strip()
    return (f"Repository: {repo}\nBranch:     {branch}\nCommit:     {commit}\n\n"
            f"Fresh Lisp image:\n  implementation/version: {implementation} {version}\n"
            f"  Slynk host: {host}\n  Slynk port: {port}\n\n"
            f"Attach another SLY client:\n  M-x sly-connect\n  Host: {host}\n"
            f"  Port: {port}\n\nExample:\n"
            f"  Spacemacs -> M-x sly-connect -> {host} -> {port}\n")


def stop(process):
    if process is not None and process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def main():
    repo = Path(subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], text=True).strip())
    scripts = repo / "scripts"
    # Resolve Slynk from the very same SLY installation used by the editor.
    loader = subprocess.check_output([
        "emacs", "-Q", "--batch", "--eval",
        '(progn (require (quote sly)) (princ (expand-file-name '
        '"slynk/slynk-loader.lisp" (file-name-directory (locate-library "sly")))))'
    ], text=True).strip()
    if not Path(loader).is_file():
        raise RuntimeError(f"SLY's Slynk loader does not exist: {loader}")
    env = dict(os.environ, HYPERDOC_REPO_ROOT=str(repo),
               HYPERDOC_SLYNK_LOADER=loader)
    lisp = editor = None
    reader, writer = os.pipe()
    env["HYPERDOC_ENDPOINT_FD"] = str(writer)

    def interrupted(signum, _frame):
        raise SystemExit(128 + signum)

    for signum in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(signum, interrupted)
    with tempfile.TemporaryFile(mode="w+b") as log:
        try:
            print("Starting a fresh SBCL image...", flush=True)
            try:
                lisp = subprocess.Popen([
                    "sbcl", "--dynamic-space-size", "8192", "--noinform",
                    "--no-sysinit", "--no-userinit", "--non-interactive",
                    "--load", str(scripts / "hyperdoc-slynk.lisp")
                ], cwd=repo, env=env, stdin=subprocess.DEVNULL,
                    stdout=log, stderr=log, pass_fds=(writer,), start_new_session=True)
            finally:
                os.close(writer)
            endpoint = read_endpoint(reader)
            print(banner(repo, endpoint), flush=True)
            env.pop("HYPERDOC_ENDPOINT_FD")
            env.update(HYPERDOC_SLYNK_HOST=endpoint[0],
                       HYPERDOC_SLYNK_PORT=str(endpoint[1]))
            editor = subprocess.Popen(
                ["emacs", "-Q", "--load", str(scripts / "hyperdoc-sly.el")],
                cwd=repo, env=env)
            completed = queue.Queue()

            def wait_for(process):
                completed.put((process, process.wait()))

            for process in (lisp, editor):
                threading.Thread(target=wait_for, args=(process,), daemon=True).start()
            process, status = completed.get()
            if process is lisp:
                raise RuntimeError(f"Authoritative SBCL exited ({status})")
            return status
        except Exception:
            stop(lisp)
            log.seek(0)
            print(log.read().decode("utf-8", errors="replace"), flush=True)
            raise
        finally:
            os.close(reader)
            stop(editor)
            stop(lisp)


if __name__ == "__main__":
    raise SystemExit(main())
