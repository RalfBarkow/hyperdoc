// The HyperDoc Project Workspace in a freshly started, loopback-only Catalog (scripts/serve-project-workspace.lisp) over an empty
// temporary FedWiki site root. Catalog → HyperBook → page → Project Workspace; along the Associations of the native Workspace from the
// project to a Work Item, its carrier page, the Deliverable, a work package, its plan step and a precondition, each step checked by the
// Point sign; the declaration in its page source; an implementation assignment and its evidence file; the CTM document and its download,
// decoded and compared with the file. Nothing is written: the source pages and the CTM file keep their digests.
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
// The Topic Maps revision this test expects is the Project Workspace's own pin, read from its source, and it is checked here without
// the Lisp that serves the Catalog: Git's own answers for the checkout the Catalog was started on (its HEAD, a clean working tree) and
// the committed manifest that names the same commit. 5a4a668 was the pin until the Topic Maps 6162ed68 integration.
const pin=fs.readFileSync(path.join(repo,'dreyeck/work/project/project-workspace.lisp'),'utf8').match(/\(defparameter \+topic-maps-revision\+ "([0-9a-f]{40})"/)[1]
const git=(...args)=>execFileSync('git',['-C',topicMaps,...args],{encoding:'utf8'}).trim()
assert.equal(git('rev-parse','HEAD'),pin,'the Topic Maps checkout is at the pin');assert.equal(git('status','--porcelain'),'','the Topic Maps checkout is clean')
assert(fs.readFileSync(path.join(repo,`nix/topic-maps-${pin.slice(0,8)}.manifest`),'utf8').includes(`:commit "${pin}"`),'a committed manifest names the pin')
const ctmFile=path.join(repo,'dreyeck/work/project/hyperdoc-project.ctm')
const sources=['dreyeck/pages/work/Work Breakdown.html','dreyeck/pages/work/Authoring the CTM Plan Page.html',
 'dreyeck/pages/work/CTM Plan Page WBS Dictionary.html','dreyeck/pages/project/Implementation Assignments.html'].map(f=>path.join(repo,f))
const before=Object.fromEntries([ctmFile,...sources].map(f=>[f,sha(f)]))
// Labels of the Topics on the path, read from the CTM file: a subject line, then its first Name.
const ctm=fs.readFileSync(ctmFile,'utf8')
const label=subject=>{const at=ctm.indexOf('\n'+subject+'\n');assert(at>=0,'no Topic '+subject);return ctm.slice(at).match(/\n    - "((?:[^"\\]|\\.)*)"/)[1].replace(/\\"/g,'"')}
const base='tag:dreyeck.ch,2026:hyperdoc/'
const path_=[['page/dreyeck/work/reading/work-breakdown',`<${base}page/dreyeck/work/reading/work-breakdown>`],
 ['ctm-plan-page-authoring','w:ctm-plan-page-authoring'],
 ['page/dreyeck/work/reading/authoring-the-ctm-plan-page',`<${base}page/dreyeck/work/reading/authoring-the-ctm-plan-page>`],
 ['ctm-page-edit','w:ctm-page-edit'],['ctm-wp-2','w:ctm-wp-2'],['ctm-plan-p2','w:ctm-plan-p2'],['ctm-pre-content','w:ctm-pre-content']]
  .map(([key,subject])=>({key,label:label(subject)}))
const assignmentLabel=label(`<${base}assignment/cc-2026-10-19-topic-maps-reader-scaling>`)
const port=await new Promise(r=>{const s=net.createServer();s.listen(0,'127.0.0.1',()=>{const p=s.address().port;s.close(()=>r(p))})})
const log=path.join(output,'catalog.log'),fd=fs.openSync(log,'w')
const child=spawn(lisp,['--load',path.join(repo,'scripts/serve-project-workspace.lisp')],{cwd:repo,detached:true,stdio:['ignore',fd,fd],env:{...process.env,TOPIC_MAPS_ROOT:topicMaps,HYPERDOC_PROJECT_PORT:String(port)}})
const text=()=>fs.readFileSync(log,'utf8')
const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
const browser=await chromium.launch({headless:true,executablePath:chrome})
const steps=[];let siteRoot=null;const identity={}
try{
 for(let n=0;!/PROJECT-WORKSPACE-CATALOG: /.test(text());n++){if(child.exitCode!==null||n>9000)throw Error(text().slice(-3000));await new Promise(r=>setTimeout(r,100))}
 siteRoot=text().match(/SITE-ROOT: (\S+)/)[1];assert(siteRoot.includes('TEST-COPY')&&!siteRoot.includes('/.wiki'),siteRoot)
 assert.equal(text().match(/TOPIC-MAPS: (\S+)/)[1],pin)
 steps.push(`Catalog (the trusted review runtime scripts/serve-project-workspace.lisp, not the packaged Catalog) started on loopback over a TEST-COPY site root with topic-maps ${pin.slice(0,8)}, a clean Git checkout at the pin by Git's own answers`)
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(180000);installBoundClicks(page)
 const errors=[];page.on('pageerror',e=>errors.push(e.message))
 const panes=()=>page.locator('.inspector-pane')
 const last=()=>panes().last()
 // A pane for an object shows its printed representation, with the address of the Lisp object, under its Print tab: the same address in two
 // panes is the same object, not a copy of it.
 const printedObject=async index=>{const pane=panes().nth(index);await pane.locator('.inspector-title').first().waitFor()
  // The pane first renders its default view; its tabs take effect once that view has settled (two reads, 100 ms apart, agree).
  let settled=await pane.innerText();for(let n=0;n<50;n++){await new Promise(r=>setTimeout(r,100));const now=await pane.innerText();if(now===settled&&now.length>100)break;settled=now}
  await pane.getByRole('button',{name:'Print',exact:true}).first().click()
  let printed=null
  for(let n=0;n<100&&!printed;n++){printed=(await pane.innerText()).match(/#<[A-Z-]+ \{[0-9A-F]+\}>/g);if(!printed)await new Promise(r=>setTimeout(r,100))}
  assert(printed,'a printed object; the pane shows: '+JSON.stringify((await pane.innerText()).slice(0,400)));return printed[printed.length-1]}
 let routeOne=null
 const titleOf=async pane=>(await pane.locator('.inspector-title').first().innerText()).replace(/\s+/g,' ')
 await page.goto(`http://127.0.0.1:${port}`)
 await page.getByText('HyperDoc Project Workspace',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByRole('button',{name:'Text pages',exact:true}).last().click()
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'HyperDoc Project Workspace'}).last().click()
 await last().getByRole('heading',{name:'HyperDoc Project Workspace',exact:true}).waitFor()
 steps.push('Catalog → HyperBook HyperDoc Project Workspace → Text pages → page HyperDoc Project Workspace')
 // The entry link evaluates (dreyeck/work/project:project-workspace): the reading of the sources and the complete CTM.
 const pagePanes=await panes().count()
 await last().locator('.hyperbook-reference[title="(dreyeck/work/project:project-workspace)"] .inspector-inspect').first().click()
 // The Project pane by its position: the next pane; later panes open to its right.
 const project=panes().nth(pagePanes)
 await project.locator('.inspector-title').filter({hasText:/PROJECT-READING/i}).first().waitFor()
 await project.getByRole('heading',{name:'HyperDoc Project Workspace',exact:true}).waitFor()
 assert(/PROJECT-READING/i.test(await titleOf(project)),await titleOf(project))
 for(const expected of ['Work Areas','Work Items','Implementation assignments','Proposals','Gaps',assignmentLabel])assert((await project.innerText()).includes(expected),expected)
 steps.push('page link → the Project Workspace reading: Work Areas, Work Items, assignments, proposals, gaps')
 // Roundtrip, as the reading states it.
 await project.getByRole('button',{name:'Roundtrip',exact:true}).first().click()
 await project.getByRole('heading',{name:'Roundtrip and traceability',exact:true}).waitFor()
 const roundtrip=await project.innerText()
 assert(/the pinned revision/.test(roundtrip),'the pinned reader');assert(!/NOT the pinned/.test(roundtrip))
 assert(roundtrip.includes('Git checkout, commit '+pin),'the Roundtrip view names the checkout and the commit')
 assert(/Export of the unchanged import\s*octets\s*yes/.test(roundtrip),'byte-identical export')
 assert(/The file and the sources mean the same\s*CXTM\s*yes/.test(roundtrip),'CXTM equal')
 assert(/Every Topic and statement traced to its declaration\s*TMDM against the source pages\s*yes/.test(roundtrip),'trace')
 steps.push('Roundtrip: pinned reader '+pin.slice(0,8)+' (Git checkout); export octets equal; CXTM equal to the sources; every Topic and statement traced')
 await project.getByRole('button',{name:'Project',exact:true}).first().click()
 await project.getByRole('heading',{name:'HyperDoc Project Workspace',exact:true}).waitFor()
 // Route 2 to the Work Breakdown page object: the Sources table of the reading that read it.
 const beforeRoute2=await panes().count()
 await project.locator('tr:has-text("dreyeck/pages/work/Work Breakdown.html") .inspector-inspect').first().click()
 const routeTwoObject=await printedObject(beforeRoute2)
 steps.push(`the Work Breakdown page reached from the reading's Sources table is the object ${routeTwoObject}`)
 identity.routeTwoObject=routeTwoObject
 // The comparison can fail: another source page, reached the same way, is another object.
 await project.locator('tr:has-text("dreyeck/pages/work/Authoring the CTM Plan Page.html") .inspector-inspect').first().click()
 const otherObject=await printedObject(pagePanes+1) // a link of the project pane opens its pane just to the right of it, replacing the earlier one
 assert.notEqual(otherObject,routeTwoObject,'another page is another object')
 steps.push(`control: the page Authoring the CTM Plan Page is another object, ${otherObject}`)
 assert((await project.innerText()).includes('No acceptance is recorded'),'the reading states that no acceptance is recorded')
 // The native Workspace, along its Associations.
 await project.getByText('Open the Project Workspace (native Topicmap, Point and History)',{exact:true}).first().click()
 const ws=panes().nth((await panes().count())-1);await ws.locator('.dreyeck-topicmap-point-sign[data-topic-id="hyperbook/dreyeck/work/reading"]').first().waitFor({state:'attached'})
 for(const {key,label} of path_){
  await ws.locator('tr.dreyeck-topicmap-workspace-association button.inspector-action').filter({hasText:label}).first().click()
  await ws.locator(`.dreyeck-topicmap-point-sign[data-topic-id="${key}"]`).first().waitFor({state:'attached'})
  if(key===path_[0].key){
   // Route 1 to the Work Breakdown page object: the Point panel of its Topic names it as the Topic's source page.
   const wsPane=ws,before=await panes().count()
   await wsPane.locator('tr:has-text("Source page") .inspector-inspect').first().click()
   routeOne=await printedObject(before)
  }
 }
 steps.push(`the Work Breakdown page reached from its Workspace Topic is the object ${routeOne}`)
 steps.push('Workspace along its Associations: Working on HyperDoc → '+path_.map(p=>p.label).join(' → '))
 // Back to the work package: its Point panel names the declaration in its page source and the represented TMDM Topic.
 await ws.locator('tr.dreyeck-topicmap-workspace-association button.inspector-action').filter({hasText:path_[5].label}).first().click()
 await ws.locator('.dreyeck-topicmap-point-sign[data-topic-id="ctm-plan-p2"]').first().waitFor({state:'attached'})
 await ws.locator('tr.dreyeck-topicmap-workspace-association button.inspector-action').filter({hasText:path_[4].label}).first().click()
 await ws.locator('.dreyeck-topicmap-point-sign[data-topic-id="ctm-wp-2"]').first().waitFor({state:'attached'})
 const point=await ws.innerText();assert(/Declared on/.test(point));assert(/wbs-acceptance-criterion|WBS acceptance criterion/.test(point))
 // Absent evidence is named, not left out: the work package has an acceptance criterion and no acceptance record.
 assert(point.includes('ctm-wp-2: acceptance criterion without an acceptance record'),'the Point panel names the absent acceptance record')
 steps.push('the work package ctm-wp-2 names its absent acceptance record: "ctm-wp-2: acceptance criterion without an acceptance record"')
 await ws.getByText('the declaration in the page source',{exact:true}).first().click()
 const occurrence=last();await occurrence.locator('.inspector-title').first().waitFor();await page.waitForTimeout(400)
 assert(/WORK-TOPIC-SOURCE-OCCURRENCE/i.test(await titleOf(occurrence)),await titleOf(occurrence))
 steps.push('back along the Associations to the work package; its Point panel opens the declaration in its page source (work-topic-source-occurrence)')
 // An implementation assignment and its evidence.
 await project.getByRole('button',{name:assignmentLabel,exact:true}).first().click()
 const assignment=last();await assignment.locator('.dreyeck-topicmap-point-sign[data-topic-id="assignment/cc-2026-10-19-topic-maps-reader-scaling"]').first().waitFor({state:'attached'})
 const assignmentText=await assignment.innerText()
 for(const expected of ['5a4a668','No acceptance by the user is recorded.','evidence'])assert(assignmentText.includes(expected),expected)
 await assignment.locator('tr.dreyeck-topicmap-workspace-association button.inspector-action').filter({hasText:'dreyeck/tests/project-ctm.lisp'}).first().click()
 await last().locator('.dreyeck-topicmap-point-sign[data-topic-id="file/dreyeck/tests/project-ctm.lisp"]').first().waitFor({state:'attached'})
 steps.push('assignment "'+assignmentLabel+'" with its evidence and no acceptance → its evidence file dreyeck/tests/project-ctm.lisp')
 // The CTM document and its download.
 await project.getByRole('button',{name:'Project',exact:true}).first().click()
 await project.getByText('The project CTM document: open and download',{exact:true}).first().click()
 const doc=last();await doc.locator('a.project-ctm-download').first().waitFor({state:'attached'})
 const href=await doc.locator('a.project-ctm-download').first().getAttribute('href')
 const downloaded=Buffer.from(href.slice(href.indexOf('base64,')+7),'base64')
 assert.equal(crypto.createHash('sha256').update(downloaded).digest('hex'),sha(ctmFile),'the download is the file')
 assert((await doc.innerText()).includes(sha(ctmFile)),'the document view shows the digest')
 assert.equal(fs.readFileSync(ctmFile+'.sha256','utf8').slice(0,64),sha(ctmFile),'the sidecar digest is the file')
 steps.push('CTM document → download: '+downloaded.length+' octets, SHA-256 '+sha(ctmFile)+', equal to the file and its sidecar')
 assert.equal(identity.routeTwoObject,routeOne,'the same page object from both routes')
 steps.push('object identity retained across panes and routes: '+routeOne)
 assert.deepEqual(errors,[])
 for(const [f,digest] of Object.entries(before))assert.equal(sha(f),digest,f+' unchanged')
 assert.deepEqual(fs.readdirSync(path.join(siteRoot,'pages')),[],'the test-copy site root stays empty')
 steps.push('nothing written: source pages, CTM file and the site root unchanged')
 await context.close()
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',topicMaps:pin,runtime:'scripts/serve-project-workspace.lisp (trusted review runtime, not the packaged Catalog)',workBreakdownPageObject:routeOne,steps},null,2))
 console.log('PROJECT-WORKSPACE-BROWSER-PASS:\n  '+steps.join('\n  '))
}catch(e){
 const pages=browser.contexts().flatMap(c=>c.pages());if(pages.length){fs.writeFileSync(path.join(output,'failure.txt'),await pages[0].locator('body').innerText());await pages[0].screenshot({path:path.join(output,'failure.png'),fullPage:true})}
 throw e
}finally{
 await browser.close()
 // The whole process group: the wrapper, nix and the SBCL that serves the Catalog.
 try{process.kill(-child.pid,'SIGKILL')}catch{};await new Promise(r=>{if(child.exitCode!==null||child.signalCode)r();else{child.once('exit',r);setTimeout(r,10000).unref()}})
 if(siteRoot&&siteRoot.includes('TEST-COPY')&&fs.existsSync(siteRoot))fs.rmSync(siteRoot,{recursive:true,force:true})
}
