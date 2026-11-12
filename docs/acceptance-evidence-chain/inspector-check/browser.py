"""Navigate a fresh loopback CLOG Inspector and probe the actual pane objects by EQ."""
import datetime
import hashlib
import json
import os
import pathlib
import socket
import subprocess
import tempfile
import time
import traceback

from playwright.sync_api import sync_playwright

out = pathlib.Path(__file__).resolve().parent
repo = out.parents[2]
sbcl = os.environ.get("EVIDENCE_SBCL", "/workspace/scratch/tmdm-mcp-portable/bin/sbcl")
protected = ["dreyeck.asd", "dreyeck/work/acceptance-evidence-chain.lisp",
             "dreyeck/tests/acceptance-evidence-chain.lisp"]


def hashes():
    return {p: hashlib.sha256((repo / p).read_bytes()).hexdigest() for p in protected}


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
command = [sbcl, "--noinform", "--no-sysinit", "--no-userinit", "--non-interactive",
           "--load", str(repo / "docs/topic-maps-integration-acceptance/hyperdoc-bootstrap.lisp"),
           "--load", str(out / "inspector.lisp")]
record = {"startedAtUTC": utc(), "implementationRevision": subprocess.check_output(
    ["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip(),
    "evidenceRevision": "9176349edb473becd7423a7ca246f9bc07a75388",
    "specifiedTestedRevision": "36c69d3312ae70748ecd40a5452759fcfaad25c4",
    "lispCommand": command, "cwd": str(repo), "port": port,
    "sourceSHA256Before": hashes(), "steps": [], "browserErrors": [], "externalRequests": []}
browser = None
with tempfile.TemporaryDirectory(prefix="evidence-inspector-") as temporary:
    stop = pathlib.Path(temporary) / "stop"
    env = dict(os.environ, DEFEDERATION_REPO=str(repo), EVIDENCE_INSPECTOR_PORT=str(port),
               EVIDENCE_INSPECTOR_STOP=str(stop))
    # No inherited candidate override: the adapter uses the existing active dependency registry.
    env.pop("TOPIC_MAPS_CANDIDATE_ROOT", None)
    log_path = out / "inspector.log"
    with log_path.open("wb") as log:
        child = subprocess.Popen(command, cwd=repo, env=env, stdout=log, stderr=subprocess.STDOUT)
        record["lispPID"] = child.pid
        try:
            deadline = time.monotonic() + 300
            while "EVIDENCE-INSPECTOR-READY" not in log_path.read_text(errors="replace"):
                if child.poll() is not None:
                    raise RuntimeError("Fresh Lisp process exited: " + str(child.returncode))
                if time.monotonic() > deadline:
                    raise TimeoutError("Fresh Inspector startup exceeded 300 seconds")
                time.sleep(.2)
            with sync_playwright() as pw:
                browser = pw.chromium.launch(executable_path="/usr/bin/chromium", headless=True,
                                            args=["--disable-background-networking", "--no-proxy-server"])
                record["browserVersion"] = browser.version
                context = browser.new_context(viewport={"width": 1600, "height": 1000}, service_workers="block")
                origin = f"http://127.0.0.1:{port}"

                def route(request):
                    if request.request.url.startswith(origin + "/"):
                        request.continue_()
                    else:
                        record["externalRequests"].append(request.request.url)
                        request.abort()

                context.route("**/*", route)
                page = context.new_page()
                page.set_default_timeout(30000)
                page.on("pageerror", lambda error: record["browserErrors"].append(str(error)))
                page.goto(origin)

                def click(locator):
                    locator.wait_for(state="visible")
                    locator.evaluate("""el => new Promise((resolve,reject)=>{
                      const end=performance.now()+10000;
                      const poll=()=>{const jq=window.jQuery; const e=jq&&jq._data(el,'events');
                        if(e&&e.click)return resolve(true);
                        if(performance.now()>end)return reject(Error('Inspector click handler not bound'));
                        setTimeout(poll,5)};poll()})""")
                    locator.click()

                def probe(expected):
                    click(page.get_by_role("button", name="Probe actual pane EQ", exact=True))
                    page.locator("#eq-result").get_by_text("EQ:" + expected + ";", exact=False).wait_for()
                    record["steps"].append({"actualPaneObjectEQ": expected,
                                            "result": page.locator("#eq-result").inner_text()})

                root = page.locator(".inspector-pane").first
                root.get_by_role("heading", name="Execution report, retained log and revision", exact=True).wait_for()
                probe("CHAIN")
                for tab, text in [("Retained report text", '"exitCode"'),
                                  ("Retained log text", "INSTANCE-OF-EXPORT-PASS")]:
                    click(root.get_by_role("button", name=tab, exact=True))
                    root.locator("pre").get_by_text(text, exact=False).wait_for()
                    probe("CHAIN")
                    record["steps"][-1]["retainedView"] = tab
                click(root.get_by_role("button", name="Evidence chain", exact=True))
                root.get_by_role("heading", name="Execution report, retained log and revision", exact=True).wait_for()
                root.screenshot(path=str(out / "evidence-chain.png"))
                for label, expected in [
                    ("Original execution report", "REPORT-FILE"),
                    ("Original retained log", "LOG-FILE"),
                    ("Fixed evidence revision", "EVIDENCE-REVISION"),
                    ("Parsed report (retained data)", "PARSED-REPORT"),
                    ("Specified tested HyperDoc revision", "SPECIFIED-REVISION"),
                    ("Retained Nix reference source", "DESCRIPTOR-FILE"),
                    ("Original execution report", "REPORT-FILE")]:
                    old = page.locator(".inspector-pane").last.get_attribute("id")
                    click(root.get_by_text(label, exact=True))
                    page.wait_for_function("""old=>{const ps=document.querySelectorAll('.inspector-pane');
                      return ps.length&&ps[ps.length-1].id!==old}""", arg=old)
                    page.locator(".inspector-pane").last.locator(".inspector-tabs button.active").first.wait_for()
                    probe(expected)
                    record["steps"][-1]["followedLabel"] = label
                page.locator(".inspector-pane").last.screenshot(path=str(out / "report-file.png"))
                assert not record["browserErrors"], record["browserErrors"]
                assert not record["externalRequests"], record["externalRequests"]
                assert hashes() == record["sourceSHA256Before"]
                record["success"] = True
                browser.close()
                browser = None
        except Exception:
            record["success"] = False
            record["failure"] = traceback.format_exc()
            if browser:
                try:
                    page.screenshot(path=str(out / "failure.png"), full_page=True)
                except Exception:
                    pass
                browser.close()
        finally:
            stop.write_text("stop\n")
            try:
                record["lispExitCode"] = child.wait(timeout=15)
            except subprocess.TimeoutExpired:
                child.terminate()
                record["lispExitCode"] = child.wait(timeout=10)
                record["forcedCleanup"] = True
            record["sourceSHA256After"] = hashes()
            record["finishedAtUTC"] = utc()
    record["logSHA256"] = hashlib.sha256(log_path.read_bytes()).hexdigest()
    record["success"] = record["success"] and record["lispExitCode"] == 0
    (out / "results.json").write_text(json.dumps(record, indent=2) + "\n")
print(json.dumps({"success": record["success"], "steps": len(record["steps"]),
                  "lispExitCode": record["lispExitCode"]}))
raise SystemExit(0 if record["success"] else 1)
