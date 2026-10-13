#!/usr/bin/env python3
"""Execute the documented control flow in disposable fixtures, never on a host.
Real filesystem/curl/HTTP/byte comparisons; Nix and activation commands substituted.
"""
from pathlib import Path
import http.server
import os
import re
import shutil
import shlex
import subprocess
import tempfile
import threading
import unittest

ROOT = Path(__file__).resolve().parents[1]
DOCS = [ROOT / 'docs/fedwiki-mech-story.md', ROOT / 'dreyeck/CATALOG-OPERATIONS.md']
BLOCKS = {}
for doc in DOCS:
    text = doc.read_text()
    for key, shell in re.findall(r'<!-- deployment-example: ([\w-]+) -->\n```bash\n(.*?)```', text, re.S):
        assert key not in BLOCKS
        BLOCKS[key] = shell
    for shell in re.findall(r'```(?:bash|sh)\n(.*?)```', text, re.S):
        subprocess.run(['bash', '-n'], input=shell, text=True, check=True)

# The bounded asset-switch trial has one source authority. Do not let a new
# Markdown copy silently replace it. Other procedures retain their reference path.
assert 'asset-switch' not in BLOCKS, 'Duplicate asset-switch authority in Markdown'
ASSET_SWITCH = ROOT / 'scripts/mech-asset-switch.sh'
subprocess.run(['bash', '-n', str(ASSET_SWITCH)], check=True)
BLOCKS['asset-switch'] = '. ' + shlex.quote(str(ASSET_SWITCH)) + '\n'

class DeploymentExamples(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='deployment-counterexamples-')
        self.root = Path(self.tmp.name)
        self.assets = self.root / 'assets'; self.assets.mkdir()
        self.source = self.root / 'source/assets/hyperbook/fedwiki/mech-host'; self.source.mkdir(parents=True)
        for name, body in {'index.html':'<!doctype html>Fixture host', 'host.js':'// fixture module',
                           'wiki-dialog.js':'// fixture dialog', 'provenance.json':'{"fixture":true}',
                           'dialog/index.html':'<!doctype html>Fixture receiver',
                           'plugins/solo/dialog/index.html':'<!doctype html>Fixture Solo'}.items():
            file = self.source / name; file.parent.mkdir(parents=True, exist_ok=True); file.write_text(body)
        self.rev = 'a' * 40
        self.version = self.assets / 'hyperdoc-mech-versions' / self.rev
        self.old = self.assets / 'hyperdoc-mech-versions' / ('b' * 40)
        self.old.mkdir(parents=True)
        self.target = self.assets / 'hyperdoc-mech'
        self.target.symlink_to('hyperdoc-mech-versions/' + 'b' * 40)
        self.initial_link = os.readlink(self.target)
        self.bin = self.root / 'bin'; self.bin.mkdir()
        # The examples target GNU/NixOS mv, not BSD mv's different flags.
        for name in ('mv', 'readlink'):
            executable = shutil.which('g' + name) or shutil.which(name)
            self.bin.joinpath(name).symlink_to(executable)
        self.stub('nix', 'printf "%s\\n" "$SOURCE_ROOT"')
        self.stub('nixos-rebuild', '''printf '%s\\n' "$*" >> "$COMMAND_LOG"
if test "${MUTATE_BUILD:-0}" = 1; then printf '%040d' 0 > "$LOCK_FIXTURE"; fi''')
        self.env = dict(os.environ, PATH=str(self.bin)+':'+os.environ['PATH'],
                        SOURCE_ROOT=str(self.root/'source'), WIKI_ASSETS_DIR=str(self.assets),
                        MECH_REV=self.rev, TMPDIR=str(self.root), COMMAND_LOG=str(self.root/'commands'),
                        LOCK_FIXTURE=str(self.root/'lock'))
        self.bad_body = False; self.bad_mime = False
        fixture = self
        class Handler(http.server.SimpleHTTPRequestHandler):
            def log_message(self, *args): pass
            def translate_path(self, path):
                if path.startswith('/assets/'):
                    return str(fixture.assets / path.removeprefix('/assets/'))
                return str(fixture.source / path.lstrip('/'))
            def do_GET(self):
                if self.path.endswith('/host.js') and (fixture.bad_body or fixture.bad_mime):
                    self.send_response(200)
                    self.send_header('Content-Type', 'text/plain' if fixture.bad_mime else 'application/javascript')
                    self.end_headers()
                    self.wfile.write(b'Wrong body' if fixture.bad_body else (fixture.source/'host.js').read_bytes())
                else: super().do_GET()
        self.server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True); self.thread.start()
        self.env['ASSET_ORIGIN'] = f'http://127.0.0.1:{self.server.server_port}'
    def tearDown(self):
        self.server.shutdown(); self.server.server_close(); self.thread.join()
        # Authored copies are deliberately read-only.
        for directory, dirs, files in os.walk(self.root):
            os.chmod(directory, 0o700)
        self.tmp.cleanup()
    def stub(self, name, body):
        file = self.bin/name; file.write_text('#!/bin/bash\nset -eu\n'+body+'\n'); file.chmod(0o700)
    def run_blocks(self, *names, extra='', **environment):
        return subprocess.run(['bash'], input='set -euo pipefail\n'+''.join(BLOCKS[n] for n in names)+extra,
                              text=True, capture_output=True, cwd=self.root, env=dict(self.env, **environment))
    def unchanged(self): self.assertEqual(os.readlink(self.target), self.initial_link)
    def prepare(self):
        result=self.run_blocks('asset-prepare'); self.assertEqual(result.returncode,0,result.stderr)
    def test_missing_then_identical_existing_is_noop(self):
        self.prepare(); before=(self.version.stat().st_ino,(self.version/'host.js').stat().st_mtime_ns)
        result=self.run_blocks('asset-prepare','asset-http')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('Existing revision verified',result.stdout)
        self.assertEqual(before,(self.version.stat().st_ino,(self.version/'host.js').stat().st_mtime_ns)); self.unchanged()
    def test_existing_content_or_provenance_mismatch(self):
        for resource in ('host.js','provenance.json'):
            with self.subTest(resource=resource):
                if not self.version.exists(): self.prepare()
                file=self.version/resource; file.chmod(0o600); original=file.read_bytes(); file.write_text('wrong')
                result=self.run_blocks('asset-prepare','asset-http','asset-switch',APPROVE_ASSET_SWITCH=self.rev)
                self.assertNotEqual(result.returncode,0); self.assertIn('Existing revision differs',result.stderr)
                self.assertEqual(file.read_text(),'wrong'); self.unchanged(); file.write_bytes(original)
    def test_failed_staged_file_comparison(self):
        self.stub('diff','echo "Injected file comparison failure" >&2; exit 42')
        result=self.run_blocks('asset-prepare','asset-http','asset-switch',APPROVE_ASSET_SWITCH=self.rev)
        self.assertNotEqual(result.returncode,0); self.assertIn('Staged copy differs',result.stderr)
        self.assertFalse(self.version.exists()); self.unchanged()
    def test_http_200_wrong_body_or_mime_refuses_switch(self):
        self.prepare()
        for mode in ('bad_body','bad_mime'):
            with self.subTest(mode=mode):
                setattr(self,mode,True)
                result=self.run_blocks('asset-prepare','asset-http','asset-switch',APPROVE_ASSET_SWITCH=self.rev)
                self.assertNotEqual(result.returncode,0)
                self.assertIn('HTTP content mismatch' if mode == 'bad_body' else 'Wrong JavaScript MIME', result.stderr)
                self.unchanged(); setattr(self,mode,False)
    def test_approval_required(self):
        self.prepare()
        result=self.run_blocks('asset-prepare','asset-http','asset-switch',APPROVE_ASSET_SWITCH='no')
        self.assertNotEqual(result.returncode,0); self.unchanged()
    def test_selection_repeat_and_rollback(self):
        result=self.run_blocks('asset-prepare','asset-http','asset-switch',APPROVE_ASSET_SWITCH=self.rev)
        self.assertEqual(result.returncode,0,result.stderr)
        inode=self.target.lstat().st_ino
        result=self.run_blocks('asset-prepare','asset-http','asset-switch',APPROVE_ASSET_SWITCH=self.rev)
        self.assertEqual(result.returncode,0,result.stderr); self.assertEqual(inode,self.target.lstat().st_ino)
        # Recreate initial target, then exercise the actual rollback of a switch.
        self.target.unlink(); self.target.symlink_to(self.initial_link)
        result=self.run_blocks('asset-prepare','asset-http','asset-switch','asset-rollback',APPROVE_ASSET_SWITCH=self.rev)
        self.assertEqual(result.returncode,0,result.stderr); self.unchanged()
    def catalog(self, selected, activate=False, **env):
        (self.root/'lock').write_text(selected)
        (self.root/'result').symlink_to(self.source)
        prefix='set -euo pipefail\nlocked_hyperdoc_rev() { cat "$LOCK_FIXTURE"; }\ncatalog_receipt="$TMPDIR"\n'
        return subprocess.run(['bash'],input=prefix+BLOCKS['catalog-review']+(BLOCKS['catalog-activate'] if activate else ''),text=True,capture_output=True,
                              cwd=self.root,env=dict(self.env,REVIEWED_CATALOG_REV=self.rev,**env))
    def test_unexpected_catalog_revision_prevents_build(self):
        result=self.catalog('c'*40,activate=True)
        self.assertNotEqual(result.returncode,0); self.assertIn('Unexpected Catalog revision',result.stderr)
        self.assertFalse((self.root/'commands').exists())
    def test_reviewed_branch_builds_without_pin(self):
        result=self.catalog(self.rev,CATALOG_MODE='branch')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual((self.root/'commands').read_text(),'build --flake /etc/nixos#dreyeck\n')
    def test_explicit_pin_mismatch_refused(self):
        result=self.catalog(self.rev,activate=True,CATALOG_MODE='pin',CATALOG_REV='d'*40)
        self.assertNotEqual(result.returncode,0); self.assertFalse((self.root/'commands').exists())
    def test_matching_pin_builds(self):
        result=self.catalog(self.rev,CATALOG_MODE='pin',CATALOG_REV=self.rev)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertNotIn('switch',(self.root/'commands').read_text())
    def test_activation_requires_separate_approval(self):
        result=self.catalog(self.rev,activate=True,APPROVE_CATALOG_SWITCH='no')
        self.assertNotEqual(result.returncode,0)
        self.assertNotIn('switch',(self.root/'commands').read_text())
    def test_revision_changes_during_build(self):
        result=self.catalog(self.rev,MUTATE_BUILD='1')
        self.assertNotEqual(result.returncode,0); self.assertIn('Revision changed during build',result.stderr)
        self.assertNotIn('switch',(self.root/'commands').read_text())

if __name__ == '__main__': unittest.main(verbosity=2)
