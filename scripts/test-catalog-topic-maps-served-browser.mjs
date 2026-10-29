// A real browser over the packaged, served Catalog: the Topic Maps views it offers, read-only.
// node THIS PLAYWRIGHT_CORE_DIRECTORY CHROME OUTPUT_DIRECTORY (--executable HYPERDOC_CATALOG | --origin http://127.0.0.1:PORT)
// With --executable the script starts the packaged hyperdoc-catalog itself (no development mode: the executable has none), with the
// service's choice of Topic Maps readings; with --origin it uses a Catalog that is already running, started that way.
// For each view it checks that the reading is there and navigable, and that no run button is: the buttons the same views have in a
// development server (checked in Lisp, dreyeck/tests/topic-maps-public-views.lisp) are shown as "not run in a served Catalog".
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
import {installBoundClicks,readiness} from './lib/inspector-ready.mjs'
const [pw,chrome,output,mode,target]=process.argv.slice(2)
assert(output && (mode==='--executable'||mode==='--origin') && target,'usage: PLAYWRIGHT CHROME OUTPUT (--executable PATH | --origin URL)')
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),'..')
fs.mkdirSync(output,{recursive:true})
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'catalog-served-browser-'))
const steps=[],errors=[],external=[],started=new Date().toISOString()
let child=null,origin=target,fd=null
if(mode==='--executable'){
 const sock=net.createServer();await new Promise(r=>sock.listen(0,'127.0.0.1',r));const port=sock.address().port;await new Promise(r=>sock.close(r))
 origin=`http://127.0.0.1:${port}`
 fd=fs.openSync(path.join(output,'catalog.log'),'w')
 child=spawn(target,[String(port)],{cwd:temp,stdio:['ignore',fd,fd],env:{PATH:process.env.PATH,HOME:path.join(temp,'home'),TMPDIR:process.env.TMPDIR||'/tmp',
  HYPERDOC_CATALOG_HOST:'127.0.0.1',HYPERDOC_CATALOG_SYSTEM:'dreyeck/work/topic-maps-ctm-review',
  HYPERDOC_FEDWIKI_SITE_ROOT:path.join(root,'dreyeck/tests/fixtures/local-fedwiki-view-site')}})
 fs.mkdirSync(path.join(temp,'home'),{recursive:true})
}
let browser,success=false,failure=null
const offered=/^(Read a fresh 22U Map|Exercise on a separate fresh Map|Run the experiment|Read default-type example|Read explicit-type example)$/
try {
 for(let n=0;n<9000;n++){
  if(child&&child.exitCode!==null)throw Error(fs.readFileSync(path.join(output,'catalog.log'),'utf8').slice(-5000))
  try{if((await fetch(origin)).ok)break}catch{}
  if(n===8999)throw Error('Catalog did not answer')
  await new Promise(r=>setTimeout(r,100))
 }
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch({headless:true,executablePath:chrome,args:['--disable-background-networking','--no-proxy-server']})
 const context=await browser.newContext({serviceWorkers:'block',viewport:{width:1280,height:900}})
 await context.route('**/*',r=>{const u=new URL(r.request().url());if(u.origin===origin||u.protocol==='ws:')return r.continue();external.push(u.href);return r.abort()})
 const page=await context.newPage();page.setDefaultTimeout(60000);installBoundClicks(page);page.on('pageerror',e=>errors.push(e.message))
 const panes=()=>page.locator('.inspector-pane'),last=()=>panes().last()
 const tab=async title=>last().getByRole('button',{name:title,exact:true}).first().click()
 const heading=async (pane,title)=>pane.getByRole('heading',{name:title,exact:true}).waitFor()
 const open=async book=>{await page.goto(origin);await page.getByText(book,{exact:true}).and(page.locator(':visible')).first().click();await tab('Text pages')}
 const openPage=async title=>{await page.locator('tr.inspector-inspect:visible').filter({hasText:title}).last().click();await last().getByRole('heading',{name:title,exact:true}).first().waitFor()}
 // No control that runs code is offered in the pane: no button with a run label, none of upstream's action class with one.
 const noRunControl=async (pane,labels,where)=>{
  const text=await pane.innerText()
  for(const label of labels){
   assert(text.includes(`${label} (not run in a served Catalog)`),`${where}: "${label}" is not shown as not offered; the pane reads: ${text.slice(0,600)}`)
   assert.equal(await pane.getByRole('button',{name:label,exact:true}).count(),0,`${where}: "${label}" is offered as a button`)
  }
  const buttons=await pane.locator('button').allInnerTexts()
  assert(!buttons.some(t=>offered.test(t.trim())),`${where}: a run button is present: ${JSON.stringify(buttons)}`)
 }

 // 1. The CTM review: reading, claim, loaded definition, source at the pinned commit; the experiment is not offered.
 await open('Topic Maps CTM Review (22U)');await openPage('Reviewing the CTM Reader')
 steps.push('Catalog → Topic Maps CTM Review (22U) → Text pages → Reviewing the CTM Reader')
 await last().getByText('Claim scheme-plus: an undelimited IRI whose scheme contains +',{exact:true}).first().click()
 await heading(last(),'Claim scheme-plus')
 const claimIndex=(await panes().count())-1,claim=panes().nth(claimIndex),claimText=await claim.innerText()
 for(const part of ['1. Claim','2. Normative basis','3. Implementation: loaded definitions','4. Counterexample and controls','5. Expected behaviour','6. Observed behaviour','7. Evaluation','8. Provenance'])assert(claimText.includes(part),part)
 assert(claimText.includes('Not executed in this image.'))
 await noRunControl(claim,['Run the experiment'],'claim scheme-plus')
 steps.push('page → Claim scheme-plus: eight parts, "Not executed in this image.", and the experiment shown as not offered; no button')
 const before=await panes().count()
 await claim.getByText('next-token',{exact:true}).first().click()
 await page.waitForFunction(n=>document.querySelectorAll('.inspector-pane').length>n,before)
 steps.push('Claim → the loaded definition next-token (a function object): read-only navigation continues')
 await claim.getByText(/^src\/ctm\/lexer\.lisp at /).first().click()
 await last().getByText('(defun next-token',{exact:false}).first().waitFor()
 assert((await last().innerText()).includes('Verified now'),'the snapshot file is read through a verification made when it is shown')
 steps.push('Claim → src/ctm/lexer.lisp at the pinned commit, read from the verified /nix/store snapshot')

 // 2. The 22U reading page and its view.
 await open('Topic Maps Project Example (22U)');await openPage('Reading Slice 22U')
 await tab('Topic Maps 22U')
 await noRunControl(last(),['Read a fresh 22U Map','Exercise on a separate fresh Map'],'22U reading page')
 steps.push('Catalog → Topic Maps Project Example (22U) → Reading Slice 22U → view Topic Maps 22U: both buttons shown as not offered')

 // 3. An existing page gaining views, and the TMDM model reached from it.
 await open('Working on HyperDoc');await openPage('Work Breakdown')
 await tab('Topic Maps 22U')
 await noRunControl(last(),['Read a fresh 22U Map','Exercise on a separate fresh Map'],'Work Breakdown / Topic Maps 22U')
 await tab('TMDM model')
 const tmdm=last();await tmdm.getByText('TMDM model reading',{exact:true}).first().waitFor()
 steps.push('Catalog → Working on HyperDoc → Work Breakdown → views Topic Maps 22U (not offered) and TMDM model')
 const beforeTopic=await panes().count()
 await tmdm.getByText('ctm-plan-page-authoring',{exact:true}).first().click()
 await page.waitForFunction(n=>document.querySelectorAll('.inspector-pane').length>n,beforeTopic)
 await tab('TMDM model')
 await heading(last(),'Topic → Name → Type Topic')
 await noRunControl(last(),['Read default-type example','Read explicit-type example'],'work topic / TMDM model')
 steps.push('TMDM model → Work topic ctm-plan-page-authoring → view TMDM model: both examples shown as not offered; their definitions stay readable')
 assert(!(await last().innerText()).includes('Existing Work Workspace'),'the served view must not link the shared Workspace')
 steps.push('the served TMDM model view has no direct link to the shared Workspace')
 // A reviewed control still works through the real click path: the conversation cursor, reached from the same Work topic.
 await tab('Conversation sources')
 const beforeSession=await panes().count()
 await last().getByText('Conversation Session',{exact:true}).first().click()
 await page.waitForFunction(n=>document.querySelectorAll('.inspector-pane').length>n,beforeSession)
 const sessionIndex=(await panes().count())-1,sessionPane=()=>panes().nth(sessionIndex)
 await heading(sessionPane(),'Conversation chronology')
 const cursor=async()=>((await sessionPane().innerText()).match(/Cursor:\s*(Message #\d+)/)||[])[1]
 const at0=await cursor();assert(at0,'the chronology shows a cursor')
 await sessionPane().getByRole('button',{name:'Next selected message',exact:true}).click()
 await page.waitForFunction(([i,was])=>{const t=document.querySelectorAll('.inspector-pane')[i].innerText;const m=t.match(/Cursor:\s*(Message #\d+)/);return m&&m[1]!==was},[sessionIndex,at0])
 const at1=await cursor();assert.notEqual(at1,at0,'Next selected message moved the cursor')
 await sessionPane().getByRole('button',{name:'Previous selected message',exact:true}).click()
 await page.waitForFunction(([i,was])=>{const t=document.querySelectorAll('.inspector-pane')[i].innerText;const m=t.match(/Cursor:\s*(Message #\d+)/);return m&&m[1]===was},[sessionIndex,at0])
 steps.push(`Work topic → Conversation sources → Conversation Session → Chronology: Next selected message moves the cursor (${at0} → ${at1}) and Previous moves it back, by real clicks when served`)
 await page.screenshot({path:path.join(output,'served-topic-maps.png')})
 assert.deepEqual(errors,[],'browser errors');assert.deepEqual(external,[],'external requests')
 success=true
} catch(e) {failure=String(e.stack||e);console.error(failure)}
finally {
 if(browser)await browser.close()
 if(child){child.kill('SIGTERM');for(let n=0;n<150&&child.exitCode===null;n++)await new Promise(r=>setTimeout(r,100));fs.closeSync(fd)}
 fs.writeFileSync(path.join(output,'served-browser.json'),JSON.stringify({kind:'packaged-served-Catalog-read-only-Topic-Maps-views',startedAtUTC:started,finishedAtUTC:new Date().toISOString(),mode,origin,success,failure,steps,errors,externalRequests:external,clickReadiness:readiness,shutdownExit:child?child.exitCode:null},null,1))
}
if(!success)process.exitCode=1
