// What pressing Preview shows, in a served Catalog with the preview system activated the way
// test-item-edit-preview-activation.mjs does it (START-CATALOG with an additive catalog system,
// development off), on a temporary copy of the retained page:
//   unchanged text, one-line and many-line Item  -> "No change", no backtrace
//   changed text                                  -> the regular Preview
//   the page file changed after the proposal      -> "Edit conflict", proposal kept, no write
// The conflict changes only the temporary copy. The retained page is never touched.
// node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT
import {installBoundClicks,readiness} from './lib/inspector-ready.mjs'
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import crypto from 'node:crypto'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,pw,chrome,output]=process.argv.slice(2)
if(!output)throw Error('LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT required')
fs.mkdirSync(output,{recursive:true})
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'item-edit-outcomes-'))
const evidence=path.resolve(path.dirname(new URL(import.meta.url).pathname),'../dreyeck/work/ctm-page-evidence/ctm-and-tmdm-in-hyperdoc.json')
const site=path.join(temp,'site'),pageFile=path.join(site,'pages','ctm-and-tmdm-in-hyperdoc')
fs.mkdirSync(path.dirname(pageFile),{recursive:true});fs.copyFileSync(evidence,pageFile)
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')
const observed='d7215c50f4efa07b3e94749b060b7d7b828654f2a44caab7f1034415c6003dff'
const retained=sha(evidence)
assert.equal(retained,observed);assert.equal(sha(pageFile),observed)
const port=await new Promise(r=>{const s=net.createServer();s.listen(0,'127.0.0.1',()=>{const p=s.address().port;s.close(()=>r(p))})})
const stop=path.join(temp,'stop'),script=path.join(temp,'witness.lisp'),log=path.join(output,'lisp.log')
fs.writeFileSync(script,`(require :asdf)
(asdf:load-system "dreyeck/catalog-application")
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1"
 :site-root ${JSON.stringify(site+'/')} :catalog-system "dreyeck/fedwiki-item-edit-preview")
(format t "~&WRITER-LOADED=~A~%" (if (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING") "YES" "NO"))
(format t "~&OUTCOMES-READY~%") (finish-output)
(unwind-protect (loop repeat 4800 until (probe-file #p"${stop}") do (sleep .1)) (clog:shutdown))`)
const fd=fs.openSync(log,'w'),child=spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
const browser=await chromium.launch({headless:true,executablePath:chrome})
const steps=[]
try{
 for(let n=0;n<3000;n++){if(child.exitCode!==null)throw Error(fs.readFileSync(log,'utf8').slice(-4000));if(fs.readFileSync(log,'utf8').includes('OUTCOMES-READY'))break;await new Promise(r=>setTimeout(r,100))}
 assert(fs.readFileSync(log,'utf8').includes('WRITER-LOADED=NO'))
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(30000);installBoundClicks(page)
 const errors=[];page.on('pageerror',e=>errors.push(e.message))
 const last=()=>page.locator('.inspector-pane').last()
 const click=async label=>last().getByText(label,{exact:true}).first().click()
 const tab=async label=>last().getByRole('button',{name:label,exact:true}).first().click()
 const heading=async label=>last().getByRole('heading',{name:label,exact:true}).waitFor()
 const noBacktrace=async()=>{const text=await page.locator('body').innerText();assert(!text.includes('Backtrace'),'a backtrace is shown');assert(!text.includes('FEDWIKI-PAGE-EDIT-REFUSED'))}
 const openItem=async id=>{
  await page.goto(`http://127.0.0.1:${port}/view/ctm-and-tmdm-in-hyperdoc`)
  await last().locator('.inspector-title').filter({hasText:'CTM and TMDM in HyperDoc'}).first().waitFor()
  await tab('Page source');await last().getByText(observed,{exact:true}).first().waitFor()
  await last().getByText(id,{exact:true}).first().click();await heading(`Story Item ${id}`)
  await tab('Edit');await click('Prepare edit proposal');await heading(`Edit proposal for ${id}`)
 }
 const e3='ed37e9bac2fcd548',multi='174e5462ccd2815f'

 // Unchanged text, one-line Item: a neutral answer in place of an error pane.
 await openItem(e3)
 await click('Preview');await heading(`No change for ${e3}`)
 let text=await last().innerText()
 assert(text.includes('nothing was written'));assert(text.includes(observed))
 await noBacktrace();steps.push('E3 unchanged → No change, no backtrace')
 await click('Return to the proposal');await heading(`Edit proposal for ${e3}`);steps.push('back to the proposal')
 assert.equal(sha(pageFile),observed)

 // Changed text: the regular preview.
 const proposed='E3 — Darstellung: outcome test text, not a decision.'
 const input=last().locator('input').first()
 await input.fill(proposed);await input.dispatchEvent('change');await page.waitForTimeout(500)
 await click('Preview');await heading(`Preview: edit of ${e3}`)
 text=await last().innerText();assert(text.includes('Executed: no.'));assert(text.includes(proposed))
 await noBacktrace();steps.push('E3 changed → Preview')
 assert.equal(sha(pageFile),observed)
 // The preview's sentence about the journal links the Action itself.
 {
  // The Preview pane is the last pane. In its sentence about the journal only the words "this edit Action" are a link.
  const panes=()=>page.locator('.inspector-pane')
  const addr=async pane=>((await pane.locator('.inspector-title').first().innerText()).match(/\{([0-9A-F]+)\}/)||[])[1]
  const previewIndex=await panes().count()-1
  const previewPane=panes().nth(previewIndex)
  const right=()=>panes().nth(previewIndex+1)
  const sentence=previewPane.locator('li').filter({hasText:'Journal:'})
  assert.equal(await sentence.count(),1)
  assert(/^Journal: 2 entries become 3; the new entry is this edit Action, which has no date field/.test((await sentence.innerText()).trim()))
  assert.equal(await sentence.locator('.inspector-inspect').count(),1,'only these words are a link')
  assert.equal(await sentence.locator('.inspector-inspect').first().innerText(),'this edit Action')
  assert.equal(await previewPane.getByText('The Edit Action in its context').count(),0)
  assert.equal(await previewPane.getByText('The Action itself').count(),0)
  const panesBefore=await panes().count()
  await sentence.getByText('this edit Action',{exact:true}).click()
  await page.waitForFunction(n=>document.querySelectorAll('.inspector-pane').length>n,panesBefore)
  const viaSentence=right()
  await viaSentence.locator('.inspector-title').filter({hasText:'HASH-TABLE'}).waitFor()
  await viaSentence.getByText('ed37e9bac2fcd548').first().waitFor()
  const items=await viaSentence.innerText()
  assert(items.includes('edit'));assert(items.includes('ed37e9bac2fcd548'))
  const addressOfSentenceLink=await addr(viaSentence)
  steps.push('Preview: "this edit Action" in the Expected effect opens the Action hash table')
  // The Edit Action view is an alternative tab of the same Preview pane.
  await previewPane.getByRole('button',{name:'Action context',exact:true}).first().click()
  await previewPane.getByRole('heading',{name:/^Edit Action for ed37e9bac2fcd548$/}).waitFor()
  const contextText=await previewPane.innerText()
  for(const expected of ['proposed','previewed','persisted','not by this Inspector','It has no date field.','nothing in this code adds one','Not decided here','Recorded, not performed here.','preview-action, a hash table','It is an ordinary function, not a generic function'])assert(contextText.includes(expected),expected)
  assert(!contextText.includes('its source code'));assert(!contextText.includes('its callers'))
  steps.push('Action context tab of the Preview: proposed, previewed, persisted; the date said to be missing')
  // The same object by the other route: the identity of the Action behind both links.
  await previewPane.getByText('preview-action, a hash table',{exact:true}).first().click()
  await page.waitForTimeout(700)
  assert.equal(await addr(right()),addressOfSentenceLink,'the same Action object by both routes')
  steps.push('the Action by both routes is one object')
  // The Action's pane has no view that leads back by registration; the Preview pane stands next to it.
  assert.equal(await right().getByRole('button',{name:'Where this comes from',exact:true}).count(),0)
  // plan-fedwiki-page-edit is linked where it is mentioned, and its own views stay.
  const computed=previewPane.locator('p').filter({hasText:'and called'})
  assert.equal(await computed.locator('.inspector-inspect').filter({hasText:/^plan-fedwiki-page-edit$/}).count(),1)
  await computed.getByText('plan-fedwiki-page-edit',{exact:true}).click()
  const functionPane=right()
  await functionPane.locator('.inspector-title').filter({hasText:'plan-fedwiki-page-edit'}).waitFor()
  await functionPane.getByRole('button',{name:'Source code',exact:true}).waitFor()
  await functionPane.getByRole('button',{name:'Callers',exact:true}).waitFor()
  await functionPane.locator('pre.code-snippet').first().waitFor()
  assert((await functionPane.innerText()).toLowerCase().includes('defun plan-fedwiki-page-edit'))
  steps.push('plan-fedwiki-page-edit in the sentence opens the function: Source code and Callers tabs')
  await functionPane.getByRole('button',{name:'Callers',exact:true}).click()
  await functionPane.getByText('preview-item-edit').first().waitFor({timeout:120000})
  steps.push('its Callers include preview-item-edit')
  await previewPane.getByText('the recorded trial',{exact:true}).first().click();await page.waitForTimeout(600)
 }
 assert((await last().locator('.inspector-title').first().innerText()).toUpperCase().includes('TRIAL'));steps.push('→ the recorded trial object')
 assert.equal(sha(pageFile),observed)

 // Unchanged text, many-line Item (the other Preview button).
 await openItem(multi)
 await click('Preview');await heading(`No change for ${multi}`)
 await noBacktrace();steps.push('many-line Item unchanged → No change, no backtrace')
 assert.equal(sha(pageFile),observed)

 // The page file changes after the proposal was made: a conflict, the proposal kept, nothing written.
 await openItem(e3)
 const typed='E3 — my edit, made before the page changed.'
 const field=last().locator('input').first()
 await field.fill(typed);await field.dispatchEvent('change');await page.waitForTimeout(500)
 const json=JSON.parse(fs.readFileSync(pageFile,'utf8'))
 json.story.find(item=>item.id==='fa6304a65d40144c').text='E2 changed elsewhere.'
 fs.writeFileSync(pageFile,JSON.stringify(json))
 const moved=sha(pageFile);assert.notEqual(moved,observed);assert.equal(sha(evidence),retained)
 await click('Preview');await heading(`Edit conflict for ${e3}`)
 text=await last().innerText()
 for(const expected of [observed,moved,typed,'nothing was replaced or rebased','Return to the proposal','The page source now','Inspect the original condition'])
  assert(text.includes(expected),expected)
 await noBacktrace();steps.push('E3 conflict → Edit conflict: both revisions, proposal text, no backtrace')
 assert.equal(sha(pageFile),moved,'previewing must not write')
 await click('Return to the proposal');await heading(`Edit proposal for ${e3}`)
 assert.equal(await last().locator('input').first().inputValue(),typed);steps.push('proposal kept after the conflict')
 // The original condition stays reachable for a deeper look.
 await page.locator('.inspector-pane').filter({has:page.getByRole('heading',{name:`Edit conflict for ${e3}`,exact:true})}).last()
  .getByText('Inspect the original condition',{exact:true}).click()
 await last().getByRole('heading',{name:'Backtrace',exact:true}).waitFor();steps.push('original condition inspectable on request')
 // Positive control: the backtrace check can see a backtrace where there is one.
 assert((await page.locator('body').innerText()).includes('Backtrace'),'control: the condition view shows a backtrace')
 assert.equal(sha(pageFile),moved)
 assert.deepEqual(errors,[]);assert.deepEqual(fs.readdirSync(path.dirname(pageFile)),['ctm-and-tmdm-in-hyperdoc'])
 assert.equal(sha(evidence),retained)
 await page.screenshot({path:path.join(output,'outcomes.png'),fullPage:false})
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',browser:browser.version(),writerLoaded:'NO',retainedPageSha256:retained,steps},null,2))
 console.log('ITEM-EDIT-PREVIEW-OUTCOMES-PASS: '+steps.join(' → ')+' | clicks '+JSON.stringify(readiness))
}catch(e){
 const pages=browser.contexts().flatMap(c=>c.pages());if(pages.length){fs.writeFileSync(path.join(output,'failure.txt'),await pages[0].locator('body').innerText());await pages[0].screenshot({path:path.join(output,'failure.png')})}
 throw e
}finally{
 await browser.close();fs.writeFileSync(stop,'')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.rmSync(temp,{recursive:true,force:true})
}
