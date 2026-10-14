// Fresh loopback Catalog/Inspector, exact retained Wiki pages; no Mech host.
// node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,pw,chrome,output]=process.argv.slice(2)
if(!output)throw Error('LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT required')
fs.mkdirSync(output,{recursive:true})
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'hub-reading-browser-')),stop=path.join(temp,'stop')
const server=net.createServer();await new Promise(r=>server.listen(0,'127.0.0.1',r))
const port=server.address().port;await new Promise(r=>server.close(r))
const script=path.join(temp,'witness.lisp'),log=path.join(output,'lisp.log')
fs.writeFileSync(script,`(require :asdf)
(asdf:load-system "dreyeck/work/reading/tests")
(dreyeck/work/hubs/tests:seed-hub-wiki-pages)
(clog:initialize (lambda (body)
 (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
 (let ((i (clog-moldable-inspector::create-inspector body :pane-width "750px" :playground? nil)))
  (clog-moldable-inspector::create-pane i hyperbook::*catalog* :select "HyperBooks"))
 (let ((probe (clog:create-button body :content "Probe workspace state"))
       (result (clog:create-div body :content "No workspace probe")))
  (clog:set-on-click probe (lambda (event) (declare (ignore event))
    (let ((w (dreyeck/work/hubs::hub-and-trail-workspace)))
      (setf (clog:text result) (format nil "Point=~A; History=~S"
        (dreyeck/topicmap:topicmap-workspace-point-of w)
        (dreyeck/topicmap:topicmap-workspace-history-of w)))))))) :host "127.0.0.1" :port ${port})
(format t "~&HUBS-BROWSER-READY~%") (finish-output)
(unwind-protect (loop repeat 2400 until (probe-file #p"${stop}") do (sleep .1)) (clog:shutdown))`)
const fd=fs.openSync(log,'w'),child=spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
let browser
try {
 for(let n=0;n<1200;n++){if(child.exitCode!==null)throw Error(fs.readFileSync(log,'utf8').slice(-4000));if(fs.readFileSync(log,'utf8').includes('HUBS-BROWSER-READY'))break;await new Promise(r=>setTimeout(r,100))}
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch({headless:true,executablePath:chrome})
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).hostname==='127.0.0.1'?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(30000)
 await page.goto(`http://127.0.0.1:${port}`)
 await page.getByText('Working on HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByRole('button',{name:'Text pages',exact:true}).last().click()
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'What Counts as a Hub?'}).last().click()
 await page.getByRole('heading',{name:'What Counts as a Hub?',exact:true}).last().waitFor()
 await page.getByText('Reading Mech Hubs',{exact:true}).and(page.locator(':visible')).first().click()
 await page.locator('.inspector-pane').last().locator('.inspector-title').filter({hasText:'Reading Mech Hubs'}).waitFor()
 await page.locator('.inspector-pane').last().getByRole('button',{name:'Hub evidence',exact:true}).click()
 await page.getByText('The Source view retains this Code Page', {exact:false}).last().waitFor()
 await page.locator('.inspector-pane').last().getByText('hubs',{exact:true}).click()
 await page.getByRole('heading',{name:'Mech source: hubs',exact:true}).last().waitFor()
 assert((await page.locator('pre').allTextContents()).some(t=>t.includes('function hubs(count = 12)')))
 await page.getByText('blanket',{exact:true}).and(page.locator(':visible')).last().click()
 await page.getByRole('heading',{name:'Mech source: blanket',exact:true}).last().waitFor()
 await page.getByText('Synthetic selection and expansion',{exact:true}).and(page.locator(':visible')).last().click()
 await page.getByRole('heading',{name:'Synthetic hub selection and expansion',exact:true}).last().waitFor()
 await page.getByText('Input neighborhood',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByText('Return to What Counts as a Hub?',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByText('Hub and Trail Workspace',{exact:true}).and(page.locator(':visible')).last().click()
 await page.locator('.dreyeck-topicmap-workspace-action[data-topic-id="hubs"]').last().click()
 await page.locator('.dreyeck-topicmap-point-sign[data-topic-id="hubs"]').last().waitFor()
 await page.getByRole('button',{name:'Probe workspace state',exact:true}).click()
 await page.getByText('Point=hubs; History=("definition")',{exact:true}).waitFor()
 // Point's represented source object is independently navigable.
 await page.getByText('Mech hubs source',{exact:true}).and(page.locator(':visible')).last().click()
 await page.getByRole('heading',{name:'Mech source: hubs',exact:true}).last().waitFor()
 await page.getByText('From Two Hubs to One Trail',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByRole('heading',{name:'From Two Hubs to One Trail',exact:true}).last().waitFor()
 const expectedMessage="Here, while browsing \"hubs\" I selected two that I though would connect. They didn't. So clicked four nodes to make a \"trail\" which will render as its own kind of symbol. This is my first end-to-end run through the new code in Mech and Solo plugins."
 assert.equal(await page.locator('.inspector-pane').last().locator('blockquote').innerText(),expectedMessage)
 assert((await page.locator('.inspector-pane').last().innerText()).includes("The transmission date does not establish the message's publication date."))

 await page.locator('.inspector-pane').last().getByText('Dewey Alexander Trail',{exact:true}).click()
 await page.locator('.inspector-pane').last().locator('.inspector-title').filter({hasText:'Dewey Alexander Trail'}).waitFor()
 await page.locator('.inspector-pane').last().getByRole('button',{name:'Hub and trail reading',exact:true}).click()
 await page.getByRole('heading',{name:'Dewey Alexander Trail — source and reading',exact:true}).last().waitFor()
 await page.getByText("Ward's How Trails Travel Plan",{exact:true}).and(page.locator(':visible')).last().click()
 await page.getByRole('heading',{name:"Ward's plan — original order",exact:true}).last().waitFor()
 await page.getByText('Plan step fcbf4b3a2dcbe81b',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByText('composite',{exact:true}).and(page.locator(':visible')).last().click()
 await page.getByRole('heading',{name:'composite',exact:true}).last().waitFor()
 await page.getByText('composite — full function definition',{exact:true}).and(page.locator(':visible')).last().click()
 await page.getByRole('heading',{name:'JavaScript definition: composite',exact:true}).last().waitFor()
 assert.equal(await page.locator('iframe').count(),0)
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',browser:browser.version(),scope:'fresh local CLOG, retained original Wiki JSON, synthetic execution evidence; no production claim'},null,2))
 console.log('HUBS-BROWSER-PASS: Catalog/Code/source/blanket/evidence, native Point+History, original site-qualified Wiki page → Plan → Solo definition; no executable host')
}finally{
 if(browser)await browser.close();fs.writeFileSync(stop,'')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.closeSync(fd)
}
