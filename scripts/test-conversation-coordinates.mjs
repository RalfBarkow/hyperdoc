// Actual served Catalog, development disabled and policy enforced. No writer.
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
const executable=process.env.HYPERDOC_CATALOG_EXECUTABLE
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),'..')
const sources=['dreyeck/pages/work/Work Breakdown.html','dreyeck/pages/work/Conversation Coordinates.html',
 'dreyeck/pages/work/Authoring the CTM Plan Page.html','dreyeck/pages/work/CTM Plan Page WBS Dictionary.html',
 'dreyeck/work/conversation-evidence/coordinates.json','dreyeck/work/ctm-page-evidence/ctm-and-tmdm-in-hyperdoc.json']
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex')
const before=sources.map(sha)
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'conversation-browser-')),stop=path.join(temp,'stop'),script=path.join(temp,'witness.lisp')
fs.mkdirSync(path.join(temp,'site','pages'),{recursive:true})
const server=net.createServer();await new Promise(r=>server.listen(0,'127.0.0.1',r))
const port=server.address().port;await new Promise(r=>server.close(r))
fs.writeFileSync(script,`(require :asdf)
(asdf:load-system "dreyeck/catalog-application")
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1" :site-root ${JSON.stringify(temp+'/site/')} :development nil)
(assert (dreyeck/authority-policy:policy-enforced-p))
(assert (not (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING")))
(format t "~&CONVERSATION-BROWSER-READY policy=ENFORCED writer=ABSENT~%") (finish-output)
(unwind-protect (loop repeat 2400 until (probe-file #p"${stop}") do (sleep .1)) (clog:shutdown))`)
const log=path.join(output,'lisp.log'),fd=fs.openSync(log,'w'),child=executable ? spawn(executable,[String(port)],{cwd:temp,env:{...process.env,HYPERDOC_CATALOG_HOST:'127.0.0.1',HYPERDOC_FEDWIKI_SITE_ROOT:temp+'/site/'},stdio:['ignore',fd,fd]}) : spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
let browser
try{
 for(let n=0;n<1800;n++){
  if(child.exitCode!==null)throw Error(fs.readFileSync(log,'utf8').slice(-4000))
  if(fs.readFileSync(log,'utf8').includes(executable?'HyperBook Catalog listening on':'CONVERSATION-BROWSER-READY'))break
  await new Promise(r=>setTimeout(r,100))
 }
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch({headless:true,executablePath:chrome})
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(20000)
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
 await click('Inspect Conversation Coordinates');await heading('Conversation Coordinates');steps.push('carrier page')
 await click('Conversation Session');await heading('Conversation chronology');steps.push('Chronology')
 await last().getByText('Next selected message',{exact:true}).click()
 await last().locator('p').filter({hasText:'Cursor:'}).getByText('Message #8',{exact:true}).waitFor();steps.push('independent chronology cursor')
 await click('Message #8');await heading('Message #8')
 let body=await last().innerText()
 assert(body.includes('NOT-RUN'));assert(body.includes('recorded offline PASS'))
 await click('Source span #8');await heading('Source span #8')
 await click('original-report');await heading('CTM/TMDM original report')
 body=await last().innerText()
 assert(body.includes('localhost:3000'));assert(body.includes('404'));assert(body.includes('NOT-RUN here'))
 assert.equal(await last().locator('a[href*="ctm-and-tmdm-in-hyperdoc-original-report"]').count(),0)
 steps.push('H2: local report, offline identity, runtime NOT-RUN, historical HTTP 404, no public link')
 // N1: inspect both observed input forms, with no authorship inference.
 await page.locator('.inspector-pane').filter({has:page.getByRole('heading',{name:'Conversation chronology',exact:true})}).last()
  .getByText('Message #16',{exact:true}).first().click()
 await heading('Message #16')
 body=await last().innerText()
 assert(body.includes('unwrapped'));assert(body.includes('not-recorded'))
 assert(!body.includes('pasted-wrapper'));steps.push('N1: #16 unwrapped, author not-recorded')
 // Return through the already open Chronology; do not fetch an external source.
 await page.locator('.inspector-pane').filter({has:page.getByRole('heading',{name:'Conversation chronology',exact:true})}).last()
  .getByText('Message #20',{exact:true}).first().click()
 await heading('Message #20');steps.push('Message #20: pasted-wrapper, author not-recorded')
 assert((await last().innerText()).includes('not published'))
 assert((await last().innerText()).includes('not-recorded'))
 assert((await last().innerText()).includes('pasted-wrapper'))
 assert((await last().innerText()).includes('recorded offline PASS'))
 await click('Source span #20');await heading('Source span #20');steps.push('Source span #20')
 await click('ctm-plan-p1');await heading('P1 Verify the page source');steps.push('P1')
 await click('Verified page source');await heading('Verified page source');steps.push('WBS 1')
 await tab('Conversation sources');await heading('Conversation sources: ctm-wp-1');steps.push('Conversation sources')
 assert((await last().innerText()).includes('Evidence binding: current'))
 await click('E3 source evidence');await heading('E3 source evidence');steps.push('E3 evidence')
 assert((await last().innerText()).includes('localhost:3000'))
 assert((await last().innerText()).includes('NOT-RUN here'))
 assert((await last().innerText()).includes('E3 — Darstellung'))
 assert((await last().innerText()).includes('Decision: open'))
 await page.screenshot({path:path.join(output,'e3-evidence.png'),fullPage:false})
 await click('Source span #20');await heading('Source span #20')
 await click('Message #20');await heading('Message #20');steps.push('return to same coordinate')
 await click('Conversation Session');await heading('Conversation chronology')
 await click('Message #2');await heading('Message #2')
 await click('Source span #2');await heading('Source span #2')
 await click('claude-review');await tab('Conversation findings');await heading('Review in Message #2')
 await click('F3');await last().getByRole('heading',{name:'Claude finding F3',exact:true}).waitFor();steps.push('Message #2 → review → existing F3')
 // Existing finding return links reach the original case and its Workspace.
 await last().getByText('Revision case',{exact:true}).first().click()
 await heading('Collaborative planning — the documented revision case');steps.push('Planning case')
 // Return to the coordinate Workspace through an existing Chronology pane.
 await page.locator('.inspector-pane').filter({has:page.getByRole('heading',{name:'Conversation chronology',exact:true})}).last()
  .getByText('Conversation Workspace',{exact:true}).first().click()
 await page.locator('.dreyeck-topicmap-point-sign[data-topic-id="session"]').last().waitFor();steps.push('native Workspace')
 for(const id of ['message-20','ctm-plan-p1','ctm-wp-1']){
  await last().locator(`.dreyeck-topicmap-workspace-action[data-topic-id="${id}"]`).last().dispatchEvent('click')
  await last().locator(`.dreyeck-topicmap-point-sign[data-topic-id="${id}"]`).waitFor()
 }
 const workspacePane=page.locator('.inspector-pane').nth(await page.locator('.inspector-pane').count()-1)
 await tab('Slots')
 const history=last().getByRole('row').filter({hasText:/^history/i}).first()
 await history.waitFor()
 await history.locator('td').last().click()
 await tab('Items')
 const values=await last().innerText()
 for(const id of ['ctm-plan-p1','message-20','session'])assert(values.includes(id),values)
 steps.push('History values inspected through native Slots → Items')
 // Return to the Workspace pane and confirm its retained Point.
 await workspacePane.getByRole('button',{name:'Topicmap',exact:true}).first().click()
 await workspacePane.locator('.dreyeck-topicmap-point-sign[data-topic-id="ctm-wp-1"]').waitFor()
 await page.locator('.inspector-pane').filter({has:page.getByRole('heading',{name:'Conversation chronology',exact:true})}).last()
  .locator('p').filter({hasText:'Cursor:'}).getByText('Message #8',{exact:true}).waitFor()
 steps.push('Point retained and Chronology cursor still #8')
 const text=await page.locator('body').innerText()
 assert(!text.includes('/.claude/'));assert(!text.includes('/.codex/'))
 assert.deepEqual(before,sources.map(sha));assert.deepEqual(errors,[])
 await page.screenshot({path:path.join(output,'workspace.png'),fullPage:false})
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',browser:browser.version(),development:false,
  packaged:!!executable,policy:'ENFORCED',writer:executable?'static Catalog closure verified separately':'ABSENT',steps,sourcesUnchanged:true,privateBodiesPublished:false,privatePathsDisclosed:false},null,2))
 console.log('CONVERSATION-BROWSER-PASS: '+steps.join(' → '))
}catch(e){
 if(browser){const pages=browser.contexts().flatMap(c=>c.pages());if(pages.length){fs.writeFileSync(path.join(output,'failure.txt'),await pages[0].locator('body').innerText());await pages[0].screenshot({path:path.join(output,'failure.png')})}}
 throw e
}finally{
 if(browser)await browser.close();fs.writeFileSync(stop,'');if(executable && child.exitCode===null)child.kill('SIGTERM')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.rmSync(temp,{recursive:true,force:true})
}
