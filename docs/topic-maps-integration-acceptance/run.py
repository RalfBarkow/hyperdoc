#!/usr/bin/env python3
"""Acceptance evidence only: run an explicit command and record its real exit status and log."""
import argparse, datetime, hashlib, json, os, pathlib, subprocess, sys

p = argparse.ArgumentParser()
p.add_argument('label')
p.add_argument('--cwd', required=True)
p.add_argument('--env', action='append', default=[])
p.add_argument('command', nargs=argparse.REMAINDER)
a = p.parse_args()
command = a.command[1:] if a.command[:1] == ['--'] else a.command
if not command:
    p.error('An explicit command is required')
out = pathlib.Path(__file__).resolve().parent
environment = dict(os.environ)
selected = dict(item.split('=', 1) for item in a.env)
environment.update(selected)
record = {'command': command, 'cwd': a.cwd, 'environmentOverrides': selected,
          'startedAtUTC': datetime.datetime.now(datetime.timezone.utc).isoformat()}
with (out / (a.label + '.log')).open('wb') as log:
    result = subprocess.run(command, cwd=a.cwd, env=environment, stdout=log, stderr=subprocess.STDOUT)
record.update(exitCode=result.returncode, finishedAtUTC=datetime.datetime.now(datetime.timezone.utc).isoformat(),
              log=a.label + '.log', logSHA256=hashlib.sha256((out / (a.label + '.log')).read_bytes()).hexdigest())
(out / (a.label + '.json')).write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps({'label': a.label, 'exitCode': result.returncode, 'log': record['log']}))
sys.exit(result.returncode)
