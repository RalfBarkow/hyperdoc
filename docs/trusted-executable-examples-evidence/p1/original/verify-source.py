import hashlib,json
from pathlib import Path
root=Path(__file__).resolve().parent
entries=json.loads((root/'source-tree.json').read_text())
rows=[]
for e in entries:
    if e['type']!='blob': continue
    data=(root/'source'/e['path']).read_bytes()
    actual=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
    rows.append({'path':e['path'],'expected_git_blob':e['sha'],'actual_git_blob':actual,'match':actual==e['sha']})
report={'code_revision':'9b57bd4bb87d92fbf3061b91a42a6f539e18cdb1','tree_sha':'1c2a981db7cf7700f39325cc3aad26440555370e','blobs_checked':len(rows),'mismatches':sum(not r['match'] for r in rows),'blobs':rows}
(root/'source-verification.json').write_text(json.dumps(report,indent=2)+'\n')
print({k:v for k,v in report.items() if k!='blobs'})
assert report['mismatches']==0
