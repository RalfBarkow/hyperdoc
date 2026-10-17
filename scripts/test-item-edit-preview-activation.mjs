// The non-writing Item edit preview, activated the way a served Catalog is
// configured: START-CATALOG with an additive catalog system, development off.
// Phase A, the default Catalog: E3 has no Edit tab. Phase B, with
// HYPERDOC_CATALOG_SYSTEM's value dreyeck/fedwiki-item-edit-preview:
// /view → Page source → E3 → Edit → Edit proposal → Preview, no writer loaded,
// the page file unchanged.
// node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT
import {installBoundClicks} from './lib/inspector-ready.mjs'
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
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'item-edit-activation-'))
// The retained page has the digest the productive Page source view reported.
const evidence=path.resolve(path.dirname(new URL(import.meta.url).pathname),'../dreyeck/work/ctm-page-evidence/ctm-and-tmdm-in-hyperdoc.json')
const site=path.join(temp,'site'),pageFile=path.join(site,'pages','ctm-and-tmdm-in-hyperdoc')
fs.mkdirSync(path.dirname(pageFile),{recursive:true});fs.copyFileSync(evidence,pageFile)
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')
const observed='d7215c50f4efa07b3e94749b060b7d7b828654f2a44caab7f1034415c6003dff'
assert.equal(sha(pageFile),observed)
const freePort=async()=>{const s=net.createServer();await new Promise(r=>s.listen(0,'127.0.0.1',r));const p=s.address().port;await new Promise(r=>s.close(r));return p}
const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
const browser=await chromium.launch({headless:true,executablePath:chrome})
const results={}

async function phase(name,catalogSystem,drive){
 const port=await freePort(),stop=path.join(temp,`${name}.stop`),script=path.join(temp,`${name}.lisp`),log=path.join(output,`${name}.log`)
 fs.writeFileSync(script,`(require :asdf)
(asdf:load-system "dreyeck/catalog-application")
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1"
 :site-root ${JSON.stringify(site+'/')} :catalog-system ${JSON.stringify(catalogSystem)})
(format t "~&WRITER-LOADED=~A~%" (if (or (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING") (asdf:component-loaded-p "dreyeck/fedwiki-page-authoring")) "YES" "NO"))
(format t "~&PREVIEW-LOADED=~A~%" (if (asdf:component-loaded-p "dreyeck/fedwiki-item-edit-preview") "YES" "NO"))
(format t "~&POLICY-ENFORCED=~A~%" (if (dreyeck/authority-policy:policy-enforced-p) "YES" "NO"))
(format t "~&ACTIVATION-READY~%") (finish-output)
(unwind-protect (loop repeat 2400 until (probe-file #p"${stop}") do (sleep .1)) (clog:shutdown))`)
 const fd=fs.openSync(log,'w'),child=spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
 try{
  for(let n=0;n<1800;n++){if(child.exitCode!==null)throw Error(fs.readFileSync(log,'utf8').slice(-4000));if(fs.readFileSync(log,'utf8').includes('ACTIVATION-READY'))break;await new Promise(r=>setTimeout(r,100))}
  const text=fs.readFileSync(log,'utf8'),flag=k=>(text.match(new RegExp(`${k}=(YES|NO)`))||[])[1]
  const context=await browser.newContext({serviceWorkers:'block'})
  await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
  const page=await context.newPage();page.setDefaultTimeout(30000);installBoundClicks(page)
  const errors=[];page.on('pageerror',e=>errors.push(e.message))
  const last=()=>page.locator('.inspector-pane').last()
  const tab=async label=>last().getByRole('button',{name:label,exact:true}).first().click()
  const heading=async label=>last().getByRole('heading',{name:label,exact:true}).waitFor()
  await page.goto(`http://127.0.0.1:${port}/view/ctm-and-tmdm-in-hyperdoc`)
  await last().locator('.inspector-title').filter({hasText:'CTM and TMDM in HyperDoc'}).first().waitFor()
  await tab('Page source');await last().getByText(observed,{exact:true}).first().waitFor()
  await last().getByText('ed37e9bac2fcd548',{exact:true}).first().click();await heading('Story Item ed37e9bac2fcd548')
  assert((await last().innerText()).includes('11 of 18'))
  const steps=await drive({page,last,tab,heading})
  assert.deepEqual(errors,[])
  await context.close()
  results[name]={catalogSystem,writerLoaded:flag('WRITER-LOADED'),previewLoaded:flag('PREVIEW-LOADED'),policyEnforced:flag('POLICY-ENFORCED'),steps}
 }finally{
  fs.writeFileSync(stop,'')
  await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 }
}

try{
 await phase('default','dreyeck/catalog',async({last})=>{
  // As observed in production: the Story item is inspectable, with no Edit tab.
  assert.equal(await last().getByRole('button',{name:'Edit',exact:true}).count(),0)
  return ['/view','Page source','Story Item E3','no Edit tab']
 })
 await phase('activated','dreyeck/fedwiki-item-edit-preview',async({page,last,tab,heading})=>{
  await tab('Edit');await last().getByText('Prepare edit proposal',{exact:true}).first().click()
  await heading('Edit proposal for ed37e9bac2fcd548')
  const proposed='E3 — Darstellung: Association-Knoten. Decision: activation regression example, not a decision.'
  const input=last().locator('input').first()  // hvr:input writes type="TEXT"
  await input.fill(proposed);await input.dispatchEvent('change');await page.waitForTimeout(500)
  await last().getByText('Preview',{exact:true}).first().click();await heading('Preview: edit of ed37e9bac2fcd548')
  const text=await last().innerText()
  for(const expected of ['ed37e9bac2fcd548',observed,'Rollentyp-Topics',proposed,'Item 11 is replaced; 17 Items stay','Journal: 2 entries become 3','Executed: no.'])
   assert(text.includes(expected),expected)
  return ['/view','Page source','Story Item E3','Edit','Edit proposal','Preview']
 })
 assert.equal(results.default.previewLoaded,'NO');assert.equal(results.activated.previewLoaded,'YES')
 for(const name of ['default','activated']){
  assert.equal(results[name].writerLoaded,'NO',`${name}: the page-authoring writer must not be loaded`)
  assert.equal(results[name].policyEnforced,'YES',`${name}: served-mode policy must be enforced`)
 }
 assert.equal(sha(pageFile),observed);assert.deepEqual(fs.readdirSync(path.dirname(pageFile)),['ctm-and-tmdm-in-hyperdoc'])
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',browser:browser.version(),pageSha256:sha(pageFile),results},null,2))
 console.log(`ITEM-EDIT-PREVIEW-ACTIVATION-PASS: default Catalog: ${results.default.steps.join(' → ')}; activated: ${results.activated.steps.join(' → ')}; writer not loaded, policy enforced, page file ${observed} unchanged`)
}finally{
 await browser.close()
 fs.rmSync(temp,{recursive:true,force:true})
}
