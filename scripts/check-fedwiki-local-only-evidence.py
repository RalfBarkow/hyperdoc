"""Verify that this checkout contains the exact tested source delta and test logs."""
from pathlib import Path
import hashlib
import json
import subprocess

root = Path(__file__).resolve().parents[1]
evidence = root / 'docs/fedwiki-local-only/evidence'
record = json.loads((evidence / 'tested-source.json').read_text())
subprocess.run(['git', '-C', str(root), 'merge-base', '--is-ancestor', record['base_commit'], 'HEAD'], check=True)
for relative, expected in record['source_sha256'].items():
    assert hashlib.sha256((root / relative).read_bytes()).hexdigest() == expected, relative
for run in record['runs']:
    path = evidence / (run['name'] + '.log')
    assert hashlib.sha256(path.read_bytes()).hexdigest() == run['log_sha256'], str(path)
    assert run['exit_code'] == 0 and run['marker'] in path.read_text(), run['name']
print('LOCAL-ONLY-EVIDENCE-MATCH: tested source delta and logs match the manifest.')
