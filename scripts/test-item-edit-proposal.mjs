// Work package ctm-wp-2, Inspectable edit proposal, in an actual served Catalog (development off,
// policy enforced) with the optional system dreyeck/topic-maps-reading added the way
// HYPERDOC_CATALOG_SYSTEM adds a system, and the topic-maps checkout in the ASDF registry:
//   Work Breakdown → carrier page → plan → ctm-wp-2 → Proposal anatomy → the objects of the proposal,
//   the preview apart from the recorded persisted trial, operation / Work package / TMDM Topic,
//   the TMDM example read with the topic-maps reader, its projections and the projected Topic.
// No writer is loaded, nothing is written.
// node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT TOPIC_MAPS_DIRECTORY
import {installBoundClicks,readiness} from './lib/inspector-ready.mjs'
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import crypto from 'node:crypto'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,pw,chrome,output,topicMaps]=process.argv.slice(2)
if(!topicMaps)throw Error('LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT TOPIC_MAPS_DIRECTORY required')
fs.mkdirSync(output,{recursive:true})
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),'..')
const sources=['dreyeck/pages/work/Work Breakdown.html','dreyeck/pages/work/Authoring the CTM Plan Page.html','dreyeck/pages/work/CTM Plan Page WBS Dictionary.html',
 'dreyeck/work/ctm-page-evidence/ctm-and-tmdm-in-hyperdoc.json','dreyeck/work/ctm-page-evidence/persisted-edit-trial.json',
 'dreyeck/work/ctm-page-evidence/site/pages/ctm-and-tmdm-in-hyperdoc']
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex')
const before=sources.map(sha)
const ctmFile=path.join(topicMaps,'vendor/cxtm/ctm/in/association-binary.ctm')
const ctmSha=crypto.createHash('sha256').update(fs.readFileSync(ctmFile)).digest('hex')
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'proposal-browser-')),stop=path.join(temp,'stop'),probe=path.join(temp,'probe'),script=path.join(temp,'witness.lisp')
fs.mkdirSync(path.join(temp,'site','pages'),{recursive:true})
const port=await new Promise(r=>{const s=net.createServer();s.listen(0,'127.0.0.1',()=>{const p=s.address().port;s.close(()=>r(p))})})
fs.writeFileSync(script,`(require :asdf)
(pushnew #p${JSON.stringify(topicMaps.endsWith('/')?topicMaps:topicMaps+'/')} asdf:*central-registry* :test (function equal))
(asdf:load-system "dreyeck/catalog-application")
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1" :site-root ${JSON.stringify(temp+'/site/')}
 :catalog-system "dreyeck/topic-maps-reading" :development nil)
(assert (dreyeck/authority-policy:policy-enforced-p))
(defun state () (format nil "writer-package=~A writer-loaded=~A" (if (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING") "YES" "NO")
                        (if (asdf:component-loaded-p "dreyeck/fedwiki-page-authoring") "YES" "NO")))
(format t "~&PROPOSAL-BROWSER-READY ~A~%" (state)) (finish-output)
(unwind-protect
    (loop repeat 6000 until (probe-file #p"${stop}")
          do (when (probe-file #p"${probe}") (delete-file #p"${probe}") (format t "~&PROPOSAL-BROWSER-STATE ~A~%" (state)) (finish-output))
             (sleep .1))
  (clog:shutdown))`)
const log=path.join(output,'lisp.log'),fd=fs.openSync(log,'w'),child=spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
const logText=()=>fs.readFileSync(log,'utf8')
let browser
try{
 for(let n=0;n<4000;n++){if(child.exitCode!==null)throw Error(logText().slice(-4000));if(logText().includes('PROPOSAL-BROWSER-READY'))break;await new Promise(r=>setTimeout(r,100))}
 assert.equal(logText().match(/PROPOSAL-BROWSER-READY (.*)/)[1],'writer-package=NO writer-loaded=NO')
 const stateNow=async()=>{
  const count=()=>(logText().match(/PROPOSAL-BROWSER-STATE/g)||[]).length,seen=count()
  fs.writeFileSync(probe,'')
  for(let n=0;n<100&&count()<=seen;n++)await new Promise(r=>setTimeout(r,100))
  return [...logText().matchAll(/PROPOSAL-BROWSER-STATE (.*)/g)].pop()[1]
 }
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch({headless:true,executablePath:chrome})
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(30000);installBoundClicks(page)
 const errors=[];page.on('pageerror',e=>errors.push(e.message))
 const last=()=>page.locator('.inspector-pane').last()
 const click=async label=>last().getByText(label,{exact:true}).first().click()
 const tab=async label=>last().getByRole('button',{name:label,exact:true}).first().click()
 const heading=async label=>last().getByRole('heading',{name:label,exact:true}).waitFor()
 const paneIndex=async()=>await page.locator('.inspector-pane').count()-1
 const steps=[]
 await page.goto(`http://127.0.0.1:${port}/`)
 await page.getByText('Working on HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
 await tab('Text pages')
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'Work Breakdown'}).last().click()
 await heading('Work Breakdown')
 await click('Author the CTM Plan Page through HyperDoc');await heading('Authoring the CTM Plan Page')
 await click('the plan');await last().getByText('neither permits an effect',{exact:false}).first().waitFor();steps.push('Work Breakdown → carrier page → plan')
 await last().locator('tr').filter({hasText:'P2 Prepare the inspectable edit proposal'}).getByText('Inspectable edit proposal',{exact:true}).first().click()
 await heading('Inspectable edit proposal');steps.push('Work package ctm-wp-2')
 await last().getByRole('button',{name:'Proposal anatomy',exact:true}).waitFor()
 await tab('Proposal anatomy');await click('Open the proposal anatomy')
 await heading('Prepare edit proposal: the objects');steps.push('Proposal anatomy')
 const anatomy=page.locator('.inspector-pane').nth(await paneIndex())
 let body=await anatomy.innerText()
 for(const expected of ['Observed page revision','Selected Story Item','Edit proposal','Expected Item','Replacement Item','FedWiki edit Action','Result of the page checks','Preview','Executed: no.','content decision of E3 is open'])
  if(expected!=='Executed: no.')assert(body.includes(expected),expected)
 assert(body.includes('propose-item-edit'));assert(body.includes('plan-fedwiki-page-edit'))
 // A part as an object: the expected Item's exact JSON.
 const panesBefore=await page.locator('.inspector-pane').count()
 await anatomy.getByText("the Item's exact current JSON",{exact:true}).click()
 await page.waitForFunction(n=>document.querySelectorAll('.inspector-pane').length>n,panesBefore)
 await page.waitForTimeout(800)
 assert((await last().innerText()).includes('ed37e9bac2fcd548'));steps.push('expected Item as an object')
 // From the Preview object to its Edit Action, the Action's hash table and the recorded trial.
 await anatomy.getByText('Preview of the edit of ed37e9bac2fcd548',{exact:true}).click()
 await heading('Preview: edit of ed37e9bac2fcd548')

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
  await heading('A journal edit that was executed, on a temporary copy')
 assert((await last().innerText()).includes('Recorded, not performed here.'));steps.push('Edit Action → the recorded trial')
 await anatomy.getByRole('button',{name:'Anatomy',exact:true}).first().click()
 await anatomy.getByRole('heading',{name:'Prepare edit proposal: the objects',exact:true}).waitFor()
 // The preview apart from the writer, from the classes and source.
 await anatomy.getByRole('button',{name:'Preview or edit?',exact:true}).first().click()
 await anatomy.getByRole('heading',{name:'A computed preview and a persisted edit',exact:true}).waitFor()
 body=await anatomy.innerText()
 for(const expected of ['item-edit-preview','fedwiki-page-edit','not loaded in this image','it does not','Neither the preview nor the writer sets a date','plan-fedwiki-page-edit'])assert(body.includes(expected),expected)
 steps.push('Preview or edit?: the writer not loaded here, the date unset')
 await anatomy.getByText('see the trial',{exact:true}).click()
 await heading('A journal edit that was executed, on a temporary copy')
 body=await last().innerText()
 for(const expected of ['Recorded, not performed here.','check-persisted-trial','18 / 2','18 / 3','ed37e9bac2fcd548','example text only','Authorization of the edit step (P3)'])assert(body.includes(expected),expected)
 steps.push('recorded persisted trial, kept apart')
 await click('Authorization of the edit step (P3)');await last().getByRole('heading',{name:/^Authorization of P3/}).waitFor()
 assert((await last().innerText()).includes('Not granted'));steps.push('P3 authorization: not granted')
 // Operation, Work package, TMDM Topic.
 await anatomy.getByRole('button',{name:'Operation or topic?',exact:true}).first().click()
 await anatomy.getByRole('heading',{name:'Three things that are easily taken for one',exact:true}).waitFor()
 body=await anatomy.innerText()
 for(const expected of ['Prepare edit proposal','ctm-wp-2','a TMDM Topic','an operation','a Work package'])assert(body.includes(expected),expected)
 steps.push('operation, Work package and TMDM Topic told apart')
 // The TMDM example.
 await anatomy.getByRole('button',{name:'TMDM example',exact:true}).first().click()
 await anatomy.getByRole('heading',{name:'What E3 is about, with real TMDM objects',exact:true}).waitFor()
 assert((await anatomy.innerText()).includes('No candidate is chosen here.'))
 await anatomy.getByText('association-binary.ctm, read with topic-maps',{exact:true}).click()
 await heading('association-binary.ctm as TMDM objects')
 const objects=last()
 body=await objects.innerText()
 for(const expected of [ctmSha,'ctm-tests.example.invalid','equal: yes','833 octets','TMDM Topic','TMDM Role','roletype1','roletype2','topic1','topic2'])assert(body.includes(expected),expected)
 steps.push('TMDM objects read with the topic-maps reader')
 await objects.locator('tr').filter({hasText:'topic1'}).getByText('TMDM Topic',{exact:true}).first().click()
 await page.waitForFunction(()=>document.querySelector('.inspector-pane:last-child .inspector-title')!==null)
 assert((await last().locator('.inspector-title').first().innerText()).toUpperCase().includes('TOPIC'));steps.push('the TMDM Topic itself')
 const objectsPane=page.locator('.inspector-pane').filter({has:page.getByRole('heading',{name:'association-binary.ctm as TMDM objects',exact:true})}).last()
 await objectsPane.getByText('Projections: four ways to show these objects',{exact:true}).click()
 await heading('Four candidate projections')
 body=await last().innerText()
 for(const expected of ['Association as a node, type Topics shown','Association as an edge, type Topics hidden','None is chosen','E4 '])
  assert(body.includes(expected.trim()),expected)
 const projectionsPane=page.locator('.inspector-pane').nth(await paneIndex())
 await projectionsPane.getByText('topic1 (TMDM topic)',{exact:true}).click()
 await heading('topic1')
 body=await last().innerText()
 for(const expected of ['TMDM object (topic-maps.tmdm)','Projected topic (dreyeck/topicmap)','item identifier','E4, the key policy, is open','not a Work Topic','(EQ): yes'])assert(body.includes(expected),expected)
 steps.push('projected Topic: TMDM object and projection told apart')
 const panesNow=await page.locator('.inspector-pane').count()
 await last().locator('tr').filter({has:page.locator('td',{hasText:/^Object$/})}).locator('span.inspector-inspect').first().click()
 await page.waitForFunction(n=>document.querySelectorAll('.inspector-pane').length>n-1,panesNow)
 await page.waitForTimeout(500)
 assert((await last().locator('.inspector-title').first().innerText()).toUpperCase().includes('TOPIC'))
 steps.push('from the projected Topic to its TMDM object')
 await projectionsPane.getByText('Topicmap workspace',{exact:true}).first().click()
 await last().locator('.dreyeck-topicmap-point-sign').first().waitFor();steps.push('native Workspace of the projection')
 const probeState=await stateNow()
 assert.equal(probeState,'writer-package=NO writer-loaded=NO');steps.push('no writer loaded after the whole walk')
 assert.deepEqual(before,sources.map(sha));assert.deepEqual(errors,[]);assert.equal(crypto.createHash('sha256').update(fs.readFileSync(ctmFile)).digest('hex'),ctmSha)
 assert.deepEqual(fs.readdirSync(path.join(temp,'site','pages')),[])
 await page.screenshot({path:path.join(output,'proposal.png'),fullPage:false})
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',browser:browser.version(),development:false,policy:'ENFORCED',writer:'ABSENT',steps,sourcesUnchanged:true},null,2))
 console.log('PROPOSAL-BROWSER-PASS: '+steps.join(' → ')+' | clicks '+JSON.stringify(readiness))
}catch(e){
 if(browser){const pages=browser.contexts().flatMap(c=>c.pages());if(pages.length){fs.writeFileSync(path.join(output,'failure.txt'),await pages[0].locator('body').innerText());await pages[0].screenshot({path:path.join(output,'failure.png')})}}
 throw e
}finally{
 if(browser)await browser.close();fs.writeFileSync(stop,'')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.rmSync(temp,{recursive:true,force:true})
}
