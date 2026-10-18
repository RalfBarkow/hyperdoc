// The documentation of the Item edit path, read in an actual served Catalog (development off, policy enforced) that
// serves the local review system. Nothing is written; the site is an empty temporary directory.
//   Working on HyperDoc → Text pages → Work Breakdown → Author the CTM Plan Page → implementation state
//   → Item Edit Path in HyperDoc → class, function with Source code, system
// The Item E3 is opened both ways (the E3 link, and the page link → Page source → E3), and each way goes on:
//   Edit → Prepare edit proposal → Preview, on a temporary copy of the page, which stays unchanged.
// node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT   (TOPIC_MAPS_ROOT: the topic-maps checkout)
// CATALOG_SYSTEM=dreyeck/ctm-page-authoring runs the served-sized Catalog: same Edit path, and no writer, no execution,
// no topic-maps in the image; the steps that open objects of the local system are left out.
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
const topicMaps=process.env.TOPIC_MAPS_ROOT
const catalogSystem=process.env.CATALOG_SYSTEM||'dreyeck/ctm-page-authoring/local'
const servedSized=catalogSystem==='dreyeck/ctm-page-authoring'
if(!output||(!servedSized&&!topicMaps))throw Error('LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT and, for the local system, TOPIC_MAPS_ROOT required')
fs.mkdirSync(output,{recursive:true})
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'ctm-documentation-browser-'))
const site=path.join(temp,'site');fs.mkdirSync(path.join(site,'pages'),{recursive:true})
const retained=path.resolve(path.dirname(new URL(import.meta.url).pathname),'../dreyeck/work/ctm-page-evidence/site/pages/ctm-and-tmdm-in-hyperdoc')
const pageFile=path.join(site,'pages','ctm-and-tmdm-in-hyperdoc');fs.copyFileSync(retained,pageFile)
const sha=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex'),before=sha(pageFile)
const port=await new Promise(r=>{const s=net.createServer();s.listen(0,'127.0.0.1',()=>{const p=s.address().port;s.close(()=>r(p))})})
const stop=path.join(temp,'stop'),script=path.join(temp,'witness.lisp'),log=path.join(output,'lisp.log')
fs.writeFileSync(script,`(require :asdf)
${topicMaps?`(pushnew #p${JSON.stringify(topicMaps.endsWith('/')?topicMaps:topicMaps+'/')} asdf:*central-registry* :test (function equal))`:''}
(asdf:load-system "dreyeck/catalog-application")
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1" :site-root ${JSON.stringify(site+'/')}
 :catalog-system ${JSON.stringify(catalogSystem)} :development nil)
(assert (dreyeck/authority-policy:policy-enforced-p))
(format t "~&PACKAGES preview=~A writer=~A execution=~A topic-maps=~A~%"
 (if (find-package "DREYECK/FEDWIKI-ITEM-EDIT-PREVIEW") "YES" "NO") (if (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING") "YES" "NO")
 (if (find-package "DREYECK/FEDWIKI-ITEM-EDIT-EXECUTION") "YES" "NO") (if (find-package "TOPIC-MAPS.TMDM") "YES" "NO"))
(format t "~&DOCUMENTATION-BROWSER-READY~%") (finish-output)
(unwind-protect (loop repeat 3000 until (probe-file #p${JSON.stringify(stop)}) do (sleep .1)) (clog:shutdown))`)
const fd=fs.openSync(log,'w'),child=spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
const logText=()=>fs.readFileSync(log,'utf8')
const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
const browser=await chromium.launch({headless:true,executablePath:chrome})
const steps=[]
try{
 for(let n=0;n<6000;n++){if(child.exitCode!==null)throw Error(logText().slice(-4000));if(logText().includes('DOCUMENTATION-BROWSER-READY'))break;await new Promise(r=>setTimeout(r,100))}
 const packages=(logText().match(/PACKAGES [^\n]*/)||[''])[0]
 assert(packages.includes('preview=YES'),packages)
 assert.equal(packages.includes('writer=NO')&&packages.includes('execution=NO'),servedSized,packages)
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(60000);installBoundClicks(page)
 const errors=[];page.on('pageerror',e=>errors.push(e.message))
 const last=()=>page.locator('.inspector-pane').last()
 const click=async label=>last().getByText(label,{exact:true}).first().click()
 const heading=async label=>last().getByRole('heading',{name:label,exact:true}).waitFor()
 await page.goto(`http://127.0.0.1:${port}`)
 await page.getByText('Working on HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByRole('button',{name:'Text pages',exact:true}).last().click()
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'Work Breakdown'}).last().click()
 await heading('Work Breakdown')
 let text=await last().innerText()
 for(const expected of ['How this page uses its terms','PMBOK Guide 2000','Agile Practice Guide 2017','HERMES Online','Reference basis'])assert(text.includes(expected),expected)
 steps.push('Work Breakdown: terms and reference basis')
 await click('Author the CTM Plan Page through HyperDoc');await heading('Authoring the CTM Plan Page')
 text=await last().innerText()
 for(const expected of ['Implementation state of packages 2 to 4','Integrated in source','Locally executable','Tested on temporary copies','Read in the local Inspector','Served on dreyeck.ch','Accepted'])assert(text.includes(expected),expected)
 steps.push('carrier page: implementation state')
 // Two links on the carrier page, two different objects: the whole page, and the Item E3 of it by its id.
 const panes=()=>page.locator('.inspector-pane')
 const carrier=await panes().count()-1
 const normalized=async pane=>(await pane.innerText()).replace(/, observed [^\n]*UTC/,'')
 await panes().nth(carrier).getByText('E3',{exact:true}).first().click()
 await panes().nth(carrier+1).getByRole('heading',{name:'Story Item ed37e9bac2fcd548',exact:true}).waitFor()
 const viaLink=await normalized(panes().nth(carrier+1));steps.push('E3 → the local-story-item')
 assert(viaLink.includes('11 of 18'));assert(viaLink.includes('Item JSON, as observed'))
 // Each way offers Edit, and Edit goes on to a proposal and a preview. A link that did not lead there would be no navigation to the Item's authoring.
 const e3='ed37e9bac2fcd548',proposed='E3 — Darstellung: documentation test text, not a decision.'
 const editPath=async item=>{
  await panes().nth(item).getByRole('button',{name:'Edit',exact:true}).first().click()
  await panes().nth(item).getByText('Prepare edit proposal',{exact:true}).first().click()
  await panes().nth(item+1).getByRole('heading',{name:`Edit proposal for ${e3}`,exact:true}).waitFor()
  const input=panes().nth(item+1).locator('input').first()
  await input.fill(proposed);await input.dispatchEvent('change');await page.waitForTimeout(500)
  await panes().nth(item+1).getByText('Preview',{exact:true}).first().click()
  await panes().nth(item+2).getByRole('heading',{name:`Preview: edit of ${e3}`,exact:true}).waitFor()
  const preview=await panes().nth(item+2).innerText()
  assert(preview.includes('Executed: no.'));assert(preview.includes(proposed))
  // The execution is the local system's: its tab is there where the system is loaded, and absent where it is not.
  const tabs=await panes().nth(item+2).getByRole('button').allInnerTexts()
  assert.equal(tabs.includes('Execution'),!servedSized,tabs.join('|'))
  assert.equal(sha(pageFile),before)}
 await editPath(carrier+1);steps.push('E3 link → Edit → Prepare edit proposal → Preview')
 if(!servedSized){
  // On to the completion, and to its tab CTM, as the documentation says: Execution → Complete the Action with a date.
  const preview=carrier+3
  await panes().nth(preview).getByRole('button',{name:'Execution',exact:true}).first().click()
  await panes().nth(preview).getByRole('button',{name:'Complete the Action with a date',exact:true}).click()
  const completion=preview+1
  await panes().nth(completion).getByRole('heading',{name:'The Action that would be authorized',exact:true}).waitFor()
  const date=(await panes().nth(completion).innerText()).match(/date added: (\d+)/)[1]   // the completion's date, to be found again in the completed Action
  const title=(await panes().nth(completion).locator('.inspector-title').first().innerText()).replace(/\s+/g,' ')
  assert(title.includes('item-edit-completion')&&title.includes('Completed Action'),title)   // the completion pane, not the completed Action
  const tabNames=(await panes().nth(completion).getByRole('button').allInnerTexts()).filter(Boolean)
  for(const tab of ['Completed Action','CTM','Slots','Print','Operations','Playground'])assert(tabNames.includes(tab),tab+' in '+tabNames.join('|'))
  await panes().nth(completion).getByRole('button',{name:'CTM',exact:true}).first().click()
  await panes().nth(completion).getByRole('heading',{name:`CTM of the completion of ${e3}`,exact:true}).waitFor()
  assert((await panes().nth(completion).innerText()).includes('completed-from(completed: the-completed-action, original: the-proposed-action) @derived'))
  await panes().nth(completion).getByText('the TMDM Topic Map',{exact:true}).first().click()
  await panes().nth(completion+1).locator('.inspector-title').filter({hasText:'TOPIC-MAP'}).first().waitFor()
  steps.push('… → Execution → Complete the Action with a date → the item-edit-completion pane (tabs '+tabNames.join(', ')+') → CTM → the TMDM Topic Map')
  // The tab Topicmap, right after CTM: the diagram at once, then real Inspector actions on it.
  const order=tabNames.slice(tabNames.indexOf('Completed Action',2));assert.deepEqual(order.slice(0,3),['Completed Action','CTM','Topicmap'],order.join('|'))
  const map=panes().nth(completion)
  await map.getByRole('button',{name:'Topicmap',exact:true}).first().click()
  await map.getByRole('heading',{name:`Topicmap of the completion of ${e3}`,exact:true}).waitFor()
  assert.equal(await map.locator('svg.dreyeck-topicmap-canvas').count(),1)
  for(const id of ['the-proposal','the-preview','the-proposed-action','the-completion','the-completed-action','the-expected-item','the-signed-body'])
    assert.equal(await map.locator(`.dreyeck-topicmap-topic[data-topic-id="${id}"]`).count(),1,id)
  assert.equal(await map.locator('.dreyeck-topicmap-topic[data-topic-id*="("]').count(),8,'eight Associations drawn as nodes')
  assert.equal(await map.locator('.dreyeck-topicmap-association').count(),16,'one edge for each Role')
  steps.push('Topicmap: seven objects, eight Association nodes, sixteen Role edges')
  const sign=id=>map.locator(`.dreyeck-topicmap-workspace-action[data-topic-id="${id}"]`)
  const pointAt=async id=>map.locator(`.dreyeck-topicmap-point-sign[data-topic-id="${id}"]`).waitFor()
  // 1. the-completion.  2. completed-from.
  await sign('the-completion').dispatchEvent('click');await pointAt('the-completion')
  const completedFrom='completed-from(completed=the-completed-action,original=the-proposed-action)'
  await sign(completedFrom).dispatchEvent('click');await pointAt(completedFrom)
  steps.push('Point → the-completion → completed-from')
  // 3. Its Roles completed and original; its class and its reason, which the Topic Map does not carry.
  text=await map.innerText()
  for(const expected of ['derived','Why HyperDoc states it','equal in every field but the date','The Topic Map carries the class as the Scope','completed','original','the-completed-action','the-proposed-action'])assert(text.includes(expected),expected)
  const roleRows=map.locator('tr.dreyeck-topicmap-workspace-association')
  assert.equal(await roleRows.count(),2)
  assert.deepEqual((await roleRows.locator('tt').allInnerTexts()).sort(),['completed','original'])
  steps.push('completed-from: Roles completed and original, class derived, reason shown')
  // 4. Follow each Role to its player.
  await map.locator('tr.dreyeck-topicmap-workspace-association[data-association-id$=":completed:the-completed-action"] .inspector-action').first().click()
  await pointAt('the-completed-action')
  await map.locator('tr.dreyeck-topicmap-workspace-association').first().waitFor()
  steps.push('Role completed → the-completed-action')
  // 5. To the Lisp object: the completed Action, which holds the date.
  await map.locator('p').filter({hasText:'Lisp object:'}).locator('.inspector-inspect').first().click()
  await panes().nth(completion+1).locator('.inspector-title').filter({hasText:'HASH-TABLE'}).first().waitFor()
  assert((await panes().nth(completion+1).innerText()).includes(String(date)))
  steps.push('the-completed-action → the Lisp object (its date)')
  // 6. The reason of the derived Association, found again; 7. back on the Topicmap, the Point goes on.
  await sign(completedFrom).dispatchEvent('click');await pointAt(completedFrom)
  assert((await map.innerText()).includes('equal in every field but the date'))
  await sign('the-proposed-action').dispatchEvent('click');await pointAt('the-proposed-action')
  assert((await map.innerText()).includes('An object of the Item edit'))
  steps.push('completed-from again (reason), then the-proposed-action: the Point goes on')
  // The Point's Topic as a pane: its Provenance, and the way back to the Topicmap.
  await map.locator('h3').filter({hasText:'Point'}).first().locator('xpath=following-sibling::p[1]').locator('.inspector-inspect').first().click()
  const topicPane=panes().nth(completion+1)
  await topicPane.getByRole('heading',{name:'the-proposed-action',exact:true}).waitFor()
  assert((await topicPane.innerText()).includes('Provenance in the HyperDoc projection'))
  await topicPane.getByText('Back to the Topicmap',{exact:true}).first().click()
  await panes().nth(completion+2).getByRole('heading',{name:`Topicmap of the completion of ${e3}`,exact:true}).waitFor()
  steps.push('the Point as a pane: Provenance → back to the Topicmap')
  // The schema Topics are not drawn and are listed.
  text=await map.innerText();for(const expected of ['association type','role type','occurrence type','scope: how a statement is known'])assert(text.includes(expected),expected)
  assert.equal(await map.locator('.dreyeck-topicmap-topic[data-topic-id="date"]').count(),0)
  steps.push('schema Topics: not drawn, listed')
  // TALA: the same projection laid out again, on request, with Inspector actions on its groups.
  await map.getByRole('button',{name:'Lay out with TALA',exact:true}).click()
  const tala=panes().nth(completion+1)
  await tala.locator('.inspector-title').filter({hasText:/TALA-RENDERING|PLIST|TALA/i}).first().waitFor({timeout:120000})
  const talaTabs=(await tala.getByRole('button').allInnerTexts()).filter(Boolean)
  if(talaTabs.includes('TALA (interactive)')){
   await tala.getByRole('button',{name:'TALA (interactive)',exact:true}).click()
   await tala.locator('svg g[data-topic-id="the-completed-action"]').waitFor()
   assert.equal(await tala.locator('svg g[data-topic-id]').count(),15)
   assert.equal(await tala.locator('svg g[data-association-id]').count(),16)
   await tala.locator('svg g[data-topic-id="the-completed-action"]').first().click()
   await panes().nth(completion+2).getByRole('heading',{name:'the-completed-action',exact:true}).waitFor()
   assert((await panes().nth(completion+2).innerText()).includes('Provenance in the HyperDoc projection'))
   steps.push('Lay out with TALA → TALA (interactive): 15 Topics, 16 Role edges, a click opens the Topic and its Provenance')
  }else steps.push('Lay out with TALA → no D2 here: '+talaTabs.join(', '))
  assert.equal(sha(pageFile),before)
 }
 await panes().nth(carrier).getByText('ctm-and-tmdm-in-hyperdoc',{exact:true}).first().click()
 await panes().nth(carrier+1).locator('.inspector-title').filter({hasText:'CTM and TMDM in HyperDoc'}).first().waitFor();steps.push('the linked FedWiki page → its local-fedwiki-page')
 // The same Item by the other way: Page source → E3. Each reading observes the file anew, so the two are equal in id, position,
 // source revision and content (the observation time aside), not the same object.
 await panes().nth(carrier+1).getByRole('button',{name:'Page source',exact:true}).first().click()
 await panes().nth(carrier+1).getByText('ed37e9bac2fcd548',{exact:true}).first().click()
 await panes().nth(carrier+2).getByRole('heading',{name:'Story Item ed37e9bac2fcd548',exact:true}).waitFor()
 assert.equal(await normalized(panes().nth(carrier+2)),viaLink);steps.push('Page source → E3: the same Item')
 await editPath(carrier+2);steps.push('Page source → E3 → Edit → Prepare edit proposal → Preview')
 if(servedSized){
  assert.deepEqual(errors,[]);assert.equal(sha(pageFile),before)
  fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',catalogSystem,servedSized,packages,development:false,policy:'ENFORCED',nothingWritten:true,steps},null,2))
  console.log('DOCUMENTATION-BROWSER-PASS (served-sized: '+packages+'): '+steps.join(' → ')+' | clicks '+JSON.stringify(readiness))
 }else{
  // back on the carrier page for the next link
  await panes().nth(carrier).getByText('Item Edit Path in HyperDoc',{exact:true}).first().click()
  await heading('Item Edit Path in HyperDoc')
  text=await last().innerText()
  for(const expected of ['The path and its objects','Three statements about an execution','ASDF systems','Operation','Known limits'])assert(text.includes(expected),expected)
  steps.push('Item Edit Path in HyperDoc')
  const docIndex=await panes().count()-1   // a captured index: last() would follow the newest pane
  // A link of the documentation pane opens its object in the pane to the right; a later link replaces that pane.
  const open=async(label,title)=>{await panes().nth(docIndex).locator('.inspector-inspect').filter({hasText:new RegExp('^'+label.replace(/[.*+?^${}()|[\]\\/]/g,'\\$&')+'$')}).first().click()   // the link, not a code word of the same text
   await panes().nth(docIndex+1).locator('.inspector-title').filter({hasText:title}).first().waitFor()}
  await open('item-edit-preview','ITEM-EDIT-PREVIEW');steps.push('item-edit-preview → the class')
  await open('execute-completed-edit','EXECUTE-COMPLETED-EDIT')
  await panes().nth(docIndex+1).getByRole('button',{name:'Source code',exact:true}).waitFor();steps.push('execute-completed-edit → the function, with its Source code')
  await open('edit-fedwiki-page-item','EDIT-FEDWIKI-PAGE-ITEM');steps.push('edit-fedwiki-page-item → the writer')
  await open('dreyeck/ctm-page-authoring/local','dreyeck/ctm-page-authoring/local');steps.push('the local system')
  assert.deepEqual(errors,[]);assert.equal(sha(pageFile),before);assert.deepEqual(fs.readdirSync(path.join(site,'pages')),['ctm-and-tmdm-in-hyperdoc'])
  fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',catalogSystem,packages,development:false,policy:'ENFORCED',nothingWritten:true,steps},null,2))
  console.log('DOCUMENTATION-BROWSER-PASS: '+steps.join(' → ')+' | clicks '+JSON.stringify(readiness))
 }
}catch(e){
 const pages=browser.contexts().flatMap(c=>c.pages());if(pages.length){fs.writeFileSync(path.join(output,'failure.txt'),await pages[0].locator('body').innerText());await pages[0].screenshot({path:path.join(output,'failure.png')})}
 throw e
}finally{
 await browser.close();fs.writeFileSync(stop,'')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.rmSync(temp,{recursive:true,force:true})
}
