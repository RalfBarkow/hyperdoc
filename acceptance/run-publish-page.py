"""Run the real FedWiki fork fixture and SHOP3 in a disposable single-writer store."""
import argparse
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import zipfile

HERE = Path(__file__).resolve().parent
SLUG = "publish-page-test"


def json_file(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def setup_release(work):
    source = work / "source"
    for site in (source, work / "data"):
        (site / "pages").mkdir(parents=True)
        (site / "assets/pages" / SLUG).mkdir(parents=True)
    story = [
        {"id": "c2e7839577a01d01", "type": "paragraph", "text": "Freigegebene Prüffassung."},
        {"id": "c2e7839577a01d02", "type": "markdown", "text": "**Zweiter** Absatz."},
        {"id": "c2e7839577a01d03", "type": "assets", "text": "pages/" + SLUG},
    ]
    page = {"title": "Publish Page Test", "story": story}
    page["journal"] = [{"type": "create", "date": 1700000000000,
                        "item": {"title": page["title"], "story": story}}]
    snapshot = source / "pages" / SLUG
    json_file(snapshot, page)
    baseline = {"title": page["title"], "story": [dict(story[0], text="Observed target.")], "journal": []}
    json_file(work / "data/pages" / SLUG, baseline)
    assets = source / "assets/pages" / SLUG
    with zipfile.ZipFile(assets / (SLUG + ".zip"), "w") as archive:
        member = zipfile.ZipInfo(f"{SLUG}/{SLUG}.asd", (2026, 1, 1, 0, 0, 0))
        archive.writestr(member, f'(asdf:defsystem "{SLUG}" :version "1.0.0")\n')
    (assets / "note.txt").write_text("Testanhang für den Fork.\n", encoding="utf-8")
    digests = {}
    for item in sorted(assets.iterdir()):
        shutil.copyfile(item, work / "data/assets/pages" / SLUG / item.name)
        digests[item.name] = sha(item)
    # forkDate belongs to the reviewed manifest and survives a retry.
    json_file(source / "release.json", {"slug": SLUG, "sourceSite": "source.fixture.test",
              "forkDate": time.time_ns() // 1000000, "pageSha256": sha(snapshot),
              "assetsItem": story[-1]["id"], "assets": digests})
    return digests


@contextmanager
def running_wiki(work, wiki):
    origin = f"http://{work.name}.test"
    sock = work / "wiki.sock"
    # Reuse the original login, server, routing and storage. Only the listener in
    # the disposable launcher changes. A socket in a 0700 directory has no TCP port.
    launcher = (wiki / "integration-tests/server.mjs").read_text()
    old = "app.listen(Number(port),'127.0.0.1',"
    if launcher.count(old) != 1:
        raise RuntimeError("Cannot isolate the current FedWiki test launcher")
    capture = """
listening.prependListener('request',(req,res)=>res.once('finish',()=>{
  const action=req.body?.action ? JSON.parse(req.body.action) : undefined
  const record={method:req.method,path:req.url,status:res.statusCode}
  if(action){record.type=action.type;record.forkPage=!!action.forkPage;record.action=action}
  fs.appendFileSync(path.join(work,'requests.jsonl'),JSON.stringify(record)+'\\n')
}))
"""
    runner = work / "server.mjs"
    runner.write_text(launcher.replace(old, "app.listen(path.join(work,'wiki.sock'),") + capture)
    with (work / "server.log").open("w+") as log:
        server = subprocess.Popen(["node", runner, wiki, work, "80", origin], stdout=log, stderr=log)
        try:
            for _ in range(250):
                if server.poll() is not None:
                    log.seek(0)
                    raise RuntimeError(log.read()[-4000:])
                if sock.exists():
                    break
                time.sleep(0.1)
            else:
                raise RuntimeError("FedWiki socket did not start")
            assert stat.S_IMODE(work.stat().st_mode) == 0o700 and sock.is_socket()
            unix_sockets = subprocess.check_output(["/usr/sbin/lsof", "-w", "-nP", "-a", "-p",
                                                    str(server.pid), "-U", "-Fn"])
            assert os.fsencode(sock) in unix_sockets.splitlines()[1:] or b"n" + os.fsencode(sock) in unix_sockets.splitlines()
            listeners = subprocess.run(["/usr/sbin/lsof", "-w", "-nP", "-a", "-p", str(server.pid),
                                        "-iTCP", "-sTCP:LISTEN"], capture_output=True)
            assert (listeners.returncode, listeners.stdout, listeners.stderr) == (1, b"", b""), listeners
            subprocess.run(["/usr/bin/curl", "--disable", "--fail", "--silent", "--show-error",
                            "--noproxy", "*", "--unix-socket", sock, "--cookie-jar", work / "owner.jar",
                            "--max-time", "8", "--request", "POST", origin + "/fixture/login"],
                           stdout=subprocess.DEVNULL, check=True)
            yield origin
        finally:
            server.terminate()
            try:
                server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait()


def run(work, wiki, hyperdoc):
    assets = setup_release(work)
    with running_wiki(work, wiki) as origin:
        env = dict(os.environ, FORK_FIXTURE=str(work) + "/")
        subprocess.run(["nix", "develop", "--no-write-lock-file", "-c", "sbcl",
                        "--noinform", "--no-sysinit", "--no-userinit", "--non-interactive",
                        "--load", HERE / "ki-plan-next.lisp",
                        "--load", HERE.parent / "publication/publish-page.lisp",
                        "--load", HERE / "test-publish-page.lisp"],
                       cwd=hyperdoc, env=env, check=True, timeout=240)

    trace = [json.loads(line) for line in (work / "requests.jsonl").read_text().splitlines()]
    writes = [r for r in trace if r["method"] == "PUT"]
    expected = [("fork", 403, True), ("edit", 200, False), ("fork", 200, True)]
    assert [(r["type"], r["status"], r["forkPage"]) for r in writes] == expected, writes
    assert all(r["path"] == f"/page/{SLUG}/action" for r in writes)
    stored = json.loads((work / "data/pages" / SLUG).read_bytes())
    approved = json.loads((work / "source/pages" / SLUG).read_bytes())
    manifest = json.loads((work / "source/release.json").read_bytes())
    fork = {"type": "fork", "site": manifest["sourceSite"], "date": manifest["forkDate"],
            "releaseSha256": sha(work / "source/release.json")}
    assert stored == dict(approved, journal=approved["journal"] + [fork])
    print("Verified target assets:", assets)
    assert all(r["action"] == dict(fork, forkPage=approved) for r in writes if r["type"] == "fork")
    print("Wire writes:", [(r["type"], r["status"]) for r in writes])
    return (json.loads((work / "results.json").read_text()), {"origin": origin, "slug": SLUG,
            "transport": {"socket": "private Unix socket", "parentMode": "0700", "tcpListeners": 0},
            "approvedManifest": manifest,
            "server": json.loads((wiki / "node_modules/wiki-server/package.json").read_text())["version"],
            "manifestSha256": sha(work / "source/release.json"), "assetSha256": assets,
            "requests": trace, "journal": stored["journal"]})


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--wiki", type=Path, default=Path.home() / "Projects/RalfBarkow/wiki")
    p.add_argument("--hyperdoc", type=Path, default=Path.home() / "workspace/hyperdoc-dreyeck-ch")
    p.add_argument("--report", type=Path, help="Save the HTTP trace and SHOP3 receipts as JSON")
    p.add_argument("--serve", action="store_true", help="Serve one private fixture until the owning image closes stdin")
    args = p.parse_args()
    os.umask(0o077)
    with tempfile.TemporaryDirectory(prefix="fork-test-", dir="/private/tmp") as directory:
        work = Path(directory)
        if args.serve:
            setup_release(work)
            with running_wiki(work, args.wiki.resolve()):
                print(directory + "/", flush=True)
                sys.stdin.readline()
            sys.exit(0)
        results, evidence = run(work, args.wiki.resolve(), args.hyperdoc.resolve())
    if args.report:
        json_file(args.report, dict(evidence, shop3Receipts=results))
