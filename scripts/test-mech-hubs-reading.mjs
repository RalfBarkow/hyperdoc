// Exact retained Mech, trusted synthetic input, offline. No Wiki Story execution.
import fs from 'node:fs'
import assert from 'node:assert/strict'
import crypto from 'node:crypto'
import {fileURLToPath} from 'node:url'
import path from 'node:path'
import {sha} from '../tools/how-trails-definitions/extract.mjs' // verifies offline Acorn pin
import * as acorn from '../tools/how-trails-definitions/vendor/acorn-8.16.0/acorn.mjs'
import {walks} from '../assets/hyperbook/fedwiki/mech-host/plugins/mech/library.js'
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..')
const read=p=>fs.readFileSync(path.join(root,p))
const provenance=JSON.parse(read('assets/hyperbook/fedwiki/mech-host/provenance.json'))
for(const p of ['mech','blocks','interpreter','library']) {
 const record=provenance.assets.find(a=>a.path===`plugins/mech/${p}.js`)
 assert.equal(sha(read('assets/hyperbook/fedwiki/mech-host/'+record.path)),record.sha256)
}
const source=read('assets/hyperbook/fedwiki/mech-host/plugins/mech/library.js').toString('utf8')
const ast=acorn.parse(source,{ecmaVersion:2022,sourceType:'module',locations:true})
const functions=[]
function visit(node,scope=[]) {
 if(!node||typeof node!=='object')return
 if(node.type==='FunctionDeclaration') {
  const key=[...scope,node.id.name].join('/')
  if(['walks','walks/hubs','walks/blanket'].includes(key))functions.push({name:node.id.name,key,start:node.start,end:node.end,startLine:node.loc.start.line,endLine:node.loc.end.line,text:source.slice(node.start,node.end),sha256:sha(source.slice(node.start,node.end))})
  scope=[...scope,node.id.name]
 }
 for(const [k,v] of Object.entries(node))if(k!=='loc') {if(Array.isArray(v))v.forEach(x=>visit(x,scope));else if(v&&typeof v==='object')visit(v,scope)}
}
visit(ast)
assert.equal(functions.length,3)
const links=(n)=>Object.fromEntries(['hub',...Array.from({length:n-1},(_,i)=>'missing-'+i)].map(s=>[s,1]))
const page=(slug,title,domain,links={},date=0,patterns)=>({slug,title,domain,links,date,...(patterns?{patterns}:{})})
const neighborhood=[
 page('hub','Hub A','a.example', {child:1,'missing-target':1},100,{up:['pattern-parent'],down:['child']}),
 page('hub','Hub B','b.example',{},200,{up:[],down:[]}),
 page('child','Child','a.example'),page('pattern-parent','Pattern Parent','a.example'),
 page('small-1','Small One','a.example',{hub:1,'missing-target':1},30),
 page('small-2','Small Two','b.example',{hub:1},40),
 page('small-3','Small Three','a.example',{hub:1},50),
 page('fifteen','Exactly Fifteen','a.example',links(15),60),
 page('sixteen','Exactly Sixteen','b.example',links(16),70)
]
const failures=[],cases=[],oldLog=console.log,oldNow=Date.now
function run(label,input,count) {
 const logs=[]; console.log=(...items)=>logs.push(items)
 try {
  const aspects=walks(count,'hubs',structuredClone(input))
  const ranking=logs.flat().find(x=>x?.hits&&x?.hubs)
  const result=JSON.parse(JSON.stringify({label,neighborhood:input,ranking,aspects,logs}))
  cases.push(result);return result
 }finally {console.log=oldLog}
}
try {
 Date.now=()=>1791936000000
 const result=run('patterns and mixed site slugs',neighborhood,1)
 assert.deepEqual(result.ranking.hits,{child:1,hub:4})
 assert.deepEqual(result.ranking.hubs,[['hub',4]])
 assert(!('missing-target' in result.ranking.hits))
 assert.equal(Object.keys(neighborhood[7].links).length,15)
 assert.equal(Object.keys(neighborhood[8].links).length,16)
 assert.equal(result.aspects[0].name,'hub 4 hub')
 assert.deepEqual(result.aspects[0].graph.nodes.map(n=>n.props.title),['Hub A','Pattern Parent','Child'])
 assert.equal(result.aspects[0].graph.rels.length,3) // duplicate root→child retained
 assert.equal(result.aspects[0].graph.nodes[0].in.length,1) // hits=4 is not graph in-degree
 const fallback=structuredClone(neighborhood);delete fallback[0].patterns
 const expanded=run('fallback parent filter',fallback,1)
 assert.deepEqual(expanded.aspects[0].graph.nodes.slice(1,4).map(n=>n.props.title),['Small Three','Small Two','Small One'])
 assert(!expanded.aspects[0].graph.nodes.some(n=>n.props.title==='Exactly Fifteen'))
 const downOverride=structuredClone(neighborhood);downOverride[0].patterns.down=['pattern-parent']
 assert(!run('explicit down overrides links',downOverride,1).aspects[0].graph.nodes.some(n=>n.props.title==='Child'))
 const empty=structuredClone(neighborhood);empty[0].patterns.up=[]
 assert.equal(run('explicit empty up',empty,1).aspects[0].graph.nodes[0].in.length,0)
 const reverse=structuredClone(neighborhood);[reverse[0],reverse[1]]=[reverse[1],reverse[0]]
 const reversed=run('duplicate slug order reversed',reverse,1)
 assert.deepEqual(reversed.ranking.hits,result.ranking.hits)
 assert.equal(reversed.aspects[0].graph.nodes[0].props.title,'Hub B')
 assert.equal(reversed.aspects[0].graph.nodes.length,1)
 const badParent=structuredClone(neighborhood);badParent[0].patterns.up=['absent-parent']
 const savedLog=console.log;console.log=()=>{}
 try {assert.throws(()=>walks(1,'hubs',badParent),e=>{failures.push({label:'missing explicit parent',message:e.message});return e instanceof TypeError})}finally{console.log=savedLog}
 const many=Array.from({length:15},(_,i)=>page('target-'+i,'Target '+i,'limits.example'))
 many.push(page('all','All','limits.example',Object.fromEntries(many.map(p=>[p.slug,1]))))
 assert.equal(run('default count',many,undefined).aspects.length,12)
 assert.equal(run('explicit count',many,2).aspects.length,2)
}finally{Date.now=oldNow;console.log=oldLog}
const record={generatorSha256:sha(read('scripts/test-mech-hubs-reading.mjs')),nodeVersion:process.version,kind:'Trusted synthetic execution of the unchanged retained Mech library, not Ward\'s runtime',clock:1791936000000,
 source:{retainedRepositoryAuthority:'local:/Users/rgb/workspace/hyperdoc',retainedOid:'9a1764250f31013a50965aad324dd72c0662b9cc',path:'assets/hyperbook/fedwiki/mech-host/plugins/mech/library.js',sha256:sha(source),provenance:provenance.assets.find(a=>a.path==='plugins/mech/library.js').source,
  status:'Retained composed module verified by digest; declared upstream base unavailable in local Git stores and at its raw URL. No whole upstream revision equivalence asserted.'},
 dependencies:provenance.assets.filter(a=>/^plugins\/mech\/.*\.js$/.test(a.path)),parser:{name:'acorn',version:acorn.version},
 functions,cases,failures,checks:['15-link source counts','16-link source excluded','Unfindable targets absent','Duplicate slug hits conflate sites','First matching slug controls blanket','Explicit up/down honored','Fallback parents have <10 links, newest three, slug dedup','Empty up prevents fallback','Ranking differs from graph degree/aspect','Default count 12; explicit limit honored'],
 limitations:['No reconstruction of Ward\'s two-hub/four-node selection','No Solo or Graphviz execution','No claim about paths outside selected expansion']}
const target=path.join(root,'dreyeck/work/hubs-evidence/synthetic-selection.json')
const output=JSON.stringify(record,null,2)+'\n'
if(process.argv[2]==='--record')fs.writeFileSync(target,output)
else {assert.equal(process.argv.length,2,'Use --record to deliberately retain evidence or no argument to verify');assert.equal(fs.readFileSync(target,'utf8'),output)}
console.log('MECH-HUBS-PASS: exact library, seven synthetic cases, source thresholds, missing targets, duplicate slugs, patterns, fallback, count, ranking vs graph; deterministic retained evidence')
