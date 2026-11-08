"""Check corrected assertions and actual syscall traces; retain the old review verbatim."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
BASE = '49ef9afd52539234290e38064847d4589a3be412'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def snapshot():
    old = json.loads((ROOT / 'docs/fedwiki-local-only/evidence/tested-source.json').read_text())
    paths = set(old['source_sha256']) | {
        'dreyeck/tests/fedwiki-local-only-inputs.lisp',
        'dreyeck/work/defederation-planning.lisp',
        'docs/defederation-consolidation/regressions.lisp',
        'docs/fedwiki-local-only/corrections/run.sh',
        'docs/fedwiki-local-only/corrections/check.py',
    }
    paths.update(str(p.relative_to(ROOT)) for p in (ROOT / 'docs/fedwiki-local-only/review').rglob('*') if p.is_file())
    return {'base_commit': BASE, 'source_sha256': {p: digest(ROOT / p) for p in sorted(paths)}}

def check_results(out):
    recorded = json.loads((out / 'source-before.json').read_text())
    assert snapshot() == recorded == json.loads((out / 'source-after.json').read_text()), 'source changed'
    assert not subprocess.check_output(['git', '-C', str(ROOT), 'diff', BASE, '--', 'docs/fedwiki-local-only/review']), 'historical review changed'
    integration = (out / 'integration.log').read_text()
    for marker in ['LOCAL-ONLY-INTEGRATION-PASS', 'INPUT-REGRESSIONS-PASS 48',
                   '0 socket attempts, 0 plugin/context attempts', 'INSPECTOR-EQ PASS',
                   'positive verified snapshot / fork once / continuation',
                   'local read failure UNKNOWN / unexpected error propagates']:
        assert marker in integration, marker
    lines = (out / 'probes.log').read_text().splitlines()
    def line(prefix):
        matches = [s for s in lines if s.startswith(prefix)]
        assert len(matches) == 1, (prefix, matches)
        return matches[0]
    for id_ in ([f'1{x}' for x in 'abcd'] + [f'2{x}' for x in 'abcde'] +
                [f'3{x}' for x in 'abcdefghijklmno'] + ['4a', '4b']):
        assert ':CONDITION I:INVALID-OBSERVATION' in line(f'P {id_} '), id_
    # P1e reads the intentionally corrected remote fixture. Original own-500 is a Lisp regression.
    assert ':FINDING :UNKNOWN :LOCAL-ONLY NIL :FORK 0' in line('P 1e ')
    assert 'INPUT-PASS P1e Invalid observation: OWN-SITE-AVAILABILITY' in integration
    for prefix, text in [
        ('C 0 ', ': (1 1)'), ('C 1a ', 'INVALID-CONTINUATION'),
        ('C 1b ', 'INVALID-CONTINUATION'), ('C 2 ', 'INVALID-CONTINUATION'),
        ('C 3b ', 'INVALID-CONTINUATION'), ('C 3c ', ':OK ((D::!PREPARE-LOCAL-LINKS'),
        ('C 5c ', 'INVALID-CONTINUATION'), ('C 6 ', '(1 1 (:OK ((D::!PREPARE-LOCAL-LINKS'),
        ('C 6b ', ':OK ((D::!PREPARE-LOCAL-LINKS'),
        ('C 7 ', '(0 (:CONDITION I:INVALID-CONTINUATION'),
        ('C 9 ', '(:CONFIRMED-LOCAL-ABSENCE NIL NIL ((R::MODELED-LOCAL-PAGE'),
        ('I 2 ', '(T T T T T T T T T)'), ('N 1 LOCAL:', ':FINDING :OBSERVED-LOCAL'),
        ('N 1 BROKEN:', ':FINDING :UNKNOWN')]:
        assert text in line(prefix), prefix
    alternatives = line('C 5a ')
    assert alternatives.count('D::!SIMULATE-FORK') == 2
    assert '"remote-item"' in alternatives and '"remote-new"' in alternatives
    for index in (0, 1):
        continued = line(f'C 5b index {index}:')
        assert 'R::!USE-MODELED-PAGE' in continued and '!SIMULATE-FORK' not in continued
    assert line('G 1 ').endswith('(("fw::load-page" 16))'), 'unexpected guarded calls'
    assert 'PROBES35-DONE' in lines
    net = re.compile(r'^\d+\s+(socket|socketpair|connect|bind|listen|accept4?|sendto|sendmsg|sendmmsg|recvfrom|recvmsg|recvmmsg|getsockname|getpeername|setsockopt|getsockopt|shutdown)\(')
    for name in ('integration', 'probes'):
        before, after, marker = 0, 0, False
        for entry in (out / (name + '.strace')).read_text().splitlines():
            if 'mkdir(' in entry and 'STRACE-MARKER-BEFORE-CONTROL' in entry:
                marker = True
            elif net.match(entry):
                if marker: after += 1
                else: before += 1
        assert before == 0, (name, before)
        if name == 'probes': assert marker and after > 0, 'missing actual socket positive control'
        print(f'CHECK-PASS {name}: {before} network syscalls before control; {after} after control')
    regressions = (out / 'regressions.log').read_text()
    assert regressions.count('BASELINE TEST-PASS') == 6
    assert 'BASELINE EMPTY-WITH-TREE REPRODUCED' in regressions
    assert 'SUITE-PASS dreyeck/wiki-link/tests' in (out / 'wiki-link.log').read_text()
    reading = (out / 'reading.log').read_text()
    if 'SUITE-ERROR' in reading:
        assert ':STATUS :UNAVAILABLE' in reading and ':PROGRAM "d2"' in reading
        print('CHECK-LIMIT reading suite: unavailable D2/TALA (same as historical review; NOT PASS)')
    else:
        assert 'SUITE-PASS dreyeck/work/reading/tests' in reading
    print('CHECK-PASS F1–F3, 48 invalid inputs, positive snapshot, original probes, continuation, alternatives, Inspector EQ, six planning/local-page suites, wiki-link suite')
    print('CHECK-PASS tested source digests match; historical review unchanged')

if __name__ == '__main__':
    mode, target = sys.argv[1:]
    if mode == 'snapshot': Path(target).write_text(json.dumps(snapshot(), indent=2) + '\n')
    elif mode == 'results': check_results(Path(target))
    else: raise ValueError(mode)
