#!/usr/bin/env python3
"""Independent local two-server client; no graph conversion, writes, synchronization or public endpoint."""
import argparse
import base64
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import http.client
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import threading
import time
from urllib.parse import quote

REPO = Path(__file__).resolve().parent.parent
ISO_REV = '521a1f38ffe40edf02f8c3d6faae2c373ad150c1'
SNAPSHOT_REV = '0484a4b76128c3ed302a6a8d6e0343bfe03cece5'
PIN = '88994c1b9e1edbf13e665e984a5c9c3b2cdf7575'
SHA = '8b4142421f5bfa1cc089e7ac53b43ebc6975e597cdedea5a49f6fc226dcc2e1d'
OWNER = 'tag:dreyeck.ch,2026:hyperdoc/assignment/codex-2026-10-29-template-identity-substitution'
DMX_URI = 'hyperdoc:mcp/workspace-note/local-iso-reference'
NOTE = f'ISO subject identifier: {OWNER}\nISO snapshot source: {SNAPSHOT_REV}\nDMX authority: local-dmx-fixture-v1'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--iso-root', type=Path, required=True)
    parser.add_argument('--topic-maps-root', type=Path, required=True)
    parser.add_argument('--artifacts', type=Path, required=True)
    args = parser.parse_args()
    out = args.artifacts.resolve()
    out.mkdir(parents=True, exist_ok=True)
    iso = args.iso_root.resolve()
    reader = args.topic_maps_root.resolve()
    assert subprocess.check_output(['git', '-C', str(iso), 'rev-parse', 'HEAD']).decode().strip() == ISO_REV
    assert not subprocess.check_output(['git', '-C', str(iso), 'status', '--porcelain'])
    assert subprocess.check_output(['git', '-C', str(reader), 'rev-parse', 'HEAD']).decode().strip() == PIN
    assert not subprocess.check_output(['git', '-C', str(reader), 'status', '--porcelain'])
    original_script = subprocess.check_output(['git', 'show', ISO_REV + ':scripts/review-tmdm-mcp.lisp'], cwd=REPO)
    assert (iso / 'scripts/review-tmdm-mcp.lisp').read_bytes() == original_script
    expected = subprocess.check_output(['git', 'show', SNAPSHOT_REV + ':dreyeck/work/project/hyperdoc-project.ctm'], cwd=REPO)
    assert hashlib.sha256(expected).hexdigest() == SHA
    (out / 'expected.ctm').write_bytes(expected)
    calls = []

    class Backend(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def do_GET(self):
            calls.append((self.command, self.path))
            topic = {'id': 7, 'uri': DMX_URI, 'typeUri': 'dmx.notes.note', 'value': 'ISO subject reference',
                     'children': {'dmx.notes.title': {'value': 'ISO subject reference'}, 'dmx.notes.text': {'value': NOTE}}}
            if self.path.startswith('/topicmaps/1?'):
                data = {'topic': {'id': 1}, 'topics': [topic], 'assocs': []}
            elif self.path.startswith('/core/topic/7?'):
                data = topic
            else:
                self.send_error(404)
                return
            body = json.dumps(data).encode()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_POST(self):
            calls.append((self.command, self.path))
            self.send_error(405)
        do_PUT = do_POST
        do_DELETE = do_POST
        do_PATCH = do_POST

    backend = ThreadingHTTPServer(('127.0.0.1', 0), Backend)
    threading.Thread(target=backend.serve_forever, daemon=True).start()
    processes = []
    logs = []
    checks = 0

    def check(label, condition):
        nonlocal checks
        if not condition:
            raise AssertionError(label)
        checks += 1
        print('MCP-COEXISTENCE', label, 'PASS', flush=True)

    def port():
        with socket.socket() as listener:
            listener.bind(('127.0.0.1', 0))
            return listener.getsockname()[1]

    def start(script, env, name):
        log = (out / (name + '.log')).open('w')
        logs.append(log)
        process = subprocess.Popen([os.environ.get('SBCL', 'sbcl'), '--noinform', '--no-sysinit', '--no-userinit',
                                    '--script', str(script)], cwd=script.parent.parent, env=env,
                                   stdout=log, stderr=subprocess.STDOUT)
        processes.append(process)
        return process

    def call(server_port, token, method, sid=None, params=None, request_id=1):
        payload = {'jsonrpc': '2.0', 'method': method}
        if method != 'notifications/initialized':
            payload['id'] = request_id
        if params is not None:
            payload['params'] = params
        headers = {'Content-Type': 'application/json', 'Accept': 'application/json, text/event-stream',
                   'Authorization': 'Bearer ' + token}
        if sid:
            headers['Mcp-Session-Id'] = sid
        client = http.client.HTTPConnection('127.0.0.1', server_port, timeout=30)
        try:
            client.request('POST', '/mcp', json.dumps(payload), headers)
            response = client.getresponse()
            data = response.read(2_000_001)
            assert len(data) <= 2_000_000
            return response.status, dict(response.getheaders()), json.loads(data) if data else None
        finally:
            client.close()

    def initialize(server_port, token, process):
        deadline = time.monotonic() + 90
        while True:
            if process.poll() is not None:
                raise RuntimeError('Server startup failed; inspect local logs')
            try:
                status, headers, data = call(server_port, token, 'initialize', params={
                    'protocolVersion': '2025-03-26', 'capabilities': {},
                    'clientInfo': {'name': 'independent-two-server-client', 'version': '1'}})
                assert status == 200
                sid = next(v for k, v in headers.items() if k.lower() == 'mcp-session-id')
                assert call(server_port, token, 'notifications/initialized', sid)[0] == 202
                return sid, data['result']
            except OSError:
                if time.monotonic() >= deadline:
                    raise TimeoutError('Server startup')
                time.sleep(.1)

    dmx_port, iso_port = port(), port()
    dmx_token, iso_token = secrets.token_urlsafe(32), secrets.token_urlsafe(32)
    dmx_stop, iso_stop = out / 'dmx-stop', out / 'iso-stop'
    dmx_stop.unlink(missing_ok=True)
    iso_stop.unlink(missing_ok=True)
    try:
        dmx_env = dict(os.environ, HYPERDOC_DISCOVERY_BACKEND=f'http://127.0.0.1:{backend.server_port}',
                       HYPERDOC_DISCOVERY_PORT=str(dmx_port), HYPERDOC_DISCOVERY_TOKEN=dmx_token,
                       HYPERDOC_DISCOVERY_STOP=str(dmx_stop))
        dmx_process = start(REPO / 'tests/dmx-mcp-resource-discovery-server.lisp', dmx_env, 'dmx-server')
        iso_env = dict(os.environ, HYPERDOC_REVIEW_PORT=str(iso_port), HYPERDOC_REVIEW_TOKEN=iso_token,
                       HYPERDOC_REVIEW_CTM=str(out / 'expected.ctm'), HYPERDOC_REVIEW_STOP=str(iso_stop),
                       HYPERDOC_REVIEW_RECEIVED=str(out / 'received.ctm'))
        iso_env['CL_SOURCE_REGISTRY'] = str(reader) + '//:' + str(iso) + '/:' + os.environ.get('CL_SOURCE_REGISTRY', '')
        iso_process = start(iso / 'scripts/review-tmdm-mcp.lisp', iso_env, 'iso-server')
        dmx_sid, dmx_info = initialize(dmx_port, dmx_token, dmx_process)
        iso_sid, iso_info = initialize(iso_port, iso_token, iso_process)
        check('independent-server-identities', dmx_info['serverInfo']['name'] == 'hyperdoc-dmx-mcp' and
              iso_info['serverInfo']['name'] == 'hyperdoc-iso13250-review')
        check('distinct-capability-boundaries', set(dmx_info['capabilities']) == {'resources', 'tools'} and
              set(iso_info['capabilities']) == {'resources'})
        dmx_list = call(dmx_port, dmx_token, 'resources/list', dmx_sid)[2]
        check('dmx-list', 'result' in dmx_list and
              'dmx://topic/7' in [r['uri'] for r in dmx_list['result']['resources']])
        check('dmx-discovery-one-backend-get', calls == [('GET', '/topicmaps/1?children=true')])
        iso_list = call(iso_port, iso_token, 'resources/list', iso_sid)[2]['result']['resources']
        ctm_uri = next(r['uri'] for r in iso_list if r['uri'].endswith('/project.ctm'))
        manifest_uri = next(r['uri'] for r in iso_list if r['uri'].endswith('/manifest.json'))

        def read(server_port, token, sid, uri):
            status, _, data = call(server_port, token, 'resources/read', sid, {'uri': uri})
            assert status == 200 and 'result' in data
            content = data['result']['contents']
            assert len(content) == 1 and content[0]['uri'] == uri
            return content[0]

        note = json.loads(read(dmx_port, dmx_token, dmx_sid, 'dmx://topic/7')['text'])
        check('dmx-note-keeps-own-authority', note['id'] == 7 and note['uri'] == DMX_URI and
              'DMX authority: local-dmx-fixture-v1' in note['text'])
        subject = note['text'].split('ISO subject identifier: ', 1)[1].splitlines()[0]
        check('reference-is-stable-si-not-dmx-identity', subject == OWNER and note['uri'] != subject)
        manifest = json.loads(read(iso_port, iso_token, iso_sid, manifest_uri)['text'])
        check('iso-source-revision-and-reader-pin', manifest['sourceRevision'] == SNAPSHOT_REV and
              manifest['topicMapsRevision'] == PIN and f'ISO snapshot source: {SNAPSHOT_REV}' in note['text'])
        check('retrieval-uri-distinct-from-topic-and-document-identities', manifest['documentIRI'] ==
              'tag:dreyeck.ch,2026:hyperdoc/project.ctm' and ctm_uri != manifest['documentIRI'] and ctm_uri != subject)
        content = read(iso_port, iso_token, iso_sid, ctm_uri)
        received = base64.b64decode(content['blob'], validate=True)
        check('iso-ctm-reviewed-octets', content['mimeType'] == 'application/octet-stream' and
              received == expected and hashlib.sha256(received).hexdigest() == manifest['sha256'] == SHA)
        (out / 'received.ctm').write_bytes(received)
        templates = call(iso_port, iso_token, 'resources/templates/list', iso_sid)[2]['result']['resourceTemplates']
        template = templates[0]['uriTemplate']
        native = json.loads(read(iso_port, iso_token, iso_sid, template.replace('{si}', quote(subject, safe='')))['text'])
        check('native-tmdm-reference-lookup', subject in native['identity']['subjectIdentifiers'])
        check('native-source-association-present', any('tag:dreyeck.ch,2026:hyperdoc/schema/reads-source' in
              a['type']['subjectIdentifiers'] for a in native['associations']))
        evidence_id = subject.replace('/assignment/', '/evidence/') + '/original-source'
        evidence = json.loads(read(iso_port, iso_token, iso_sid,
                              template.replace('{si}', quote(evidence_id, safe='')))['text'])
        check('native-evidence-retains-reification', subject in evidence['reifiedOccurrence']['parent']['subjectIdentifiers']
              and evidence_id in evidence['reifiedOccurrence']['reifier']['subjectIdentifiers'])
        check('dmx-uri-not-an-iso-resource', call(iso_port, iso_token, 'resources/read', iso_sid,
              {'uri': 'dmx://topic/7'})[2]['error']['code'] == -32002)
        check('iso-si-not-a-dmx-resource', 'error' in call(dmx_port, dmx_token, 'resources/read', dmx_sid,
              {'uri': subject})[2])
        backend.shutdown()
        backend.server_close()
        down = call(dmx_port, dmx_token, 'resources/list', dmx_sid, request_id=31)[2]
        check('dmx-backend-failure-retains-id', down['id'] == 31 and down['error']['code'] == -32099)
        check('iso-list-survives-dmx-backend-failure', len(call(iso_port, iso_token, 'resources/list', iso_sid)[2]
              ['result']['resources']) == 2)
        check('independent-data-not-synchronized', json.loads(read(iso_port, iso_token, iso_sid,
              template.replace('{si}', quote(subject, safe='')))['text'])['identity'] == native['identity'])
        check('no-backend-write', all(method == 'GET' for method, _ in calls))
        dmx_stop.touch()
        iso_stop.touch()
        check('both-fresh-processes-exit-zero', dmx_process.wait(timeout=30) == 0 and iso_process.wait(timeout=30) == 0)
        for log in logs:
            log.flush()
        iso_log = (out / 'iso-server.log').read_text()
        check('native-received-ctm-cxtm-and-unchanged-map', 'MCP-REVIEW-READBACK PASS' in iso_log and
              'MCP-REVIEW-UNCHANGED' in iso_log)
        result = {'checks': checks, 'isoSource': ISO_REV, 'isoScriptSHA256': hashlib.sha256(original_script).hexdigest(),
                  'snapshotSource': SNAPSHOT_REV, 'snapshotSHA256': SHA, 'topicMapsPin': PIN,
                  'dmxAuthority': 'local-dmx-fixture-v1', 'dmxNoteURI': DMX_URI, 'referencedSubjectIdentifier': subject,
                  'dmxRepairSourceSHA256': hashlib.sha256((REPO / 'hyperdoc/mcp-server.lisp').read_bytes()).hexdigest(),
                  'remoteAccess': False, 'writeBack': False, 'graphConversion': False, 'nativeCXTM': 'PASS'}
        (out / 'results.json').write_text(json.dumps(result, indent=2) + '\n')
        print(f'MCP-COEXISTENCE-PASS: {checks} checks', flush=True)
    finally:
        for process in processes:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=10)
        for log in logs:
            log.close()
        backend.shutdown()
        backend.server_close()


if __name__ == '__main__':
    main()
