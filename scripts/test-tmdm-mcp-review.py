#!/usr/bin/env python3
"""Isolated MCP review fixture; never contacts DMX or the public MCP endpoint.

Run with --launcher pointing to a trusted local Python Lisp launcher that loads
scripts/review-tmdm-mcp.lisp and writes native.log in --artifacts.
"""
import argparse
import base64
import hashlib
import http.client
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import sys
import time
from urllib.parse import quote

REV = "0484a4b76128c3ed302a6a8d6e0343bfe03cece5"
SHA = "8b4142421f5bfa1cc089e7ac53b43ebc6975e597cdedea5a49f6fc226dcc2e1d"
PIN = "88994c1b9e1edbf13e665e984a5c9c3b2cdf7575"
DOC = "tag:dreyeck.ch,2026:hyperdoc/project.ctm"
ROOT = f"hyperdoc-iso13250://snapshot/{SHA}/"
ASSIGNMENT = "codex-2026-10-29-template-identity-substitution"
OWNER = f"tag:dreyeck.ch,2026:hyperdoc/assignment/{ASSIGNMENT}"
SCHEMA = "tag:dreyeck.ch,2026:hyperdoc/schema/"
PAGE = "tag:dreyeck.ch,2026:hyperdoc/page/dreyeck/work/project/implementation-assignments"
ENTRIES = ("original-source", "corpus-expectation", "reader-behavior", "expanded-control",
           "grammar-reading", "substitution-reading", "unresolved-question",
           "unresolved-contracts", "execution-boundary", "decision-note")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--launcher", type=Path, required=True)
    parser.add_argument("--artifacts", type=Path, required=True)
    args = parser.parse_args()
    out = args.artifacts.resolve()
    out.mkdir(parents=True, exist_ok=True)
    expected = subprocess.check_output(["git", "show", f"{REV}:dreyeck/work/project/hyperdoc-project.ctm"])
    assert hashlib.sha256(expected).hexdigest() == SHA
    (out / "expected.ctm").write_bytes(expected)
    stop = out / "stop"
    stop.unlink(missing_ok=True)
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
    token = secrets.token_urlsafe(32)
    env = dict(os.environ, HYPERDOC_REVIEW_PORT=str(port), HYPERDOC_REVIEW_TOKEN=token,
               HYPERDOC_REVIEW_CTM=str(out / "expected.ctm"), HYPERDOC_REVIEW_STOP=str(stop),
               HYPERDOC_REVIEW_RECEIVED=str(out / "received.ctm"))
    checks = 0

    def check(label, condition):
        nonlocal checks
        if not condition:
            raise AssertionError(label)
        checks += 1
        print(f"MCP-CHECK {label} PASS", flush=True)

    def call(method="resources/list", params=None, sid=None, auth=token, origin=None, verb="POST", raw=None):
        headers = {"Content-Type": "application/json", "Accept": "application/json, text/event-stream"}
        if auth is not None:
            headers["Authorization"] = f"Bearer {auth}"
        if sid is not None:
            headers["Mcp-Session-Id"] = sid
        if origin is not None:
            headers["Origin"] = origin
        payload = {"jsonrpc": "2.0", "method": method}
        if method != "notifications/initialized":
            payload["id"] = 1
        if params is not None:
            payload["params"] = params
        conn = http.client.HTTPConnection("127.0.0.1", port, timeout=5)
        try:
            conn.request(verb, "/mcp", body=raw if raw is not None else json.dumps(payload), headers=headers)
            response = conn.getresponse()
            body = response.read(2_000_001)
            if len(body) > 2_000_000:
                raise ValueError("Oversized response")
            return response.status, dict(response.getheaders()), json.loads(body) if body else None
        finally:
            conn.close()

    def read(uri, sid):
        status, _, result = call("resources/read", {"uri": uri}, sid=sid)
        assert status == 200 and "result" in result, result
        contents = result["result"]["contents"]
        assert len(contents) == 1 and contents[0]["uri"] == uri
        return contents[0]

    def sis(ref):
        return ref["subjectIdentifiers"]

    def topic(si, sid):
        return json.loads(read(ROOT + "topic?si=" + quote(si, safe=""), sid)["text"])

    proc = subprocess.Popen([sys.executable, str(args.launcher.resolve())], env=env)
    try:
        deadline = time.monotonic() + 50
        while True:
            if proc.poll() is not None:
                raise RuntimeError(f"Lisp launcher exited {proc.returncode}; see native.log")
            try:
                call(verb="GET", auth=None)
                break
            except (OSError, http.client.HTTPException):
                if time.monotonic() >= deadline:
                    raise TimeoutError("MCP review startup; see native.log")
                time.sleep(0.1)
        check("missing-bearer-401", call(auth=None)[0] == 401)
        check("wrong-bearer-401", call(auth="incorrect")[0] == 401)
        check("wrong-origin-403", call(origin="https://untrusted.invalid")[0] == 403)
        check("get-405", call(verb="GET")[0] == 405)
        check("missing-session-400", call()[0] == 400)
        check("unknown-session-404", call(sid="unknown")[0] == 404)
        check("malformed-json-refused", call(raw="{")[0] == 400)
        check("array-request-refused", call(raw="[]")[0] == 400)
        check("request-size-refused", call(raw=" " * 16385)[0] == 413)
        check("unsupported-protocol-refused", call("initialize", {"protocolVersion": "unknown"})[2]["error"]["code"] == -32602)
        status, headers, result = call("initialize", {"protocolVersion": "2025-03-26", "capabilities": {},
                                                     "clientInfo": {"name": "readonly-review", "version": "0"}},
                                       origin="https://review.invalid")
        check("initialize-200", status == 200)
        sid = next(v for k, v in headers.items() if k.lower() == "mcp-session-id")
        check("resources-only-capabilities", set(result["result"]["capabilities"]) == {"resources"})
        check("pre-initialized-request-refused", call(sid=sid)[2]["error"]["code"] == -32000)
        check("initialized-202", call("notifications/initialized", sid=sid)[0] == 202)
        check("ping", call("ping", sid=sid)[2]["result"] == {})
        listing = call(sid=sid)[2]["result"]["resources"]
        check("two-fixed-resources", {r["uri"] for r in listing} == {ROOT + "project.ctm", ROOT + "manifest.json"})
        template = call("resources/templates/list", sid=sid)[2]["result"]["resourceTemplates"]
        check("topic-template", len(template) == 1 and template[0]["uriTemplate"] == ROOT + "topic?si={si}")
        manifest = json.loads(read(ROOT + "manifest.json", sid)["text"])
        check("anchored-provenance", (manifest["sourceRevision"], manifest["topicMapsRevision"],
                                     manifest["documentIRI"], manifest["sha256"]) == (REV, PIN, DOC, SHA))
        resource = read(ROOT + "project.ctm", sid)
        check("ctm-is-octet-blob", resource["mimeType"] == "application/octet-stream" and "text" not in resource)
        received = base64.b64decode(resource["blob"], validate=True)

        def accept(data, digest, mime):
            if mime != "application/octet-stream" or digest != SHA or hashlib.sha256(data).hexdigest() != SHA:
                raise ValueError("Untrusted content/digest")

        for label, data, digest, mime in (("bad-digest", received, "0" * 64, resource["mimeType"]),
                                         ("unexpected-content", b"#.(error :must-not-execute)", SHA, resource["mimeType"]),
                                         ("wrong-mime", received, SHA, "text/html")):
            try:
                accept(data, digest, mime)
            except ValueError:
                check(label + "-rejected-before-native-reader", True)
            else:
                raise AssertionError(label)
        accept(received, manifest["sha256"], resource["mimeType"])
        check("retrieved-octets-match-reviewed-blob", received == expected)
        (out / "received.ctm").write_bytes(received)
        owner = topic(OWNER, sid)
        check("native-assignment-identity", OWNER in sis(owner["identity"]) and owner["sha256"] == SHA)
        for relation, owner_role, page_role in (("declared-on", "declaration", "source-page"),
                                                ("reads-source", "assignment", "source")):
            matches = [a for a in owner["associations"] if SCHEMA + relation in sis(a["type"])]
            check(relation + "-association-and-role-players", any(
                len(a["roles"]) == 2 and
                any(SCHEMA + owner_role in sis(r["type"]) and OWNER in sis(r["player"]) for r in a["roles"]) and
                any(SCHEMA + page_role in sis(r["type"]) and PAGE in sis(r["player"]) for r in a["roles"]) for a in matches))
        for entry in ENTRIES:
            evidence_si = f"tag:dreyeck.ch,2026:hyperdoc/evidence/{ASSIGNMENT}/{entry}"
            evidence = topic(evidence_si, sid)
            occurrence = evidence["reifiedOccurrence"]
            check(entry + "/reification-and-owner", OWNER in sis(occurrence["parent"]) and
                  evidence_si in sis(occurrence["reifier"]) and SCHEMA + "evidence-note" in sis(occurrence["type"]))
            check(entry + "/operator-attribution", occurrence["value"].startswith("Operator report"))
        page = topic(PAGE, sid)
        for kind, value in (("repository-path", "dreyeck/pages/project/Implementation Assignments.html"),
                            ("source-sha256", "0d755af7b32bd02c30d41573afc9956767c8027e0e7fb79f20affa294cc1e463")):
            check(kind, any(SCHEMA + kind in sis(o["type"]) and o["value"] == value for o in page["occurrences"]))
        for uri in ("file:///etc/passwd", "dmx://topic/907120", ROOT + "missing.ctm",
                    ROOT + "topic?si=" + quote("tag:unknown", safe="")):
            check("unknown-resource-refused/" + uri.rsplit("/", 1)[-1],
                  call("resources/read", {"uri": uri}, sid=sid)[2]["error"]["code"] == -32002)
        for method in ("tools/list", "tools/call", "eval", "resources/subscribe"):
            check(method + "-not-exposed", call(method, {"name": "upsert_workspace_note", "code": "(error :forbidden)"},
                                              sid=sid)[2]["error"]["code"] == -32601)
        check("delete-session-204", call(sid=sid, verb="DELETE")[0] == 204)
        check("deleted-session-404", call(sid=sid)[0] == 404)
        stop.touch()
        check("native-readback-and-unchanged-map-exit-0", proc.wait(timeout=15) == 0)
        log = (out / "native.log").read_text()
        check("native-readback-marker", "MCP-REVIEW-READBACK PASS" in log and "MCP-REVIEW-UNCHANGED" in log)
        summary = {"checks": checks, "status": "PASS", "sourceRevision": REV, "sha256": SHA,
                   "topicMapsRevision": PIN, "documentIRI": DOC, "transport": "loopback-only",
                   "nativeReadback": "PASS", "sameBaseCXTM": "PASS", "publicMCP": "CONNECT 403; not reached"}
        (out / "results.json").write_text(json.dumps(summary, indent=2) + "\n")
        print(f"MCP-REVIEW-PASS: {checks} focused checks", flush=True)
    finally:
        if proc.poll() is None:
            proc.terminate()
            proc.wait(timeout=10)


if __name__ == "__main__":
    main()
