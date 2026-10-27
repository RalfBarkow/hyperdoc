// The reading "Deploying Topic Maps with HyperDoc" in a real Catalog and browser, using installed Playwright and Chrome.
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
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),'..')
const topicMapsRepository=process.env.TOPIC_MAPS_REPOSITORY||'/Users/rgb/workspace/topic-maps'
fs.mkdirSync(output,{recursive:true})
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'hyperdoc-deployment-review-browser-'))
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
(asdf:load-system "topic-maps-deployment-review")
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
 // 1. Open the review from the Catalog.
 await page.goto(origin)
 await page.getByText('Deploying Topic Maps with HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
 await tab('Text pages')
 await last().locator('tr.inspector-inspect').filter({hasText:'Deploying Topic Maps with HyperDoc'}).first().click()
 await heading(last(),'Deploying Topic Maps with HyperDoc');await proved('PAGE-EQ Deploying Topic Maps with HyperDoc')
 const overviewIndex=(await panes().count())-1,overview=()=>panes().nth(overviewIndex)
 const overviewText=await overview().innerText()
 for(const s of ['uncommitted','First finding of this review','Observed:','Derived:','Open:'])assert(overviewText.includes(s),s)
 await shot('overview.png')
 steps.push('Catalog → Deploying Topic Maps with HyperDoc → Text pages → the overview')
 // 2. Read the rationale in Text Pages, and reach a declaration.
 await click(overview(),'Why a separate Nix package?');await heading(last(),'Why a Separate Nix Package');await proved('PAGE-EQ Why a Separate Nix Package')
 await click(last(),'this attribute of flake.nix');await proved('EXCERPT-EQ flake:production')
 await shows(last(),'hyperdoc-catalog = pkgs.callPackage ./nix/catalog.nix')
 steps.push('Why a Separate Nix Package → the production declaration in flake.nix, as the working tree holds it')
 // 3. Follow links into actual source definitions; read a Code page.
 await click(overview(),'What does the snapshot verifier actually establish?');await heading(last(),'What the Snapshot Verifier Establishes')
 await click(last(),'verify-snapshot-tree');await proved('FUNCTION-EQ verify-snapshot-tree')
 await last().getByText('defun verify-snapshot-tree',{exact:false}).first().waitFor()
 steps.push('What the Snapshot Verifier Establishes → verify-snapshot-tree, the loaded function and its source')
 await click(overview(),'the variant\'s main');await proved('FUNCTION-EQ main')
 await click(overview(),'The candidate');await proved('CANDIDATE-EQ');await shows(last(),'Git agrees with the declaration')
 const candidateText=await last().innerText()
 assert(candidateText.includes('Git agrees with the declaration'),'the declaration agrees with Git')
 assert(candidateText.includes('uncommitted')&&candidateText.includes('same bytes as tested'),'working-tree identity and tested bytes')
 await shot('candidate.png')
 steps.push('Overview → the Candidate: 43 files by working-tree identity, as tested')
 // 4. Navigate the subjects and relations in the Workspace.
 await click(overview(),'The deployment\'s subjects');await proved('WORKSPACE-EQ')
 const workspaceIndex=(await panes().count())-1,workspace=()=>panes().nth(workspaceIndex)
 await workspace().locator('g.dreyeck-topicmap-topic').first().waitFor()
 for(const id of ['b2eecffa','snapshot','manifest','asdf-ctm','nix-variant','startup','test-package','D1'])
  assert.equal(await workspace().locator(`g.dreyeck-topicmap-topic[data-topic-id="${id}"]`).count(),1,id)
 await workspace().locator('rect.dreyeck-topicmap-workspace-action[data-topic-id="guard"]').first().click()
 await workspace().locator('tr.topic-maps-deployment-review-warrant').filter({hasText:'refuses'}).first().waitFor()
 assert((await workspace().innerText()).includes('Why these relations hold'))
 await shot('workspace-at-guard.png')
 steps.push('Overview → the subjects → Go to the Project Workspace guard: its relations with type, provenance, evidence and how each is known')
 await workspace().locator('tr.topic-maps-deployment-review-warrant').filter({hasText:'refuses'}).getByText('refuses',{exact:true}).first().click()
 await proved('WARRANT-EQ refuses');await shows(last(),'Relation type:')
 const warrantText=await last().innerText()
 for(const s of ['Relation type:','Known as:','observed','Provenance','Evidence'])assert(warrantText.includes(s),s)
 steps.push('Guard → the relation "refuses": its warrant')
 // 5. Follow a claim to its supporting test evidence.
 await click(last(),'Executable contract, corrected candidate (by hand)');await proved('EVIDENCE-EQ after-guard-correction/executable.log');await shows(last(),'Recorded run.')
 const recordText=await last().innerText()
 assert(recordText.includes('Recorded run.')&&recordText.includes('test_project_workspace_refused'),'the recorded run of the executable contract')
 await shot('record.png')
 steps.push('Warrant → its evidence: the recorded executable contract of the corrected candidate, test_project_workspace_refused ok')
 await click(overview(),'the first guard replaced two ASDF methods, the corrected one adds none');await proved('CLAIM-EQ guard-replaces-asdf-methods')
 await click(last(),'Which ASDF methods the first guard replaced');await proved('METHOD-ORIGINS-EQ');await shows(last(),'Defined now in')
 const originsText=await last().innerText()
 assert(originsText.includes('Neither is the guard')&&originsText.includes('both are ASDF')&&!originsText.includes('Both are the guard'),'the methods ASDF runs are ASDF\'s own')
 await shot('method-origins.png')
 steps.push('Overview → claim: the first guard replaced two ASDF methods, the corrected one adds none → the live Method origins check: both are ASDF\'s own')
 // 6. Identify observed, derived and open conclusions.
 await click(overview(),'plain thunk buttons are not gated');await proved('CLAIM-EQ plain-thunks-ungated')
 await shows(last(),'derived — it follows from source')
 await click(overview(),'the archive is not published');await proved('CLAIM-EQ unpublished')
 await shows(last(),'open — not done or not known')
 await click(overview(),'the archive is the commit');await proved('CLAIM-EQ archive-is-the-commit')
 await shows(last(),'observed — a recorded run saw it')
 await shot('claim-observed.png')
 steps.push('Overview → one claim of each class: observed, derived, open')
 // An explicit run in a served Catalog whose authority policy is enforced.
 await click(overview(),'verify the snapshot now');await proved('RUNNER-EQ')
 await last().locator('button.inspector-action').filter({hasText:'Verify the snapshot now'}).click();await proved('VERIFICATION-EQ')
 await last().getByText('verified snapshot',{exact:false}).first().waitFor()
 steps.push('Verify now → the button: a fresh verification object of this image\'s Topic Maps source')
 // 7. Return from inspected objects to the review context: from the candidate's own verification object, through its
 // manifest, to the overview.
 await click(last(),'The manifest');await proved('MANIFEST b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc');await shows(last(),'The raw commit object')
 const panesBeforeReturn=await panes().count()
 await click(last(),'Overview');await proved('PAGE-EQ Deploying Topic Maps with HyperDoc')
 for(let n=0;n<50&&(await panes().count())<=panesBeforeReturn;n++)await new Promise(r=>setTimeout(r,100))
 await heading(last(),'Deploying Topic Maps with HyperDoc')
 steps.push('Verification → its manifest → Overview: back to the reading')
 // Last, because a click in the HyperDoc pane replaces the panes after it. A Code page of the reading: its DEFEXAMPLEs are withheld (▷) because the served Catalog enforces its policy.
 await panes().nth(1).getByRole('button',{name:'Code pages',exact:true}).first().click()
 await panes().nth(1).locator('tr.inspector-inspect').filter({hasText:'Explicit Runs, ASDF Origins and the Reading'}).first().click()
 await shows(last(),'verify-snapshot-now')
 const withheld=last().locator('span[title^="Not run here"]')
 await withheld.first().waitFor()
 assert((await withheld.count())>=2,'both DEFEXAMPLEs are withheld');assert.equal(await last().getByRole('button',{name:'►',exact:true}).count(),0)
 await shot('code-page.png')
 steps.push('HyperDoc → Code pages → Explicit Runs: both DEFEXAMPLEs shown, their ► withheld under the enforced policy')
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
