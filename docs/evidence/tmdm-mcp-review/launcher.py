from pathlib import Path
import os, subprocess
root=Path('/workspace/tools/nix-portable-data/.nix-portable/nix/store')
artifacts=Path('/workspace/scratch/tmdm-mcp-review')
wrapper=(root/'s7wb16wpmlr4b4grrg8s6rz0m7ai6zna-sbcl-with-packages/bin/sbcl').read_bytes().split(b'\0')
registry=wrapper[wrapper.index(b'CL_SOURCE_REGISTRY')-1].decode()
extra=Path('/workspace/scratch/codex-evidence-resume/source-registry.txt').read_text().replace('/nix/store/kna6395gl32f2hl4n3ha4776zm9r0sgb-source', '/workspace/scratch/codex-evidence-verification/topic-maps-88994c1b')
def physical(text):return text.replace('/nix/store/',str(root)+'/')
env=dict(os.environ)
env['CL_SOURCE_REGISTRY']=physical(extra.rstrip(':')+':'+registry.rstrip(':')+':')
env['ASDF_OUTPUT_TRANSLATIONS']='(:output-translations (t "/workspace/scratch/codex-evidence-verification/fasl/") :ignore-inherited-configuration)'
libs=[root/'5m9amsvvh2z8sl7jrnc87hzy21glw6k1-glibc-2.40-66/lib', root/'h2qap7znf2iflyr7g567lnnzsnh0p4x8-zstd-1.5.6/lib', root/'qzn96phpnb6c56mlqa1424hfgf5hp67s-openssl-3.3.3/lib', root/'v9smapvfv1z340qs3p7xbw6zb6zplfcf-sqlite-3.46.1/lib', root/'b6mjyiadysqlh7nps52faznnqmp32604-zlib-1.3.1/lib']
library_path=':'.join(str(p) for p in libs)
env.pop('LD_LIBRARY_PATH',None)
sb=root/'7m20fryjy300sakr6s93g2ikgqiqb44q-sbcl-2.4.10'
cmd=[str(libs[0]/'ld-linux-x86-64.so.2'),'--library-path',library_path,str(sb/'bin/sbcl'),'--core',str(sb/'lib/sbcl/sbcl.core'),'--dynamic-space-size','3072','--noinform','--no-sysinit','--no-userinit','--non-interactive','--load','scripts/review-tmdm-mcp.lisp']
with (artifacts/'native.log').open('w') as out:
 result=subprocess.run(cmd,cwd='/workspace/hyperdoc',env=env,stdout=out,stderr=subprocess.STDOUT)
print('Focused runner exit:',result.returncode)
raise SystemExit(result.returncode)
