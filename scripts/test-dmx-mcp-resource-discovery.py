#!/usr/bin/env python3
"""Local HTTP backend + fresh real DMX MCP process; --original fingerprints the recorded failure."""
import argparse
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import http.client
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import tempfile
import threading
import time

REPO = Path(__file__).resolve().parent.parent
BASE = '591f275fc26ebef7967cc8d3e3fb5a0efc19cc85'
REMOTE_ERROR_SHA = '4c3cbe31dd2b9f4c489472d172fa90f11e9f144871f1a90f339caa2cbc415df0'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--original', action='store_true')
    parser.add_argument('--artifacts', type=Path, required=True)
    args = parser.parse_args()
    out = args.artifacts.resolve()
    out.mkdir(parents=True, exist_ok=True)
    checks = 0
    requests = []
    mode = 'valid'

    class Backend(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def do_GET(self):
            requests.append(('GET', self.path))
            if self.path.startswith('/topicmaps/1?'):
                status, data = 200, {'topic': {'id': 1}, 'topics': [{'id': 7}, {'id': 8}], 'assocs': []}
                if mode == 'malformed-json':
                    data = b'{BROKEN-SYNTHETIC-PRIVATE'
                elif mode == 'html':
                    data = b'<html>SYNTHETIC-PRIVATE</html>'
                elif mode == 'scalar':
                    data = 'unexpected scalar'
                elif mode == 'false':
                    data = False
                elif mode == 'null':
                    data = None
                elif mode == 'array':
                    data = []
                elif mode == 'blank':
                    data = b' \n'
                elif mode == 'missing-topics':
                    data = {'topic': {'id': 1}}
                elif mode == 'bad-topics':
                    data['topics'] = {'unexpected': 'SYNTHETIC-PRIVATE'}
                elif mode == 'bad-topic-id':
                    data['topics'] = [{'id': 'invalid'}]
                elif mode == 'empty':
                    data['topics'] = []
                elif mode in ('unauthorized', 'forbidden', 'unavailable'):
                    status = {'unauthorized': 401, 'forbidden': 403, 'unavailable': 503}[mode]
                    data = {'error': 'SYNTHETIC-PRIVATE'}
            elif self.path.startswith('/core/topic/7?'):
                status, data = 200, {'id': 7, 'uri': 'hyperdoc:mcp/workspace-note/local-iso-reference',
                                    'typeUri': 'dmx.notes.note', 'value': 'ISO reference fixture',
                                    'children': {'dmx.notes.title': {'value': 'ISO reference fixture'},
                                                 'dmx.notes.text': {'value': 'Local DMX authority fixture-v1'}}}
                if mode == 'malformed-topic':
                    data = b'{SYNTHETIC-PRIVATE'
                elif mode == 'wrong-topic-id':
                    data['id'] = 8
                elif mode == 'topic-unauthorized':
                    status, data = 401, {'error': 'SYNTHETIC-PRIVATE'}
            elif self.path.startswith('/core/topic/8?'):
                status, data = 200, {'id': 8, 'value': 'Second topic', 'children': {}}
            else:
                status, data = 404, {'error': 'SYNTHETIC-PRIVATE'}
            body = data if isinstance(data, bytes) else json.dumps(data).encode()
            self.send_response(status)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_POST(self):
            requests.append((self.command, self.path))
            self.send_error(405)

        do_PUT = do_POST
        do_PATCH = do_POST
        do_DELETE = do_POST

    backend = ThreadingHTTPServer(('127.0.0.1', 0), Backend)
    worker = threading.Thread(target=backend.serve_forever, daemon=True)
    worker.start()
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        port = sock.getsockname()[1]
    token = secrets.token_urlsafe(32)
    stop = out / 'stop'
    stop.unlink(missing_ok=True)
    env = dict(os.environ, HYPERDOC_DISCOVERY_BACKEND=f'http://127.0.0.1:{backend.server_port}',
               HYPERDOC_DISCOVERY_PORT=str(port), HYPERDOC_DISCOVERY_TOKEN=token,
               HYPERDOC_DISCOVERY_STOP=str(stop))
    if args.original:
        original = out / 'original-mcp-server.lisp'
        original.write_bytes(subprocess.check_output(['git', 'show', BASE + ':hyperdoc/mcp-server.lisp'], cwd=REPO))
        env['HYPERDOC_DISCOVERY_ORIGINAL_SOURCE'] = str(original)

    def check(label, condition):
        nonlocal checks
        if not condition:
            raise AssertionError(label)
        checks += 1
        print(f'DMX-DISCOVERY {label} PASS', flush=True)

    def call(method, *, sid=None, request_id=2, params=None, auth=token, raw_body=None):
        payload = {'jsonrpc': '2.0', 'method': method}
        if method != 'notifications/initialized':
            payload['id'] = request_id
        if params is not None:
            payload['params'] = params
        headers = {'Content-Type': 'application/json', 'Accept': 'application/json, text/event-stream'}
        if auth is not None:
            headers['Authorization'] = 'Bearer ' + auth
        if sid:
            headers['Mcp-Session-Id'] = sid
        # The unchanged DMX HTTP client has a 20-second connection timeout.
        client = http.client.HTTPConnection('127.0.0.1', port, timeout=30)
        try:
            client.request('POST', '/mcp', json.dumps(payload) if raw_body is None else raw_body, headers)
            response = client.getresponse()
            data = response.read(2_000_001)
            assert len(data) <= 2_000_000
            return response.status, dict(response.getheaders()), json.loads(data) if data else None, data
        finally:
            client.close()

    with (out / 'server.log').open('w') as log:
        process = subprocess.Popen([os.environ.get('SBCL', 'sbcl'), '--noinform', '--no-sysinit', '--no-userinit',
                                    '--script', str(REPO / 'tests/dmx-mcp-resource-discovery-server.lisp')],
                                   env=env, cwd=REPO, stdout=log, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 90
            while True:
                if process.poll() is not None:
                    raise RuntimeError('Fresh DMX server failed; see server.log')
                try:
                    call('initialize', auth=None)
                    break
                except OSError:
                    if time.monotonic() >= deadline:
                        raise TimeoutError('Fresh DMX server startup; see server.log')
                    time.sleep(.1)
            status, headers, initialized, _ = call('initialize', request_id=1,
                params={'protocolVersion': '2025-03-26', 'capabilities': {}, 'clientInfo': {'name': 'local-discovery', 'version': '1'}})
            check('initialize', status == 200 and initialized['result']['serverInfo']['name'] == 'hyperdoc-dmx-mcp')
            sid = next(v for k, v in headers.items() if k.lower() == 'mcp-session-id')
            check('initialized', call('notifications/initialized', sid=sid)[0] == 202)
            status, _, response, raw = call('resources/list', sid=sid)
            if args.original:
                check('original-internal-error', status == 200 and response['error']['code'] == -32099)
                check('original-false-id', response['id'] is False)
                check('recorded-remote-error-fingerprint', len(raw) == 214 and hashlib.sha256(raw).hexdigest() == REMOTE_ERROR_SHA)
                check('real-http-topicmap-read-before-failure', requests == [('GET', '/topicmaps/1?children=true')])
                summary = {'source': BASE, 'checks': checks, 'errorBodyBytes': len(raw),
                           'errorBodySHA256': hashlib.sha256(raw).hexdigest(),
                           'fingerprintMatchedException': 'undefined HYPERDOC::JSON-ARRAY-ELEMENTS',
                           'deployedGitRevision': 'unknown; no operator deployment evidence'}
            else:
                check('list-success', status == 200 and 'result' in response)
                resources = response['result']['resources']
                uris = [r['uri'] for r in resources]
                check('same-resource-identities', set(uris) == {'dmx://workspace/context-window', 'dmx://topicmap/1',
                      'dmx://topic/7', 'dmx://topic/8', 'dmx://topic/999'})
                check('known-and-member-id-deduplication', uris.count('dmx://topic/7') == 1)
                check('one-topicmap-get-and-zero-topic-gets', requests == [('GET', '/topicmaps/1?children=true')])
                check('discovery-does-not-fetch-optional-title', all('title' not in r for r in resources))
                before = len(requests)
                status, _, data, _ = call('resources/read', sid=sid, request_id=17, params={'uri': 'dmx://topic/7'})
                topic = json.loads(data['result']['contents'][0]['text'])
                check('on-demand-topic-read', status == 200 and topic['id'] == 7 and
                      requests[before:] == [('GET', '/core/topic/7?children=true&assocChildren=true')])
                check('on-demand-topic-content', topic['text'] == 'Local DMX authority fixture-v1')
                missing = call('resources/read', sid=sid, request_id=18, params={'uri': 'dmx://topic/999'})[2]
                check('absent-configured-topic-fails-on-demand', missing['id'] == 18 and
                      missing['error']['data']['statusCode'] == 404)
                check('absent-topic-diagnostics-private', 'SYNTHETIC-PRIVATE' not in json.dumps(missing) and
                      'responseBody' not in json.dumps(missing))
                cases = {}
                for mode in ['malformed-json', 'html', 'scalar', 'false', 'null', 'array', 'blank',
                             'missing-topics', 'bad-topics', 'bad-topic-id',
                             'unauthorized', 'forbidden', 'unavailable']:
                    before = len(requests)
                    status, _, data, _ = call('resources/list', sid=sid, request_id=mode)
                    check(mode + '/bounded-error-and-id', status == 200 and data['id'] == mode and
                          data['error']['code'] == -32010)
                    check(mode + '/diagnostics-private', 'SYNTHETIC-PRIVATE' not in json.dumps(data) and
                          not any(k in json.dumps(data) for k in ('responseBody', 'httpEvidence', '"detail"', '"url"')))
                    check(mode + '/no-topic-reads', requests[before:] == [('GET', '/topicmaps/1?children=true')])
                    if mode in ('unauthorized', 'forbidden', 'unavailable'):
                        check(mode + '/backend-status', data['error']['data']['statusCode'] ==
                              {'unauthorized': 401, 'forbidden': 403, 'unavailable': 503}[mode])
                    cases[mode] = {'http': status, 'rpc': data['error']['code']}
                for mode in ['malformed-topic', 'wrong-topic-id', 'topic-unauthorized']:
                    status, _, data, _ = call('resources/read', sid=sid, request_id=mode, params={'uri': 'dmx://topic/7'})
                    check(mode + '/on-demand-refusal', status == 200 and data['id'] == mode and
                          data['error']['code'] == -32010 and 'SYNTHETIC-PRIVATE' not in json.dumps(data))
                mode = 'empty'
                data = call('resources/list', sid=sid)[2]
                check('empty-topicmap-still-advertises-configured-ids', len(data['result']['resources']) == 4)
                mode = 'valid'
                before = len(requests)
                check('unauthorized-client-refused', call('resources/list', sid=sid, auth=None)[0] == 401)
                check('unauthorized-client-does-not-touch-backend', len(requests) == before)
                malformed = call('resources/list', sid=sid, raw_body='{')[2]
                check('unparseable-request-error-id-null', malformed['id'] is None and 'data' not in malformed['error'])
                malformed = call(42, sid=sid, request_id=44)[2]
                check('unexpected-error-preserves-request-id', malformed['id'] == 44 and malformed['error']['code'] == -32099)
                check('unexpected-error-detail-private', 'data' not in malformed['error'])
                before = len(requests)
                check('unauthorized-write-tool-refused', call('tools/call', sid=sid, auth=None,
                      params={'name': 'upsert_workspace_note', 'arguments': {'dryRun': False}})[0] == 401)
                denied = call('tools/call', sid=sid, params={'name': 'append_workspace_note',
                              'arguments': {'dryRun': False, 'title': 'Fixture', 'text': 'Fixture'}})[2]
                check('authorized-client-cannot-bypass-live-write-flag', denied['result']['isError'] is True and
                      denied['result']['structuredContent']['status'] == 'write_unavailable')
                dry = call('tools/call', sid=sid, params={'name': 'validated_dmx_write_dry_run',
                           'arguments': {'writeKind': 'topicmap_context_add', 'topicmapId': 1, 'topicId': 7,
                                         'viewProps': {'dmx.topicmaps.x': 1, 'dmx.topicmaps.y': 2,
                                                       'dmx.topicmaps.visibility': True, 'dmx.topicmaps.pinned': False}}})[2]
                check('existing-guarded-dry-run-still-works', 'result' in dry and not dry['result'].get('isError'))
                invalid = call('tools/call', sid=sid, params={'name': 'validated_dmx_write_dry_run',
                           'arguments': {'writeKind': 'topicmap_context_add', 'topicmapId': 1, 'topicId': 7,
                                         'viewProps': {'x': 1, 'y': 2}}})[2]
                check('existing-write-validation-still-refuses-short-keys', invalid['result']['isError'] is True)
                check('guard-tests-never-call-backend', len(requests) == before)
                backend.shutdown()
                backend.server_close()
                status, _, down, _ = call('resources/list', sid=sid, request_id=99)
                check('connection-refusal-is-bounded', status == 200 and down['id'] == 99 and
                      down['error']['code'] == -32099 and 'data' not in down['error'])
                templates = call('resources/templates/list', sid=sid)[2]
                check('template-discovery-independent-of-backend', len(templates['result']['resourceTemplates']) == 2)
                check('no-backend-writes', all(verb == 'GET' for verb, _ in requests))
                summary = {'checks': checks, 'sourceBase': BASE, 'negativeCases': cases,
                           'successfulDiscoveryHttpRequests': 1, 'discoveryTopicReads': 0,
                           'deployedGitRevision': 'unknown; no operator deployment evidence'}
            tools = call('tools/list', sid=sid)
            check('existing-tool-schema-advertised', tools[0] == 200 and 'tools' in tools[2]['result'])
            summary['toolDefinitionsSHA256'] = hashlib.sha256(tools[3]).hexdigest()
            stop.touch()
            check('local-server-exit', process.wait(timeout=15) == 0)
            summary['checks'] = checks
            (out / 'results.json').write_text(json.dumps(summary, indent=2) + '\n')
            print(f'DMX-DISCOVERY-PASS: {checks} checks; original={args.original}', flush=True)
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=10)
            backend.shutdown()
            backend.server_close()


if __name__ == '__main__':
    main()
