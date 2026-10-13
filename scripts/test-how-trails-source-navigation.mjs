// Fresh disposable CLOG Inspector; retained original Wiki JSON is seeded explicitly.
// No production runtime or Wiki JavaScript execution. Logs stay in OUTPUT.
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,pw,chrome,output]=process.argv.slice(2)
if(!output) throw Error('LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT required')
fs.mkdirSync(output,{recursive:true})
const work=fs.mkdtempSync(path.join(os.tmpdir(),'how-trails-navigation-')),stop=path.join(work,'stop')
const server=net.createServer(); await new Promise(r=>server.listen(0,'127.0.0.1',r))
const port=server.address().port; await new Promise(r=>server.close(r))
const script=path.join(work,'witness.lisp'), log=path.join(output,'lisp.log')
fs.writeFileSync(script,`(require :asdf)
(asdf:load-system "dreyeck/work/reading/tests")
(defparameter *direct-page* (dreyeck/work/trails-rendered-reading/tests::seed-how-trails-page))
(assert (zerop (hash-table-count dreyeck/work/trails-rendered-reading::*how-trails-sources*)))
(clog:initialize (lambda (body)
 (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
 (let ((i (clog-moldable-inspector::create-inspector body :pane-width "700px" :playground? nil)))
 (clog-moldable-inspector::create-pane i *direct-page* :select "Story"))) :host "127.0.0.1" :port ${port})
(format t "~&HOW-TRAILS-BROWSER-READY~%") (finish-output)
(unwind-protect (loop repeat 2400 until (probe-file #p"${stop}") do (sleep .1)) (clog:shutdown))`)
const fd=fs.openSync(log,'w'), child=spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
let browser
try {
 for(let n=0;n<1200;n++) {
  if(child.exitCode!==null) throw Error(fs.readFileSync(log,'utf8').slice(-4000))
  if(fs.readFileSync(log,'utf8').includes('HOW-TRAILS-BROWSER-READY'))break
  await new Promise(r=>setTimeout(r,100))
 }
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch({headless:true,executablePath:chrome})
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).hostname==='127.0.0.1'?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(30000)
 await page.goto(`http://127.0.0.1:${port}`)
 await page.getByRole('heading',{name:'How Trails Travel',exact:true}).waitFor()
 // No selection of Source references precedes any of these four item journeys.
 for(const anchor of ['#L107','#L182-L227','#L318-L378','#L382-L446'])
  assert(await page.locator(`a[href$="${anchor}"]`).count()>0)
 for(const [id,name,code] of [
  ['fcbf4b3a2dcbe81b','composite','function composite(concepts)'],
  ['f6ed717454f29690','window.dochoose','window.dochoose ='],
  ['d1b0aa5e1a47349e','display','async function display(chosen)'],
  ['d41b9ef67e45521e','dotify','function dotify(complex)']]) {
  await page.getByText('Inspect story item '+id,{exact:true}).first().click()
  await page.getByRole('button',{name:'Source reference',exact:true}).last().click()
  await page.getByText(name,{exact:true}).last().click()
  await page.getByRole('heading',{name,exact:true}).last().waitFor()
  assert((await page.locator('pre').allTextContents()).some(t=>t.includes(code)))
  if(name==='composite') {
   const definitions=JSON.parse(fs.readFileSync('dreyeck/work/how-trails-definitions.json','utf8')).definitions
   await page.getByText('composite — full function definition',{exact:true}).last().click()
   for(const definition of definitions) {
    await page.getByRole('heading',{name:'JavaScript definition: '+definition.key,exact:true}).last().waitFor()
    assert((await page.locator('pre').allTextContents()).includes(definition.text))
    if(definition.name==='composite')await page.getByText('merge',{exact:true}).last().click()
    if(definition.name==='merge')await page.getByText('mergeprops',{exact:true}).last().click()
   }
   assert((await page.locator('body').innerText()).includes('not an isolated test'))
   await page.getByText('Enclosing definition',{exact:true}).last().click()
   await page.getByRole('heading',{name:'JavaScript definition: composite/merge',exact:true}).last().waitFor()
   await page.getByText('Enclosing definition',{exact:true}).last().click()
   await page.getByRole('heading',{name:'JavaScript definition: composite',exact:true}).last().waitFor()
   await page.getByText('Composite execution evidence',{exact:true}).last().click()
   await page.getByText('cases',{exact:true}).last().waitFor()
   await page.getByText("Ward's original page",{exact:true}).last().click()
   await page.getByRole('heading',{name:'How Trails Travel',exact:true}).last().waitFor()
   console.log('PASS: Story → source reference → composite → merge → mergeprops; complete AST source, lexical parents, retained evidence and original page return')
  }

 }
 // Only after all four direct journeys, check the page-wide view and Links.
 await page.getByRole('button',{name:'Links',exact:true}).first().click()
 for(const anchor of ['#L107','#L182-L227','#L318-L378','#L382-L446'])
  await page.locator(`a[href$="${anchor}"]`).last().waitFor()
 await page.getByRole('button',{name:'Source references',exact:true}).first().click()
 for(const id of ['f6ed717454f29690','d1b0aa5e1a47349e','fcbf4b3a2dcbe81b','d41b9ef67e45521e'])
  await page.getByText(id,{exact:true}).first().waitFor()
 await page.getByText('composite',{exact:true}).first().click()
 await page.getByText('Pinned Git revision',{exact:true}).last().click()
 await page.getByText('Full OID:',{exact:false}).last().waitFor()
 assert((await page.locator('body').innerText()).includes('17915844349bada64c901bd5ea73472702c446f9'))
 await page.getByText('client/dialog/index.html',{exact:true}).last().click()
 await page.getByText('Relevant definitions and exact retained source ranges.',{exact:false}).waitFor()
 await page.getByText('Return to How Trails Travel',{exact:true}).first().click()
 await page.getByText('Inspect the offline execution record',{exact:true}).last().click()
 await page.getByText('cases',{exact:true}).last().waitFor()
 // The same original page provides ordered Plan and Refactor views.
 await page.getByRole('button',{name:'Plan',exact:true}).first().click()
 const ids=['f6ed717454f29690','d60bd1c1d8fdd32b','fc195fe5fbc3592f','d1b0aa5e1a47349e','fcbf4b3a2dcbe81b','d41b9ef67e45521e','db592e6139141964','93dc48d83a96cd61','8771026b69762044','aac36e1826b25199']
 await page.getByRole('heading',{name:"Ward's plan — original order",exact:true}).waitFor()
 const planText=await page.locator('body').innerText()
 for(let i=1;i<ids.length;i++) assert(planText.indexOf('Plan step '+ids[i-1])<planText.indexOf('Plan step '+ids[i]))
 await page.getByText('Plan step fcbf4b3a2dcbe81b',{exact:true}).first().click()
 await page.getByRole('heading',{name:'Plan step fcbf4b3a2dcbe81b',exact:true}).last().waitFor()
 await page.getByText('composite',{exact:true}).last().click()
 await page.getByRole('heading',{name:'composite',exact:true}).last().waitFor()
 await page.getByText('Return to original plan step',{exact:true}).last().click()
 await page.getByRole('heading',{name:'Plan step fcbf4b3a2dcbe81b',exact:true}).last().waitFor()
 await page.getByText('overlap: complex',{exact:true}).last().click()
 await page.getByText('merged',{exact:true}).last().waitFor()
 await page.getByText('Return to original plan',{exact:true}).last().click()
 await page.getByRole('heading',{name:"Ward's plan — original order",exact:true}).last().waitFor()
 await page.getByRole('button',{name:'Refactor',exact:true}).last().click()
 await page.getByRole('heading',{name:"Ward's architecture question",exact:true}).last().waitFor()
 assert((await page.locator('body').innerText()).includes('Graphviz is called by display, not by dotify'))
 await page.getByText('Full retained source',{exact:true}).last().click()
 await page.locator('.ace_editor').last().waitFor()
 await page.waitForFunction(()=>[...document.querySelectorAll('.ace_editor')].some(e=>e.env?.editor?.getValue().includes('display(chosen)')))
 const shown=await page.evaluate(()=>[...document.querySelectorAll('.ace_editor')].map(e=>e.env.editor.getValue()).find(t=>t.includes('display(chosen)')))
 assert.equal(shown,fs.readFileSync('assets/hyperbook/fedwiki/mech-host/plugins/solo/dialog/index.html','utf8'))
 console.log('PASS: original Plan order, exact item → source → original step, concrete overlap evidence, return, Refactor → full retained source')
 assert.equal(await page.locator('iframe').count(),0)
 console.log('PASS: fresh direct Story entry (composite first), four item → source journeys without page-wide view, Git/file coordinates, reading → counterexample; no executable frame')
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',browser:browser.version(),fixture:'exact retained original How Trails Travel JSON; no live site claim'},null,2))
} finally {
 if(browser)await browser.close()
 fs.writeFileSync(stop,'')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.closeSync(fd)
}
