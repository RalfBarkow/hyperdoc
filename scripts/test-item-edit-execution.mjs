// A previewed Item edit, authorized, executed, persisted and verified, in an actual served Catalog
// (development off, policy enforced) on a TEMPORARY copy of the retained page. The real wiki store
// of localhost:3000 and the retained evidence copy are never written.
//   /view → Page source → E3 → Edit → Prepare edit proposal → Edit proposal → Preview
//   → tab Execution → Complete the Action → (a signed request is attached by trusted code, as an
//   operator's tooling would, outside the browser) → Execute → Execution → Verify in a new process
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
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),'..')
const evidence=path.join(root,'dreyeck/work/ctm-page-evidence/site/pages/ctm-and-tmdm-in-hyperdoc')
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')
const observed='d7215c50f4efa07b3e94749b060b7d7b828654f2a44caab7f1034415c6003dff'
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'item-edit-execution-browser-'))
const site=path.join(temp,'site'),pageFile=path.join(site,'pages','ctm-and-tmdm-in-hyperdoc')
fs.mkdirSync(path.dirname(pageFile),{recursive:true});fs.copyFileSync(evidence,pageFile)
assert.equal(sha(pageFile),observed);assert.equal(sha(evidence),observed)
const port=await new Promise(r=>{const s=net.createServer();s.listen(0,'127.0.0.1',()=>{const p=s.address().port;s.close(()=>r(p))})})
const stop=path.join(temp,'stop'),flag=path.join(temp,'sign.request'),script=path.join(temp,'witness.lisp'),log=path.join(output,'lisp.log')
const topicMapsRoot=process.env.TOPIC_MAPS_ROOT   // only needed when CATALOG_SYSTEM names a system that reads topic-maps
fs.writeFileSync(script,`(require :asdf)
${topicMapsRoot?`(pushnew #p${JSON.stringify(topicMapsRoot.endsWith('/')?topicMapsRoot:topicMapsRoot+'/')} asdf:*central-registry* :test (function equal))`:''}
(asdf:load-system "dreyeck/catalog-application")
(asdf:load-system "dreyeck/fedwiki-item-edit-execution/tests")
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1" :site-root ${JSON.stringify(site+'/')}
 :catalog-system ${JSON.stringify(process.env.CATALOG_SYSTEM||"dreyeck/fedwiki-item-edit-execution")} :development nil)
(assert (dreyeck/authority-policy:policy-enforced-p))
;; What an operator's tooling would do, outside the browser: hold a principal and its key, and sign.
(defvar *completion* nil)
(defvar *capabilities* 0)
(sb-int:encapsulate 'dreyeck/fedwiki-item-edit-execution:complete-item-edit 'capture
                    (lambda (function &rest arguments) (setf *completion* (apply function arguments))))
(sb-int:encapsulate 'dreyeck/fedwiki-page-authoring:make-fedwiki-page-authoring-capability 'count
                    (lambda (function &rest arguments) (incf *capabilities*) (apply function arguments)))
(defvar *principal* (dreyeck/fedwiki-item-edit-execution/tests::make-principal (truename ${JSON.stringify(site+'/')})))
(format t "~&EXECUTION-BROWSER-READY capabilities=~D~%" *capabilities*) (finish-output)
(unwind-protect
    (loop repeat 9000 until (probe-file #p"${stop}")
          do (when (probe-file #p"${flag}")
               (delete-file #p"${flag}")
               (dreyeck/fedwiki-item-edit-execution:attach-signed-request
                *completion* (getf *principal* :authority)
                (dreyeck/fedwiki-item-edit-execution/tests::signed-request *principal* *completion*))
               (format t "~&EXECUTION-BROWSER-ATTACHED capabilities=~D~%" *capabilities*) (finish-output))
             (sleep .1))
  (clog:shutdown))`)
const fd=fs.openSync(log,'w'),child=spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
const logText=()=>fs.readFileSync(log,'utf8')
const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
const browser=await chromium.launch({headless:true,executablePath:chrome})
const steps=[]
try{
 for(let n=0;n<6000;n++){if(child.exitCode!==null)throw Error(logText().slice(-4000));if(logText().includes('EXECUTION-BROWSER-READY'))break;await new Promise(r=>setTimeout(r,100))}
 assert(logText().includes('EXECUTION-BROWSER-READY capabilities=0'),'no capability exists before any request')
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(60000);installBoundClicks(page)
 const errors=[];page.on('pageerror',e=>errors.push(e.message))
 const panes=()=>page.locator('.inspector-pane')
 const last=()=>panes().last()
 const click=async label=>last().getByText(label,{exact:true}).first().click()
 const tab=async label=>last().getByRole('button',{name:label,exact:true}).first().click()
 const heading=async label=>last().getByRole('heading',{name:label,exact:true}).waitFor()
 const e3='ed37e9bac2fcd548'
 await page.goto(`http://127.0.0.1:${port}/view/ctm-and-tmdm-in-hyperdoc`)
 await last().locator('.inspector-title').filter({hasText:'CTM and TMDM in HyperDoc'}).first().waitFor()
 await tab('Page source');await last().getByText(observed,{exact:true}).first().waitFor()
 await last().getByText(e3,{exact:true}).first().click();await heading(`Story Item ${e3}`)
 await tab('Edit');await click('Prepare edit proposal');await heading(`Edit proposal for ${e3}`)
 const proposed='E3 — Darstellung: execution browser test text, not a decision.'
 const input=last().locator('input').first()
 await input.fill(proposed);await input.dispatchEvent('change');await page.waitForTimeout(500)
 await click('Preview');await heading(`Preview: edit of ${e3}`)
 const previewIndex=await panes().count()-1,previewPane=panes().nth(previewIndex)
 steps.push('E3 → Edit → Prepare edit proposal → Preview')
 // Previewed, and nothing more.
 await previewPane.getByRole('button',{name:'Execution',exact:true}).first().click()
 await previewPane.getByRole('heading',{name:'From this preview to an executed edit',exact:true}).waitFor()
 let text=await previewPane.innerText()
 for(const expected of ['It is not authorized, executed or persisted','has no date, and it stays as it is','Complete the Action with a date'])assert(text.includes(expected),expected)
 assert.equal(sha(pageFile),observed)
 await previewPane.getByRole('button',{name:'Complete the Action with a date',exact:true}).click()
 const completionPane=panes().nth(previewIndex+1)
 await completionPane.getByRole('heading',{name:'The Action that would be authorized',exact:true}).waitFor()
 text=await completionPane.innerText()
 for(const expected of ['The previewed Action','has no date','is a copy with date added','milliseconds since 1970-01-01 UTC','Everything else equals the proposed Action: checked, equal.','To authorize:'])assert(text.includes(expected),expected)
 assert.equal(await completionPane.getByRole('button',{name:'Execute the attached signed request'}).count(),0)
 assert.equal(sha(pageFile),observed)
 steps.push('Execution tab → completed Action: a copy with a date, not an authorization')
 // CTM: the completion as CTM, read back with the topic-maps reader as TMDM objects (only where the local system is served).
 if(process.env.CATALOG_SYSTEM==='dreyeck/ctm-page-authoring/local'){
  await completionPane.getByRole('button',{name:'CTM',exact:true}).first().click()
  await completionPane.getByRole('heading',{name:`CTM of the completion of ${e3}`,exact:true}).waitFor()
  text=await completionPane.innerText()
  for(const expected of ['the-completed-action isa edit-action','date: ','proposes(proposal: the-proposal, action: the-proposed-action) @derived','previews(preview: the-preview, action: the-proposed-action) @observed',
    'completed-from(completed: the-completed-action, original: the-proposed-action) @derived','contains(body: the-signed-body, content: the-expected-item) @derived','A completion is not an authorization.','request-attached: "no"','not stored'])assert(text.includes(expected),expected)
  assert(!/authorized: |executed: |persisted: /.test(text))
  assert.equal(sha(pageFile),observed)
  // The date in the CTM is the completion's: it is found again, below, in the completed Action itself.
  const date=text.match(/date: (\d+)/)[1]
  steps.push('Completed Action → CTM: parsed text, observed and derived relations')
  await completionPane.getByText('The derived projection: its Topics, Associations and the Lisp objects they stand for',{exact:true}).first().click()
  const projectionPane=panes().nth(previewIndex+2)
  await projectionPane.getByRole('heading',{name:`CTM of the completion of ${e3}`,exact:true}).waitFor()
  text=await projectionPane.innerText()
  for(const expected of ['Topics for the objects of the Item edit','the-completed-action','the-proposed-action','the-signed-body','Associations and Roles','completed-from','observed: COMPLETION-ACTION'])assert(text.includes(expected),expected)
  assert(await projectionPane.getByText('TMDM Association',{exact:true}).count()>=8)
  assert(await projectionPane.getByText('TMDM Role',{exact:true}).count()>=16)
  steps.push('CTM → the projection: Topics, Associations, Roles and the Lisp objects')
  await projectionPane.getByText('the TMDM Topic Map',{exact:true}).first().click()
  await panes().nth(previewIndex+3).locator('.inspector-title').filter({hasText:'TOPIC-MAP'}).first().waitFor()
  steps.push('the projection → the TMDM Topic Map')
  await projectionPane.getByText('TMDM Topic',{exact:true}).first().click()
  await panes().nth(previewIndex+3).locator('.inspector-title').filter({hasText:'TOPIC'}).first().waitFor()
  steps.push('the projection → a TMDM Topic')
  // Back to the Lisp object: the completed Action itself, by the projection's own binding.
  await projectionPane.locator('tr').filter({hasText:'the-completed-action'}).first().locator('.inspector-inspect').last().click()
  await panes().nth(previewIndex+3).locator('.inspector-title').filter({hasText:'HASH-TABLE'}).first().waitFor()
  assert((await panes().nth(previewIndex+3).innerText()).includes(String(date)))
  steps.push('the projection → the completed Action, the Lisp object')
  assert.equal(sha(pageFile),observed)
  await completionPane.getByRole('button',{name:'Completed Action',exact:true}).last().click()   // the tab; the title is a button too
  await completionPane.getByRole('heading',{name:'The Action that would be authorized',exact:true}).waitFor()
 }
 // Trusted code, outside the browser, attaches a request signed by a registered principal.
 fs.writeFileSync(flag,'')
 for(let n=0;n<300&&!logText().includes('EXECUTION-BROWSER-ATTACHED');n++)await new Promise(r=>setTimeout(r,100))
 assert(logText().includes('EXECUTION-BROWSER-ATTACHED capabilities=0'),'attaching a request makes no capability')
 assert.equal(sha(pageFile),observed)
 // The pane's own refresh button evaluates its views again.
 await completionPane.locator('.inspector-title-bar .inspector-button').first().click()
 await page.waitForTimeout(800)
 await completionPane.getByRole('heading',{name:'The Action that would be authorized',exact:true}).waitFor()
 text=await completionPane.innerText()
 assert(text.includes('a signed request is attached; it has not been checked yet'));assert(text.includes('Attaching grants nothing.'))
 steps.push('a signed request attached by trusted code: shown as not yet checked')
 // Executed by an explicit click.
 await completionPane.getByRole('button',{name:'Execute the attached signed request',exact:true}).click()
 const executionPane=panes().nth(previewIndex+2)
 await executionPane.getByRole('heading',{name:`Executed edit of ${e3}`,exact:true}).waitFor()
 assert(logText().includes('capabilities=0'))
 assert.notEqual(sha(pageFile),observed)
 const saved=JSON.parse(fs.readFileSync(pageFile,'utf8')),original=JSON.parse(fs.readFileSync(evidence,'utf8'))
 assert.equal(saved.story.length,18);assert.equal(saved.journal.length,3)
 assert.deepEqual(saved.story.filter((item,i)=>JSON.stringify(item)!==JSON.stringify(original.story[i])).map(item=>item.id),[e3])
 const entry=saved.journal[2]
 assert.equal(entry.type,'edit');assert.equal(entry.id,e3);assert.equal(typeof entry.date,'number');assert.deepEqual(Object.keys(entry),['type','id','item','date'])
 assert.equal(entry.item.text,proposed);assert.equal(saved.story[10].text,proposed)
 assert.deepEqual(saved.journal.slice(0,2),original.journal)
 assert.equal(sha(evidence),observed)
 text=await executionPane.innerText()
 for(const expected of ['proposed','previewed','authorized','executed','persisted','verified','Authorized by the authenticated principal','Executed by edit-fedwiki-page-item','Persisted: the page file was read again','3 journal entries','not yet. A new process has not read the file.'])assert(text.includes(expected),expected)
 assert.equal((await executionPane.locator('tr').filter({hasText:/^verified/}).innerText()).includes('no, not shown'),true)
 steps.push('Execute → executed, persisted; verified not yet claimed')
 // The objects, one click each.
 await executionPane.getByText('the page edit',{exact:true}).click();await page.waitForTimeout(700)
 let pane=panes().nth(previewIndex+3)
 assert((await pane.locator('.inspector-title').first().innerText()).toLowerCase().includes('fedwiki-page-edit'))
 await pane.getByRole('button',{name:'Executed edit',exact:true}).first().click()
 await pane.getByRole('heading',{name:`Executed edit of ${e3} on ctm-and-tmdm-in-hyperdoc`,exact:true}).waitFor()
 text=await pane.innerText()
 for(const expected of ['the Action','the previous Item','the page source','the journal entry'])assert(text.includes(expected),expected)
 steps.push('fedwiki-page-edit → the Action, the previous Item, the persisted page, its journal entry')
 await pane.getByText('the journal entry',{exact:true}).click();await page.waitForTimeout(700)
 assert((await panes().nth(previewIndex+4).innerText()).includes('edit'))
 await executionPane.getByText('edit-fedwiki-page-item',{exact:true}).first().click()
 pane=panes().nth(previewIndex+3)
 await pane.locator('.inspector-title').filter({hasText:'edit-fedwiki-page-item'}).waitFor()
 await pane.getByRole('button',{name:'Source code',exact:true}).waitFor()
 steps.push('edit-fedwiki-page-item → the function, with its Source code')
 // Verified, by a new process, on an explicit click.
 await executionPane.getByRole('button',{name:'Verify in a new process',exact:true}).click()
 await panes().nth(previewIndex+3).getByRole('heading',{name:'Verified in a new process',exact:true}).waitFor({timeout:120000})
 text=await panes().nth(previewIndex+3).innerText()
 for(const expected of ['changed-ids','new-entry-equals-completed-action','sha256'])assert(text.includes(expected),expected)
 steps.push('Verify → verified in a new process')
 assert.equal(sha(pageFile),sha(pageFile));assert.deepEqual(errors,[])
 assert.equal(sha(evidence),observed);assert.deepEqual(fs.readdirSync(path.dirname(pageFile)),['ctm-and-tmdm-in-hyperdoc'])
 await page.screenshot({path:path.join(output,'execution.png'),fullPage:false})
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',browser:browser.version(),development:false,policy:'ENFORCED',temporaryCopyOnly:true,steps},null,2))
 console.log('EXECUTION-BROWSER-PASS: '+steps.join(' → ')+' | clicks '+JSON.stringify(readiness))
}catch(e){
 const pages=browser.contexts().flatMap(c=>c.pages());if(pages.length){fs.writeFileSync(path.join(output,'failure.txt'),await pages[0].locator('body').innerText());await pages[0].screenshot({path:path.join(output,'failure.png')})}
 throw e
}finally{
 await browser.close();fs.writeFileSync(stop,'')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.rmSync(temp,{recursive:true,force:true})
}
