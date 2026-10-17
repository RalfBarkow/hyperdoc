// The E3 edit-view diagnosis reached in an actual served Catalog (development off, policy
// enforced, no writer): Work Breakdown → Conversation Coordinates → Workspace → the Work Topic
// ctm-plan-page-authoring → its diagnosis → a finding → its basis → the operator's observation,
// and the diagnosis's subjects. The preview system is never loaded, and no file changes.
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
const sources=['dreyeck/pages/work/Work Breakdown.html','dreyeck/pages/work/Authoring the CTM Plan Page.html',
 'dreyeck/work/ctm-page-evidence/ctm-and-tmdm-in-hyperdoc.json','dreyeck/src/fedwiki-item-edit-preview.lisp','dreyeck.asd']
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex')
const before=sources.map(sha)
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'diagnosis-browser-')),stop=path.join(temp,'stop'),probe=path.join(temp,'probe'),script=path.join(temp,'witness.lisp')
fs.mkdirSync(path.join(temp,'site','pages'),{recursive:true})
const server=net.createServer();await new Promise(r=>server.listen(0,'127.0.0.1',r))
const port=server.address().port;await new Promise(r=>server.close(r))
fs.writeFileSync(script,`(require :asdf)
(asdf:load-system "dreyeck/catalog-application")
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1" :site-root ${JSON.stringify(temp+'/site/')} :development nil)
(assert (dreyeck/authority-policy:policy-enforced-p))
(defun state ()
  (format nil "preview-package=~A preview-loaded=~A writer-package=~A"
          (if (find-package "DREYECK/FEDWIKI-ITEM-EDIT-PREVIEW") "YES" "NO")
          (if (asdf:component-loaded-p "dreyeck/fedwiki-item-edit-preview") "YES" "NO")
          (if (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING") "YES" "NO")))
(format t "~&DIAGNOSIS-BROWSER-READY ~A~%" (state)) (finish-output)
(unwind-protect
    (loop repeat 4800 until (probe-file #p"${stop}")
          do (when (probe-file #p"${probe}")
               (delete-file #p"${probe}")
               (format t "~&DIAGNOSIS-BROWSER-STATE ~A~%" (state)) (finish-output))
             (sleep .1))
  (clog:shutdown))`)
const log=path.join(output,'lisp.log'),fd=fs.openSync(log,'w'),child=spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
const logText=()=>fs.readFileSync(log,'utf8')
let browser
try{
 for(let n=0;n<3000;n++){
  if(child.exitCode!==null)throw Error(logText().slice(-4000))
  if(logText().includes('DIAGNOSIS-BROWSER-READY'))break
  await new Promise(r=>setTimeout(r,100))
 }
 const ready=logText().match(/DIAGNOSIS-BROWSER-READY (.*)/)[1]
 assert.equal(ready,'preview-package=NO preview-loaded=NO writer-package=NO')
 const stateNow=async()=>{
  const seen=(logText().match(/DIAGNOSIS-BROWSER-STATE/g)||[]).length
  fs.writeFileSync(probe,'')
  for(let n=0;n<100;n++){if((logText().match(/DIAGNOSIS-BROWSER-STATE/g)||[]).length>seen)break;await new Promise(r=>setTimeout(r,100))}
  const all=[...logText().matchAll(/DIAGNOSIS-BROWSER-STATE (.*)/g)];return all[all.length-1][1]
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
 const steps=[]
 await page.goto(`http://127.0.0.1:${port}/`)
 await page.getByText('Working on HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
 await tab('Text pages')
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'Work Breakdown'}).last().click()
 await heading('Work Breakdown');steps.push('Catalog → Work Breakdown')
 await click('Inspect Conversation Coordinates');await heading('Conversation Coordinates')
 await click('Conversation Session');await heading('Conversation chronology')
 await last().getByText('Conversation Workspace',{exact:true}).first().click()
 await last().locator('.dreyeck-topicmap-point-sign[data-topic-id="session"]').last().waitFor()
 await last().locator('.dreyeck-topicmap-workspace-action[data-topic-id="ctm-plan-page-authoring"]').last().dispatchEvent('click')
 await last().locator('.dreyeck-topicmap-point-sign[data-topic-id="ctm-plan-page-authoring"]').waitFor()
 await last().locator('p:visible').filter({hasText:'Represented object:'}).locator('span.inspector-inspect').first().click()
 steps.push('Work Topic ctm-plan-page-authoring')
 // The Work Topic offers the diagnosis next to its other views.
 await last().getByRole('button',{name:'Conversation sources',exact:true}).waitFor()
 await tab('E3 edit-view diagnosis');await click('Open the diagnosis')
 await heading("Why was E3's Edit tab missing?");steps.push('Diagnosis: question, explanation, evidence, falsification, next observation')
 const diagnosisPane=page.locator('.inspector-pane').nth(await page.locator('.inspector-pane').count()-1)
 const subjectsTab=async()=>{await diagnosisPane.getByRole('button',{name:'Subjects',exact:true}).first().click();await diagnosisPane.getByRole('heading',{name:'What the diagnosis is about',exact:true}).waitFor()}
 let body=await diagnosisPane.innerText()
 const order=['Question','Explanation (provisional)','Evidence','Falsification','What we do not know yet','Next observation']
 const at=order.map(h=>body.indexOf(h));assert(at.every(n=>n>=0),at);assert.deepEqual(at,[...at].sort((a,b)=>a-b))
 for(const expected of ['Provisional for the original browser observation','not run in this session','Prediction:','A preview writes nothing'])assert(body.includes(expected),expected)
 assert(!body.includes('inferred-edit-view-absent-because-system-not-loaded'),'finding identities are not primary text')
 // The comparison table, then a measurement's evidence in one click.
 assert((await diagnosisPane.locator('tr').filter({hasText:'VIEW-REGISTERED'}).first().innerText()).includes('No → Yes'))
 assert((await diagnosisPane.locator('tr').filter({hasText:'WRITER-PACKAGE-PRESENT'}).first().innerText()).includes('nothing to compare'))
 // The controlled test of 44ebc23a, as inspectable source.
 await diagnosisPane.getByText('the check on the default Catalog',{exact:true}).click()
 await last().getByRole('heading',{name:/^Source scripts\/test-item-edit-preview-activation\.mjs:\d+$/}).waitFor()
 assert((await last().innerText()).includes('count(),0'));steps.push('controlled test source (default Catalog check)')
 // The listing of all findings stays available, by class.
 await diagnosisPane.getByRole('button',{name:'Findings by how they are known',exact:true}).first().click()
 await diagnosisPane.getByRole('heading',{name:'Findings by how they are known',exact:true}).waitFor()
 body=await diagnosisPane.innerText()
 for(const cls of ['Observed','Derived','Inferred','Hypothesized','Unresolved'])assert(body.includes(cls),cls)
 steps.push('Findings by how they are known')
 // Finding → basis → finding → supplied observation.
 await diagnosisPane.getByText('inferred-edit-view-absent-because-system-not-loaded',{exact:true}).click()
 await heading('inferred inferred-edit-view-absent-because-system-not-loaded');steps.push('inferred finding')
 body=await last().innerText();assert(body.includes('not because a policy withheld'));assert(body.includes('Rests on findings'))
 await click('derived derived-registration-changed-across-load')
 await heading('derived derived-registration-changed-across-load');steps.push('derived: registration changed across the load')
 await click('observed observed-before-loading')
 await heading('observed observed-before-loading');steps.push('observed: before loading')
 await click('Operator-supplied before: before-1');await heading('Operator-supplied before: before-1')
 body=await last().innerText()
 for(const expected of [':SYSTEM-LOADED NIL',':OPERATOR-SUPPLIED',':NOT-SUPPLIED','not an Evaluation Record'])assert(body.includes(expected),expected)
 steps.push('operator-supplied observation, verbatim, no time or expression')
 // The after state is another observation, not the present image.
 await page.locator('.inspector-pane').filter({has:page.getByRole('heading',{name:'derived derived-registration-changed-across-load',exact:true})}).last()
  .getByText('observed observed-after-loading',{exact:true}).first().click()
 await heading('observed observed-after-loading')
 await click('Operator-supplied after: after-1');await heading('Operator-supplied after: after-1')
 assert((await last().innerText()).includes(':VIEW-REGISTERED T'));steps.push('after loading, apart from before')
 // Subjects of the diagnosis: ASDF systems, source, E3, and what this image now holds.
 await subjectsTab()
 const subjects=diagnosisPane.locator('li').filter({hasText:/^ASDF system dreyeck\/fedwiki-item-edit-preview: /}).first()
 assert((await subjects.innerText()).includes('defined, not loaded'));steps.push('Subjects: preview system defined, not loaded')
 await diagnosisPane.locator('li').filter({hasText:'Generic function'}).first().getByText('its defview form',{exact:true}).click()
 await last().getByRole('heading',{name:/^Source dreyeck\/src\/fedwiki-item-edit-preview\.lisp:\d+$/}).waitFor()
 body=await last().innerText();assert(body.includes('(v:defview story-item-edit-offer (item lp:local-story-item)'));steps.push('Source: the defview form')
 await subjectsTab()
 await diagnosisPane.locator('li').filter({hasText:'Wiki page'}).first().getByText('E3 in the retained copy',{exact:true}).click()
 await heading('Story Item E3 in the retained copy')
 body=await last().innerText();assert(body.includes('d7215c50f4efa07b3e94749b060b7d7b828654f2a44caab7f1034415c6003dff'));assert(body.includes('retained copy'))
 steps.push('E3 in the retained copy')
 await subjectsTab()
 await diagnosisPane.locator('li').filter({hasText:'Wiki page'}).first().getByText('page file in this image now',{exact:true}).click()
 await heading('This image now')
 body=await last().innerText()
 assert(body.includes('preview-system-loaded'));assert(body.includes('could not be read'));assert(body.includes('live E3 is not observed'))
 steps.push('This image now: page file unavailable, said so')
 // Load closure.
 await subjectsTab()
 await diagnosisPane.locator('li').filter({hasText:/^ASDF system dreyeck\/catalog-application: /}).first().getByText('its load closure',{exact:true}).click()
 await last().getByRole('heading',{name:/^Load closure of dreyeck\/catalog-application \(\d+ systems\)$/}).waitFor()
 body=await last().innerText();assert(/Contains dreyeck\/fedwiki-item-edit-preview\s+no/.test(body),body);assert(/holds this diagnosis\s+yes/.test(body))
 steps.push('Load closure: preview not in it')
 // Nothing was loaded by navigating.
 assert.equal(await stateNow(),'preview-package=NO preview-loaded=NO writer-package=NO');steps.push('preview system and writer still not loaded')
 assert.deepEqual(before,sources.map(sha));assert.deepEqual(errors,[]);assert.deepEqual(fs.readdirSync(path.join(temp,'site','pages')),[])
 await page.screenshot({path:path.join(output,'diagnosis.png'),fullPage:false})
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',browser:browser.version(),development:false,policy:'ENFORCED',steps,sourcesUnchanged:true},null,2))
 console.log('DIAGNOSIS-BROWSER-PASS: '+steps.join(' → ')+' | clicks '+JSON.stringify(readiness))
}catch(e){
 if(browser){const pages=browser.contexts().flatMap(c=>c.pages());if(pages.length){fs.writeFileSync(path.join(output,'failure.txt'),await pages[0].locator('body').innerText());await pages[0].screenshot({path:path.join(output,'failure.png')})}}
 throw e
}finally{
 if(browser)await browser.close();fs.writeFileSync(stop,'')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.rmSync(temp,{recursive:true,force:true})
}
