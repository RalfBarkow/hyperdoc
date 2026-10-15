// Fresh loopback Catalog/Inspector: the CTM plan page's WBS and plan, and the
// proposal and preview of one Item edit on a temporary copy of the retained page.
// node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT
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
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'ctm-plan-browser-')),stop=path.join(temp,'stop')
// The page is the retained local observation; a write to this copy would show below.
const evidence=path.resolve(path.dirname(new URL(import.meta.url).pathname),'../dreyeck/work/ctm-page-evidence/ctm-and-tmdm-in-hyperdoc.json')
const site=path.join(temp,'site'),pageFile=path.join(site,'pages','ctm-and-tmdm-in-hyperdoc')
fs.mkdirSync(path.dirname(pageFile),{recursive:true});fs.copyFileSync(evidence,pageFile)
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')
const observed='d7215c50f4efa07b3e94749b060b7d7b828654f2a44caab7f1034415c6003dff'
assert.equal(sha(pageFile),observed)
const server=net.createServer();await new Promise(r=>server.listen(0,'127.0.0.1',r))
const port=server.address().port;await new Promise(r=>server.close(r))
const script=path.join(temp,'witness.lisp'),log=path.join(output,'lisp.log')
fs.writeFileSync(script,`(require :asdf)
(asdf:load-system "dreyeck/work/reading/tests")
(asdf:load-system "dreyeck/fedwiki-item-edit-preview")
(defparameter cl-user::*ctm-site* ${JSON.stringify(site+'/')})
(defparameter cl-user::*ctm-page*
 (dreyeck/local-fedwiki-page:make-local-fedwiki-page cl-user::*ctm-site*
  (dreyeck/local-fedwiki-page:register-local-fedwiki cl-user::*ctm-site* "fedwiki:ctm-fixture")
  "ctm-and-tmdm-in-hyperdoc"))
(clog:initialize (lambda (body)
 (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
 (let ((i (clog-moldable-inspector::create-inspector body :pane-width "750px" :playground? nil)))
  (clog-moldable-inspector::create-pane i hyperbook::*catalog* :select "HyperBooks")
  (let ((open (clog:create-button body :content "Open CTM fixture page")))
   (clog:set-on-click open (lambda (event) (declare (ignore event))
     (clog-moldable-inspector::create-pane i cl-user::*ctm-page*)))))
 (let ((probe (clog:create-button body :content "Probe CTM workspace"))
       (result (clog:create-div body :content "No CTM probe")))
  (clog:set-on-click probe (lambda (event) (declare (ignore event))
    (let ((w (dreyeck/work/ctm-page-authoring:ctm-authoring-workspace)))
      (setf (clog:text result) (format nil "CTM Point=~A; History=~S"
        (dreyeck/topicmap:topicmap-workspace-point-of w)
        (dreyeck/topicmap:topicmap-workspace-history-of w)))))))) :host "127.0.0.1" :port ${port})
(format t "~&CTM-BROWSER-READY~%") (finish-output)
(unwind-protect (loop repeat 2400 until (probe-file #p"${stop}") do (sleep .1)) (clog:shutdown))`)
const fd=fs.openSync(log,'w'),child=spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
let browser
try {
 for(let n=0;n<1800;n++){if(child.exitCode!==null)throw Error(fs.readFileSync(log,'utf8').slice(-4000));if(fs.readFileSync(log,'utf8').includes('CTM-BROWSER-READY'))break;await new Promise(r=>setTimeout(r,100))}
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch({headless:true,executablePath:chrome})
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(30000)
 const browserErrors=[];page.on('pageerror',e=>browserErrors.push(e.message))
 const last=()=>page.locator('.inspector-pane').last()
 const click=async label=>last().getByText(label,{exact:true}).first().click()
 const tab=async label=>last().getByRole('button',{name:label,exact:true}).first().click()
 const heading=async label=>last().getByRole('heading',{name:label,exact:true}).waitFor()
 const steps=[]
 await page.goto(`http://127.0.0.1:${port}`)

 // WBS and plan: Work Breakdown → carrier page → plan, authorization, WBS element, control.
 await page.getByText('Working on HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByRole('button',{name:'Text pages',exact:true}).last().click()
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'Work Breakdown'}).last().click()
 await heading('Work Breakdown');steps.push('Work Breakdown')
 await click('Author the CTM Plan Page through HyperDoc');await heading('Authoring the CTM Plan Page');steps.push('carrier page')
 await click('the plan');await last().getByText('neither permits an effect',{exact:false}).first().waitFor();steps.push('Plan steps')
 await click('P3 Execute the authorized single-item edit');await heading('P3 Execute the authorized single-item edit');steps.push('P3')
 assert((await last().innerText()).includes('Status blocked'))
 await click('none permitted');await heading('Authorization of P3 Execute the authorized single-item edit');steps.push('Authorization')
 assert((await last().innerText()).includes('Permitted now'))
 assert((await last().innerText()).includes('Not granted'))
 await click('Return to the plan step');await heading('P3 Execute the authorized single-item edit')
 await click('Authorized single-item edit');await heading('Authorized single-item edit');steps.push('WBS element 3')
 await click('stale-source-refused');await heading('stale-source-refused');steps.push('planned control')
 assert((await last().innerText()).includes('(refused :stale'))
 await page.locator('.inspector-pane').filter({has:page.getByRole('heading',{name:'Authorized single-item edit',exact:true})}).last()
   .getByText('Return to Authoring the CTM Plan Page',{exact:true}).first().click()
 await heading('Authoring the CTM Plan Page');steps.push('return to carrier page')

 // Native Workspace: Point moves twice and History keeps the earlier Points.
 await click('native Workspace')
 await page.locator('.dreyeck-topicmap-point-sign[data-topic-id="ctm-page-edit"]').last().waitFor();steps.push('Workspace')
 await page.getByRole('button',{name:'Probe CTM workspace',exact:true}).click()
 await page.getByText('CTM Point=ctm-page-edit; History=NIL',{exact:true}).waitFor()
 // Signs beyond the pane's width are clicked by event; that is the event the handler receives.
 await page.locator('.dreyeck-topicmap-workspace-action[data-topic-id="ctm-wp-3"]').last().dispatchEvent('click')
 await page.locator('.dreyeck-topicmap-point-sign[data-topic-id="ctm-wp-3"]').last().waitFor()
 await page.locator('.dreyeck-topicmap-workspace-action[data-topic-id="ctm-plan-p3"]').last().dispatchEvent('click')
 await page.locator('.dreyeck-topicmap-point-sign[data-topic-id="ctm-plan-p3"]').last().waitFor()
 await page.getByRole('button',{name:'Probe CTM workspace',exact:true}).click()
 await page.getByText('CTM Point=ctm-plan-p3; History=("ctm-wp-3" "ctm-page-edit")',{exact:true}).waitFor();steps.push('Point/History')
 await last().locator('p:visible').filter({hasText:'Represented object:'}).locator('span.inspector-inspect').first().click()
 await heading('P3 Execute the authorized single-item edit');steps.push('represented object')

 // P2: local-fedwiki-page → Story Item E3 → Edit proposal → Preview, writing nothing.
 await page.getByRole('button',{name:'Open CTM fixture page',exact:true}).click()
 await last().locator('.inspector-title').filter({hasText:'CTM and TMDM in HyperDoc'}).first().waitFor();steps.push('local-fedwiki-page')
 await tab('Page source')
 await last().getByText(observed,{exact:true}).first().waitFor();steps.push('Page source')
 await click('ed37e9bac2fcd548');await heading('Story Item ed37e9bac2fcd548');steps.push('Story Item E3')
 assert((await last().innerText()).includes('11 of 18'))
 assert((await last().innerText()).includes('E3 — Darstellung'))
 await tab('Edit');await click('Prepare edit proposal')
 await heading('Edit proposal for ed37e9bac2fcd548');steps.push('Edit proposal')
 const proposed='E3 — Darstellung: Association-Knoten. Decision: browser regression example, not a decision.'
 const input=last().locator('input').first()  // the proposal view's one input; hvr:input writes type="TEXT"
 await input.fill(proposed);await input.dispatchEvent('change');await page.waitForTimeout(500)
 await click('Preview');await heading('Preview: edit of ed37e9bac2fcd548');steps.push('Preview')
 const preview=await last().innerText()
 for(const text of ['ed37e9bac2fcd548',observed,'Rollentyp-Topics',proposed,'Item 11 is replaced; 17 Items stay','Journal: 2 entries become 3','Executed: no.'])
  assert(preview.includes(text),text)
 assert.equal(sha(pageFile),observed);assert.deepEqual(fs.readdirSync(path.dirname(pageFile)),['ctm-and-tmdm-in-hyperdoc'])
 steps.push('page file unchanged')
 assert.deepEqual(browserErrors,[])
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',browser:browser.version(),steps,pageSha256:sha(pageFile)},null,2))
 console.log('CTM-PLAN-BROWSER-PASS: '+steps.join(' → '))
}finally{
 if(browser)await browser.close();fs.writeFileSync(stop,'')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.rmSync(temp,{recursive:true,force:true})
}
