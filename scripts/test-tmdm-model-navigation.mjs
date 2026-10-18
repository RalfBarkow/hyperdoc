// Isolated real Catalog/Inspector. node THIS SBCL PLAYWRIGHT_DIRECTORY CHROME OUTPUT
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import crypto from 'node:crypto'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,pw,chrome,output]=process.argv.slice(2)
if(!output || !process.env.TOPIC_MAPS_ROOT)throw Error('SBCL PLAYWRIGHT_DIRECTORY CHROME OUTPUT and TOPIC_MAPS_ROOT required')
fs.mkdirSync(output,{recursive:true})
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),'..')
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'tmdm-browser-'))
const stop=path.join(temp,'stop'),script=path.join(temp,'browser.lisp'),eqLog=path.join(temp,'eq.log')
const sourceFiles=['dreyeck/pages/work/Work Breakdown.html','dreyeck/pages/work/Authoring the CTM Plan Page.html','dreyeck/pages/work/CTM Plan Page WBS Dictionary.html']
const sha=f=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,f))).digest('hex')
const before=sourceFiles.map(sha)
fs.mkdirSync(path.join(temp,'site','pages'),{recursive:true})
const socket=net.createServer();await new Promise(r=>socket.listen(0,'127.0.0.1',r))
const port=socket.address().port;await new Promise(r=>socket.close(r))
const q=x=>JSON.stringify(x)
fs.writeFileSync(script,`(load ${q(path.join(root,'scripts/tmdm-model-bootstrap.lisp'))})
(asdf:load-system "dreyeck/catalog-application")
(defvar *browser-seen* (make-hash-table :test #'eq))
(defvar *retained-browser-name* nil)
(defun browser-proof (tag)
 (with-open-file (s ${q(eqLog)} :direction :output :if-exists :append :if-does-not-exist :create) (format s "~A~%" tag)))
;; Test instrumentation observes actual Pane targets. It never substitutes them.
(defmethod clog-moldable-inspector::add-pane :after
 ((inspector clog-moldable-inspector::inspector) (pane clog-moldable-inspector::pane))
 (declare (ignore inspector))
 (let ((object (clog-moldable-inspector::pane-object pane)))
  (when (gethash object *browser-seen*) (browser-proof "REVISIT-EQ"))
  (setf (gethash object *browser-seen*) t)
  (typecase object
   (topic-maps.tmdm:topic-map
    (assert (every (lambda (topic) (eq object (topic-maps.tmdm:topic-parent topic))) (topic-maps.tmdm:topic-map-topics object)))
    (browser-proof "MAP-EQ"))
   (topic-maps.tmdm:topic
    (assert (member (topic-maps.tmdm:canonical-topic object)
                    (topic-maps.tmdm:topic-map-topics (topic-maps.tmdm:topic-parent object)) :test #'eq))
    (browser-proof "TOPIC-EQ"))
   (topic-maps.tmdm:topic-name
    (let ((name (topic-maps.tmdm:canonical-topic-name object)))
     (assert (member name (topic-maps.tmdm:topic-names (topic-maps.tmdm:topic-name-parent object)) :test #'eq))
     (assert (member (topic-maps.tmdm:topic-name-type object)
                     (topic-maps.tmdm:topic-map-topics (topic-maps.tmdm:topic-parent (topic-maps.tmdm:topic-name-parent object))) :test #'eq))
     (browser-proof "NAME-PARENT-TYPE-EQ")
     (when (eq object *retained-browser-name*)
      (assert (not (eq object name))) (browser-proof "RETAINED-NAME-EQ"))))
   (dreyeck/git:git-file-at-commit
    (maphash (lambda (map records) (declare (ignore map))
      (dolist (run records)
       (when (eq object (dreyeck/work/tmdm-reading:run-source run)) (browser-proof "SOURCE-EQ"))
       (when (eq object (dreyeck/work/tmdm-reading:run-baseline run)) (browser-proof "BASELINE-EQ"))))
      dreyeck/inspector/tmdm::*executions-by-map*)))
  (when (eq object #'topic-maps.tmdm:add-name) (browser-proof "DEFINITION-EQ"))))
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1" :site-root ${q(temp+'/site/')} :development t)
(assert (not (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING")))
;; Only this test process has this fixture route. Production has no new route.
(let* ((map (topic-maps.tmdm:make-topic-map))
       (a (topic-maps.tmdm:intern-topic map :item-identifier "urn:fixture:a"))
       (b (topic-maps.tmdm:intern-topic map :item-identifier "urn:fixture:b"))
       (x (topic-maps.tmdm:intern-topic map :item-identifier "urn:fixture:x"))
       (y (topic-maps.tmdm:intern-topic map :item-identifier "urn:fixture:y")))
 (setf *retained-browser-name* (topic-maps.tmdm:add-name a "Retained Name" :type x))
 (topic-maps.tmdm:add-name b "Retained Name" :type y)
 (topic-maps.tmdm:merge-topics a b) (topic-maps.tmdm:merge-topics x y)
 (clog:set-on-new-window (lambda (body)
  (clog-moldable-inspector:on-new-inspector body :object *retained-browser-name* :pane-width "700px" :playground? nil))
  :path "/tmdm-browser-fixture"))
(format t "~&TMDM-BROWSER-READY writer=ABSENT~%") (finish-output)
(unwind-protect (loop repeat 6000 until (probe-file ${q(stop)}) do (sleep .1)) (clog:shutdown))`)
const log=path.join(output,'browser-lisp.log'),fd=fs.openSync(log,'w')
const child=spawn('/usr/bin/sandbox-exec',['-p','(version 1)(allow default)(deny network*)(allow network-inbound (local ip \"localhost:*\"))(allow network-outbound (remote ip \"localhost:*\"))',lisp,'--noinform','--no-sysinit','--no-userinit','--script',script],{cwd:root,stdio:['ignore',fd,fd]})
let browser
const steps=[]
const until=async(fn,why)=>{for(let n=0;n<250;n++){if(await fn())return;await new Promise(r=>setTimeout(r,100))}throw Error(why)}
try{
 let ready=false
 for(let n=0;n<2400;n++){
  if(child.exitCode!==null)throw Error(fs.readFileSync(log,'utf8').slice(-3500))
  if(fs.readFileSync(log,'utf8').includes('TMDM-BROWSER-READY')){ready=true;break}
  await new Promise(r=>setTimeout(r,100))
 }
 assert(ready,'fresh Lisp server did not become ready')
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch({headless:true,executablePath:chrome,args:['--disable-background-networking']})
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(25000)
 const errors=[];page.on('pageerror',e=>errors.push(e.message))
 const last=()=>page.locator('.inspector-pane').last()
 const tab=async label=>last().getByRole('button',{name:label,exact:true}).first().click()
 const heading=async label=>last().getByRole('heading',{name:label,exact:true}).waitFor()
 const click=async(label,options={})=>last().getByText(label,{exact:true}).first().click(options)
 const contains=async value=>{await last().getByText(value,{exact:false}).first().waitFor()}
 const pane=async()=>page.locator(`[id="${await last().getAttribute('id')}"]`)
 await page.goto(`http://127.0.0.1:${port}/`)
 await page.getByText('Working on HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
 await tab('Text pages')
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'Work Breakdown'}).last().click()
 await heading('Work Breakdown');await tab('TMDM model')
 await click('ctm-plan-page-authoring');await heading('Topic → Name → Type Topic')
 const workPane=await pane();steps.push('Catalog → Work Breakdown → existing Work Topic')
 for(const explicit of [false,true]){
  await workPane.getByRole('button',{name:explicit?'Read explicit-type example':'Read default-type example',exact:true}).click()
  await heading('TMDM Topic Map')
  await click('Topic #topic');await heading('Topic #topic')
  await click('Topic Name "Name"');await heading('TMDM Topic Name');const namePane=await pane()
  await page.screenshot({path:path.join(output,explicit?'explicit-name.png':'default-name.png'),fullPage:false})
  await click(explicit?'Topic #nametype':'Default name type')
  await heading(explicit?'Topic #nametype':'Default name type')
  const typePane=await pane()
  const typeBody=await last().innerText()
  assert(typeBody.includes(explicit?'#nametype':'http://psi.topicmaps.org/iso13250/model/topic-name'))
  steps.push((explicit?'Explicit':'Default')+': Map → Topic → Name → actual Type Topic')
  // Revisit the same live Map via an actual Parent reference; after-method checks EQ.
  await click('Parent Topic Map');await heading('TMDM Topic Map')
  // Shift navigation preserves the existing Lineup; this is native pane history.
  const count=await page.locator('.inspector-pane').count()
  await namePane.getByText(explicit?'Topic #nametype':'Default name type',{exact:true}).first().click({modifiers:['Shift']})
  await heading(explicit?'Topic #nametype':'Default name type')
  await until(async()=>await page.locator('.inspector-pane').count()===count+1,'Shift navigation did not preserve Lineup')
  assert(await typePane.count()===1,'earlier Type pane survives Shift navigation')
  steps.push('Native Lineup: same-object revisit and Shift-preserved history')
  await namePane.getByRole('button',{name:'Definitions',exact:true}).click()
  await namePane.getByText('add-name',{exact:true}).first().click({modifiers:['Shift']})
  await tab('Source code');await last().locator('pre').first().waitFor()
  assert((await last().innerText()).includes('add-name'))
  steps.push('Actual loaded add-name function → Source code')
  await namePane.getByRole('button',{name:'Evidence',exact:true}).click()
  await namePane.locator('.inspector-inspect:visible').filter({hasText:'checked here'}).first().click({modifiers:['Shift']})
  await heading('CTM → TMDM → CXTM execution');const runPane=await pane()
  let text=await last().innerText();assert(text.includes('outcome PASS'));assert(text.includes('not executed here'))
  await click('CTM source at commit');await tab('Contents')
  await contains(explicit?'nametype':'Name')
  await runPane.getByText('Executed CXTM result',{exact:true}).click({modifiers:['Shift']})
  await contains('<topicMap>');const outputText=await last().innerText();assert(outputText.includes('<topicMap>'))
  if(explicit)assert(outputText.includes('<type topicref="1">'))
  await runPane.getByText('Baseline at commit',{exact:true}).click({modifiers:['Shift']})
  await tab('Contents');await contains('<topicMap>')
  await runPane.getByText('Stored Slice 12A evidence — not executed here',{exact:true}).click({modifiers:['Shift']})
  await tab('Contents');await contains('startedAtUTC')
  await runPane.getByText('Derived interpretation and clauses',{exact:true}).click({modifiers:['Shift']})
  await tab('Contents');await contains('CTM 3.11')
  steps.push('Object → Evidence → pinned CTM source / actual CXTM / original baseline / stored evidence / derived interpretation')
  await runPane.getByText('Runtime and revisions',{exact:true}).click({modifiers:['Shift']})
  await tab('Items');await contains(/inferred-from-matching-asdf-checkout/i)
  steps.push('Runtime context: observed execution and inferred revision binding separated')
 }
 // Existing Work Workspace history is independent of the model/Lineup.
 await workPane.getByText('Existing Work Workspace',{exact:true}).click()
 await last().locator('.dreyeck-topicmap-point-sign').waitFor()
 for(const id of ['ctm-plan-page-authoring','fedwiki-item-authoring']){
  await last().locator(`.dreyeck-topicmap-workspace-action[data-topic-id="${id}"]`).last().dispatchEvent('click')
  await last().locator(`.dreyeck-topicmap-point-sign[data-topic-id="${id}"]`).waitFor()
 }
 await tab('Slots')
 await last().getByRole('row').filter({hasText:/^history/i}).first().locator('td').last().click()
 await tab('Items')
 const history=await last().innerText();assert(history.includes('ctm-plan-page-authoring'));assert(history.includes('connections-example'))
 steps.push('Existing Work Workspace Point/History')
 await page.goto(`http://127.0.0.1:${port}/tmdm-browser-fixture`)
 await heading('TMDM Topic Name');assert((await last().innerText()).includes('Retained handle'))
 const retainedId=await last().getAttribute('id')
 await click('Canonical Name')
 await until(async()=>await last().getAttribute('id')!==retainedId,'canonical Name pane did not open')
 await heading('TMDM Topic Name')
 assert(!(await last().innerText()).includes('Retained handle'))
 await click('Topic urn:fixture:x');await heading('Topic urn:fixture:x')
 steps.push('Retained Name handle → canonical Name → canonical Type Topic')
 await page.screenshot({path:path.join(output,'retained-name.png'),fullPage:false})
 const eq=fs.readFileSync(eqLog,'utf8').trim().split('\n')
 for(const tag of ['MAP-EQ','TOPIC-EQ','NAME-PARENT-TYPE-EQ','RETAINED-NAME-EQ','REVISIT-EQ','SOURCE-EQ','BASELINE-EQ','DEFINITION-EQ'])assert(eq.includes(tag),tag)
 assert.deepEqual(errors,[]);assert.deepEqual(sourceFiles.map(sha),before)
 fs.writeFileSync(path.join(output,'browser-result.json'),JSON.stringify({status:'PASS',browser:browser.version(),freshLisp:true,
  development:true,host:'127.0.0.1',externalBrowserRequests:'blocked',writer:'ABSENT',steps,
  eqObservations:eq,sourcesUnchanged:true,fixtureRoute:'test process only; not an application route'},null,2)+'\n')
 console.log('TMDM-BROWSER-PASS: '+steps.join(' → '))
}catch(e){
 fs.writeFileSync(path.join(output,'failed-steps.json'),JSON.stringify(steps,null,2))
 if(browser){const pages=browser.contexts().flatMap(c=>c.pages());if(pages.length){fs.writeFileSync(path.join(output,'browser-failure.txt'),await pages[0].locator('body').innerText());await pages[0].screenshot({path:path.join(output,'browser-failure.png')})}}
 throw e
}finally{
 if(browser)await browser.close();fs.writeFileSync(stop,'')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.closeSync(fd);fs.rmSync(temp,{recursive:true,force:true})
}
