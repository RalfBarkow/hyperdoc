// The reading's ASDF method collision path in a real Catalog and browser, using installed Playwright and Chrome.
// node THIS SBCL PLAYWRIGHT_DIRECTORY CHROME OUTPUT, with TOPIC_MAPS_ROOT the verified store snapshot; no installation.
// A sandboxed loopback server, not in development mode; an add-pane hook records which actual object each pane holds.
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import crypto from 'node:crypto'
import {spawn,execFileSync} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,pw,chrome,output]=process.argv.slice(2)
assert(output && process.env.TOPIC_MAPS_ROOT && process.env.TOPIC_MAPS_ROOT.startsWith('/nix/store/'),'TOPIC_MAPS_ROOT must be the store snapshot')
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),'../../../..')
const topicMapsRepository=process.env.TOPIC_MAPS_REPOSITORY||'/Users/rgb/workspace/topic-maps'
fs.mkdirSync(output,{recursive:true})
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'hyperdoc-collision-browser-'))
fs.mkdirSync(path.join(temp,'site','pages'),{recursive:true})
const stop=path.join(temp,'stop'),proof=path.join(output,'native-eq.log'),script=path.join(temp,'browser.lisp')
if(fs.existsSync(proof))fs.unlinkSync(proof)
const sock=net.createServer();await new Promise(r=>sock.listen(0,'127.0.0.1',r));const port=sock.address().port;await new Promise(r=>sock.close(r))
const q=JSON.stringify
const git=(...a)=>execFileSync('git',['-C',root,...a]).toString()
const state=()=>({status:git('status','--porcelain'),diff:crypto.createHash('sha256').update(git('diff','--binary')).digest('hex'),
  topicMaps:execFileSync('git',['-C',topicMapsRepository,'status','--porcelain']).toString()})
const before=state()
fs.writeFileSync(script,`(load ${q(path.join(root,'scripts/topic-maps-project-bootstrap.lisp'))})
(asdf:load-system "topic-maps-deployment-review-asdf-collision")
(asdf:load-system "dreyeck/catalog-application")
(defun browser-proof (tag)
 (with-open-file (s ${q(proof)} :direction :output :if-exists :append :if-does-not-exist :create) (format s "~A~%" tag)))
;; Observe real Pane targets only. Never replace an Inspector object.
(defmethod clog-moldable-inspector::add-pane :after
 ((inspector clog-moldable-inspector::inspector) (pane clog-moldable-inspector::pane))
 (declare (ignore inspector))
 (handler-case (proof-of (clog-moldable-inspector::pane-object pane))
   (error (e) (browser-proof (format nil "HOOK-ERROR ~A" e)))))
(defun proof-of (o)
 (let ((w (topic-maps-deployment-review:the-workspace)))
  (cond ((eq o (topic-maps-deployment-review:the-candidate)) (browser-proof "CANDIDATE-EQ"))
        ((eq o w) (browser-proof "WORKSPACE-EQ"))
        ((eq o #'dreyeck/source-snapshot:verify-snapshot-tree) (browser-proof "FUNCTION-EQ verify-snapshot-tree"))
        ((eq o #'dreyeck/catalog-topic-maps:main) (browser-proof "FUNCTION-EQ main"))
        ((member o (topic-maps-deployment-review:claims)) (browser-proof (format nil "CLAIM-EQ ~A" (topic-maps-deployment-review:claim-id o))))
        ((member o (topic-maps-deployment-review:all-evidence)) (browser-proof (format nil "EVIDENCE-EQ ~A" (topic-maps-deployment-review:evidence-file o))))
        ((member o (topic-maps-deployment-review:excerpts)) (browser-proof (format nil "EXCERPT-EQ ~A" (topic-maps-deployment-review:excerpt-key o))))
        ((member o (dreyeck/topicmap:topicmap-projection-associations-of (dreyeck/topicmap:topicmap-workspace-projection-of w)))
         (browser-proof (format nil "WARRANT-EQ ~A" (dreyeck/topicmap:topicmap-association-type-of o))))
        ((eq o (topic-maps-deployment-review::method-origins)) (browser-proof "METHOD-ORIGINS-EQ"))
        ((eq o (topic-maps-deployment-review::guard-operate-method)) (browser-proof "METHOD-EQ operate"))
        ((eq o (topic-maps-deployment-review::guard-perform-method)) (browser-proof "METHOD-EQ perform"))
        ((eq o #'asdf:perform) (browser-proof "GENERIC-EQ perform"))
        ((eq o #'dreyeck/catalog-topic-maps:refuse-project-workspace) (browser-proof "FUNCTION-EQ refuse"))
        ((member o (topic-maps-deployment-review::asdf-originals)) (browser-proof (format nil "ORIGINAL-EQ ~A" (topic-maps-deployment-review:excerpt-key o))))
        ((eq o (topic-maps-deployment-review::asdf-collision-finding)) (browser-proof "FINDING-EQ"))
        ((eq o (topic-maps-deployment-review::proposed-correction)) (browser-proof "CORRECTION-EQ"))
        ((eq o (topic-maps-deployment-review:the-guard-trial)) (browser-proof "GUARD-EQ"))
        ((member o (topic-maps-deployment-review::collision-claims)) (browser-proof (format nil "CLAIM-EQ ~A" (topic-maps-deployment-review:claim-id o))))
        ((typep o 'dreyeck/source-snapshot:snapshot-manifest) (browser-proof (format nil "MANIFEST ~A" (dreyeck/source-snapshot:manifest-commit o))))
        ((eq o (topic-maps-deployment-review:the-verification-runner)) (browser-proof "RUNNER-EQ"))
        ((eq o (first (first (topic-maps-deployment-review:runner-runs (topic-maps-deployment-review:the-verification-runner)))))
         (browser-proof "VERIFICATION-EQ"))
        ((and (typep o 'hyperbook:page) (eq (hyperbook:hyperbook-of o) (hyperbook:find-hyperbook "topic-maps-deployment-review")))
         (browser-proof (format nil "PAGE-EQ ~A" (hyperbook:title-of o))))
        (t (browser-proof (format nil "OTHER ~A" (type-of o)))))))
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1" :site-root ${q(temp+'/site/')})
(assert (dreyeck/authority-policy:policy-enforced-p))
(assert (not (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING")))
(format t "~&DEPLOYMENT-REVIEW-BROWSER-READY policy-enforced~%") (finish-output)
(unwind-protect (loop repeat 9000 until (probe-file ${q(stop)}) do (sleep .1)) (clog:shutdown))`)
const policy=`(version 1)(allow default)(deny network*)(allow network-inbound (local ip "localhost:*"))(allow network-outbound (remote ip "localhost:*"))(deny file-write* (subpath ${q(root)}))(deny file-write* (subpath ${q(topicMapsRepository)}))`
const log=path.join(output,'browser-lisp.log'),fd=fs.openSync(log,'w')
const args=['-p',policy,lisp,'--noinform','--no-sysinit','--no-userinit','--script',script]
const child=spawn('/usr/bin/sandbox-exec',args,{cwd:root,stdio:['ignore',fd,fd],env:{...process.env,XDG_CACHE_HOME:path.join(temp,'cache')}})
let browser,success=false,failure=null
const steps=[],started=new Date().toISOString()
try {
 let ready=false
 for(let n=0;n<3000;n++){
  if(child.exitCode!==null)throw Error(fs.readFileSync(log,'utf8').slice(-5000))
  if(fs.readFileSync(log,'utf8').includes('DEPLOYMENT-REVIEW-BROWSER-READY')){ready=true;break}
  await new Promise(r=>setTimeout(r,100))
 }
 assert(ready,'fresh local Catalog did not become ready')
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch({headless:true,executablePath:chrome,args:['--disable-background-networking']})
 const context=await browser.newContext({serviceWorkers:'block',viewport:{width:1440,height:900}})
 const origin=`http://127.0.0.1:${port}`
 await context.route('**/*',r=>new URL(r.request().url()).origin===origin?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(30000)
 const panes=()=>page.locator('.inspector-pane'),last=()=>panes().last()
 const tab=async title=>last().getByRole('button',{name:title,exact:true}).first().click()
 const heading=async (pane,title)=>pane.getByRole('heading',{name:title,exact:true}).first().waitFor()
 const tags=()=>fs.existsSync(proof)?fs.readFileSync(proof,'utf8').split('\n'):[]
 const proved=async tag=>{for(let n=0;n<80&&!tags().includes(tag);n++)await new Promise(r=>setTimeout(r,100));assert(tags().includes(tag),tag+' missing')}
 const click=async (pane,text)=>pane.getByText(text,{exact:true}).first().click()
 const shows=async (pane,text)=>pane.getByText(text,{exact:false}).first().waitFor()
 const shot=async name=>last().screenshot({path:path.join(output,name)})

 // 1. The guard's intended responsibility.
 await page.goto(origin)
 await page.getByText('Deploying Topic Maps with HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
 await tab('Text pages')
 await last().locator('tr.inspector-inspect').filter({hasText:'The ASDF Method Collision'}).first().click()
 await heading(last(),'The ASDF Method Collision');await proved('PAGE-EQ The ASDF Method Collision')
 const pageIndex=(await panes().count())-1,collision=()=>panes().nth(pageIndex)
 await shot('collision-page.png')
 await click(collision(),'refuse-project-workspace');await proved('FUNCTION-EQ refuse');await shows(last(),'defun refuse-project-workspace')
 await click(collision(),'the guard\'s subject');await proved('GUARD-EQ');await shows(last(),'The Project Workspace guard')
 steps.push('Overview → Text pages → The ASDF Method Collision → step 1: refuse-project-workspace (function) and the guard\'s subject')
 // 2. The first guard's two methods, kept as history; the methods with those identities now are ASDF's own.
 await click(collision(),'the first guard\'s two methods');await proved('EXCERPT-EQ startup:guard-methods');await shows(last(),'(defmethod asdf:operate :before');await shows(last(),'keeps the file verbatim')
 await shot('first-guard-methods.png')
 await click(collision(),'operate :before on (t t)');await proved('METHOD-EQ operate');await tab('Generic');await shows(last(),'Qualifiers')
 await click(collision(),'perform :before on (operation component)');await proved('METHOD-EQ perform');await shows(last(),'Qualifiers')
 steps.push('Step 2: the first guard\'s text, kept verbatim (historical source); the two identities now hold ASDF\'s own methods, as method objects with their Generic view')
 // 3. ASDF's original definitions.
 await click(collision(),'perform :before ((o operation) (c component))');await proved('ORIGINAL-EQ asdf:perform-before')
 await shows(last(),'ensure-all-directories-exist (output-files o c)');await shows(last(),'it is ASDF\'s own')
 await shot('asdf-original.png')
 await click(last(),'All methods of its generic function');await proved('GENERIC-EQ perform')
 await click(collision(),'operate :before (operation-class system &rest args)');await proved('ORIGINAL-EQ asdf:operate-before-abl');await shows(last(),'ASDF-BINARY-LOCATIONS')
 steps.push('Step 3: ASDF\'s own text of both methods, each asking the image whose method has its identity now; perform\'s generic function and its methods')
 // 4. The evidence of the replacement: the record, and the warrant in the Workspace.
 await click(collision(),'The probe\'s record');await proved('FINDING-EQ');await shows(last(),'Recorded run.');await shows(last(),'Both identities move')
 await shot('finding.png')
 await click(collision(),'the subjects');await proved('WORKSPACE-EQ')
 const workspaceIndex=(await panes().count())-1,workspace=()=>panes().nth(workspaceIndex)
 await workspace().locator('g.dreyeck-topicmap-topic').first().waitFor()
 await workspace().locator('rect.dreyeck-topicmap-workspace-action[data-topic-id="asdf"]').first().click()
 await workspace().locator('tr.topic-maps-deployment-review-warrant').filter({hasText:'once replaced two methods of'}).first().waitFor()
 await workspace().locator('tr.topic-maps-deployment-review-warrant').filter({hasText:'defines'}).first().waitFor()
 await shot('workspace-at-asdf.png')
 await workspace().locator('tr.topic-maps-deployment-review-warrant').filter({hasText:'once replaced two methods of'}).getByText('once replaced two methods of',{exact:true}).first().click()
 await proved('WARRANT-EQ once replaced two methods of');await shows(last(),'Relation type:')
 await click(last(),'Method collision probe, recorded 2026-10-27');await proved('FINDING-EQ')
 steps.push('Step 4: the probe\'s record; in the Workspace, Point at ASDF 3.3.1 → the relation "once replaced two methods of" → its warrant → the record')
 // 5. Invariant, consequences (observed apart from inferred), correction.
 await click(collision(),'the invariant');await proved('CLAIM-EQ collision-invariant');await shows(last(),'derived — it follows from source')
 await click(collision(),'ASDF no longer creates an action\'s output directories');await proved('CLAIM-EQ collision-directories');await shows(last(),'observed — a recorded run saw it')
 await click(collision(),'which real actions were affected');await proved('CLAIM-EQ collision-affected-actions');await shows(last(),'inferred — expected from other facts')
 await click(collision(),'the correction');await proved('CORRECTION-EQ');await shows(last(),'free: no method has it')
 await shot('correction.png')
 steps.push('Step 5: the invariant (derived), a consequence (observed on the probe action), affected actions (inferred), the correction (applied)')
 // Return from the inspected objects to the reading.
 await click(last(),'Overview');await proved('PAGE-EQ Deploying Topic Maps with HyperDoc')
 steps.push('Correction → Overview: back to the reading')
 const after=state()
 assert.deepEqual(after,before,'the working tree, the index and the topic-maps repository are unchanged')
 success=true
} catch(e) {failure=String(e.stack||e);console.error(failure)}
finally {
 if(browser)await browser.close()
 fs.writeFileSync(stop,'stop')
 for(let n=0;n<100&&child.exitCode===null;n++)await new Promise(r=>setTimeout(r,100))
 if(child.exitCode===null)child.kill('SIGTERM')
 fs.closeSync(fd)
 fs.writeFileSync(path.join(output,'browser.json'),JSON.stringify({kind:'deployment-review-reading-browser-navigation',startedAtUTC:started,finishedAtUTC:new Date().toISOString(),success,failure,steps,
  identity:[...new Set(tags().filter(Boolean))],command:['/usr/bin/sandbox-exec',...args],runtime:lisp,playwright:pw,chrome,topicMapsRoot:process.env.TOPIC_MAPS_ROOT,
  stateBefore:before,stateAfter:state(),policyEnforced:true,repositoryWritesDenied:true,loopbackOnly:true,testServerStopped:child.exitCode!==null},null,1))
}
if(!success)process.exitCode=1
function tags(){return fs.existsSync(proof)?fs.readFileSync(proof,'utf8').split('\n'):[]}
