"""Independent check of docs/fedwiki-local-only/evidence/tested-source.json against a tree (argv[1]):
recompute every source and log SHA-256, and list changed files the manifest does not cover (argv[2] = base commit, argv[3] = repo for git diff)."""
import hashlib, json, pathlib, subprocess, sys
tree = pathlib.Path(sys.argv[1]); base, repo, head = sys.argv[2], sys.argv[3], sys.argv[4]
record = json.loads((tree / 'docs/fedwiki-local-only/evidence/tested-source.json').read_text())
bad = [p for p, h in record['source_sha256'].items() if hashlib.sha256((tree / p).read_bytes()).hexdigest() != h]
print('MANIFEST source entries', len(record['source_sha256']), 'mismatches', bad)
for run in record['runs']:
    log = tree / 'docs/fedwiki-local-only/evidence' / (run['name'] + '.log')
    ok = hashlib.sha256(log.read_bytes()).hexdigest() == run['log_sha256']
    print('MANIFEST run', run['name'], run['commit'], 'log-digest', 'ok' if ok else 'MISMATCH', 'exit', run['exit_code'],
          'marker', run['marker'] in log.read_text(), 'feature_delta_applies', run.get('feature_delta_applies'))
changed = subprocess.run(['git', '-C', repo, 'diff', '--name-only', base, head], capture_output=True, text=True, check=True).stdout.split()
print('MANIFEST changed files outside the manifest and outside docs/:', [p for p in changed if p not in record['source_sha256'] and not p.startswith('docs/')])
