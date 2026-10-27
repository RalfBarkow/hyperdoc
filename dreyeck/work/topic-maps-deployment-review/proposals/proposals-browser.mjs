// The proposed project work in a real Catalog and browser, using installed Playwright and Chrome.
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
const {installBoundClicks,readiness}=await import(pathToFileURL(path.join(root,'scripts/lib/inspector-ready.mjs')))
const topicMapsRepository=process.env.TOPIC_MAPS_REPOSITORY||'/Users/rgb/workspace/topic-maps'
fs.mkdirSync(output,{recursive:true})
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'hyperdoc-proposals-browser-'))
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
(in-package :topic-maps-deployment-review)
(defun cl-user::proof-of (o)
 (let ((p (the-proposals)))
  (cond ((eq o p) (cl-user::browser-proof "PROPOSALS-EQ"))
        ((eq o (the-proposal-workspace)) (cl-user::browser-proof "PROPOSAL-WORKSPACE-EQ"))
        ((member o (proposals-topics p)) (cl-user::browser-proof (format nil "PROPOSAL-EQ ~A" (proposal-id o))))
        ((member o (proposals-entries p)) (cl-user::browser-proof (format nil "ENTRY-EQ ~A" (entry-id o))))
        ((member o (proposals-evidence p)) (cl-user::browser-proof (format nil "EVIDENCE-ENTRY-EQ ~A" (evidence-id o))))
        ((member o (proposals-assignments p)) (cl-user::browser-proof (format nil "ASSIGNMENT-EQ ~A" (assignment-id o))))
        ((member o (proposal-sources)) (cl-user::browser-proof (format nil "SOURCE-EQ ~(~A~)" (proposal-source-key o))))
        ((member o (model-excerpts)) (cl-user::browser-proof (format nil "MODEL-EXCERPT-EQ ~A" (excerpt-key o))))
        ((eq o (the-emitter-crosscheck)) (cl-user::browser-proof "CROSSCHECK-EQ"))
        ((eq o (work-reader-check)) (cl-user::browser-proof "WORK-READER-EQ"))
        ((member o (candidate-files (the-candidate))) (cl-user::browser-proof (format nil "CANDIDATE-FILE-EQ ~A" (file-path o))))
        ((member o (all-evidence)) (cl-user::browser-proof (format nil "EVIDENCE-EQ ~A" (evidence-file o))))
        ((eq o (asdf-collision-finding)) (cl-user::browser-proof "FINDING-EQ"))
        ((eq o #'dreyeck/work/ctm-page-authoring::read-wbs-dictionary) (cl-user::browser-proof "FUNCTION-EQ read-wbs-dictionary"))
        ((eq o #'read-addition) (cl-user::browser-proof "FUNCTION-EQ read-addition"))
        ((eq o #'dreyeck/work/reading:project-work-breakdown) (cl-user::browser-proof "FUNCTION-EQ project-work-breakdown"))
        ((member o (getf *subjects* :decisions)) (cl-user::browser-proof (format nil "DECISION-EQ ~A" (decision-id o))))
        ((typep o 'hyperbook:page) (cl-user::browser-proof (format nil "PAGE-EQ ~A ~A" (if (eq (hyperbook:hyperbook-of o) (hyperbook:find-hyperbook "topic-maps-deployment-review")) "topic-maps-deployment-review" "other") (hyperbook:title-of o))))
        (t (cl-user::browser-proof (format nil "OTHER ~A" (type-of o)))))))
(in-package :cl-user)
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1" :site-root ${q(temp+'/site/')})
(assert (dreyeck/authority-policy:policy-enforced-p))
(assert (not (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING")))
(format t "~&PROPOSALS-BROWSER-READY policy-enforced~%") (finish-output)
(unwind-protect (loop repeat 9000 until (probe-file ${q(stop)}) do (sleep .1)) (clog:shutdown))`)
const policy=`(version 1)(allow default)(deny network*)(allow network-inbound (local ip "localhost:*"))(allow network-outbound (remote ip "localhost:*"))(deny file-write* (subpath ${q(root)}))(deny file-write* (subpath ${q(topicMapsRepository)}))`
const log=path.join(output,'browser-lisp.log'),fd=fs.openSync(log,'w')
const args=['-p',policy,lisp,'--noinform','--no-sysinit','--no-userinit','--script',script]
const child=spawn('/usr/bin/sandbox-exec',args,{cwd:root,stdio:['ignore',fd,fd],env:{...process.env,XDG_CACHE_HOME:path.join(temp,'cache')}})
let browser,page,success=false,failure=null
const steps=[],started=new Date().toISOString()
try {
 let ready=false
 for(let n=0;n<6000;n++){
  if(child.exitCode!==null)throw Error(fs.readFileSync(log,'utf8').slice(-5000))
  if(fs.readFileSync(log,'utf8').includes('PROPOSALS-BROWSER-READY')){ready=true;break}
  await new Promise(r=>setTimeout(r,100))
 }
 assert(ready,'fresh local Catalog did not become ready')
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch({headless:true,executablePath:chrome,args:['--disable-background-networking']})
 const context=await browser.newContext({serviceWorkers:'block',viewport:{width:1440,height:900}})
 const origin=`http://127.0.0.1:${port}`
 await context.route('**/*',r=>new URL(r.request().url()).origin===origin?r.continue():r.abort())
 page=await context.newPage();page.setDefaultTimeout(30000);installBoundClicks(page)
 const panes=()=>page.locator('.inspector-pane'),last=()=>panes().last()
 const tab=async title=>last().getByRole('button',{name:title,exact:true}).first().click()
 const heading=async (pane,title)=>pane.getByRole('heading',{name:title,exact:true}).first().waitFor()
 const tags=()=>fs.existsSync(proof)?fs.readFileSync(proof,'utf8').split('\n'):[]
 const proved=async tag=>{for(let n=0;n<80&&!tags().includes(tag);n++)await new Promise(r=>setTimeout(r,100));assert(tags().includes(tag),tag+' missing')}
 const click=async (pane,text)=>pane.getByText(text,{exact:true}).first().click()
 const shows=async (pane,text)=>pane.getByText(text,{exact:false}).first().waitFor()
 const shot=async name=>last().screenshot({path:path.join(output,name)})
 const book='topic-maps-deployment-review'

 // 1. From the Catalog to the reading's overview, and from there to the six decisions.
 await page.goto(origin)
 await page.getByText('Deploying Topic Maps with HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
 await tab('Text pages')
 await last().locator('tr.inspector-inspect').filter({hasText:'Deploying Topic Maps with HyperDoc'}).first().click()
 await heading(last(),'Deploying Topic Maps with HyperDoc');await proved(`PAGE-EQ ${book} Deploying Topic Maps with HyperDoc`)
 const overviewIndex=(await panes().count())-1,overview=()=>panes().nth(overviewIndex)
 await click(overview(),'The Six Open Decisions');await proved(`PAGE-EQ ${book} The Six Open Decisions`)
 const decisionsIndex=(await panes().count())-1,decisions=()=>panes().nth(decisionsIndex)
 await heading(decisions(),'The Six Open Decisions');await shows(decisions(),'Your decision of 2026-10-27')
 await shot('six-decisions.png')
 steps.push('Catalog → Deploying Topic Maps with HyperDoc → Text pages → the overview → The Six Open Decisions')
 // 2. Each decision's constraint is the existing model's own text or code.
 await click(decisions(),'four sources of the derived project CTM');await proved('MODEL-EXCERPT-EQ emitter:sources');await shows(last(),'(defparameter +sources+')
 await click(decisions(),'the determinism check');await proved('MODEL-EXCERPT-EQ tests:determinism');await shows(last(),'deterministic:retained-file-is-what-the-pages-give-now')
 await click(decisions(),'The emitter\'s own reading');await proved('CROSSCHECK-EQ');await shows(last(),'No refusal:');await shows(last(),'5a4a66850403cdfe2755c6c88083a8e31af89628')
 await shot('cross-check.png')
 await click(decisions(),'read-wbs-dictionary');await proved('FUNCTION-EQ read-wbs-dictionary');await shows(last(),'has an unknown field')
 await click(decisions(),'The ordinary Work reader');await proved('WORK-READER-EQ');await shows(last(),'from the addition: 0 Work Topics')
 steps.push('Decision 2: the emitter\'s sources and the determinism check (excerpts), the emitter\'s recorded reading; decision 5: read-wbs-dictionary (function); decision 1: the Work reader on the addition')
 await click(decisions(),'the probe\'s execution report');await proved('EVIDENCE-ENTRY-EQ tmd-run-asdf-collision-probe');await shows(last(),'An execution report:')
 await click(last(),'Method collision probe, recorded 2026-10-27');await proved('FINDING-EQ')
 steps.push('Decision 4: the collision probe\'s execution report → its recorded probe')
 // 3. The proposed WBS, its Workspace, Point at 2.3: four questions apart, the entry, the implementation object.
 await click(decisions(),'The Proposed Deployment WBS');await proved(`PAGE-EQ ${book} The Proposed Deployment WBS`)
 const wbsIndex=(await panes().count())-1,wbs=()=>panes().nth(wbsIndex)
 await shows(wbs(),'Reported by the executor, not a status.')
 await click(wbs(),'the proposal Workspace');await proved('PROPOSAL-WORKSPACE-EQ')
 const workspaceIndex=(await panes().count())-1,workspace=()=>panes().nth(workspaceIndex)
 await workspace().locator('g.dreyeck-topicmap-topic').first().waitFor()
 await shot('proposal-workspace.png')
 await workspace().locator('rect.dreyeck-topicmap-workspace-action[data-topic-id="tmd-wp-2-3"]').first().click()
 await shows(workspace(),'At Point: 2.3 Catalog startup policy')
 for(const h of ['WBS decomposition','Plan','Scope, criterion and implementation objects','Evidence reported by assignments','Acceptance'])await heading(workspace(),h)
 await shows(workspace(),'No acceptance record.')
 await shot('point-at-2-3.png')
 await click(workspace(),'Its draft dictionary entry tmd-wp-2-3');await proved('ENTRY-EQ tmd-wp-2-3');await shows(last(),'planned: no test yet');await shows(last(),'tmd-asdf-methods-preserved')
 await shot('entry-2-3.png')
 await click(last(),'dreyeck/src/catalog-topic-maps.lisp');await proved('CANDIDATE-FILE-EQ dreyeck/src/catalog-topic-maps.lisp');await shows(last(),'The tests ran on these bytes')
 steps.push('The Proposed Deployment WBS → the proposal Workspace → Point at 2.3: decomposition, plan, scope, evidence, acceptance apart → its draft entry (a planned control) → its implementation object')
 // 4. Reported evidence to its record; a Code page reader; promotion; the way back.
 await click(wbs(),'the package contract\'s run');await proved('EVIDENCE-ENTRY-EQ tmd-run-package-contract');await shows(last(),'An execution report:');await shows(last(),'53ee999358f455a2dcb375743072d56d0f4c31cd')
 await click(last(),'Package contract: Lisp suites in the build sandbox');await proved('EVIDENCE-EQ package-check/lisp.log');await shows(last(),'Recorded run.')
 steps.push('An execution report (run facts) → the recorded run it names')
 await click(wbs(),'read-addition');await proved('FUNCTION-EQ read-addition');await shows(last(),'defun read-addition')
 await click(wbs(),'Promoting the Proposals');await proved(`PAGE-EQ ${book} Promoting the Proposals`);await shows(last(),'Stage A: the proposals recorded in the project, still proposals')
 const promotionIndex=(await panes().count())-1,promotion=()=>panes().nth(promotionIndex)
 await click(promotion(),'the addition');await proved('SOURCE-EQ addition');await shows(last(),'appended, unchanged, to dreyeck/pages/project/Implementation Assignments.html')
 steps.push('read-addition (source code) → Promoting the Proposals → the addition as a proposal source')
 await click(last(),'Overview');await proved(`PAGE-EQ ${book} Deploying Topic Maps with HyperDoc`)
 steps.push('Proposal source → Overview: back to the reading')
 const after=state()
 assert.deepEqual(after,before,'the working tree, the index and the topic-maps repository are unchanged')
 success=true
} catch(e) {failure=String(e.stack||e);console.error(failure);try{await page.locator('.inspector-pane').last().screenshot({path:path.join(output,'failure.png')})}catch{}}
finally {
 if(browser)await browser.close()
 fs.writeFileSync(stop,'stop')
 for(let n=0;n<100&&child.exitCode===null;n++)await new Promise(r=>setTimeout(r,100))
 if(child.exitCode===null)child.kill('SIGTERM')
 fs.closeSync(fd)
 fs.writeFileSync(path.join(output,'browser.json'),JSON.stringify({kind:'deployment-review-proposals-browser-navigation',startedAtUTC:started,finishedAtUTC:new Date().toISOString(),success,failure,steps,
  identity:[...new Set(tags().filter(Boolean))],readiness,command:['/usr/bin/sandbox-exec',...args],runtime:lisp,playwright:pw,chrome,topicMapsRoot:process.env.TOPIC_MAPS_ROOT,
  stateBefore:before,stateAfter:state(),policyEnforced:true,repositoryWritesDenied:true,loopbackOnly:true,testServerStopped:child.exitCode!==null},null,1))
}
if(!success)process.exitCode=1
function tags(){return fs.existsSync(proof)?fs.readFileSync(proof,'utf8').split('\n'):[]}
