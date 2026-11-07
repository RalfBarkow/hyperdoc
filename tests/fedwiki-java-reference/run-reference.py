#!/usr/bin/env python3
"""Run the unchanged fedwiki-java Main.java against network-free fixtures and record what it requests.

    python3 -I tests/fedwiki-java-reference/run-reference.py --fedwiki-java PATH [--out observed.json]

PATH is a checkout of RalfBarkow/fedwiki-java at b58fb43e7ffbbbda66685363dcda1facbd2a46a1 (checked).
The script re-executes itself in a new, empty network namespace (unshare --net, else unshare -rn),
brings up only the loopback interface, and checks that a public name does not resolve. Each served
fixture site is a separate HTTP server on 127.0.0.1; a 'dead' site gets a port nobody listens on.
Main.java is compiled from PATH into a temporary directory with the jars in PATH; nothing in PATH
is modified. Every request a server receives is logged in arrival order.
"""
import argparse, fcntl, hashlib, http.server, json, os, re, socket, struct, subprocess, sys, tempfile, threading

REVISION = "b58fb43e7ffbbbda66685363dcda1facbd2a46a1"
HERE = os.path.dirname(os.path.abspath(__file__))
JARS = ["jackson-core-2.14.2.jar", "jackson-annotations-2.14.2.jar", "jackson-databind-2.14.2.jar"]
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def bring_up_loopback():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    request = struct.pack("16sH14s", b"lo", 0, b"")
    flags = struct.unpack("16sH", fcntl.ioctl(s.fileno(), 0x8913, request)[:18])[1]   # SIOCGIFFLAGS
    fcntl.ioctl(s.fileno(), 0x8914, struct.pack("16sH14s", b"lo", flags | 1, b""))      # SIOCSIFFLAGS, IFF_UP


def isolated():
    try:
        socket.getaddrinfo("example.org", 80)
        return False
    except socket.gaierror:
        return True


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


def substitute(value, hosts):
    """Replace symbolic site names in every 'site' field by host:port."""
    if isinstance(value, dict):
        return {k: (hosts.get(v, v) if k == "site" and isinstance(v, str) else substitute(v, hosts)) for k, v in value.items()}
    if isinstance(value, list):
        return [substitute(v, hosts) for v in value]
    return value


def serve(name, pages, statuses, hosts, log, lock):
    class Handler(http.server.BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def do_GET(self):
            path = self.path
            status, body, extra = 404, b"Page not found", {}
            if path == "/system/sitemap.json":
                status = 200
                body = json.dumps([{"slug": slug, "title": page.get("title"), "date": 0, "synopsis": ""}
                                   for slug, page in pages.items()]).encode()
            elif path.endswith(".json"):
                slug = path[1:-len(".json")]
                if slug in statuses:
                    status = statuses[slug]
                    body = b"status from fixture"
                    if status in (301, 302, 303, 307, 308):
                        extra["Location"] = "http://%s/%s.json" % (hosts.get("origin"), slug)
                elif slug in pages:
                    status, body = 200, json.dumps(substitute(pages[slug], hosts)).encode()
            with lock:
                log.append({"site": name, "path": path, "status": status})
            self.send_response(status)
            self.send_header("Content-Type", "application/json" if status == 200 else "text/plain")
            for k, v in extra.items():
                self.send_header(k, v)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    server = http.server.ThreadingHTTPServer(("127.0.0.1", int(hosts[name].split(":")[1])), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


def run_scenario(scenario, classes, jar_path):
    names = set(scenario["sites"]) | set(scenario.get("dead", []))
    hosts = {name: "127.0.0.1:%d" % free_port() for name in sorted(names)}
    log, lock, servers = [], threading.Lock(), []
    for name, pages in scenario["sites"].items():
        servers.append(serve(name, pages, scenario.get("status", {}).get(name, {}), hosts, log, lock))
    env = {k: v for k, v in os.environ.items() if not k.upper().startswith(("JAVA_TOOL_OPTIONS", "HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY"))}
    stdin = "\n".join(scenario["commands"] + ["exit"]) + "\n"
    proc = subprocess.run(["java", "-cp", jar_path + os.pathsep + classes, "Main", hosts["origin"]],
                          input=stdin, capture_output=True, text=True, timeout=60, env=env)
    for server in servers:
        server.shutdown()
    back = {v: k for k, v in hosts.items()}
    unmap = lambda text: re.sub(r"127\.0\.0\.1:\d+", lambda m: back.get(m.group(0), m.group(0)), text)
    out = unmap(ANSI.sub("", proc.stdout))
    err = unmap(ANSI.sub("", proc.stderr))
    lines = out.splitlines()
    marks = [re.match(r"^ << (.*) >>$", l) for l in lines]
    troubles = [m.group(1) for m in marks if m and not re.match(r"^\d+ ", m.group(1)) and (" " in m.group(1) or ":" in m.group(1))]
    debug_sites = [m.group(1) for m in marks if m and m.group(1) in hosts]
    # Main.link() prints the whole lineup (title, site) between a blank line and a line of '='; keep the last block.
    lineup = []
    for i, l in enumerate(lines):
        if l.startswith("=========="):
            j = i - 1
            block = []
            while j >= 0 and lines[j] != "":
                block.insert(0, lines[j].rsplit(" ", 1))
                j -= 1
            lineup = block
    return {
        "id": scenario["id"],
        "exit_code": proc.returncode,
        "requests": log,
        "page_requests": [[r["site"], r["path"][1:-len(".json")], r["status"]] for r in log if r["path"] != "/system/sitemap.json"],
        "sitemap_requests": [r["site"] for r in log if r["path"] == "/system/sitemap.json"],
        "debug_sites": debug_sites,
        "trouble": troubles,
        "lineup": lineup,
        "stdout": out,
        "stderr_tail": err.splitlines()[-3:],
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--fedwiki-java", required=True)
    parser.add_argument("--scenarios", default=os.path.join(HERE, "scenarios.json"))
    parser.add_argument("--out", default=os.path.join(HERE, "observed.json"))
    args = parser.parse_args()
    ref = os.path.abspath(args.fedwiki_java)
    if os.environ.get("FEDWIKI_REFERENCE_ISOLATED") != "1":
        env = dict(os.environ, FEDWIKI_REFERENCE_ISOLATED="1")
        argv = [sys.executable, "-I", os.path.abspath(__file__), "--fedwiki-java", ref,
                "--scenarios", os.path.abspath(args.scenarios), "--out", os.path.abspath(args.out)]
        for prefix in (["unshare", "--net"], ["unshare", "-rn"]):
            if subprocess.run(prefix + ["true"], capture_output=True).returncode == 0:
                sys.exit(subprocess.run(prefix + argv, env=env).returncode)
        sys.exit("cannot create an isolated network namespace (unshare --net / -rn)")
    bring_up_loopback()
    if not isolated():
        sys.exit("refusing to run: a public name resolves, the namespace is not isolated")
    head = subprocess.run(["git", "-C", ref, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    if head != REVISION:
        sys.exit("fedwiki-java is at %s, expected %s" % (head, REVISION))
    dirty = subprocess.run(["git", "-C", ref, "status", "--porcelain", "--", "Main.java"] + JARS, capture_output=True, text=True).stdout
    if dirty:
        sys.exit("Main.java or the jars differ from %s" % REVISION)
    jar_path = os.pathsep.join(os.path.join(ref, j) for j in JARS)
    digests = {name: hashlib.sha256(open(os.path.join(ref, name), "rb").read()).hexdigest() for name in ["Main.java"] + JARS}
    java = subprocess.run(["java", "-version"], capture_output=True, text=True, env={k: v for k, v in os.environ.items() if k != "JAVA_TOOL_OPTIONS"}).stderr.splitlines()[0]
    with tempfile.TemporaryDirectory() as classes:
        subprocess.run(["javac", "-d", classes, "-cp", jar_path, os.path.join(ref, "Main.java")], check=True,
                       env={k: v for k, v in os.environ.items() if k != "JAVA_TOOL_OPTIONS"})
        scenarios = json.load(open(args.scenarios))["scenarios"]
        results = [run_scenario(s, classes, jar_path) for s in scenarios]
    observed = {"reference": {"repository": "RalfBarkow/fedwiki-java", "revision": REVISION, "sha256": digests, "java": java,
                              "network": "empty network namespace; loopback only; example.org did not resolve"},
                "scenarios": results}
    with open(args.out, "w") as f:
        json.dump(observed, f, indent=1, ensure_ascii=False)
        f.write("\n")
    for r in results:
        print("%-22s exit=%d pages=%s trouble=%s" % (r["id"], r["exit_code"], [(s, slug, st) for s, slug, st in r["page_requests"]], r["trouble"]))


if __name__ == "__main__":
    main()
