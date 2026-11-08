"""Check every expected finding of the PR #35 review against the outputs of one run-review.sh run (argv[1] = OUT_DIR).
Prints EXPECT-PASS / EXPECT-FAIL per item and exits 1 if any item fails. Expected failures of the tested code (F1-F7) and the
environment-dependent failure of dreyeck/work/reading/tests are checked as such; neither is counted as a passing test of PR #35."""
import pathlib, re, sys

out = pathlib.Path(sys.argv[1])
failures = 0


def text(name):
    path = out / name
    return path.read_text(errors='replace') if path.exists() else ''


def line(name, prefix):
    for l in text(name).splitlines():
        if l.startswith(prefix):
            return l
    return None


def expect(label, ok, detail=''):
    global failures
    print(('EXPECT-PASS ' if ok else 'EXPECT-FAIL ') + label + (('  [' + detail + ']') if (detail and not ok) else ''))
    failures += 0 if ok else 1


def has(name, prefix, *needles, absent=()):
    l = line(name, prefix)
    ok = l is not None and all(n in l for n in needles) and not any(a in l for a in absent)
    expect(f'{name}: {prefix.strip()} contains {needles}' + (f' and none of {absent}' if absent else ''), ok, l or 'line missing')


def segment(name, label):
    m = re.search(r'STRACE-SEGMENT ' + re.escape(label) + r' network-syscalls (\d+)', text(name))
    return int(m.group(1)) if m else None


summary = text('summary.log')
# --- runs and the PR #34 / PR #35 comparison ---
for step in ['own-suite35', 'regressions-pr34', 'regressions-pr35', 'wiki-link-tests-pr34', 'wiki-link-tests-pr35',
             'shared-diff-pr34', 'shared-diff-pr35', 'probes35', 'ext-views35', 'titlebar35']:
    expect(f'step {step} exit=0 and its end marker present', f'STEP {step} exit=0 marker=present' in summary)
expect('reading-tests ran to a SUITE-PASS/ERROR line on both commits',
       'STEP reading-tests-pr34 exit=0 marker=present' in summary and 'STEP reading-tests-pr35 exit=0 marker=present' in summary)
for a, b in [('regressions-pr34', 'regressions-pr35'), ('wiki-link-tests-pr34', 'wiki-link-tests-pr35'), ('reading-tests-pr34', 'reading-tests-pr35')]:
    expect(f'{a} = {b} after removing only the BASELINE-ROOT line',
           f'COMPARE {a} = {b} (identical after removing only the BASELINE-ROOT line)' in summary
           and (out / f'compare-{a}-{b}.diff').exists() and (out / f'compare-{a}-{b}.diff').stat().st_size == 0)
for t in ['pr34', 'pr35']:
    log = text(f'regressions-{t}.log')
    expect(f'regressions-{t}: six TEST-PASS lines and the empty-tree defect reproduced',
           log.count('BASELINE TEST-PASS ') == 6 and 'BASELINE EMPTY-WITH-TREE REPRODUCED' in log)
    expect(f'wiki-link-tests-{t}: SUITE-PASS', 'SUITE-PASS dreyeck/wiki-link/tests' in text(f'wiki-link-tests-{t}.log'))
    r = text(f'reading-tests-{t}.log')
    expect(f'reading-tests-{t}: SUITE-ERROR at authored-d2 with :STATUS :UNAVAILABLE (environment limit, NOT a passing test)',
           'SUITE-ERROR dreyeck/work/reading/tests' in r and 'AUTHORED-D2' in r and ':STATUS :UNAVAILABLE' in r and 'SUITE-PASS' not in r)
diff = [l for l in text('shared-diff.diff').splitlines() if l[:1] in '<>']
expect('shared-diff: exactly two differing lines, both the set-page-data lambda list',
       len(diff) == 2 and all('set-page-data lambda-list' in l for l in diff), ' | '.join(diff))
expect('shared-diff-pr35: no socket attempt beyond the plugin resolver probe', line('shared-diff-pr35.log', 'SD socket attempts') == 'SD socket attempts: ("origin")')

# --- system calls: zero in the local-only paths, visible for the deliberate control connection ---
expect('own-suite35: 0 network system calls', segment('own-suite35.strace-summary.log', 'start') == 0)
expect('probes35: 0 network system calls before the control marker', segment('probes35.strace-summary.log', 'start') == 0)
n = segment('probes35.strace-summary.log', 'after STRACE-MARKER-BEFORE-CONTROL')
expect('probes35: control connection after the marker is visible', bool(n) and 'connect(' in text('probes35.strace-network.log')
       and '127.0.0.1' in text('probes35.strace-network.log'), str(n))
expect('ext-views35: 0 network system calls while loading', segment('ext-views35.strace-summary.log', 'start') == 0)
expect('ext-views35: 0 network system calls between the markers', segment('ext-views35.strace-summary.log', 'after EXT-MARKER-A-AFTER-LOAD') == 0)
expect('ext-views35: control connection after marker B is visible', bool(segment('ext-views35.strace-summary.log', 'after EXT-MARKER-B-BEFORE-CONTROL')))

P = 'probes35.log'
expect('probes35 ran to the end', 'PROBES35-DONE' in text(P))
# --- network paths (N, G) ---
has(P, 'N 1 LOCAL:', ':FINDING :OBSERVED-LOCAL', '(I::OWN-PAGE I::OWN-PAGE I::OWN-PAGE)')
has(P, 'N 1 MISSING:', ':FINDING :CONFIRMED-LOCAL-ABSENCE', 'WIKI-LOOKUP-FAILURE')
has(P, 'N 1 REMOTE:', ':FINDING :CONFIRMED-LOCAL-ABSENCE', 'WIKI-LOOKUP-FAILURE')
has(P, 'N 1 BROKEN:', ':FINDING :UNKNOWN', 'SHASHT-INVALID-CHAR')
has(P, 'N 2 ', '(:CONFIRMED-LOCAL-ABSENCE :CONFIRMED-LOCAL-ABSENCE :CONFIRMED-LOCAL-ABSENCE)')
has(P, 'N 3 source2 context', '(NIL (:PARAGRAPH :REFERENCE :IMAGE))')
has(P, 'N 3 thunk target:', 'I::OWN-PAGE')
has(P, 'N 4 ', '(:OK :LOADED)')
has(P, 'G 0 ', 'registered in this image: 0')
has(P, 'G 1 ', 'fw::load-page', absent=('socket', 'host', 'drakma', 'fetch', 'fedwiki"', 'plugin', 'run-program', 'make-thread', 'extract-context'))
# --- F1: external evidence decides own-site presence ---
has(P, 'P 1a ', ':FINDING :UNKNOWN', ':LOCAL-ONLY ((R::!REQUEST R::!OPEN-PANEL))', ':FORK 0')
has(P, 'P 1b ', ':FINDING :CONFIRMED-LOCAL-ABSENCE', ':LOCAL-ONLY NIL')
has(P, 'P 1c ', ':FINDING :UNKNOWN', ':LOCAL-ONLY ((R::!REQUEST R::!CONCLUDE-UNRESOLVED))')
has(P, 'P 1d ', ':FINDING :OBSERVED-LOCAL', ':LOCAL-ONLY NIL')
has(P, 'P 1e ', ':FINDING :UNKNOWN', ':LOCAL-ONLY ((R::!REQUEST R::!CONCLUDE-UNRESOLVED))', ':FORK 0')
# --- F2: snapshot copy bound to bytes only ---
for k in ['2a', '2b', '2c']:
    has(P, f'P {k} ', ':OK', ':FORK 1')
for k in ['2d', '2e']:
    has(P, f'P {k} ', 'SNAPSHOT-COPY-NOT-VERIFIED')
# --- F3: malformed input ---
for k, needle in [('3a', 'TYPE-ERROR'), ('3b', 'TYPE-ERROR'), ('3e', 'BOUNDING-INDICES-BAD-ERROR'), ('3m', 'SHASHT-INVALID-CHAR'),
                  ('3f', '(D::FORK-PERMITTED :NULL :NULL)'), ('4a', 'INDEX-TOO-LARGE-ERROR'), ('4b', 'INDEX-TOO-LARGE-ERROR')]:
    has(P, f'P {k} ', needle)
for k, needle in [('3c', 'UNAPPROVED-PREDICATE'), ('3d', 'UNAPPROVED-PREDICATE'), ('3g', 'UNAPPROVED-FACT'), ('3h', 'UNAPPROVED-FACT'),
                  ('3i', 'UNAPPROVED-FACT'), ('3n', 'UNAPPROVED-FACT'), ('3j', 'LOCAL-OBSERVATIONS-MUST-COME-FROM-STORE'),
                  ('3k', 'UNAPPROVED-PREDICATE MODELED-FORK'), ('3l', 'UNKNOWN-POLICY')]:
    has(P, f'P {k} ', 'INVALID-OBSERVATION', needle)
has(P, 'P 4c ', '(:OK :CONFIRMED-LOCAL-ABSENCE)')
# --- sealing (confirmed) and F7 (not sealed) ---
for k in ['5a', '5b', '5c', '5d', '5e', '5h']:
    has(P, f'P {k} ', 'INVALID-CONTINUATION')
for k in ['5f', '5g']:
    has(P, f'P {k} ', ':OK ((D::!SIMULATE-FORK')
# --- continuation ---
has(P, 'C 0 ', ': (1 1)')
for k in ['C 1a ', 'C 1b ', 'C 2 ', 'C 3b ', 'C 5c ']:
    has(P, k, 'INVALID-CONTINUATION')
has(P, 'C 3c ', ':OK ((D::!PREPARE-LOCAL-LINKS')
for index in ['-1', '1', '1.0', '"0"', 'NIL']:
    has(P, f'C 4 index {index}:', 'INVALID-CONTINUATION')
has(P, 'C 4 index 0:', ':OK ((D::!PREPARE-LOCAL-LINKS')
has(P, 'C 5a ', '"remote-new"', '"remote-item"')
has(P, 'C 5b index 0', 'R::!USE-MODELED-PAGE')
has(P, 'C 5b index 1', 'R::!USE-MODELED-PAGE')
has(P, 'C 6 ', '(1 1 (:OK ((D::!PREPARE-LOCAL-LINKS')
has(P, 'C 6b ', ':OK ((D::!PREPARE-LOCAL-LINKS')
has(P, 'C 7 ', '(0 (:CONDITION I:INVALID-CONTINUATION', 'I:INVALID-CONTINUATION')
has(P, 'C 8 ', '((R::!REQUEST R::!OPEN-PANEL))')
has(P, 'C 9 ', '(:CONFIRMED-LOCAL-ABSENCE NIL NIL ((R::MODELED-LOCAL-PAGE "fedwiki:local" "missing")) ((R::!USE-MODELED-PAGE)))')
has(P, 'C 10 ', ': 6')
# --- inspector (F5, F6) ---
has(P, 'I 2 ', '(T T T T T T T T T)')
has(P, 'I 3 ', '?: NIL')
has(P, 'I 4 ', '(NIL NIL NIL)')
has(P, 'I 5 ', '?: NIL')
has(P, 'I 6 ', '("" :BUTTON)')
has(P, 'STRACE-MARKER control connect', ':CONDITION')
has('titlebar35.log', 'TB own-site buttons', ':BUTTON T')
has('titlebar35.log', 'TB own-site open-external target', 'https://local/')
has('titlebar35.log', 'TB story html of own-page', 'Local read-only source', absent=('<img', 'href='))
E = 'ext-views35.log'
expect('ext-views35: all six systems loaded', text(E).count(': :LOADED') == 6)
has(E, 'EXT thunks:', '(I::OWN-PAGE FW::WIKI-LOOKUP-FAILURE)')
bad = [l for l in text(E).splitlines() if l.startswith('EXT ') and ':CONDITION' in re.sub(r'\("<span style=\\"color: #666;\\">Playground</span>" \(:CONDITION SB-PCL::NO-APPLICABLE-METHOD-ERROR\)\)', '', l)]
expect('ext-views35: every view renders, except the generic Playground view outside CLOG', not bad, ' | '.join(b[:80] for b in bad))
# --- manifest ---
M = text('manifest.log')
expect('manifest: all 18 source digests match', 'MANIFEST source entries 18 mismatches []' in M)
expect('manifest: all 5 log digests match', M.count('log-digest ok') == 5)
expect('manifest: the only changed file outside it and outside docs/ is its own check script',
       "outside docs/: ['scripts/check-fedwiki-local-only-evidence.py']" in M)
print(f'EXPECTATIONS {"PASS" if failures == 0 else "FAIL"}: {failures} failing item(s)')
sys.exit(1 if failures else 0)
