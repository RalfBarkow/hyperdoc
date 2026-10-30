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
adapted_count = 0
repairs = manifest.get('localRepairs', {})
for path, repair in repairs.items():
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == repair['fileSHA256'], path
    for original_path, start, end in repair['adaptedSpans']:
        assert [start, end] in manifest['files'][original_path]['characterSpans']
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
        repair = repairs.get(str(path.relative_to(root)), {})
        if [original_path, start, end] in repair.get('adaptedSpans', []):
            # The complete replacement file, including new loader definitions,
            # was checked against the explicit local repair hash above.
            adapted_count += 1
        else:
            assert text[match.end():].startswith(expected + '\n'), (path, original_path, start)
        count += 1
assert count == sum(len(entry['characterSpans']) for entry in manifest['files'].values())
assert adapted_count == sum(len(r['adaptedSpans']) for r in repairs.values())
print('DMX-MCP-SOURCE', count - adapted_count, 'retained spans verified against', revision,
      'and', adapted_count, 'adapted spans verified by local repair file hashes')
