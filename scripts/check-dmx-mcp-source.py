#!/usr/bin/env python3
"""Audit retained source spans against the verified repair Git object (no network)."""
import hashlib
import json
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parent.parent
manifest = json.loads((root / 'docs/dmx-mcp-source-manifest.json').read_text())
revision = manifest['sourceCommit']
sources = {}
for path, entry in manifest['files'].items():
    data = subprocess.check_output(['git', 'show', revision + ':' + path], cwd=root)
    assert hashlib.sha256(data).hexdigest() == entry['sourceSHA256'], path
    sources[path] = data.decode()
count = 0
for path in sorted((root / 'dmx-mcp').glob('*.lisp')):
    text = path.read_text()
    pattern = r';; From (.*), characters (\d+)\.\.(\d+)\.\n'
    for match in re.finditer(pattern, text):
        original_path, start, end = match.groups()
        start, end = int(start), int(end)
        assert [start, end] in manifest['files'][original_path]['characterSpans']
        expected = sources[original_path][start:end].strip()
        expected = expected.replace('normalize-topic-factory-snippet-source', 'dmx-mcp-require-snippet-definition')
        expected = expected.replace('json-array-elements', 'dmx-runtime-array-elements')
        assert text[match.end():].startswith(expected + '\n'), (path, original_path, start)
        count += 1
assert count == sum(len(entry['characterSpans']) for entry in manifest['files'].values())
print('DMX-MCP-SOURCE', count, 'retained source spans verified against', revision)
