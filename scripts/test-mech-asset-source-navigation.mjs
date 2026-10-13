// Fresh local CLOG; inspect the real operation and an inertness sentinel.
// node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import {spawn,spawnSync} from 'node:child_process'
import {fileURLToPath,pathToFileURL} from 'node:url'
const [lisp,pw,chrome,output]=process.argv.slice(2)
if(!output)throw Error('LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT required')
const root=fileURLToPath(new URL('../',import.meta.url))
fs.mkdirSync(output,{recursive:true})
const work=fs.mkdtempSync(path.join(os.tmpdir(),'asset-source-view-'))
const stop=path.join(work,'stop'),marker=path.join(work,'EXECUTED'),fixture=path.join(work,'inert.sh')
const sentinel=`#!/bin/sh\n# UTF-8 source: Prüfung → read-only\nprintf executed > '${marker}'\n`
fs.writeFileSync(fixture,sentinel)
fs.chmodSync(fixture,0o755)
const server=net.createServer();await new Promise(r=>server.listen(0,'127.0.0.1',r))
const port=server.address().port;await new Promise(r=>server.close(r))
const script=path.join(work,'run.lisp'),log=path.join(output,'lisp.log')
fs.writeFileSync(script,`(require :asdf)
(asdf:load-system "dreyeck/work/reading/tests")
(clog:initialize (lambda (body)
 (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
 (let ((i (clog-moldable-inspector::create-inspector body :pane-width "700px" :playground? nil)))
   (clog:set-on-click (clog:create-button body :content "Inspect inert shell fixture")
     (lambda (event) (declare (ignore event))
       (clog-moldable-inspector::create-pane i #p"${fixture}" :select "Text")))
   (clog-moldable-inspector::create-pane i
     (hyperbook:find-page (hyperbook:find-hyperbook "dreyeck/work/reading") "dreyeck.ch deployment") :select "Content")))
 :host "127.0.0.1" :port ${port})
(format t "~&ASSET-SOURCE-BROWSER-READY~%") (finish-output)
(unwind-protect (loop repeat 2400 until (probe-file #p"${stop}") do (sleep .1)) (clog:shutdown))`)
const fd=fs.openSync(log,'w'),child=spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
let browser
try {
 let ready=false
 for(let n=0;n<1200;n++) {
  if(child.exitCode!==null)throw Error(fs.readFileSync(log,'utf8').slice(-4000))
  if(fs.readFileSync(log,'utf8').includes('ASSET-SOURCE-BROWSER-READY')){ready=true;break}
  await new Promise(r=>setTimeout(r,100))
 }
 assert(ready,'fresh Inspector startup timed out')
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch({headless:true,executablePath:chrome})
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).hostname==='127.0.0.1'?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(30000)
 await page.goto(`http://127.0.0.1:${port}`)
 const assertSource=async (needle,expected)=>{
  await page.waitForFunction(text=>[...document.querySelectorAll('.ace_editor')]
   .some(e=>window.ace?.edit(e).getValue().includes(text)),needle)
  const shown=await page.evaluate(text=>[...document.querySelectorAll('.ace_editor')]
   .map(e=>({text:window.ace.edit(e).getValue(),readOnly:window.ace.edit(e).getReadOnly()}))
   .find(x=>x.text.includes(text)),needle)
  assert(shown.readOnly)
  assert.deepEqual(Buffer.from(shown.text,'utf8'),expected)
 }
 await page.getByText('Inspect the asset-switch operation',{exact:true}).click()
 await page.getByRole('button',{name:'Text',exact:true}).last().waitFor()
 await assertSource('APPROVE_ASSET_SWITCH',fs.readFileSync(path.join(root,'scripts/mech-asset-switch.sh')))
 await page.getByText('Mech asset procedure and rollback',{exact:true}).click()
 await assertSource('Mech in the FedWiki Story Inspector',fs.readFileSync(path.join(root,'docs/fedwiki-mech-story.md')))
 await page.getByRole('button',{name:'Inspect inert shell fixture',exact:true}).click()
 await assertSource('Prüfung',Buffer.from(sentinel,'utf8'))
 assert(!fs.existsSync(marker),'Inspecting a shell source must not run it')
 // Positive control, separate from inspection: the trusted sentinel would run.
 assert.equal(spawnSync('/bin/sh',[fixture]).status,0);assert(fs.existsSync(marker))
 assert.equal(await page.locator('iframe').count(),0)
 const result={status:'PASS',browser:browser.version(),checks:['Native reading/pathname/Text journey',
  'Script bytes match UTF-8 editor bytes exactly','Existing Markdown Text path unchanged',
  'Read-only editors','Shell execution sentinel not created','No Mech frame']}
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify(result,null,2)+'\n')
 console.log(JSON.stringify(result))
} finally {
 if(browser)await browser.close()
 fs.writeFileSync(stop,'')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.closeSync(fd)
 fs.rmSync(work,{recursive:true,force:true})
}
