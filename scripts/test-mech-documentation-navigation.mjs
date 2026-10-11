// Fresh local CLOG Inspector; live read-only Wiki retrieval, no execution-host clicks.
// Usage: node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT_DIRECTORY
// OUTPUT_DIRECTORY must be outside the source repository.
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,playwrightPath,chrome,output]=process.argv.slice(2)
if(!output)throw Error('Usage: LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT_DIRECTORY')
assert(!path.resolve(output).startsWith(process.cwd()+path.sep),'Keep verification output outside the repository')
fs.mkdirSync(output,{recursive:true})
const work=fs.mkdtempSync(path.join(os.tmpdir(),'mech-documentation-')),stop=path.join(work,'stop')
const probe=net.createServer();await new Promise(r=>probe.listen(0,'127.0.0.1',r))
const port=probe.address().port;await new Promise(r=>probe.close(r))
const origin=`http://127.0.0.1:${port}`,script=path.join(work,'witness.lisp')
fs.writeFileSync(script,`(require :asdf)
(asdf:load-system "dreyeck/work/reading/tests")
(defvar *navigation-inspector* nil)
(setf hyperbook/fedwiki::*mech-plugin-host-url* "https://mech.dreyeck.ch/assets/hyperdoc-mech/")
(clog:initialize
 (lambda (body)
   (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
   (setf *navigation-inspector* (clog-moldable-inspector::create-inspector body :pane-width "700px" :playground? nil))
   (clog-moldable-inspector::create-pane *navigation-inspector*
     (hyperbook:find-page (hyperbook:find-hyperbook "dreyeck/work/reading") "Trails Rendered public reproduction") :select "Content"))
 :port ${port} :host "127.0.0.1")
(format t "~&DOCUMENTATION-BROWSER-READY~%") (finish-output)
(unwind-protect
 (progn
  (loop repeat 2400 until (probe-file #p"${stop}") do (sleep 0.1))
  (dolist (spec '(("mech.dreyeck.ch" "hyperdoc-mech") ("ward.voices.ustawi.wiki" "trails-rendered")))
   (let* ((wiki (hyperbook:find-hyperbook (concatenate 'string "fedwiki:" (first spec))))
          (expected (hyperbook:find-page wiki (second spec)))
          (objects (mapcar #'clog-moldable-inspector::pane-object
                     (fset:convert 'list (clog-moldable-inspector::inspector-panes *navigation-inspector*)))))
    (assert (typep expected 'hyperbook/fedwiki::fedwiki-page))
    (assert (member expected objects :test #'eq))
    (format t "~&CLICKED-FEDWIKI-PAGE ~A ~A~%" (hyperbook:id-of wiki) (hyperbook:id-of expected)))))
 (clog:shutdown))
`)
const log=fs.openSync(path.join(output,'lisp.log'),'w')
const child=spawn(lisp,['--load',script],{stdio:['ignore',log,log]})
const report={kind:'Fresh local Inspector, live read-only Wiki sources',checks:[],hostRequests:[],productionActivation:false}
let browser
try{
  for(let i=0;i<1200;i++){
    if(child.exitCode!==null)throw Error(fs.readFileSync(path.join(output,'lisp.log'),'utf8').slice(-4000))
    if(fs.readFileSync(path.join(output,'lisp.log'),'utf8').includes('DOCUMENTATION-BROWSER-READY'))break
    await new Promise(r=>setTimeout(r,100))
  }
  const {chromium}=await import(pathToFileURL(path.join(playwrightPath,'index.mjs')))
  browser=await chromium.launch({headless:true,executablePath:chrome})
  report.browser=browser.version()
  const context=await browser.newContext({serviceWorkers:'block'})
  // Fail closed: do not execute a host, including when later checking the Ward link.
  await context.route('**/assets/hyperdoc-mech/**',route=>{report.hostRequests.push(route.request().url());return route.abort()})
  const page=await context.newPage();page.setDefaultTimeout(60000)
  await page.goto(origin)
  const link=page.locator('.hyperbook-reference').filter({hasText:/^HyperDoc Mech$/})
  await link.waitFor();await link.locator('[id]').click()
  await page.getByRole('heading',{name:'HyperDoc Mech',exact:true}).waitFor()
  await page.getByText('HyperDoc Mech provides a browser-side execution environment',{exact:false}).first().waitFor()
  assert.equal(await page.locator('iframe').count(),0)
  assert.equal(await page.locator('.fedwiki-mech-host').count(),0)
  assert.equal(context.pages().length,1)
  assert.deepEqual(report.hostRequests,[])
  report.documentationHostRequests=[]
  report.checks.push('Native HyperBook link opens live HyperDoc Mech Story; no host frame, host request or popup')
  // Returning to the original pane does not replace the existing Ward link.
  await page.locator('.hyperbook-reference').filter({hasText:/^Trails Rendered$/}).locator('[id]').click({modifiers:['Shift']})
  await page.getByRole('heading',{name:'Trails Rendered',exact:true}).waitFor()
  report.checks.push('Existing Ward Trails Rendered link opens its Inspector Story')
  fs.writeFileSync(stop,'')
  await new Promise((resolve,reject)=>{
    if(child.exitCode!==null)return child.exitCode===0?resolve():reject(Error('Lisp failed'))
    child.once('exit',code=>code===0?resolve():reject(Error(`Lisp exit ${code}`)))
    setTimeout(()=>reject(Error('Lisp object-identity check timed out')),10000).unref()
  })
  const result=fs.readFileSync(path.join(output,'lisp.log'),'utf8')
  assert(result.includes('CLICKED-FEDWIKI-PAGE fedwiki:mech.dreyeck.ch hyperdoc-mech'))
  assert(result.includes('CLICKED-FEDWIKI-PAGE fedwiki:ward.voices.ustawi.wiki trails-rendered'))
  report.checks.push('Actual clicked pane objects verified by EQ against both native site/slug lookups')
  report.status='PASS'
}catch(error){report.status='FAIL';report.failure=error.stack;throw error}
finally{
  if(browser)await browser.close()
  if(child.exitCode===null)child.kill('SIGTERM')
  fs.closeSync(log)
  fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2)+'\n')
}
console.log(JSON.stringify(report,null,2))
