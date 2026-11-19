"""Exercise the FedWiki control boundary with a fake, observable image."""

from contextlib import closing, ExitStack
from http.client import HTTPConnection
from http.server import HTTPServer
import json
from pathlib import Path
import sys
import tempfile
from threading import Thread
import unittest
from unittest.mock import patch
from urllib.parse import urlencode

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import hyperdoc_sly_fedwiki as fedwiki


class FakeImage:
    error = ""
    readback = "PID: 42\nSlynk port: 54321"

    def __init__(self):
        self.active = False

    def running(self):
        return self.active

    def start(self):
        self.active = True

    def close(self):
        self.active = False


class FedWikiTests(unittest.TestCase):
    def test_installation_preserves_existing_page(self):
        with tempfile.TemporaryDirectory() as directory:
            site = Path(directory)
            (site / "pages").mkdir()
            page = fedwiki.install_page(site)
            original = page.read_bytes()
            self.assertEqual(json.loads(original)["story"][1]["type"], "frame")
            self.assertEqual(fedwiki.install_page(site), page)
            self.assertEqual(page.read_bytes(), original)
            edited = json.loads(original)
            edited["title"] = "Edited locally"
            page.write_text(json.dumps(edited), encoding="utf-8")
            with self.assertRaises(RuntimeError):
                fedwiki.install_page(site)
            self.assertEqual(json.loads(page.read_bytes()), edited)

    def test_local_operator_control(self):
        image = FakeImage()
        with ExitStack() as cleanup:
            server = cleanup.enter_context(HTTPServer(("127.0.0.1", 0), fedwiki.BaseHTTPRequestHandler))
            port = server.server_port
            with patch.object(fedwiki, "PORT", port):
                server.RequestHandlerClass = fedwiki.handler_for(image, "local-grant")
            thread = Thread(target=server.serve_forever)
            thread.start()
            cleanup.callback(thread.join)
            cleanup.callback(server.shutdown)
            addressed_origin = f"http://localhost:{port}"

            def request(method, url, *, origin=addressed_origin, token="local-grant", host=f"localhost:{port}"):
                with closing(HTTPConnection("127.0.0.1", port, timeout=2)) as connection:
                    connection.request(method, url, body=urlencode({"token": token}) if method == "POST" else None,
                                       headers={"Host": host, "Origin": origin,
                                                "Content-Type": "application/x-www-form-urlencoded"})
                    reply = connection.getresponse()
                    return reply.status, reply.read().decode("utf-8"), reply.headers

            self.assertEqual(request("GET", "/start")[0], 404)
            self.assertEqual(request("POST", "/start", origin="http://localhost:3000")[0], 403)
            self.assertEqual(request("POST", "/start", token="wrong")[0], 403)
            self.assertEqual(request("GET", "/", host="unrelated.example")[0], 404)
            self.assertFalse(image.running())
            status, html, headers = request("GET", "/")
            self.assertEqual(status, 200)
            self.assertIn("Frisches SBCL-Image starten", html)
            self.assertIn("frame-ancestors http://localhost:3000", headers["Content-Security-Policy"])
            self.assertEqual(request("POST", "/start")[0], 303)
            self.assertIn("Slynk port: 54321", request("GET", "/")[1])
            self.assertEqual(request("POST", "/stop")[0], 303)
            self.assertFalse(image.running())


if __name__ == "__main__":
    unittest.main()
