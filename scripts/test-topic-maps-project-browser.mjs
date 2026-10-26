// Real local Catalog/Inspector, using an already installed Playwright and Chrome.
// node THIS SBCL PLAYWRIGHT_DIRECTORY CHROME OUTPUT; no dependency installation.
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import crypto from 'node:crypto'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,pw,chrome,output]=process.argv.slice(2)
assert(output && process.env.TOPIC_MAPS_ROOT)
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),'..')
fs.mkdirSync(output,{recursive:true})
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'hyperdoc-project-22u-browser-'))
fs.mkdirSync(path.join(temp,'site','pages'),{recursive:true})
const stop=path.join(temp,'stop'),proof=path.join(output,'native-eq.log'),script=path.join(temp,'browser.lisp')
const sock=net.createServer();await new Promise(r=>sock.listen(0,'127.0.0.1',r));const port=sock.address().port;await new Promise(r=>sock.close(r))
const q=JSON.stringify
const source=path.join(process.env.TOPIC_MAPS_ROOT,'examples/project-work.ctm')
const digest=()=>crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex')
const before=digest()
fs.writeFileSync(script,`(load ${q(path.join(root,'scripts/topic-maps-project-bootstrap.lisp'))})
(asdf:load-system "dreyeck/catalog-application")
(defvar *browser-map* nil)
(defvar *browser-state* nil)
(defun browser-proof (tag)
 (with-open-file (s ${q(proof)} :direction :output :if-exists :append :if-does-not-exist :create) (format s "~A~%" tag)))
;; Observe real Pane targets only. Never replace an Inspector object or model.
(defmethod clog-moldable-inspector::add-pane :after
 ((inspector clog-moldable-inspector::inspector) (pane clog-moldable-inspector::pane))
 (declare (ignore inspector))
 (let* ((object (clog-moldable-inspector::pane-object pane))
        (map (typecase object
          (topic-maps.tmdm:topic-map object)
          (topic-maps.tmdm:topic (topic-maps.tmdm:topic-parent object))
          (topic-maps.tmdm:association (topic-maps.tmdm:association-parent object))
          (topic-maps.tmdm:association-role
           (topic-maps.tmdm:association-parent (topic-maps.tmdm:association-role-parent object))))))
  (when map
   (unless *browser-map*
    (setf *browser-map* map *browser-state* (topic-maps.project-work.example:model-view map)))
   (assert (eq map *browser-map*))
   (assert (equal *browser-state* (topic-maps.project-work.example:model-view map)))
   (assert (topic-maps.project-work.example:references-current-p map))
   (typecase object
    (topic-maps.tmdm:topic-map (browser-proof "MAP-EQ"))
    (topic-maps.tmdm:topic
     (assert (eq object (topic-maps.tmdm:canonical-topic object)))
     (cond ((eq object (topic-maps.project-work.example:find-topic map "urn:topic-maps:project")) (browser-proof "PROJECT-EQ"))
           ((eq object (topic-maps.project-work.example:find-topic map "urn:topic-maps:question:Q-XTM-LOOP")) (browser-proof "QUESTION-EQ"))
           ((eq object (topic-maps.project-work.example:local-topic map "disposition")) (browser-proof "DISPOSITION-EQ"))))
    (topic-maps.tmdm:association
     (assert (eq object (topic-maps.tmdm:canonical-association object))) (browser-proof "ASSOCIATION-EQ"))
    (topic-maps.tmdm:association-role
     (assert (eq object (topic-maps.tmdm:canonical-association-role object)))
     (assert (member object (topic-maps.tmdm:topic-roles-played (topic-maps.tmdm:association-role-player object)) :test #'eq))
     (browser-proof "ROLE-TYPE-PLAYER-INVERSE-EQ"))))))
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1" :site-root ${q(temp+'/site/')} :development t)
(assert (not (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING")))
(format t "~&PROJECT-22U-BROWSER-READY writer=ABSENT~%") (finish-output)
(unwind-protect (loop repeat 6000 until (probe-file ${q(stop)}) do (sleep .1)) (clog:shutdown))`)
const policy=`(version 1)(allow default)(deny network*)(allow network-inbound (local ip "localhost:*"))(allow network-outbound (remote ip "localhost:*"))(deny file-write* (subpath ${q(root)}))(deny file-write* (subpath ${q(process.env.TOPIC_MAPS_ROOT)}))`
const log=path.join(output,'browser-lisp.log'),fd=fs.openSync(log,'w')
const args=['-p',policy,lisp,'--noinform','--no-sysinit','--no-userinit','--script',script]
const child=spawn('/usr/bin/sandbox-exec',args,{cwd:root,stdio:['ignore',fd,fd],env:{...process.env,HYPERDOC_22U_FASL_ROOT:path.join(temp,'fasls')}})
let browser,success=false,failure=null
const steps=[],started=new Date().toISOString()
try {
 let ready=false
 for(let n=0;n<2400;n++){
  if(child.exitCode!==null)throw Error(fs.readFileSync(log,'utf8').slice(-5000))
  if(fs.readFileSync(log,'utf8').includes('PROJECT-22U-BROWSER-READY')){ready=true;break}
  await new Promise(r=>setTimeout(r,100))
 }
 assert(ready,'fresh local Catalog did not become ready')
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch({headless:true,executablePath:chrome,args:['--disable-background-networking']})
 const context=await browser.newContext({serviceWorkers:'block'})
 const origin=`http://127.0.0.1:${port}`
 await context.route('**/*',r=>new URL(r.request().url()).origin===origin?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(25000)
 const last=()=>page.locator('.inspector-pane').last()
 const tab=async title=>last().getByRole('button',{name:title,exact:true}).first().click()
 const click=async label=>last().getByText(label,{exact:true}).first().click()
 const heading=async title=>last().getByRole('heading',{name:title,exact:true}).waitFor()
 await page.goto(origin)
 await page.getByText('Topic Maps Project Example (22U)',{exact:true}).and(page.locator(':visible')).first().click()
 await tab('Text pages')
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'Reading Slice 22U'}).last().click()
 await heading('Reading Slice 22U');await tab('Topic Maps 22U')
 await last().getByRole('button',{name:'Read a fresh 22U Map',exact:true}).click()
 await heading('TMDM Topic Map');steps.push('Catalog → Reading Slice 22U → explicit execution → native Map')
 for(const [relation,nextRole,target,tag] of [
  ['Betrifft','Arbeit','project','PROJECT-EQ'],
  ['Dokumentiert durch','Dokumentierte Quelle','disposition','DISPOSITION-EQ']]) {
  await click('Topic #question');await heading('Topic #question');await tab('Roles')
  await click(`Role Gegenstand in ${relation}`);await heading('Native Association Role')
  await click('Parent Association');await heading('Native Association')
  await click(`Role ${nextRole} in ${relation}`);await heading('Native Association Role')
  await click('Role Player');await heading(`Topic #${target}`)
  assert(fs.readFileSync(proof,'utf8').includes(tag),'actual native Pane target EQ proof missing')
  await page.screenshot({path:path.join(output,`${target}.png`),fullPage:false})
  steps.push(`Question → native Roles → ${relation} Association → native Role Player → ${target}`)
  await click('Parent Topic Map');await heading('TMDM Topic Map')
 }
 const tags=fs.readFileSync(proof,'utf8').split('\n')
 for(const t of ['MAP-EQ','QUESTION-EQ','ROLE-TYPE-PLAYER-INVERSE-EQ','ASSOCIATION-EQ','PROJECT-EQ','DISPOSITION-EQ'])assert(tags.includes(t),t)
 assert.equal(digest(),before);success=true
} catch(e) {failure=String(e.stack||e);console.error(failure)}
finally {
 if(browser)await browser.close()
 fs.writeFileSync(stop,'stop')
 for(let n=0;n<100&&child.exitCode===null;n++)await new Promise(r=>setTimeout(r,100))
 if(child.exitCode===null)child.kill('SIGTERM')
 fs.closeSync(fd)
 fs.writeFileSync(path.join(output,'browser.json'),JSON.stringify({kind:'fresh-local-22U-Catalog-native-Inspector-navigation',startedAtUTC:started,finishedAtUTC:new Date().toISOString(),success,failure,steps,command:['/usr/bin/sandbox-exec',...args],runtime:lisp,playwright:pw,chrome,sourceSHA256Before:before,sourceSHA256After:digest(),freshProcess:true,bothRepositoryWritesDenied:true,loopbackOnly:true,productionServiceContacted:false,testServerStopped:true},null,2)+'\n')
}
if(!success)process.exitCode=1
