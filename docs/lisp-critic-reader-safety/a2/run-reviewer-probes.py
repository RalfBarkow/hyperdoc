"""Replay the owner-supplied exact review inputs in fresh, isolated SBCL processes."""
import hashlib
import json
import os
import pathlib
import subprocess
import tempfile

out = pathlib.Path(__file__).resolve().parent
repo = out.parents[2]
base = 'c0b5f8328805ebfaa929f4ff4c2e51052dd39511'
source = 'dreyeck/src/lisp-critic-text-passage.lisp'
records = []
with tempfile.TemporaryDirectory(prefix='a2-verbatim-') as temporary:
    original = pathlib.Path(temporary) / 'original-passage.lisp'
    original.write_bytes(subprocess.check_output(['git', 'show', base + ':' + source], cwd=repo))
    for mode in ['baseline', 'corrected', 'integration']:
        env = dict(os.environ, DEFEDERATION_REPO=str(repo))
        env.pop('A2_BASELINE_SOURCE', None)
        if mode == 'baseline':
            env['A2_BASELINE_SOURCE'] = str(original)
        command = [str(out.parent / 'portable-sbcl'), '--noinform', '--no-userinit', '--non-interactive']
        if mode == 'integration':
            command += ['--eval', '(asdf:test-system "dreyeck/lisp-critic/text-criticism/integration-tests")']
        else:
            command += ['--load', str(out / 'reviewer-probes.lisp')]
            if mode == 'corrected':
                command += ['--load', str(out / 'probes.lisp'), '--load', str(out.parent / 'probes.lisp'),
                            '--eval', '(asdf:test-system "dreyeck/lisp-critic/text-criticism")']
        log = out / ('verbatim-' + mode + '.log')
        with log.open('wb') as stream:
            result = subprocess.run(command, cwd=repo, env=env, stdout=stream, stderr=subprocess.STDOUT)
        records.append(dict(mode=mode, command=command, cwd=str(repo), exitCode=result.returncode,
                            environmentOverrides={key:env[key] for key in ['DEFEDERATION_REPO','A2_BASELINE_SOURCE'] if key in env},
                            baselineRevision=base, baselineSourceSHA256=hashlib.sha256(original.read_bytes()).hexdigest(),
                            implementationRevision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip(),
                            implementationSHA256=hashlib.sha256((repo/source).read_bytes()).hexdigest(),
                            log=log.name, sha256=hashlib.sha256(log.read_bytes()).hexdigest()))
        print(mode, result.returncode, flush=True)
(out / 'verbatim-results.json').write_text(json.dumps(records, indent=2) + '\n')
raise SystemExit(0 if all(r['exitCode'] == 0 for r in records) else 1)
