"""Compile pinned Java with TWO disclosed transport-factory substitutions, no sockets.
Requires FEDWIKI_JAVA_ROOT (Git object store at the pinned revision), Java 11+ compiler module.
"""
from pathlib import Path
import os,sys,json,subprocess,tempfile,re,hashlib,difflib
project=Path(__file__).resolve().parents[1]
if not os.environ.get('FEDWIKI_JAVA_ROOT'):
 raise SystemExit('Set FEDWIKI_JAVA_ROOT to a checkout containing the pinned fedwiki-java Git objects.')
reference=Path(os.environ['FEDWIKI_JAVA_ROOT']).resolve()
revision='b58fb43e7ffbbbda66685363dcda1facbd2a46a1'
def blob(path):return subprocess.check_output(['git','-C',str(reference),'show',revision+':'+path])
source=blob('Main.java').decode()
adapted,count=re.subn(r'HttpClient\s*\.newBuilder\(\)\s*\.build\(\)', 'OfflineReferenceProbe.client()',source)
assert count==2
assert 'HttpClient\n        .newBuilder' not in adapted
cases=json.loads((project/'dreyeck/tests/fixtures/link-resolution/cases.json').read_text())['cases']
results=[]
with tempfile.TemporaryDirectory(prefix='fedwiki-java-offline-') as temporary:
 root=Path(temporary);(root/'Main.java').write_text(adapted)
 jars=['jackson-core-2.14.2.jar','jackson-annotations-2.14.2.jar','jackson-databind-2.14.2.jar']
 for jar in jars:(root/jar).write_bytes(blob(jar))
 cp=os.pathsep.join(str(root/jar) for jar in jars)
 subprocess.run(['java','-m','jdk.compiler/com.sun.tools.javac.Main','-cp',cp,'-d',str(root),str(root/'Main.java'),str(project/'scripts/link-resolution/OfflineReferenceProbe.java')],check=True)
 for case in cases:
  if case.get('java') is False:continue
  run=subprocess.run(['java','-cp',str(root)+os.pathsep+cp,'OfflineReferenceProbe',str(project/'dreyeck/tests/fixtures/link-resolution/cases.json'),case['id']],capture_output=True,text=True,timeout=20)
  evidence=[line[9:] for line in run.stdout.splitlines() if line.startswith('EVIDENCE ')]
  assert len(evidence)==1,(case['id'],run.stdout,run.stderr)
  observed=json.loads(evidence[0]); expected=case['expectedSite'];repeat=case.get('repeat',1)
  assert run.returncode==(0 if expected else 1),(case['id'],run.returncode,run.stderr)
  assert observed.get('site')==expected,observed
  if expected is None:
   reason='http error: fixture network failure' if case['id']=='network-aborts' else "can't find page in current context"
   assert reason in run.stdout and 'AssertionError' not in run.stderr,(case['id'],run.stdout,run.stderr)
   observed['failureReason']=reason
  assert observed.get('linkTrace',observed['trace'])==case['expectedTrace']*repeat,observed
  assert observed['lineupSize']==(1+repeat if expected else 1),observed
  assert observed['links']==['target'],observed
  if expected:
   assert observed['itemno']==0 and not observed['explicitLoadEnlarges'],observed
   assert observed['englishSlug']==['i-'] and observed['turkishSlug']==['ı-'],observed
   assert observed['sourceItemno']==case.get('sourceItemno',0),observed
  if 'expectedNeighborhood' in case:
   assert observed['neighborhood']==case['expectedNeighborhood'],observed
   assert observed['sitemaps']==['a','b','c'],observed
  if case.get('sitemapStatus')==404:assert observed['nullSitemaps']==3,observed
  observed['exit']=run.returncode;results.append(observed)
  print('JAVA-REFERENCE-PASS',case['id'],json.dumps(observed,ensure_ascii=False))
passages=[]
for name,start,end in [('Page.context',289,295),('Panel.context',266,273),('Panel.load(from,slug)',225,255),('Panel.load(site,slug)',216,223),('Item.links',307,319),('Main.enlarge',193,199),('Main.fetch',143,165),('Main.fetchSiteMap',167,191),('Main.link',104,111)]:
 text=''.join(source.splitlines(True)[start-1:end])
 passages.append(dict(symbol=name,file='Main.java',startLine=start,endLine=end,text=text,sha256=hashlib.sha256(text.encode()).hexdigest(),url=f'https://github.com/RalfBarkow/fedwiki-java/blob/{revision}/Main.java#L{start}-L{end}'))
artifact={'repository':'RalfBarkow/fedwiki-java','commit':revision,'mainSha256':hashlib.sha256(source.encode()).hexdigest(),'transportSubstitutions':count,'sourcePassages':passages,'cases':results}
if len(sys.argv)>1:
 Path(sys.argv[1]).write_text(json.dumps(artifact,indent=2,ensure_ascii=False)+'\n')
 Path(sys.argv[1]).with_name('java-transport.patch').write_text(''.join(difflib.unified_diff(source.splitlines(True),adapted.splitlines(True),fromfile='pinned/Main.java',tofile='offline-test/Main.java')))
 print('EVIDENCE-WRITTEN',sys.argv[1])
print('JAVA-REFERENCE-ALL-PASS: actual resolver methods; network-free deterministic transport; no public Wiki run')
