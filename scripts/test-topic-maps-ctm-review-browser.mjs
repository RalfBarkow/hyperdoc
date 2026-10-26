// Real local Catalog/Inspector for the CTM review, using an already installed Playwright and Chrome.
// node THIS SBCL PLAYWRIGHT_DIRECTORY CHROME OUTPUT; no dependency installation.
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import crypto from 'node:crypto'
import {spawn,execFileSync} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,pw,chrome,output]=process.argv.slice(2)
assert(output && process.env.TOPIC_MAPS_ROOT)
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),'..')
fs.mkdirSync(output,{recursive:true})
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'hyperdoc-ctm-review-browser-'))
fs.mkdirSync(path.join(temp,'site','pages'),{recursive:true})
const stop=path.join(temp,'stop'),proof=path.join(output,'native-eq.log'),script=path.join(temp,'browser.lisp')
const sock=net.createServer();await new Promise(r=>sock.listen(0,'127.0.0.1',r));const port=sock.address().port;await new Promise(r=>sock.close(r))
const q=JSON.stringify
const reviewed=['src/ctm/lexer.lisp','src/ctm/iri.lisp','src/ctm/unicode.lisp'].map(p=>path.join(process.env.TOPIC_MAPS_ROOT,p))
const digest=()=>reviewed.map(f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex')).join(' ')
const status=()=>execFileSync('git',['-C',process.env.TOPIC_MAPS_ROOT,'status','--porcelain']).toString()
const before=digest(),statusBefore=status()
fs.writeFileSync(script,`(load ${q(path.join(root,'scripts/topic-maps-project-bootstrap.lisp'))})
(asdf:load-system "dreyeck/work/topic-maps-ctm-review")
(asdf:load-system "dreyeck/catalog-application")
(defun browser-proof (tag)
 (with-open-file (s ${q(proof)} :direction :output :if-exists :append :if-does-not-exist :create) (format s "~A~%" tag)))
;; Observe real Pane targets only. Never replace an Inspector object.
(defmethod clog-moldable-inspector::add-pane :after
 ((inspector clog-moldable-inspector::inspector) (pane clog-moldable-inspector::pane))
 (declare (ignore inspector))
 (let* ((object (clog-moldable-inspector::pane-object pane))
        (claim (dreyeck/work/topic-maps-ctm-review:claim-named "scheme-plus"))
        (run (first (dreyeck/work/topic-maps-ctm-review:claim-runs claim)))
        (observations (and run (dreyeck/work/topic-maps-ctm-review:run-observations run)))
        (role (lambda (r) (find r observations :key (lambda (o) (dreyeck/work/topic-maps-ctm-review:input-role (dreyeck/work/topic-maps-ctm-review:observation-input o)))))))
  (cond ((eq object claim) (browser-proof "CLAIM-EQ"))
        ((eq object #'topic-maps.ctm::next-token) (browser-proof "FUNCTION-EQ"))
        ((and run (eq object run)) (browser-proof "RUN-EQ"))
        ((and run (eq object (dreyeck/work/topic-maps-ctm-review:observation-condition (funcall role :experiment)))) (browser-proof "CONDITION-EQ"))
        ((and run (eq object (dreyeck/work/topic-maps-ctm-review:observation-map (funcall role :positive-control)))) (browser-proof "CONTROL-MAP-EQ"))
        ((and run (member object observations :test #'eq)) (browser-proof "OBSERVATION-EQ")))))
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1" :site-root ${q(temp+'/site/')} :development t)
(assert (not (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING")))
(format t "~&CTM-REVIEW-BROWSER-READY writer=ABSENT~%") (finish-output)
(unwind-protect (loop repeat 6000 until (probe-file ${q(stop)}) do (sleep .1)) (clog:shutdown))`)
const policy=`(version 1)(allow default)(deny network*)(allow network-inbound (local ip "localhost:*"))(allow network-outbound (remote ip "localhost:*"))(deny file-write* (subpath ${q(root)}))(deny file-write* (subpath ${q(process.env.TOPIC_MAPS_ROOT)}))`
const log=path.join(output,'browser-lisp.log'),fd=fs.openSync(log,'w')
const args=['-p',policy,lisp,'--noinform','--no-sysinit','--no-userinit','--script',script]
const child=spawn('/usr/bin/sandbox-exec',args,{cwd:root,stdio:['ignore',fd,fd],env:{...process.env,HYPERDOC_22U_FASL_ROOT:path.join(temp,'fasls')}})
let browser,success=false,failure=null,layout=null
const viewport={width:1280,height:800}
const steps=[],started=new Date().toISOString()
try {
 let ready=false
 for(let n=0;n<2400;n++){
  if(child.exitCode!==null)throw Error(fs.readFileSync(log,'utf8').slice(-5000))
  if(fs.readFileSync(log,'utf8').includes('CTM-REVIEW-BROWSER-READY')){ready=true;break}
  await new Promise(r=>setTimeout(r,100))
 }
 assert(ready,'fresh local Catalog did not become ready')
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch({headless:true,executablePath:chrome,args:['--disable-background-networking']})
 const context=await browser.newContext({serviceWorkers:'block',viewport})
 const origin=`http://127.0.0.1:${port}`
 await context.route('**/*',r=>new URL(r.request().url()).origin===origin?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(25000)
 const panes=()=>page.locator('.inspector-pane'),last=()=>panes().last()
 const tab=async title=>last().getByRole('button',{name:title,exact:true}).first().click()
 const heading=async (pane,title)=>pane.getByRole('heading',{name:title,exact:true}).waitFor()
 const tags=()=>fs.existsSync(proof)?fs.readFileSync(proof,'utf8').split('\n'):[]
 const proved=async tag=>{for(let n=0;n<50&&!tags().includes(tag);n++)await new Promise(r=>setTimeout(r,100));assert(tags().includes(tag),tag+' missing')}
 await page.goto(origin)
 await page.getByText('Topic Maps CTM Review (22U)',{exact:true}).and(page.locator(':visible')).first().click()
 await tab('Text pages')
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'Reviewing the CTM Reader'}).last().click()
 await heading(last(),'Reviewing the CTM Reader');steps.push('Catalog → Topic Maps CTM Review (22U) → Text pages → Reviewing the CTM Reader')
 await last().getByText('Claim scheme-plus: an undelimited IRI whose scheme contains +',{exact:true}).first().click()
 await heading(last(),'Claim scheme-plus');await proved('CLAIM-EQ')
 const claimIndex=(await panes().count())-1,claimPane=()=>panes().nth(claimIndex)
 const before1=await claimPane().innerText()
 for(const part of ['1. Claim','2. Normative basis','3. Implementation: loaded definitions','4. Counterexample and controls','5. Expected behaviour','6. Observed behaviour','7. Evaluation','8. Provenance'])assert(before1.includes(part),part)
 assert(before1.includes('Not executed in this image.'),'no execution before the button')
 assert(before1.includes('https://www.isotopicmaps.org/ctm/ctm.html')&&before1.includes('published ISO edition was not consulted'))
 const source=claimPane().locator('a.ctm-review-normative-source[href="https://www.isotopicmaps.org/ctm/ctm.html#sec-creating-iris"]')
 assert.equal(await source.count(),1,'one navigable link to §3.3.3');assert.equal(await source.getAttribute('target'),'_blank')
 assert(before1.includes('no corpus test case is registered or changed')&&before1.includes('Runtime-local execution provenance is registered deliberately'))
 assert(!before1.includes('nothing is registered'))
 steps.push('page link → Claim scheme-plus: eight parts, a link to §3.3.3 with its uncertainty, the registration statement, not executed')
 await claimPane().getByText('next-token',{exact:true}).first().click();await proved('FUNCTION-EQ')
 steps.push('Claim → loaded definition next-token (the function object)')
 await claimPane().getByRole('button',{name:'Run the experiment',exact:true}).click()
 await heading(last(),'Run of claim scheme-plus');await proved('RUN-EQ')
 const runIndex=(await panes().count())-1,runPane=()=>panes().nth(runIndex)
 const runText=await runPane().innerText()
 for(const s of ['refuted','INVALID-OCCURRENCE-LITERAL','at character 3 (line 1, column 4)','Observed: what the reader returned or signalled','Derived: conformance assessment','b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc','of the UTF-8 octets as read'])assert(runText.includes(s),s)
 const inputDigest=crypto.createHash('sha256').update('svn+ssh://example.org/x - "A".').digest('hex')
 // Readability at the fixed viewport: one Input/Expected/Observed/Evidence block per observation; the full digest is collapsed.
 const execution=runPane().locator('.ctm-review-execution'),observationBlocks=execution.locator('section.ctm-review-observation')
 assert.equal(await observationBlocks.count(),5,'one block per observation')
 for(let n=0;n<5;n++)assert.deepEqual(await observationBlocks.nth(n).locator('dt').allInnerTexts(),['Input','Expected','Observed','Evidence'],'observation parts')
 assert(runText.includes(inputDigest.slice(0,12)+'…')&&!runText.includes(inputDigest),'the main reading shows a short digest, not the full one')
 // Overflow: the pane and the view scroll no wider than they are, and nothing in the view reaches past its right edge.
 const overflow=()=>runPane().evaluate(pane=>{
  const view=pane.querySelector('.ctm-review-execution'),right=view.getBoundingClientRect().right
  const beyond=[...view.querySelectorAll('*')].filter(e=>e.getBoundingClientRect().right>right+1||(e.clientWidth>0&&e.scrollWidth>e.clientWidth+1)).map(e=>e.tagName+' '+e.textContent.slice(0,40))
  return {paneScroll:pane.scrollWidth,paneClient:pane.clientWidth,viewScroll:view.scrollWidth,viewClient:view.clientWidth,beyond}})
 const fits=o=>o.paneScroll<=o.paneClient&&o.viewScroll<=o.viewClient&&o.beyond.length===0
 const collapsed=await overflow();assert(fits(collapsed),'Execution view overflows: '+JSON.stringify(collapsed))
 // Positive control: one unbroken string that may not wrap is detected as overflow, then removed.
 await execution.evaluate(view=>{const e=document.createElement('div');e.id='ctm-review-overflow-control';e.style.cssText='overflow-wrap:normal;white-space:nowrap';e.textContent='x'.repeat(600);view.append(e)})
 const control=await overflow();await execution.evaluate(()=>document.getElementById('ctm-review-overflow-control').remove())
 assert(control.viewScroll>control.viewClient&&control.beyond.some(s=>s.startsWith('DIV x')),'the overflow check detects a long unbroken string: '+JSON.stringify(control.beyond))
 await runPane().screenshot({path:path.join(output,'execution-view.png')});await page.screenshot({path:path.join(output,'execution-viewport.png')})
 await execution.locator('h3',{hasText:'Evaluation of this run'}).scrollIntoViewIfNeeded();await runPane().screenshot({path:path.join(output,'execution-view-lower.png')})
 // The full digest and diagnostic stay available: open each Evidence detail, and the view still fits.
 for(let n=0;n<5;n++)await observationBlocks.nth(n).locator('summary').click()
 const opened=await overflow();assert(fits(opened),'Execution view with details open overflows: '+JSON.stringify(opened))
 const openText=await runPane().innerText()
 assert(openText.includes(inputDigest),'the full SHA-256 of the experiment text as read, under Evidence')
 assert(openText.includes('The condition\'s report:'),'the full diagnostic, under Evidence')
 await observationBlocks.nth(0).screenshot({path:path.join(output,'execution-observation-details.png')})
 for(let n=0;n<5;n++)await observationBlocks.nth(n).locator('summary').click()
 layout={viewport:viewport,collapsed,positiveControl:{...control,beyond:control.beyond.map(s=>s.slice(0,12))},opened}
 steps.push('Run the experiment (explicit) → run: refuted; rejection at character 3; observed and derived kept apart')
 steps.push(`Execution view at ${viewport.width}×${viewport.height}: five Input/Expected/Observed/Evidence blocks, no horizontal overflow collapsed or open; the check detects a planted overflow`)
 await runPane().getByText('CTM-REJECTION :INVALID-OCCURRENCE-LITERAL',{exact:true}).first().click();await proved('CONDITION-EQ')
 steps.push('Run → the reader\'s own CTM-REJECTION condition')
 await runPane().getByText('Topic Map read',{exact:true}).nth(0).click()
 await heading(last(),'TMDM Topic Map');await proved('CONTROL-MAP-EQ')
 await tab('Evidence');await last().getByText('svn+ssh, delimited: Topic Map read',{exact:true}).first().click();await proved('OBSERVATION-EQ')
 steps.push('Run → positive control\'s native Topic Map → Evidence → its observation')
 await runPane().getByText('The claim',{exact:true}).first().click();await heading(last(),'Claim scheme-plus')
 assert((await last().innerText()).includes('Latest run in this image: refuted'))
 steps.push('Run → back to the claim, now showing the run')
 assert.equal(digest(),before);assert.equal(status(),statusBefore);success=true
} catch(e) {failure=String(e.stack||e);console.error(failure)}
finally {
 if(browser)await browser.close()
 fs.writeFileSync(stop,'stop')
 for(let n=0;n<100&&child.exitCode===null;n++)await new Promise(r=>setTimeout(r,100))
 if(child.exitCode===null)child.kill('SIGTERM')
 fs.closeSync(fd)
 fs.writeFileSync(path.join(output,'browser.json'),JSON.stringify({kind:'fresh-local-CTM-review-Catalog-native-Inspector-navigation',startedAtUTC:started,finishedAtUTC:new Date().toISOString(),success,failure,steps,command:['/usr/bin/sandbox-exec',...args],runtime:lisp,playwright:pw,chrome,reviewedSHA256Before:before,reviewedSHA256After:digest(),topicMapsStatusAfter:status(),freshProcess:true,bothRepositoryWritesDenied:true,loopbackOnly:true,productionServiceContacted:false,testServerStopped:child.exitCode!==null,layout},null,1))
}
if(!success)process.exitCode=1
