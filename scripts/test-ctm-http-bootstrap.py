"""Loopback-only publication/client fixture. Never installs a production route.

Uses the verified PR #1 artifact without merging its code. The trusted revision
and digest are test inputs, not values accepted from the HTTP response.
"""
import argparse
import hashlib
import json
from pathlib import Path
import os
import subprocess
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import ProxyHandler, build_opener

REVISION = "0484a4b76128c3ed302a6a8d6e0343bfe03cece5"
TOPIC_MAPS = "88994c1b9e1edbf13e665e984a5c9c3b2cdf7575"
DIGEST = "8b4142421f5bfa1cc089e7ac53b43ebc6975e597cdedea5a49f6fc226dcc2e1d"
DOCUMENT_IRI = "tag:dreyeck.ch,2026:hyperdoc/project.ctm"
ARTIFACT = "dreyeck/work/project/hyperdoc-project.ctm"
LIMIT = 2 * 1024 * 1024


class Rejected(ValueError):
    pass


def retrieve(url, expected_type):
    # The fixture uses loopback directly. Production clients retain their
    # configured HTTPS proxy, trust store and certificate verification.
    opener = build_opener(ProxyHandler({}))
    try:
        with opener.open(url, timeout=10) as response:
            if response.status != 200 or response.headers.get_content_type() != expected_type:
                raise Rejected("Unexpected HTTP status or content type")
            body = response.read(LIMIT + 1)
    except (HTTPError, URLError, OSError) as error:
        raise Rejected("Resource unavailable") from error
    if len(body) > LIMIT:
        raise Rejected("Resource exceeds fixed byte limit")
    return body


def fetch_verified(base):
    metadata = json.loads(retrieve(base + "/manifest.json", "application/json"))
    # Never turn response fields into file paths, ASDF names or Lisp forms.
    required = {"format": "hyperdoc-project-ctm-snapshot-1", "source_revision": REVISION,
                "topic_maps_revision": TOPIC_MAPS, "document_iri": DOCUMENT_IRI,
                "ctm_file": "project.ctm", "sha256": DIGEST}
    if any(metadata.get(key) != value for key, value in required.items()):
        raise Rejected("Unexpected revision, identity or trusted digest")
    sidecar = retrieve(base + "/project.ctm.sha256", "text/plain")
    if sidecar != (DIGEST + "  project.ctm\n").encode("ascii"):
        raise Rejected("Incorrect digest sidecar")
    octets = retrieve(base + "/project.ctm", "application/octet-stream")
    if hashlib.sha256(octets).hexdigest() != DIGEST:
        raise Rejected("Unexpected CTM content")
    octets.decode("utf-8", errors="strict")
    return octets, metadata


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--native-launcher", type=Path, required=True,
                        help="Trusted local Python launcher, never obtained from HTTP")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    expected = subprocess.check_output(["git", "-C", str(root), "show", REVISION + ":" + ARTIFACT])
    assert hashlib.sha256(expected).hexdigest() == DIGEST
    sources = []
    for line in expected.decode("utf-8").splitlines():
        if line.startswith("#   dreyeck/pages/"):
            path, digest = line[4:].rsplit(None, 1)
            authored = subprocess.check_output(["git", "-C", str(root), "show", REVISION + ":" + path.strip()])
            assert hashlib.sha256(authored).hexdigest() == digest
            sources.append({"path": path.strip(), "sha256": digest})
    assert sources
    manifest = {"format": "hyperdoc-project-ctm-snapshot-1", "source_revision": REVISION,
                "topic_maps_revision": TOPIC_MAPS, "document_iri": DOCUMENT_IRI,
                "ctm_file": "project.ctm", "sha256": DIGEST, "source_pages": sources,
                "publication_status": "isolated-review-fixture-not-publication"}
    prefix = "/project-data/revisions/" + REVISION
    good = {"/manifest.json": ("application/json", json.dumps(manifest).encode()),
            "/project.ctm.sha256": ("text/plain", (DIGEST + "  project.ctm\n").encode()),
            "/project.ctm": ("application/octet-stream", expected)}
    # Fixed in-memory route table: no directory listing, path-to-file mapping,
    # dynamic generation, ASDF loading or response-supplied code execution.
    resources = {prefix + path: value for path, value in good.items()}
    bad_digest = {**good, "/project.ctm.sha256": ("text/plain", ("0" * 64 + "  project.ctm\n").encode())}
    wrong = b"<html>Unexpected response, not the approved CTM</html>"
    forged = {**manifest, "sha256": hashlib.sha256(wrong).hexdigest()}
    bad_content = {**good, "/project.ctm": ("application/octet-stream", wrong),
                   "/manifest.json": ("application/json", json.dumps(forged).encode()),
                   "/project.ctm.sha256": ("text/plain", (forged["sha256"] + "  project.ctm\n").encode())}
    for variant, values in (("bad-digest", bad_digest), ("unexpected-content", bad_content)):
        resources.update({"/" + variant + path: value for path, value in values.items()})

    class StaticFixture(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def do_GET(self):
            parsed = urlsplit(self.path)
            resource = None if parsed.query else resources.get(parsed.path)
            if resource is None:
                self.send_error(404)
                return
            mime, body = resource
            self.send_response(200)
            self.send_header("Content-Type", mime)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            self.wfile.write(body)

        def do_POST(self):
            self.send_error(405)

        do_PUT = do_POST
        do_DELETE = do_POST

    server = ThreadingHTTPServer(("127.0.0.1", 0), StaticFixture)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    native_calls = 0
    try:
        origin = "http://127.0.0.1:" + str(server.server_port)
        received, observed = fetch_verified(origin + prefix)
        assert received == expected and observed["source_pages"] == sources
        print("HTTP-PASS: fixed snapshot, manifest, SHA-256 and source-page identities", flush=True)
        for name in ("missing", "bad-digest", "unexpected-content"):
            try:
                fetch_verified(origin + "/" + name)
            except Rejected as error:
                print("HTTP-REJECT-PASS:", name, "-", error, flush=True)
            else:
                raise AssertionError("Accepted " + name)
        assert native_calls == 0  # None of the rejected responses reached Lisp.
        with tempfile.TemporaryDirectory(prefix="hyperdoc-http-readback-") as directory:
            expected_path, received_path = (Path(directory) / n for n in ("expected.ctm", "received.ctm"))
            expected_path.write_bytes(expected)
            received_path.write_bytes(received)
            env = dict(os.environ, HYPERDOC_BOOTSTRAP_EXPECTED=str(expected_path),
                       HYPERDOC_BOOTSTRAP_RECEIVED=str(received_path))
            native_calls += 1
            subprocess.run([sys.executable, str(args.native_launcher.resolve())], cwd=root,
                           env=env, check=True, timeout=180)
        print("HTTP-BOOTSTRAP-PASS: 3 negative cases rejected before native reading; 1 verified native read-back", flush=True)
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


if __name__ == "__main__":
    main()
