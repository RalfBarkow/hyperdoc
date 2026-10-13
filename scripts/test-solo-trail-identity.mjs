// Offline original Solo receiver, plus unchanged function extraction for alias checks.
// node THIS PLAYWRIGHT_DIRECTORY CHROME CACHE OUTPUT_JSON
import fs from 'node:fs'
import path from 'node:path'
import {pathToFileURL, fileURLToPath} from 'node:url'
import crypto from 'node:crypto'
import vm from 'node:vm'
import assert from 'node:assert/strict'
import {createMechHost, root as hostRoot} from './serve-fedwiki-mech-host.mjs'
const [pw, chrome, cache, output] = process.argv.slice(2)
if (!output) throw Error('PLAYWRIGHT_DIRECTORY CHROME CACHE OUTPUT_JSON required')
const root = fileURLToPath(new URL('../', import.meta.url))
const read = p => fs.readFileSync(path.join(root,p),'utf8')
const hash = s => crypto.createHash('sha256').update(s).digest('hex')
const clone = x => JSON.parse(JSON.stringify(x))
const solo = read('assets/hyperbook/fedwiki/mech-host/plugins/solo/dialog/index.html')
assert.equal(hash(solo),'5a513f70546ced3e2af7f83c4f14fb73d30e27f22a295558cbff4b078871aed8')
const pageText = read('dreyeck/work/trails-rendered-evidence/ward.voices.ustawi.wiki--trails-rendered.json')
assert.equal(hash(pageText),'5fdba40fd3a68eddee00497af4dadb3847500356a2f131dbc0745afb86de9810')
const page = JSON.parse(pageText)
const imports = JSON.parse(read('tests/fedwiki-mech-browser-assets.json'))
for(const a of imports) assert.equal(hash(fs.readFileSync(path.join(cache,a.name))),a.sha256)
// Verbatim region includes Graph, partitions, composite and dotify. No source rewriting.
const region = solo.slice(solo.indexOf('const uniq ='),solo.indexOf('// embolden lines'))
const api = vm.runInNewContext(region+'\n({Graph,composite,dotify})',{window:{},console:{log(){}}})
const original = JSON.parse(read('dreyeck/work/trails-rendered-solo-batch.json')).sources[0].aspects
// Deliberately synthetic overlap. No extra provenance properties repair the input.
function aspect(name,names) {
 const graph = new api.Graph(); names.forEach(name=>graph.addNode('',{name}));
 for(let i=1;i<names.length;i++) graph.addRel('Trail',i-1,i,{})
 return {name,graph:clone(graph)}
}
const overlap = [aspect('synthetic A',['A','B','C']),aspect('synthetic B',['X','B','C'])]
const cases = []
for(const [label, fixture] of [['original',original],['overlap',overlap],['overlap reversed',[...overlap].reverse()]]) {
 const chosen = clone(fixture), before = clone(chosen), complex = api.composite(chosen)
 const nodeMap = before.flatMap((a,ai)=>a.graph.nodes.map((n,id)=>({aspect:ai,local:id,
  composite:complex.graph.nodes.findIndex(c=>c.type===n.type && c.props.name===n.props.name)})))
 const relationMap = before.flatMap((a,ai)=>a.graph.rels.map((r,id)=>({aspect:ai,local:id,
  composite:complex.graph.rels.findIndex(c=>c.type===r.type && c.from===nodeMap.find(n=>n.aspect===ai&&n.local===r.from).composite && c.to===nodeMap.find(n=>n.aspect===ai&&n.local===r.to).composite)})))
 assert.deepEqual(Object.keys(complex).sort(),['graph','merged'])
 assert.equal(complex.graph.nodes.length,label==='original'?5:4)
 assert.equal(complex.graph.rels.length,label==='original'?4:3)
 assert.notDeepEqual(chosen,before) // rel.props.source mutates input
 assert.equal(complex.graph.rels[0].props,chosen[0].graph.rels[0].props)
 assert.equal(complex.graph.nodes[0].props,chosen[0].graph.nodes[0].props)
 assert.notEqual(complex.graph.nodes[0],chosen[0].graph.nodes[0])
 assert.equal(complex.graph.rels[1].props.source,chosen[0].name)
 if(label!=='original') {
  assert.equal(relationMap[1].composite,relationMap[3].composite)
  assert.deepEqual(chosen[1].graph.rels[1].props,{})
  // Non-injective composition: remove second trail's duplicate B -> C.
  // Same composite graph; the extra trail membership is unrecoverable from it.
  const reduced = clone(fixture); reduced[1].graph.rels.pop()
  reduced[1].graph.nodes[1].out=[]; reduced[1].graph.nodes[2].in=[]
  assert.deepEqual(clone(api.composite(reduced)),clone(complex))
 }
 cases.push({label,chosen:before,after:clone(chosen),complex:clone(complex),nodeMap,relationMap,dot:api.dotify(complex),
  mappingWarrant:'Derived using unchanged type/name and directed type/endpoints matching; not an exported Solo identity map.'})
}
// Re-evaluate ORIGINAL Code items with the retained original imported Graph module.
const code = page.story.filter(i=>i.type==='code').map(i=>i.text).join('\n')
const graphModule = await import(pathToFileURL(path.join(cache,'graph.js')))
const trails = vm.runInNewContext(code.replace(/^import .*$/mg,'').replace(/^export /mg,'')+'\ntrails',{Graph:graphModule.Graph})
const state = {context:{page}}; assert.equal(trails.call(state),'2 aspects')
assert.deepEqual(clone(state.aspect[0].result),original)
const host = createMechHost(); await new Promise(r=>host.listen(0,'127.0.0.1',r))
const origin = `http://127.0.0.1:${host.address().port}`
const {chromium} = await import(pathToFileURL(path.join(pw,'index.mjs')))
let browser
const blocked = [], errors = []
try {
 browser = await chromium.launch({headless:true,executablePath:chrome})
 const context = await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',route=>{
  const url=route.request().url(), a=imports.find(a=>a.url===url)
  if(a) return route.fulfill({body:fs.readFileSync(path.join(cache,a.name)),contentType:a.contentType,headers:{'access-control-allow-origin':'*'}})
  if(new URL(url).origin===origin) return route.continue()
  blocked.push(url); return route.abort()
 })
 const receiver = await context.newPage(); receiver.on('pageerror',e=>errors.push(e.message))
 await receiver.goto(origin+'/plugins/solo/dialog/')
 await receiver.waitForFunction(()=>typeof dochoose==='function')
 assert.equal(await receiver.locator('#target svg').count(),0)
 for(const result of cases) {
  await receiver.evaluate(aspects=>window.postMessage({type:'batch',sources:[{source:'trusted trail identity fixture',aspects}],pageKey:'identity-test'},location.origin),result.chosen)
  await receiver.locator('#n0').check(); await receiver.waitForFunction(()=>document.querySelectorAll('#target svg .node').length===3)
  await receiver.locator('#n1').check()
  await receiver.waitForFunction(n=>document.querySelectorAll('#target svg .node').length===n,result.complex.graph.nodes.length)
  result.svg = await receiver.evaluate(()=>({dot:window.dot,
   nodes:[...document.querySelectorAll('#target svg g.node')].map(n=>({id:n.id,title:n.querySelector('title').textContent,text:[...n.querySelectorAll('text')].map(t=>t.textContent)})),
   edges:[...document.querySelectorAll('#target svg g.edge')].map(n=>({id:n.id,title:n.querySelector('title').textContent,text:n.querySelector('text').textContent})),
   viewportTransform:document.querySelector('.svg-pan-zoom_viewport')?.getAttribute('transform')}))
  assert.equal(result.svg.dot,result.dot)
  assert.deepEqual(result.svg.nodes.map(n=>n.title).sort(),result.complex.graph.nodes.map((_,i)=>String(i)).sort())
  assert.equal(new Set(result.svg.nodes.map(n=>n.id)).size,result.svg.nodes.length)
  assert.equal(result.svg.edges.length,result.complex.graph.rels.length)
  for(const m of result.nodeMap) m.svg=result.svg.nodes.find(n=>n.title===String(m.composite)).id
  for(const r of result.complex.graph.rels) assert(result.svg.edges.some(e=>e.title===`${r.from}->${r.to}` && e.text==='Trail'))
  const before=result.svg.nodes.map(n=>({id:n.id,title:n.title}))
  await receiver.locator('#target svg').hover()
  await receiver.mouse.wheel(0,-200)
  await receiver.waitForFunction(old=>document.querySelector('.svg-pan-zoom_viewport').getAttribute('transform')!==old,result.svg.viewportTransform)
  const after=await receiver.evaluate(()=>({nodes:[...document.querySelectorAll('#target svg g.node')].map(n=>({id:n.id,title:n.querySelector('title').textContent})),transform:document.querySelector('.svg-pan-zoom_viewport').getAttribute('transform')}))
  assert.deepEqual(after.nodes,before); assert.notEqual(after.transform,result.svg.viewportTransform)
  result.zoom={transform:after.transform,nodeIdentifiersUnchanged:true}
 }
 assert.deepEqual(errors,[])
 assert(blocked.every(url=>url.endsWith('/favicon.png')))
 const report={kind:'Executed offline identity witness, not historical public capture',
  solo:{repository:'https://github.com/WardCunningham/wiki-plugin-solo',oid:'17915844349bada64c901bd5ea73472702c446f9',path:'client/dialog/index.html',sha256:hash(solo)},
  source:{site:'ward.voices.ustawi.wiki',slug:'trails-rendered',sha256:hash(pageText),paragraphs:['93cd119d6286888a','fc6c7d06e5bce7d3'],association:'Paragraph to aspect by original execution order, not preserved paragraph ID'},
  testSha256:hash(fs.readFileSync(fileURLToPath(import.meta.url))),imports,browser:browser.version(),cases,
  checks:['Original code yields recorded aspects','Original 5 nodes / 4 Trail relations','Shared relation reduced to one with first source','Removing duplicate membership yields identical complex','Reversed order changes winning source','Input props mutated and aliased','Actual unchanged Solo DOT matches extracted function','Graphviz SVG titles identify composite node indices','Real zoom changes transform but preserves node identifiers','No graph on receiver display; no external requests'],
  limits:['No original paragraph IDs survive in aspects','Derived maps are test observations, not Solo return fields','No arbitrary relayout/reload/rename guarantee','No Polyline or trails[] implemented']}
 fs.writeFileSync(output,JSON.stringify(report,null,2)+'\n')
 console.log('PASS: '+report.checks.length+' contracts; three cases including reversed overlap')
} finally {if(browser) await browser.close(); await new Promise(r=>host.close(r))}
