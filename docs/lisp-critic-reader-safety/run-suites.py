import subprocess,os,pathlib,json,hashlib
out=pathlib.Path(__file__).resolve().parent; records=[]
worktree=os.environ.get('A1_WORKTREE',str(out.parents[1])); prefix=os.environ.get('A1_LOG_PREFIX','')
systems=['dreyeck/lisp-critic/text-criticism/integration-tests','dreyeck/lisp-critic/tests','dreyeck/lisp-critic/federated-context/tests','dreyeck/lisp-critic/reading/tests','dreyeck/lisp-critic/recorded/tests','dreyeck/lisp-critic/critique/tests','dreyeck/lisp-critic/engine-integration/tests','dreyeck/lisp-critic/page-station/tests','dreyeck/catalog/tests']
systems=os.environ.get('A1_SYSTEMS',' '.join(systems)).split()
launcher=os.environ.get('A1_SBCL','/workspace/scratch/tmdm-mcp-portable/bin/sbcl')
for system in systems:
 name=prefix+system.replace('/','-'); path=out/(name+'.log')
 cmd=[launcher,'--noinform','--no-sysinit','--no-userinit','--non-interactive','--load',str(out/'bootstrap.lisp'),'--eval',f'(asdf:test-system "{system}")']
 with path.open('w') as log:
  result=subprocess.run(cmd,env=dict(os.environ,DEFEDERATION_REPO=worktree),cwd=worktree,stdout=log,stderr=subprocess.STDOUT)
 status='PASS' if result.returncode==0 else 'FAIL' # No automatic blocker inference from log text.
 record=dict(worktree=worktree,revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=worktree,text=True).strip(),system=system,command=cmd,exitCode=result.returncode,status=status,log=path.name,sha256=hashlib.sha256(path.read_bytes()).hexdigest());records.append(record)
 print(system,status,result.returncode,flush=True)
 (out/(prefix+'suites.json')).write_text(json.dumps(records,indent=2)+'\n')
