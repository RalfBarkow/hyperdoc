// The documentation of the Item edit path, read in an actual served Catalog (development off, policy enforced) that
// serves the local review system. Nothing is written; the site is an empty temporary directory.
//   Working on HyperDoc → Text pages → Work Breakdown → Author the CTM Plan Page → implementation state
//   → Item Edit Path in HyperDoc → class, function with Source code, system
// node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT   (TOPIC_MAPS_ROOT: the topic-maps checkout)
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
const topicMaps=process.env.TOPIC_MAPS_ROOT
if(!output||!topicMaps)throw Error('LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT and TOPIC_MAPS_ROOT required')
fs.mkdirSync(output,{recursive:true})
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'ctm-documentation-browser-'))
const site=path.join(temp,'site');fs.mkdirSync(path.join(site,'pages'),{recursive:true})
const retained=path.resolve(path.dirname(new URL(import.meta.url).pathname),'../dreyeck/work/ctm-page-evidence/site/pages/ctm-and-tmdm-in-hyperdoc')
const pageFile=path.join(site,'pages','ctm-and-tmdm-in-hyperdoc');fs.copyFileSync(retained,pageFile)
const sha=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex'),before=sha(pageFile)
const port=await new Promise(r=>{const s=net.createServer();s.listen(0,'127.0.0.1',()=>{const p=s.address().port;s.close(()=>r(p))})})
const stop=path.join(temp,'stop'),script=path.join(temp,'witness.lisp'),log=path.join(output,'lisp.log')
fs.writeFileSync(script,`(require :asdf)
(pushnew #p${JSON.stringify(topicMaps.endsWith('/')?topicMaps:topicMaps+'/')} asdf:*central-registry* :test (function equal))
(asdf:load-system "dreyeck/catalog-application")
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1" :site-root ${JSON.stringify(site+'/')}
 :catalog-system "dreyeck/ctm-page-authoring/local" :development nil)
(assert (dreyeck/authority-policy:policy-enforced-p))
(format t "~&DOCUMENTATION-BROWSER-READY~%") (finish-output)
(unwind-protect (loop repeat 3000 until (probe-file #p${JSON.stringify(stop)}) do (sleep .1)) (clog:shutdown))`)
const fd=fs.openSync(log,'w'),child=spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
const logText=()=>fs.readFileSync(log,'utf8')
const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
const browser=await chromium.launch({headless:true,executablePath:chrome})
const steps=[]
try{
 for(let n=0;n<6000;n++){if(child.exitCode!==null)throw Error(logText().slice(-4000));if(logText().includes('DOCUMENTATION-BROWSER-READY'))break;await new Promise(r=>setTimeout(r,100))}
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(60000);installBoundClicks(page)
 const errors=[];page.on('pageerror',e=>errors.push(e.message))
 const last=()=>page.locator('.inspector-pane').last()
 const click=async label=>last().getByText(label,{exact:true}).first().click()
 const heading=async label=>last().getByRole('heading',{name:label,exact:true}).waitFor()
 await page.goto(`http://127.0.0.1:${port}`)
 await page.getByText('Working on HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByRole('button',{name:'Text pages',exact:true}).last().click()
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'Work Breakdown'}).last().click()
 await heading('Work Breakdown')
 let text=await last().innerText()
 for(const expected of ['How this page uses its terms','PMBOK Guide 2000','Agile Practice Guide 2017','HERMES Online','Reference basis'])assert(text.includes(expected),expected)
 steps.push('Work Breakdown: terms and reference basis')
 await click('Author the CTM Plan Page through HyperDoc');await heading('Authoring the CTM Plan Page')
 text=await last().innerText()
 for(const expected of ['Implementation state of packages 2 to 4','Integrated in source','Locally executable','Tested on temporary copies','Read in the local Inspector','Served on dreyeck.ch','Accepted'])assert(text.includes(expected),expected)
 steps.push('carrier page: implementation state')
 // The edited page is a link to the page object itself, not a URL and not a slug in code.
 await click('ctm-and-tmdm-in-hyperdoc')
 await last().locator('.inspector-title').filter({hasText:'CTM and TMDM in HyperDoc'}).first().waitFor();steps.push('the linked FedWiki page → its local-fedwiki-page')
 await page.getByRole('button',{name:'Page source',exact:true}).last().waitFor()
 // back on the carrier page for the next link
 await page.locator('.inspector-pane').filter({has:page.getByRole('heading',{name:'Authoring the CTM Plan Page',exact:true})}).last().getByText('Item Edit Path in HyperDoc',{exact:true}).first().click()
 await heading('Item Edit Path in HyperDoc')
 text=await last().innerText()
 for(const expected of ['The path and its objects','Three statements about an execution','ASDF systems','Operation','Known limits'])assert(text.includes(expected),expected)
 steps.push('Item Edit Path in HyperDoc')
 const panes=()=>page.locator('.inspector-pane')
 const docIndex=await panes().count()-1   // a captured index: last() would follow the newest pane
 // A link of the documentation pane opens its object in the pane to the right; a later link replaces that pane.
 const open=async(label,title)=>{await panes().nth(docIndex).getByText(label,{exact:true}).first().click()
  await panes().nth(docIndex+1).locator('.inspector-title').filter({hasText:title}).first().waitFor()}
 await open('item-edit-preview','ITEM-EDIT-PREVIEW');steps.push('item-edit-preview → the class')
 await open('execute-completed-edit','EXECUTE-COMPLETED-EDIT')
 await panes().nth(docIndex+1).getByRole('button',{name:'Source code',exact:true}).waitFor();steps.push('execute-completed-edit → the function, with its Source code')
 await open('edit-fedwiki-page-item','EDIT-FEDWIKI-PAGE-ITEM');steps.push('edit-fedwiki-page-item → the writer')
 await open('dreyeck/ctm-page-authoring/local','dreyeck/ctm-page-authoring/local');steps.push('the local system')
 assert.deepEqual(errors,[]);assert.equal(sha(pageFile),before);assert.deepEqual(fs.readdirSync(path.join(site,'pages')),['ctm-and-tmdm-in-hyperdoc'])
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',development:false,policy:'ENFORCED',nothingWritten:true,steps},null,2))
 console.log('DOCUMENTATION-BROWSER-PASS: '+steps.join(' → ')+' | clicks '+JSON.stringify(readiness))
}catch(e){
 const pages=browser.contexts().flatMap(c=>c.pages());if(pages.length){fs.writeFileSync(path.join(output,'failure.txt'),await pages[0].locator('body').innerText());await pages[0].screenshot({path:path.join(output,'failure.png')})}
 throw e
}finally{
 await browser.close();fs.writeFileSync(stop,'')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.rmSync(temp,{recursive:true,force:true})
}
