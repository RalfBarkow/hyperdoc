// The proposed scope Regular HyperDoc Catalog with a Navigable Project Topic Map (Zettel 11359) walked in the HyperDoc Project Workspace,
// in a freshly started, loopback-only Catalog (scripts/serve-project-workspace.lisp) over an empty temporary FedWiki site root: from the
// Project Workspace to the proposed Work Item, the Deliverable, a work package, its plan steps along their dependencies, a precondition;
// an implementation assignment, its evidence entries and the absent acceptance. Every expectation is derived from the page text of
// Implementation Assignments; no Catalog-wide count is written down. Nothing is written: the source pages, the draft dictionary and the
// CTM file keep their digests.
// node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT TOPIC_MAPS_ROOT
import {installBoundClicks} from './lib/inspector-ready.mjs'
import fs from 'node:fs'
import path from 'node:path'
import net from 'node:net'
import crypto from 'node:crypto'
import assert from 'node:assert/strict'
import {spawn,execFileSync} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,pw,chrome,output,topicMaps]=process.argv.slice(2)
if(!topicMaps)throw Error('LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT TOPIC_MAPS_ROOT required')
fs.mkdirSync(output,{recursive:true})
const repo=path.resolve(path.dirname(new URL(import.meta.url).pathname),'..')
const sha=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex')
const pin=fs.readFileSync(path.join(repo,'dreyeck/work/project/project-workspace.lisp'),'utf8').match(/\(defparameter \+topic-maps-revision\+ "([0-9a-f]{40})"/)[1]
const git=(...args)=>execFileSync('git',['-C',topicMaps,...args],{encoding:'utf8'}).trim()
assert.equal(git('rev-parse','HEAD'),pin,'the Topic Maps checkout is at the pin');assert.equal(git('status','--porcelain'),'','the Topic Maps checkout is clean')
const ctmFile=path.join(repo,'dreyeck/work/project/hyperdoc-project.ctm')
const assignmentsFile=path.join(repo,'dreyeck/pages/project/Implementation Assignments.html')
const watched=[ctmFile,ctmFile+'.sha256',assignmentsFile,path.join(repo,'dreyeck/pages/project/Regular Catalog WBS Dictionary.html'),
 ...['Work Breakdown','Authoring the CTM Plan Page','CTM Plan Page WBS Dictionary'].map(t=>path.join(repo,'dreyeck/pages/work',t+'.html'))]
const before=Object.fromEntries(watched.map(f=>[f,sha(f)]))

// What the page proposes, read from its text
const source=fs.readFileSync(assignmentsFile,'utf8')
const inScope=id=>id==='topic-maps-regular-hyperdoc'||id==='tm-regular-catalog'||id.startsWith('tm-reg-')
const proposals=[...source.matchAll(/<a [^>]*data-proposed-topic="([^"]+)" data-kind="([^"]+)"[^>]*>([^<]*)<\/a>/g)]
 .map(m=>({id:m[1],kind:m[2],label:m[3]})).filter(p=>inScope(p.id))
const byId=Object.fromEntries(proposals.map(p=>[p.id,p]))
const statements=[...source.matchAll(/<li data-proposed-from="([^"]+)" data-proposed-relation="([^"]+)" data-proposed-to="([^"]+)"/g)]
 .map(m=>({from:m[1],relation:m[2],to:m[3]})).filter(s=>inScope(s.from)||inScope(s.to))
const words={'work:relation/decomposes-into':'decomposes into','work:relation/produces':'produces','work:relation/depends-on':'depends on'}
assert(proposals.length>0&&statements.length>0,'the page proposes the scope')
for(const s of statements){assert(words[s.relation],s.relation);assert(byId[s.from]&&byId[s.to],'the statement stays inside the scope: '+JSON.stringify(s))}
const assignments=[...source.matchAll(/<section data-assignment="([^"]+)">([\s\S]*?)<\/section>/g)].map(m=>({id:m[1],body:m[2],
 title:(m[2].match(/<h3>([^<]*)<\/h3>/)||[])[1],workItem:(m[2].match(/data-field="work-item" data-ref="([^"]+)"/)||[])[1],
 delivers:(m[2].match(/data-field="delivers" data-ref="([^"]+)"/)||[])[1],
 tests:[...new Set([...m[2].matchAll(/<li data-test="([^"]+)"/g)].map(e=>e[1]))],
 commits:[...new Set([...m[2].matchAll(/HyperDoc commit ([0-9a-f]{40})/g)].map(e=>e[1]))]}))
const scopeAssignments=assignments.filter(a=>a.workItem==='topic-maps-regular-hyperdoc')
assert(scopeAssignments.length>1,'assignments of the scope')
const workItem=proposals.find(p=>p.kind==='work item'),deliverable=proposals.find(p=>p.kind==='deliverable')
const packages=proposals.filter(p=>p.kind==='work package'),steps=proposals.filter(p=>p.kind==='plan step'),preconditions=proposals.filter(p=>p.kind==='precondition')
// The rows the native Workspace shows for a proposal: the page it is proposed on, its carrier, its statements, and the assignments that concern it
const expectedRows=id=>{
 const rows=[{word:'proposed on',arrow:'←',label:'Implementation Assignments'},{word:'carried by',arrow:'→',label:'HyperDoc Project Workspace'}]
 for(const s of statements){if(s.from===id)rows.push({word:words[s.relation],arrow:'→',label:byId[s.to].label});if(s.to===id)rows.push({word:words[s.relation],arrow:'←',label:byId[s.from].label})}
 for(const a of scopeAssignments){if(a.delivers===id)rows.push({word:'assignment delivers',arrow:'←',label:a.title})
  if(a.workItem===id)rows.push({word:'assignment for',arrow:'←',label:a.title})}
 return rows}
const normalize=s=>s.replace(/\s+/g,' ').trim()
const escape=s=>s.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')

const port=await new Promise(r=>{const s=net.createServer();s.listen(0,'127.0.0.1',()=>{const p=s.address().port;s.close(()=>r(p))})})
const log=path.join(output,'catalog.log'),fd=fs.openSync(log,'w')
const child=spawn(lisp,['--load',path.join(repo,'scripts/serve-project-workspace.lisp')],{cwd:repo,detached:true,stdio:['ignore',fd,fd],env:{...process.env,TOPIC_MAPS_ROOT:topicMaps,HYPERDOC_PROJECT_PORT:String(port)}})
const text=()=>fs.readFileSync(log,'utf8')
const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
const browser=await chromium.launch({headless:true,executablePath:chrome})
const steps_=[];let siteRoot=null
try{
 for(let n=0;!/PROJECT-WORKSPACE-CATALOG: /.test(text());n++){if(child.exitCode!==null||n>9000)throw Error(text().slice(-3000));await new Promise(r=>setTimeout(r,100))}
 siteRoot=text().match(/SITE-ROOT: (\S+)/)[1];assert(siteRoot.includes('TEST-COPY')&&!siteRoot.includes('/.wiki'),siteRoot)
 assert.equal(text().match(/TOPIC-MAPS: (\S+)/)[1],pin)
 steps_.push(`Catalog (the trusted review runtime scripts/serve-project-workspace.lisp, not the packaged Catalog) started on loopback over a TEST-COPY site root with topic-maps ${pin.slice(0,8)}`)
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(600000);installBoundClicks(page)
 const errors=[];page.on('pageerror',e=>errors.push(e.message))
 const panes=()=>page.locator('.inspector-pane'),last=()=>panes().last()
 await page.goto(`http://127.0.0.1:${port}`)
 await page.getByText('HyperDoc Project Workspace',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByRole('button',{name:'Text pages',exact:true}).last().click()
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'HyperDoc Project Workspace'}).last().click()
 await last().getByRole('heading',{name:'HyperDoc Project Workspace',exact:true}).waitFor()
 const pagePanes=await panes().count()
 await last().locator('.hyperbook-reference[title="(dreyeck/work/project:project-workspace)"] .inspector-inspect').first().click()
 const project=panes().nth(pagePanes)
 await project.getByRole('heading',{name:'HyperDoc Project Workspace',exact:true}).waitFor()
 await project.getByText('Proposals',{exact:true}).first().waitFor()
 steps_.push('Catalog → HyperBook HyperDoc Project Workspace → Text pages → page → the Project Workspace reading')
 // The Proposals section lists every proposal of the scope with its kind, and says they are not declared
 const projectText=normalize(await project.innerText())
 assert(projectText.includes('Not declared: proposed on the page Implementation Assignments, without status.'))
 for(const p of proposals)assert(projectText.includes(`${p.label} (${p.kind})`),`the Proposals section lists ${p.id}`)
 for(const a of scopeAssignments)assert(projectText.includes(a.title),`the assignments list ${a.id}`)
 assert(projectText.includes('No acceptance is recorded'),'the reading states that no acceptance is recorded')
 steps_.push(`the Proposals section lists the ${proposals.length} proposals of the scope with their kinds, "Not declared: proposed on the page Implementation Assignments, without status", and the ${scopeAssignments.length} assignments of the scope`)
 // A Point of the native Workspace: its sign, its rows in both directions, compared with what the page proposes
 const rowsOf=async ws=>(await ws.locator('tr.dreyeck-topicmap-workspace-association').evaluateAll(a=>a.map(x=>x.innerText))).map(normalize)
 const atPoint=async(ws,id)=>{await ws.locator(`.dreyeck-topicmap-point-sign[data-topic-id="${id}"]`).first().waitFor({state:'attached'});await page.waitForTimeout(300)}
 const checkProposal=async(ws,id)=>{
  await atPoint(ws,id)
  const rows=await rowsOf(ws),expected=expectedRows(id)
  for(const e of expected)assert(rows.some(r=>new RegExp(`^${escape(e.word)} ${escape(e.arrow)} ${escape(e.label)}$`).test(r)),`${id}: no row "${e.word} ${e.arrow} ${e.label}" among ${JSON.stringify(rows)}`)
  const relations=rows.filter(r=>/^(decomposes into|produces|depends on) /.test(r))
  assert.equal(relations.length,expected.filter(e=>/^(decomposes into|produces|depends on)$/.test(e.word)).length,`${id}: exactly the proposed relations ${JSON.stringify(relations)}`)
  assert(!rows.some(r=>/^proposed in dictionary/.test(r)),`${id}: the draft dictionary is not a source, so no row states it`)
  assert(!rows.some(r=>/accept/i.test(r)&&!/^assignment /.test(r)),`${id}: no acceptance row`)
  return rows}
 const go=async(ws,label)=>{await ws.locator('tr.dreyeck-topicmap-workspace-association button.inspector-action').filter({hasText:new RegExp('^\\s*'+escape(label)+'\\s*$')}).first().click()}
 const open=async label=>{await project.getByRole('button',{name:label,exact:true}).nth(0).click();await page.waitForTimeout(500);return last()}

 // The proposed Work Item: related to nothing but its page, its carrier and the assignments for it; the gap with the Deliverable is named
 let ws=await open(workItem.label),rows
 await checkProposal(ws,workItem.id)
 assert(projectText.includes(`${workItem.id} and ${deliverable.id} share only their carrier page`),'the Work Item and the Deliverable are not related, and the Workspace says so')
 steps_.push(`Project → Work Item ${workItem.id}: proposed on the page, carried by the Workspace page, assignments for it; no Association to the Deliverable, and the Project Workspace names the gap`)
 // The Deliverable decomposes into the work packages (the second button of the same label)
 await project.getByRole('button',{name:deliverable.label,exact:true}).nth(1).click();await page.waitForTimeout(500);ws=last()
 await checkProposal(ws,deliverable.id)
 steps_.push(`Project → Deliverable ${deliverable.id}: decomposes into ${packages.length} work packages`)
 // Work package 1, its producing plan step, and the assignment that delivers it
 const first=packages[0]
 await go(ws,first.label);await checkProposal(ws,first.id)
 steps_.push(`Deliverable → ${first.id}: proposed on the page, decomposed from the Deliverable, produced by its plan step${scopeAssignments.some(a=>a.delivers===first.id)?', delivered by an assignment':''}`)
 // The plan steps along their dependencies: from each step to the next that depends on it
 const stepOf=pkg=>statements.find(s=>s.relation==='work:relation/produces'&&s.to===pkg.id).from
 let current=stepOf(first);await go(ws,byId[current].label);await checkProposal(ws,current)
 const visited=[current]
 for(;;){
  const next=statements.find(s=>s.relation==='work:relation/depends-on'&&s.to===current&&byId[s.from].kind==='plan step'&&!visited.includes(s.from))
  if(!next)break
  await go(ws,byId[next.from].label);current=next.from;await checkProposal(ws,current);visited.push(current)
 }
 assert(visited.length>1,'the plan steps follow one another')
 steps_.push('plan steps along depends-on: '+visited.join(' → ')+', each with exactly the relations the page proposes')
 // A precondition the last step waits for
 const waits=statements.find(s=>s.relation==='work:relation/depends-on'&&s.from===current&&byId[s.to].kind==='precondition')
 assert(waits,'the last step waits for a precondition')
 await go(ws,byId[waits.to].label);await checkProposal(ws,waits.to)
 steps_.push(`${current} → precondition ${waits.to}: depends on ← ${current}; no work package depends on it`)
 // From a work package to the page it is proposed on: a Topic of the project CTM
 await go(ws,'Implementation Assignments');await atPoint(ws,'page/dreyeck/work/project/implementation-assignments')
 steps_.push('proposed on → the page Implementation Assignments as a Topic of the project CTM')

 // An implementation assignment, what it delivers, the tests it names and the commits it reports; its evidence is notes, not identified entries
 const assignment=scopeAssignments.find(a=>a.delivers&&a.tests.length>1&&a.commits.length>0)
 assert(assignment,'a scope assignment that delivers a package, names tests and reports a commit')
 await project.getByRole('button',{name:assignment.title,exact:true}).first().click();await page.waitForTimeout(500);ws=last()
 await atPoint(ws,`assignment/${assignment.id}`)
 rows=await rowsOf(ws)
 assert(rows.some(r=>r===`assignment delivers → ${byId[assignment.delivers].label}`),'the assignment delivers its package')
 assert(rows.some(r=>r===`assignment for → ${workItem.label}`),'the assignment is for the Work item')
 for(const test of assignment.tests)assert(rows.some(r=>r===`evidenced by test → ${test}`),`the assignment names the test ${test}`)
 assert.equal(rows.filter(r=>/^evidenced by test/.test(r)).length,assignment.tests.length,'exactly the tests the page names')
 assert(!rows.some(r=>/^reifies \(evidence\)/.test(r)),'the evidence is notes: no identified evidence entry')
 assert(!rows.some(r=>/accept/i.test(r)&&!/^gap /.test(r)),'no acceptance row on the assignment')
 const assignmentText=normalize(await ws.innerText())
 for(const commit of assignment.commits)assert(assignmentText.includes(commit),`the assignment reports the commit ${commit}`)
 assert(assignmentText.includes('No acceptance by the user is recorded.'),'the assignment states that no acceptance is recorded')
 assert(assignmentText.includes('NOT within 90 s')||assignmentText.includes('within 90 s'),'the assignment reports the timing as it is, not as it should be')
 steps_.push(`assignment ${assignment.id}: delivers ${assignment.delivers}, for ${workItem.id}, names ${assignment.tests.length} tests, reports the commit ${assignment.commits.map(c=>c.slice(0,8)).join(', ')} as an evidence note, no identified evidence entry, no acceptance`)
 // From a named test to its file Topic, and back
 const test=assignment.tests[0]
 await go(ws,test);await atPoint(ws,`file/${test}`)
 steps_.push(`evidenced by test → the file Topic ${test}`)
 // Every scope assignment names the absent acceptance
 for(const a of scopeAssignments)assert(new RegExp(`<section data-assignment="${escape(a.id)}">[\\s\\S]*?No acceptance by the user is recorded\\.`).test(source),a.id)
 steps_.push('every assignment of the scope states: No acceptance by the user is recorded.')

 // The CTM read back with the scope in it
 await project.getByRole('button',{name:'Roundtrip',exact:true}).first().click()
 await project.getByRole('heading',{name:'Roundtrip and traceability',exact:true}).waitFor()
 const roundtrip=await project.innerText()
 assert(roundtrip.includes('commit '+pin)||/the pinned revision/.test(roundtrip),'the pinned reader')
 assert(/Export of the unchanged import\s*octets\s*yes/.test(roundtrip),'byte-identical export')
 assert(/The file and the sources mean the same\s*CXTM\s*yes/.test(roundtrip),'CXTM equal')
 assert(/Every Topic and statement traced to its declaration\s*TMDM against the source pages\s*yes/.test(roundtrip),'trace')
 steps_.push('Roundtrip with the scope in the CTM: export octets equal; CXTM equal to the sources; every Topic and statement traced')

 assert.deepEqual(errors,[])
 for(const [f,digest] of Object.entries(before))assert.equal(sha(f),digest,f+' unchanged')
 assert.deepEqual(fs.readdirSync(path.join(siteRoot,'pages')),[],'the test-copy site root stays empty')
 steps_.push('nothing written: source pages, the draft dictionary, the CTM file and the site root unchanged')
 await context.close()
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',topicMaps:pin,runtime:'scripts/serve-project-workspace.lisp (trusted review runtime, not the packaged Catalog)',scope:{proposals:proposals.length,statements:statements.length,assignments:scopeAssignments.map(a=>a.id)},steps:steps_},null,2))
 console.log('PROJECT-WORKSPACE-SCOPE-BROWSER-PASS:\n  '+steps_.join('\n  '))
}catch(e){
 const pages=browser.contexts().flatMap(c=>c.pages());if(pages.length){fs.writeFileSync(path.join(output,'failure.txt'),await pages[0].locator('body').innerText());await pages[0].screenshot({path:path.join(output,'failure.png'),fullPage:true})}
 throw e
}finally{
 await browser.close()
 try{process.kill(-child.pid,'SIGKILL')}catch{};await new Promise(r=>{if(child.exitCode!==null||child.signalCode)r();else{child.once('exit',r);setTimeout(r,10000).unref()}})
 if(siteRoot&&siteRoot.includes('TEST-COPY')&&fs.existsSync(siteRoot))fs.rmSync(siteRoot,{recursive:true,force:true})
}
