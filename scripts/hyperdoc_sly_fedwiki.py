"""Local control for the one SBCL image owned by hyperdoc-sly --fedwiki."""

from html import escape
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
from pathlib import Path
import secrets
import subprocess
import tempfile
import time
from urllib.parse import parse_qs

PORT = 18754
WIKI_URL = "http://localhost:3000"
SLUG = "sbcl-sly-lisp-image"


def install_page(site_root):
    pages = site_root.resolve(strict=True) / "pages"
    title = "SBCL SLY Lisp Image"
    story = [
        {"type": "paragraph", "id": "18eb3a3b101cdfeb",
         "text": "Play startet ein frisches HyperDoc-Image auf diesem Mac. Die angezeigte Slynk-Adresse verbindet Emacs SLY mit diesem Image."},
        {"type": "frame", "id": "6df2f6f03d091580",
         "text": f"http://localhost:{PORT}/\nHEIGHT 425\nLokaler HyperDoc-Launcher"},
    ]
    page = {"title": title, "story": story,
            "journal": [{"type": "create", "date": time.time_ns() // 1_000_000,
                         "item": {"title": title, "story": story}}]}
    target = pages / SLUG
    with tempfile.TemporaryDirectory(dir=pages) as directory:
        source = Path(directory) / SLUG
        source.write_text(json.dumps(page, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        try:
            os.link(source, target)
        except FileExistsError:
            existing = json.loads(target.read_text(encoding="utf-8"))
            if (existing.get("title"), existing.get("story")) != (title, story):
                raise RuntimeError(f"FedWiki-Seite bereits belegt: {target}") from None
    return target


class Image:
    def __init__(self, repo, env, start_lisp, stop, banner, log):
        self.repo, self.env, self.log = repo, env, log
        self.start_lisp, self.stop, self.banner = start_lisp, stop, banner
        self.process = None
        self.readback = ""
        self.error = ""

    def running(self):
        return self.process is not None and self.process.poll() is None

    def start(self):
        if self.running():
            return
        self.error = ""
        self.log.seek(0)
        self.log.truncate()
        try:
            self.process, endpoint = self.start_lisp(self.repo, self.env, self.log)
            self.readback = f"PID: {self.process.pid}\n{self.banner(self.repo, endpoint)}"
        except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as condition:
            self.close()
            self.log.seek(0, os.SEEK_END)
            self.log.seek(max(0, self.log.tell() - 4000))
            self.error = f"{condition}\n{self.log.read().decode('utf-8', errors='replace')}"

    def close(self):
        self.stop(self.process)
        self.process = None
        self.readback = self.error = ""


def handler_for(image, token):
    hosts = {f"localhost:{PORT}", f"127.0.0.1:{PORT}"}

    class OperatorPage(BaseHTTPRequestHandler):
        def respond(self, status, body="", location=None):
            data = body.encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Content-Security-Policy",
                             "default-src 'none'; form-action 'self'; "
                             f"frame-ancestors {WIKI_URL} http://127.0.0.1:3000")
            self.send_header("Referrer-Policy", "same-origin")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Cache-Control", "no-store")
            if location:
                self.send_header("Location", location)
            self.end_headers()
            if data:
                self.wfile.write(data)

        def do_GET(self):
            if self.headers.get("Host") not in hosts or self.path != "/":
                self.respond(HTTPStatus.NOT_FOUND)
                return
            running = image.running()
            readback = image.readback if running else image.error or "Bereit für einen frischen Start."
            action = "stop" if running else "start"
            label = "Image beenden" if running else "Play · Frisches SBCL-Image starten"
            self.respond(HTTPStatus.OK, f"""<!doctype html><meta charset="utf-8">
<html lang="de"><title>HyperDoc SBCL SLY</title><h2>HyperDoc SBCL SLY</h2>
<form method="post" action="/{action}">
<input name="token" type="hidden" value="{token}">
<button type="submit">{label}</button>
</form><pre>{escape(readback)}</pre></html>""")

        def do_POST(self):
            host = self.headers.get("Host")
            operations = {"/start": image.start, "/stop": image.close}
            if (host not in hosts or self.headers.get("Origin") != f"http://{host}"
                    or self.path not in operations
                    or self.headers.get_content_type() != "application/x-www-form-urlencoded"):
                self.respond(HTTPStatus.FORBIDDEN)
                return
            length = self.headers.get("Content-Length", "")
            if not length.isascii() or not length.isdecimal() or len(length) > 3 or int(length) > 512:
                self.respond(HTTPStatus.BAD_REQUEST)
                return
            try:
                fields = parse_qs(self.rfile.read(int(length)).decode("ascii"),
                                  strict_parsing=True, max_num_fields=1, errors="strict")
                presented, = fields.get("token", ())
            except (ValueError, UnicodeError):
                self.respond(HTTPStatus.BAD_REQUEST)
                return
            if not presented.isascii() or not secrets.compare_digest(presented, token):
                self.respond(HTTPStatus.FORBIDDEN)
                return
            operations[self.path]()
            self.respond(HTTPStatus.SEE_OTHER, location="/")

    return OperatorPage


def serve(repo, env, start_lisp, stop, banner, site_root):
    with tempfile.TemporaryFile(mode="w+b") as log:
        image = Image(repo, env, start_lisp, stop, banner, log)
        try:
            with HTTPServer(("127.0.0.1", PORT), handler_for(image, secrets.token_urlsafe(32))) as server:
                if site_root is not None:
                    print(f"FedWiki-Seite: {install_page(site_root)}", flush=True)
                print(f"{WIKI_URL}/view/{SLUG}", flush=True)
                server.serve_forever()
        finally:
            image.close()
