import os,json,subprocess,sys
from pathlib import Path
root=Path('/tmp/hyperdoc-p1')
env=dict(os.environ)
env.update(json.loads((root/'local-environment.json').read_text()))
env.pop('LD_LIBRARY_PATH',None)
paths=[p for p in env['CL_SOURCE_REGISTRY'].split(':') if p and p.rstrip('/')!='/workspace/hyperdoc']
env['CL_SOURCE_REGISTRY']=str(root/'source')+'//:'+':'.join(paths)+':'
env['ASDF_OUTPUT_TRANSLATIONS']='(:output-translations (t "/tmp/hyperdoc-p1/fasl/") :ignore-inherited-configuration)'
raise SystemExit(subprocess.run(['sbcl','--no-sysinit','--no-userinit','--non-interactive','--load',str(root/'probe.lisp')],env=env,cwd=root).returncode)
