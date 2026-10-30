#!/usr/bin/env python3
"""Launch the packaged application against a loopback-only DMX fixture."""
import http.client
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import sys
import tempfile
import threading
import time

application = sys.argv[1]
calls = []
checks = 0


def check(name, value):
    global checks
    assert value, name
    checks += 1
    print('DMX-MCP-APPLICATION', name, 'PASS', flush=True)


class Backend(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_GET(self):
        calls.append((self.command, self.path))
        if self.path.startswith('/topicmaps/1?'):
            data = {'topic': {'id': 1}, 'topics': [{'id': 7}], 'assocs': []}
        elif self.path.startswith('/core/topic/7?'):
            data = {'id': 7, 'value': 'Application fixture', 'children': {}}
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


backend = ThreadingHTTPServer(('127.0.0.1', 0), Backend)
threading.Thread(target=backend.serve_forever, daemon=True).start()
with socket.socket() as sock:
    sock.bind(('127.0.0.1', 0))
    port = sock.getsockname()[1]
token = secrets.token_urlsafe(32)
with tempfile.TemporaryDirectory() as temporary:
    env = dict(os.environ, HYPERDOC_MCP_BEARER_TOKEN=token,
               HYPERDOC_DMX_IMPORT_BASE_URL=f'http://127.0.0.1:{backend.server_port}',
               HYPERDOC_MCP_WORKSPACE_TOPICMAP_ID='1', HYPERDOC_MCP_PORT=str(port),
               HYPERDOC_MCP_ALLOWED_ORIGINS='https://review.invalid',
               HYPERDOC_MCP_STATE_DIRECTORY=temporary, HYPERDOC_MCP_ENABLE_LIVE_WRITES='0')
    # Parent/backend credentials must not accidentally influence this local test.
    for key in list(env):
        if key.startswith('HYPERDOC_DMX_IMPORT_AUTH_') or key == 'HYPERDOC_DMX_IMPORT_WORKSPACE_ID':
            del env[key]
    log = (Path(temporary) / 'server.log').open('w')
    process = subprocess.Popen([application], env=env, stdout=log, stderr=subprocess.STDOUT)

    def rpc(method, ident=1, params=None, session=None, authorized=True):
        connection = http.client.HTTPConnection('127.0.0.1', port, timeout=30)
        headers = {'Content-Type': 'application/json', 'Accept': 'application/json, text/event-stream',
                   'Origin': 'https://review.invalid', 'MCP-Protocol-Version': '2025-03-26'}
        if authorized:
            headers['Authorization'] = 'Bearer ' + token
        if session:
            headers['Mcp-Session-Id'] = session
        body = {'jsonrpc': '2.0', 'method': method}
        if ident is not None:
            body['id'] = ident
        if params is not None:
            body['params'] = params
        connection.request('POST', '/mcp', json.dumps(body), headers)
        response = connection.getresponse()
        status, session_header = response.status, response.getheader('Mcp-Session-Id')
        data = response.read()
        connection.close()
        return status, session_header, json.loads(data) if data else None

    try:
        for _ in range(600):
            if process.poll() is not None:
                raise RuntimeError('Application exited; inspect private fixture log')
            try:
                with socket.create_connection(('127.0.0.1', port), timeout=.1):
                    break
            except OSError:
                time.sleep(.1)
        else:
            raise RuntimeError('Application startup timeout')
        check('bearer-required', rpc('initialize', authorized=False)[0] == 401)
        status, sid, body = rpc('initialize', params={'protocolVersion': '2025-03-26',
                                                    'clientInfo': {'name': 'local-review', 'version': '1'}})
        check('initialize', status == 200 and bool(sid) and body['result']['protocolVersion'] == '2025-03-26')
        check('initialized', rpc('notifications/initialized', ident=None, session=sid)[0] == 202)
        status, _, body = rpc('resources/list', ident=2, session=sid)
        check('resource-identities', status == 200 and {r['uri'] for r in body['result']['resources']} ==
              {'dmx://workspace/context-window', 'dmx://topicmap/1', 'dmx://topic/7', 'dmx://topic/907120'})
        check('one-member-read-no-topic-prefetch', len(calls) == 1 and calls[0][1].startswith('/topicmaps/1?'))
        status, _, body = rpc('resources/read', ident=3, session=sid, params={'uri': 'dmx://topic/7'})
        check('on-demand-read', status == 200 and body['id'] == 3 and 'result' in body)
        _, _, body = rpc('tools/call', ident=4, session=sid,
                         params={'name': 'append_workspace_note', 'arguments': {'dryRun': False}})
        check('live-write-gate', body['result']['isError'] is True)
        check('no-backend-write', all(method == 'GET' for method, _ in calls))
    finally:
        process.terminate()
        process.wait(timeout=15)
        log.close()
        backend.shutdown()
print('DMX-MCP-APPLICATION', checks, 'checks passed')
