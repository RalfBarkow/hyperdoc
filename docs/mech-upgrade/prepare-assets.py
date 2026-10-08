#!/usr/bin/env python3
"""Mirror the observed Wiki flake's source-copy-and-stamp step locally.
Usage: prepare-assets.py MECH_REPOSITORY FULL_OID NEW_OUTPUT_DIRECTORY
Reads Git objects without checking out or changing a repository. No fetch/build/deploy.
"""
import datetime
import hashlib
import json
import pathlib
import subprocess
import sys
repo, revision, output = sys.argv[1:]
oid = subprocess.check_output(['git', '-C', repo, 'rev-parse', revision + '^{commit}'], text=True).strip()
if oid != revision:
    raise SystemExit('Supply the full, exact commit OID.')
root = pathlib.Path(output)
root.mkdir(parents=True, exist_ok=False)
package = json.loads(subprocess.check_output(['git', '-C', repo, 'show', oid + ':package.json']))
paths = subprocess.check_output(['git', '-C', repo, 'ls-tree', '-r', '--name-only', oid, 'src/client'], text=True).splitlines()
records = []
for source in paths:
    rel = pathlib.Path(source).relative_to('src/client')
    body = subprocess.check_output(['git', '-C', repo, 'show', oid + ':' + source])
    dest = root / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(body)
    records.append({'source': source, 'name': str(rel), 'sourceSha256': hashlib.sha256(body).hexdigest()})
stamp = {'MECH_VERSION': package['version'],
         'MECH_BUILD_TIME': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
         'MECH_GIT_COMMIT': oid}
header = 'globalThis.__MECH_BUILD__ = { ' + ', '.join(key + ': ' + json.dumps(value) for key, value in stamp.items()) + ' };\n'
p = root / 'mech.js'
p.write_bytes(header.encode() + p.read_bytes())
for record in records:
    record['sha256'] = hashlib.sha256((root / record['name']).read_bytes()).hexdigest()
manifest = {'kind': 'local mirror of observed Wiki source-copy-and-stamp assembly; not deployed',
            'source': {'authority': 'https://github.com/RalfBarkow/wiki-plugin-mech', 'oid': oid,
                       'role': 'unpublished local candidate'},
            'stamp': stamp, 'assets': records}
(root / 'assets.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(json.dumps(manifest, indent=2))
