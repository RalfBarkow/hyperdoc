#!/usr/bin/env python3
"""The experiment: one known Federated Wiki page, read by name and then, with name resolution failing, through a given endpoint.

Two Linux network namespaces joined by a veth pair (no TUN/TAP): the "server" namespace holds the original Federated Wiki server on
10.77.0.1 (and two decoy servers), a DNS server that is made to fail, and this script; the "client" namespace (10.77.0.2) runs the
observer, an SBCL process using the HyperDoc code. Everything is disposable: a copy of the frozen test site, nothing else is read.

  python3 harness.py [--out DIRECTORY] [--dns-failure servfail|nxdomain|silent]

Needs: unshare with user namespaces, `ip` (iproute2; set IP=/path/to/ip otherwise), node with tests/fedwiki-original-editor/node_modules
(npm ci --prefix tests/fedwiki-original-editor --ignore-scripts), and SBCL with the HyperDoc registry (HYPERDOC_FEDWIKI_SBCL or SBCL,
CL_SOURCE_REGISTRY), as `nix develop .#fedwiki-original-editor` provides. It re-executes itself under `unshare -rnm`.
"""
import argparse, datetime, hashlib, json, os, re, shutil, socket, struct, subprocess, sys, tempfile, threading, time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SITE, SLUG = "wiki.without-dns.test", "without-dns-test-page"
SERVER_IP, CLIENT_IP, EMPTY_IP, ALTERED_IP, DEAD_IP = "10.77.0.1", "10.77.0.2", "10.77.0.3", "10.77.0.4", "10.77.0.9"
FROZEN = os.path.join(HERE, "frozen-site")
DNS_DESCRIPTION = {"servfail": "the DNS server answers every query with SERVFAIL (the resolver cannot answer)",
                   "nxdomain": "the DNS server answers every query with NXDOMAIN (the name does not exist)",
                   "silent": "the DNS server receives queries and never answers (a timeout)"}


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


class Dns(threading.Thread):
    """A UDP DNS server on the server address. It resolves SITE to SERVER_IP until `mode` is set to a failure mode."""
    def __init__(self):
        super().__init__(daemon=True)
        self.mode = "resolve"; self.log = []; self.stop = threading.Event()
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); self.sock.bind((SERVER_IP, 53)); self.sock.settimeout(0.2)

    def run(self):
        while not self.stop.is_set():
            try: data, addr = self.sock.recvfrom(512)
            except socket.timeout: continue
            question = data[12:]; end = question.index(b"\0") + 5
            labels, i = [], 0
            while question[i]:
                labels.append(question[i + 1:i + 1 + question[i]].decode()); i += 1 + question[i]
            qname, qtype = ".".join(labels).lower(), struct.unpack(">H", question[end - 4:end - 2])[0]
            mode, answers, rcode = self.mode, b"", 0
            if mode == "silent": self.log.append((mode, qname, qtype, "no reply")); continue
            if mode == "servfail": rcode = 2
            elif mode == "nxdomain": rcode = 3
            elif qname != SITE: rcode = 3
            elif qtype == 1: answers = b"\xc0\x0c" + struct.pack(">HHIH", 1, 1, 60, 4) + socket.inet_aton(SERVER_IP)
            # AAAA and the rest: NOERROR with no answer
            reply = data[:2] + struct.pack(">HHHHH", 0x8580 | rcode, 1, 1 if answers else 0, 0, 0) + question[:end] + answers
            self.sock.sendto(reply, addr)
            self.log.append((mode, qname, qtype, {0: "NOERROR", 2: "SERVFAIL", 3: "NXDOMAIN"}[rcode] + (" +A " + SERVER_IP if answers else "")))


def sanitize(text, work):
    """A server log without what it should not carry into a repository: the generated cookieSecret, and absolute paths of this machine."""
    text = re.sub(r"(cookieSecret:\s*)'[^']*'", r"\1'<redacted: generated per run>'", text)
    text = text.replace(work, "<work>").replace(os.path.dirname(ROOT), "<checkout>")
    text = re.sub(r"/(?:tmp|home|nix/store|root)/[^\s'\",]*", "<path>", text)
    return text


def run(command, **kwargs):
    return subprocess.run(command, check=True, text=True, capture_output=True, **kwargs)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default=None); parser.add_argument("--dns-failure", default="servfail", choices=sorted(DNS_DESCRIPTION))
    parser.add_argument("--inner", action="store_true")
    args = parser.parse_args()
    if not args.inner:
        out = os.path.abspath(args.out or tempfile.mkdtemp(prefix="fedwiki-without-dns-"))
        os.execvp("unshare", ["unshare", "-rnm", sys.executable, os.path.abspath(__file__), "--inner", "--out", out, "--dns-failure", args.dns_failure])
    inner(os.path.abspath(args.out), args.dns_failure)


def inner(out, dns_failure):
    ip = os.environ.get("IP") or shutil.which("ip") or sys.exit("ip (iproute2) not found; set IP=/path/to/ip")
    sbcl = os.environ.get("HYPERDOC_FEDWIKI_SBCL") or os.environ.get("SBCL") or shutil.which("sbcl") or sys.exit("sbcl not found")
    evidence = os.path.join(out, "evidence"); os.makedirs(evidence, exist_ok=True)
    work = tempfile.mkdtemp(prefix="fedwiki-without-dns-work-")
    processes = []
    stored = os.path.join(FROZEN, "pages", SLUG)
    frozen_before = sha256(stored)
    try:
        # --- the two namespaces and the veth pair
        run([ip, "link", "set", "lo", "up"])
        client = subprocess.Popen(["unshare", "-n", "sleep", "3600"]); processes.append(client)
        own = os.readlink("/proc/self/ns/net")
        for _ in range(50):
            if os.path.exists(f"/proc/{client.pid}/ns/net") and os.readlink(f"/proc/{client.pid}/ns/net") != own: break
            time.sleep(0.1)
        else: sys.exit("the client namespace did not appear")
        inc = ["nsenter", "-t", str(client.pid), "-n"]
        run([ip, "link", "add", "veth-server", "type", "veth", "peer", "name", "veth-client", "netns", str(client.pid)])
        for address in (SERVER_IP, EMPTY_IP, ALTERED_IP): run([ip, "addr", "add", address + "/24", "dev", "veth-server"])
        run([ip, "link", "set", "veth-server", "up"])
        run(inc + [ip, "link", "set", "lo", "up"]); run(inc + [ip, "addr", "add", CLIENT_IP + "/24", "dev", "veth-client"])
        run(inc + [ip, "link", "set", "veth-client", "up"])
        topology = run([ip, "-br", "addr"]).stdout + "--- client namespace ---\n" + run(inc + [ip, "-br", "addr"]).stdout
        # --- resolver configuration of the client: the DNS server on the veth
        resolv = os.path.join(work, "resolv.conf")
        with open(resolv, "w") as f: f.write(f"nameserver {SERVER_IP}\noptions timeout:1 attempts:1\n")
        run(["mount", "--bind", resolv, "/etc/resolv.conf"])
        dns = Dns(); dns.start()
        # --- the sites: copies of the frozen site, so that the original is never served from
        sites = {}
        for name, address in (("main", SERVER_IP), ("empty", EMPTY_IP), ("altered", ALTERED_IP)):
            sites[name] = os.path.join(work, name); os.makedirs(os.path.join(sites[name], "pages"))
        shutil.copy(stored, os.path.join(sites["main"], "pages", SLUG))
        text = open(stored, encoding="utf-8").read()
        altered = text.replace("must be the same page", "need not be the same page", 1)
        assert altered != text
        with open(os.path.join(sites["altered"], "pages", SLUG), "w", encoding="utf-8") as f: f.write(altered)
        main_before = sha256(os.path.join(sites["main"], "pages", SLUG))
        for name, address in (("main", SERVER_IP), ("empty", EMPTY_IP), ("altered", ALTERED_IP)):
            log = open(os.path.join(work, name + ".log"), "w")
            processes.append(subprocess.Popen(["node", os.path.join(HERE, "server.mjs"), sites[name], address, "80"], stdout=log, stderr=subprocess.STDOUT))
        for address in (SERVER_IP, EMPTY_IP, ALTERED_IP):
            for _ in range(150):
                try: socket.create_connection((address, 80), 1).close(); break
                except OSError: time.sleep(0.2)
            else: sys.exit(f"the wiki server on {address} did not start")
        # --- the observations
        results = {}
        logs = {name: os.path.join(work, name + ".log") for name in ("main", "empty", "altered")}
        seen = {name: len(open(path).read().splitlines()) for name, path in logs.items()}
        requests = {}   # observation id -> [(server, method, url, Host, remote)]

        def new_requests():
            """Requests the three servers received since the last call, from their own logs."""
            found = []
            for name, path in logs.items():
                lines = open(path).read().splitlines()
                for line in lines[seen[name]:]:
                    if line.startswith('{"request"'):
                        r = json.loads(line)["request"]; found.append((name, r["method"], r["url"], r["host"], r["remote"]))
                seen[name] = len(lines)
            return found
        new_requests()
        def phase(id, role, mode, endpoint=None, origin=None, timeout=5):
            dns.mode = mode
            path = os.path.join(work, f"obs-{id}.lisp-data")
            env = dict(os.environ, OBS_ID=id, OBS_ROLE=role, OBS_SITE=SITE, OBS_SLUG=SLUG, OBS_STORED=stored, OBS_OUT=path, OBS_TIMEOUT=str(timeout),
                       OBS_ENDPOINT=endpoint or "", OBS_ORIGIN=origin or "")
            done = subprocess.run(inc + [sbcl, "--script", os.path.join(HERE, "observe.lisp")], env=env, text=True, capture_output=True)
            results[id] = open(path, encoding="utf-8").read() if os.path.exists(path) else None
            time.sleep(0.3); requests[id] = new_requests()
            line = f"{id} [{role}, dns={mode}, endpoint={endpoint}]: " + (done.stdout.strip() or "NO OUTPUT") + ("" if done.returncode == 0 else f"  (exit {done.returncode}) {done.stderr[-300:]}")
            print(line); witness.write(line + "\n"); return done.returncode == 0
        def independent(label, mode):
            """Witnesses that do not use the Lisp code: libc's resolver (getent) and a raw TCP connection, from the client namespace."""
            dns.mode = mode
            resolve = subprocess.run(inc + ["getent", "hosts", SITE], text=True, capture_output=True)
            tcp = subprocess.run(inc + [sys.executable, "-c", f"import socket;socket.create_connection(('{SERVER_IP}',80),3).close();print('tcp connect ok')"], text=True, capture_output=True)
            line = f"{label} [dns={mode}]: getent hosts {SITE} -> exit {resolve.returncode} {resolve.stdout.strip() or '(nothing)'}; raw TCP to {SERVER_IP}:80 -> {tcp.stdout.strip() or ('failed: ' + tcp.stderr.strip()[-80:])}"
            print(line); witness.write(line + "\n")
        with open(os.path.join(evidence, "run.txt"), "w") as witness:
            witness.write(f"# {datetime.datetime.now(datetime.timezone.utc).isoformat()}  failure mode: {dns_failure}\n")
            independent("independent witness before", "resolve")
            phase("A", "baseline", "resolve")
            independent("independent witness under the failure", dns_failure)
            phase("B", "dns-failure", dns_failure)
            phase("C", "explicit-endpoint", dns_failure, endpoint=SERVER_IP, origin="earlier:A")
            phase("D", "control-wrong-endpoint", dns_failure, endpoint=EMPTY_IP, origin="declared:the address of a different, empty wiki server on the same link")
            phase("E", "control-unreachable-endpoint", dns_failure, endpoint=DEAD_IP, origin="declared:an address on the link at which nothing answers", timeout=4)
            phase("F", "control-different-content", dns_failure, endpoint=ALTERED_IP, origin="declared:the address of a wiki server holding the same slug with one changed sentence")
        # --- the Host header the servers received (their own logs), per observation
        def check_host(id, server, expected_count):
            got = requests[id]
            assert len(got) == expected_count, f"observation {id}: {len(got)} requests reached the servers, expected {expected_count}: {got}"
            for r in got:
                assert r[0] == server and r[1] == "GET" and r[2] == f"/{SLUG}.json" and r[3] == SITE and r[4] == CLIENT_IP, f"observation {id}: unexpected request {r}"
        check_host("A", "main", 1)       # by name, resolved to the server: Host is the site name
        check_host("B", "main", 0)       # no connection was made: no server saw anything
        check_host("C", "main", 1)       # by the given endpoint: Host is still the site name, not the address
        check_host("D", "empty", 1); check_host("E", "main", 0); check_host("F", "altered", 1)
        with open(os.path.join(evidence, "host-headers.txt"), "w") as f:
            f.write("# The requests each wiki server received, from the server's own HTTP layer (tests/fedwiki-without-dns/server.mjs), per observation.\n"
                    f"# Site identity {SITE}. The harness asserts exactly these: A and C each reached the original server once, GET /{SLUG}.json,\n"
                    f"# with Host: {SITE} (not an address), from the observer at {CLIENT_IP}; B and E reached no server.\n")
            for id in "ABCDEF":
                if requests[id]:
                    for server, method, url, host, remote in requests[id]:
                        f.write(f"{id}  server={server:7s} {method} {url}  Host: {host}  from {remote}\n")
                else:
                    f.write(f"{id}  (no request reached any server)\n")
        # --- nothing was written
        main_after = sha256(os.path.join(sites["main"], "pages", SLUG))
        frozen_after = sha256(stored)
        if not (frozen_before == frozen_after and main_before == main_after): sys.exit("a stored page changed")
        if any(v is None for v in results.values()): sys.exit("an observation is missing")
        # --- the record
        def s(x): return '"' + x.replace("\\", "\\\\").replace('"', '\\"') + '"'
        version = lambda *c: run(list(c)).stdout.strip().splitlines()[0]
        environment = [("topology", "two Linux network namespaces joined by a veth pair on 10.77.0.0/24: the wiki server and the DNS server at " + SERVER_IP + ", the observer at " + CLIENT_IP),
                       ("failure", DNS_DESCRIPTION[dns_failure]), ("kernel", version("uname", "-sr")), ("sbcl", version(sbcl, "--version")),
                       ("node", version("node", "--version")), ("wiki-server", "the original wiki-server 0.28.1 (npm), security_legacy=false: read-only for visitors"),
                       ("http", "drakma, HTTP without TLS"), ("endpoint-mapping", "drakma :real-host; the URL and the Host header keep the site name")]
        limits = ["HTTP without TLS: no authenticated site identity; the endpoint's identity is inferred from equal content, not proven.",
                  "One site, one page, one failure mode per run; a production farm and other DNS failures were not tested.",
                  "No DNS replacement, peer discovery, synchronisation or editor: the endpoint was given, not found.",
                  "The addresses are private, in disposable network namespaces; no production data was read or written."]
        header = (f"(:fedwiki-without-dns-record :version 1 :title {s('Reading one Wiki page without DNS')} :site {s(SITE)} :slug {s(SLUG)}\n"
                  f" :fixture-sha256 {s(frozen_before)} :fixture-octets {os.path.getsize(stored)} :recorded-at {int(time.time()) + 2208988800}\n"
                  f" :dns-failure {s(dns_failure + ': ' + DNS_DESCRIPTION[dns_failure])}\n :environment ({' '.join(':' + k + ' ' + s(v) for k, v in environment)})\n"
                  f" :limits ({' '.join(s(l) for l in limits)})\n :observations (\n")
        record = header + "\n".join(results[k].rstrip() for k in "ABCDEF") + "\n))\n"
        with open(os.path.join(out, "experiment-record.lisp-data"), "w", encoding="utf-8") as f: f.write(record)
        with open(os.path.join(evidence, "dns-queries.txt"), "w") as f:
            f.write("mode\tqname\tqtype\tanswer\n" + "\n".join("\t".join(map(str, row)) for row in dns.log) + "\n")
        with open(os.path.join(evidence, "topology.txt"), "w") as f: f.write(topology)
        with open(os.path.join(evidence, "stored-pages.txt"), "w") as f:
            f.write(f"frozen page before {frozen_before}\nfrozen page after  {frozen_after}\nserved copy before {main_before}\nserved copy after  {main_after}\n"
                    f"altered copy       {sha256(os.path.join(sites['altered'], 'pages', SLUG))}\n")
        for name in ("main", "empty", "altered"):
            with open(os.path.join(evidence, f"wiki-server-{name}.log"), "w") as f: f.write(sanitize(open(os.path.join(work, name + ".log")).read(), work))
        print("record written:", os.path.join(out, "experiment-record.lisp-data"))
        dns.stop.set()
    finally:
        for p in processes:
            p.terminate()
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
