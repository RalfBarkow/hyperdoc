#!/usr/bin/env python3
"""Five file-backed journal regressions, using a new Lisp process for every step.

Run with the repository's Lisp dependencies available:
  python3 scripts/test-dmx-journal-restart.py --artifacts /absolute/disposable/path
A JSON argv prefix can wrap each SBCL invocation in an isolated container.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--artifacts', required=True, type=Path)
parser.add_argument('--sbcl', default='sbcl')
parser.add_argument('--prefix-json', default='[]')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
artifacts = args.artifacts.resolve()
artifacts.mkdir(parents=True, exist_ok=True)
fixture = root / 'tests/dmx-journal-restart.lisp'
results = []
processes = []

def run(mode, state, *extra):
    label = f'{len(processes)+1:02d}-{state.name}-{mode}'
    command = json.loads(args.prefix_json) + [args.sbcl, '--noinform', '--no-sysinit',
        '--no-userinit', '--disable-debugger', '--script', str(fixture), mode,
        str(state), *map(str, extra)]
    result = subprocess.run(command, cwd=root, capture_output=True, text=True, timeout=120)
    (artifacts / (label+'.log')).write_text(result.stdout+result.stderr)
    processes.append({'step': label, 'exit': result.returncode})
    assert result.returncode == 0, f'{label} failed: see {artifacts / (label+".log")}'
    assert f'JOURNAL-RESTART-PASS {mode}' in result.stdout, label

def state(name):
    path = artifacts/name
    path.mkdir()  # A run must never reuse data from an earlier run.
    return path

def journal(path):
    files = list(path.glob('workspace-journal-*.json'))
    assert len(files) == 1
    return files[0]

def preserved(path, before):
    assert path.read_bytes() == before, 'Journal file was modified'

s = state('restart')
run('seed', s)
f = journal(s)
original = f.read_bytes()
run('read', s, 2, 'B')
run('subject-read', s)
preserved(f, original)
results.append({'test': 'restart reads and revision replay', 'status': 'PASS'})

s = state('same-subject')
run('seed', s)
f = journal(s)
before = json.loads(f.read_text())
run('update', s)
after = json.loads(f.read_text())
assert after['currentRevision'] == 3
assert after['events'][:2] == before['events']
run('read', s, 3, 'C')
results.append({'test': 'same-subject write preserves prefix and appends revision 3', 'status': 'PASS'})

s = state('unchanged')
run('seed', s)
f = journal(s)
original = f.read_bytes()
stat = f.stat()
run('noop', s)
preserved(f, original)
assert f.stat().st_mtime_ns == stat.st_mtime_ns
assert f.stat().st_ino == stat.st_ino
run('read', s, 2, 'B')
results.append({'test': 'unchanged write preserves bytes, mtime, inode and revisions', 'status': 'PASS'})

s = state('multiple-subjects')
run('seed-two', s)
originals = {f.name: f.read_bytes() for f in s.glob('*.json')}
assert len(originals) == 2
run('multi-read', s)
assert originals == {f.name: f.read_bytes() for f in s.glob('*.json')}
results.append({'test': 'multiple subjects restored without duplication', 'status': 'PASS'})

# Every variant starts from actual output of the existing journal writer.
valid = json.loads(original)
variants = {
    'malformed': b'{broken',
    'trailing-data': original+b' garbage',
    'unsupported-schema': json.dumps(dict(valid, schemaVersion=999)).encode(),
    'subject-mismatch': json.dumps(dict(valid, subjectKey='urn:wrong-subject')).encode(),
    'revision-gap': json.dumps(dict(valid, currentRevision=27)).encode(),
    'unreadable': original,
}
for name, content in variants.items():
    s = state('invalid-'+name)
    f = s/journal(artifacts/'unchanged').name
    f.write_bytes(content)
    if name == 'unreadable':
        # Test process runs as the same unprivileged uid, never as root.
        assert os.getuid() != 0, 'Unreadability regression requires an unprivileged user'
        f.chmod(0)
    try:
        run('error-read', s)
        run('error-write', s)
        run('error-startup', s)
        assert set(p.name for p in s.iterdir()) == {f.name}
    finally:
        if name == 'unreadable':
            f.chmod(0o600)
    preserved(f, content)
results.append({'test': 'damaged/unreadable files raise explicit errors without replacement',
                'variants': list(variants), 'status': 'PASS'})
report = {'tests': results, 'processes': processes,
          'lisp_process_count': len(processes),
          'fixture_sha256': hashlib.sha256(fixture.read_bytes()).hexdigest()}
(artifacts/'results.json').write_text(json.dumps(report, indent=2)+'\n')
for result in results:
    print('PASS:', result['test'])
print(f'{len(results)} regression groups; {len(processes)} separate Lisp processes')
