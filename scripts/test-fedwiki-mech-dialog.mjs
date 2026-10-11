// Fresh CLOG + exact original page. HTTPS Wiki URLs below are intercepted
// offline, never contacted; assets/regular receiver come from the local mirror.
// Usage: node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
import {createMechHost} from './serve-fedwiki-mech-host.mjs'
import {originalPage,provenance as topics,seededRandom} from '../tests/fedwiki-mech-topics-reference.mjs'
import {originalPopup,provenance} from '../tests/fedwiki-mech-popup-reference.mjs'
import {largeSitemaps} from '../tests/fedwiki-mech-dialog-fixture.mjs'
const [lisp,playwrightPath,chrome,output]=process.argv.slice(2)
if(!output)throw Error('Usage: LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT')
fs.mkdirSync(output,{recursive:true})
const work=fs.mkdtempSync(path.join(os.tmpdir(),'mech-dialog-browser-')),stop=path.join(work,'stop'),fixtureFile=path.join(work,'large.json')
const large=largeSitemaps();fs.writeFileSync(fixtureFile,JSON.stringify(large))
const host=createMechHost();await new Promise(r=>host.listen(0,'127.0.0.1',r))
const localHost=`http://127.0.0.1:${host.address().port}`,virtualHost='https://mech.dreyeck.ch',prefix='/assets/hyperdoc-mech/'
const probe=net.createServer();await new Promise(r=>probe.listen(0,'127.0.0.1',r));const port=probe.address().port;await new Promise(r=>probe.close(r))
const inspector=`http://127.0.0.1:${port}`,script=path.join(work,'witness.lisp')
fs.writeFileSync(script,`(require :asdf)\n(asdf:load-system "hyperbook/fedwiki/tests")\n(hyperbook/fedwiki/tests::serve-dialog-browser-witness ${port} "${virtualHost}${prefix}" #p"${stop}" #p"${fixtureFile}")\n`)
const log=fs.openSync(path.join(output,'lisp.log'),'w'),child=spawn(lisp,['--load',script],{stdio:['ignore',log,log]})
const report={kind:'Offline intercepted HTTPS Wiki origin / fresh CLOG / original POPUP and regular receiver',provenance,clock:topics.clock,
  virtualHost,productionExecution:false,publicNetworkRequests:0,checks:[],cases:[],unexpectedRequests:[]}
let browser
const details=async popup=>popup.evaluate(()=>Object.fromEntries([...document.querySelectorAll('details')].map(d=>[d.querySelector('summary').textContent,d.querySelector('pre').textContent])))
try{
  for(let i=0;i<300;i++){
    if(child.exitCode!==null)throw Error(fs.readFileSync(path.join(output,'lisp.log'),'utf8').slice(-4000))
    if(fs.readFileSync(path.join(output,'lisp.log'),'utf8').includes('MECH-DIALOG-BROWSER-READY'))break
    await new Promise(r=>setTimeout(r,100))
  }
  const {chromium}=await import(pathToFileURL(path.join(playwrightPath,'index.mjs')))
  browser=await chromium.launch({headless:true,executablePath:chrome,args:['--no-proxy-server']});report.browser=browser.version()
  const context=await browser.newContext({serviceWorkers:'block',locale:'en-US',timezoneId:'UTC'})
  await context.addInitScript({content:`Date.now=()=>${topics.clock}; window.__dialogMessages=[]; window.__dialogDocument=crypto.randomUUID(); window.addEventListener('message',e=>{if(location.pathname==='/dialog/')window.__dialogMessages.push({origin:e.origin,sourceIsOpener:e.source===window.opener,title:e.data?.title})});`})
  await context.route('**/*',async route=>{
    const url=new URL(route.request().url())
    if(url.origin===inspector){
      if(url.pathname==='/foreign-dialog-test')return route.fulfill({contentType:'text/html',body:'<!doctype html><title>Trusted foreign-origin test sender</title>'})
      return route.continue()
    }
    if(url.origin===virtualHost){
      const mapped=url.pathname.startsWith(prefix)?'/'+url.pathname.slice(prefix.length):url.pathname
      const response=await route.fetch({url:localHost+mapped})
      return route.fulfill({response})
    }
    if(route.request().resourceType()!=='image')report.unexpectedRequests.push(url.href)
    return route.abort()
  })
  const page=await context.newPage()
  for(const mode of ['ready','large']){
    await page.goto(inspector+'/'+mode)
    const embedded=page.locator('.fedwiki-mech-host');await embedded.waitFor()
    const wire=await embedded.evaluate(e=>{
      const decode=s=>JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(s),c=>c.charCodeAt(0))))
      return {page:decode(e.dataset.pageJsonBase64),snapshot:decode(e.dataset.neighborhoodJsonBase64),itemId:e.dataset.itemId}
    })
    assert.deepEqual(wire.page,originalPage);assert.equal(wire.itemId,'3a62aa636c883134')
    const frame=page.frameLocator('.fedwiki-mech-host iframe'),buttons=frame.getByRole('button',{name:'▶',exact:true})
    await buttons.first().waitFor();assert.equal(await buttons.count(),3)
    assert(!(await frame.locator('.item.mech').innerText()).includes('⇒'));assert.equal(context.pages().length,1)
    report.checks.push(`${mode}: original item unchanged; display opens no popup and executes no Mech program`)
    const hostFrame=page.frames().find(f=>f.url().startsWith(virtualHost))
    await hostFrame.evaluate(src=>{Math.random=(0,eval)(src)(7)},'('+seededRandom.toString()+')')
    await buttons.first().click();await frame.locator('.item.mech').getByText(/^WALK 25 hubs ⇒/).waitFor()
    const aspects=await hostFrame.evaluate(()=>JSON.parse(JSON.stringify(document.querySelector('.item.mech').aspectData())))
    const popupPromise=context.waitForEvent('page');await buttons.nth(1).click();const popup=await popupPromise
    await popup.waitForURL(virtualHost+'/dialog/#')
    await popup.waitForFunction(()=>document.title==='POPUP state'&&document.querySelector('details summary'))
    const rendered=await details(popup),neighborhood=JSON.parse(rendered.neighborhood),stateAspects=JSON.parse(rendered.aspect)
    const expected=wire.snapshot.sites.flatMap(s=>s.sitemap.map(info=>({domain:s.domain,...info}))).sort((a,b)=>b.date-a.date)
    assert.deepEqual(neighborhood,expected);assert.deepEqual(stateAspects.flatMap(a=>a.result),aspects)
    await popup.locator('summary').filter({hasText:/^neighborhood$/}).click()
    assert(await popup.locator('details[open] pre').isVisible(), 'Reader can disclose the computed neighborhood')
    await popup.locator('summary').filter({hasText:/^neighborhood$/}).click()
    assert.equal(stateAspects.length,3);assert.equal(neighborhood.length,mode==='large'?1500:45)
    assert.deepEqual(JSON.parse(rendered.context).page,originalPage)
    const state=Object.fromEntries(Object.entries(rendered).map(([key,value])=>[key,JSON.parse(value)]))
    const oracle=[];originalPopup({elem:{innerText:'POPUP state'},args:['state'],state},(title,html)=>oracle.push({title,html}))
    const originalReceiverBody=await popup.locator('.page').innerHTML()
    // Compare the actual receiver DOM against the exact original rendering,
    // accounting solely for the browser's ordinary HTML parse/serialization.
    const normalized=await popup.evaluate(html=>{const d=document.createElement('div');d.innerHTML=html;return d.innerHTML},oracle[0].html)
    assert.equal(originalReceiverBody,normalized)
    assert((await popup.evaluate(()=>window.__dialogMessages)).every(m=>m.origin===virtualHost&&m.sourceIsOpener))
    report.checks.push(`${mode}: second CLICK opens regular /dialog/ and displays actual computed state, exactly equivalent to original popup_emit`)
    report.checks.push(`${mode}: own-origin postMessage and opener source verified; neighborhood=${neighborhood.length}, three graph sources preserved`)
    const before=context.pages().length
    const receipt=await popup.evaluate(()=>({document:window.__dialogDocument,count:window.__dialogMessages.length}))
    await buttons.nth(1).click()
    await popup.waitForFunction(previous=>document.title==='POPUP state'&&window.__dialogMessages.some(m=>m.title==='POPUP state')&&(window.__dialogDocument!==previous.document||window.__dialogMessages.length>previous.count),receipt)
    assert.equal(context.pages().length,before);assert(!popup.isClosed())
    assert.deepEqual(await details(popup),rendered)
    report.checks.push(`${mode}: named regular dialog is reused with unchanged computed state`)
    if(mode==='large'){
      // Trusted test-only cache change proves that reuse carries the newly
      // computed input, not stale HTML. Original JSON/data files stay unchanged.
      await hostFrame.evaluate(()=>{Object.values(wiki.neighborhoodObject.sites)[0].sitemap[0].title='Fixture <b>escaped</b> & >'})
      await buttons.first().click();await frame.locator('.item.mech').getByText(/^WALK 25 hubs ⇒/).waitFor()
      const updatedAspects=await hostFrame.evaluate(()=>JSON.parse(JSON.stringify(document.querySelector('.item.mech').aspectData())))
      await buttons.nth(1).click()
      await popup.waitForFunction(()=>document.querySelector('.page').textContent.includes('Fixture <b>escaped</b> & >'))
      const updated=await details(popup);assert(JSON.parse(updated.neighborhood).some(p=>p.title==='Fixture <b>escaped</b> & >'))
      assert.deepEqual(JSON.parse(updated.aspect).flatMap(a=>a.result),updatedAspects)
      assert.equal(await popup.locator('.page b').count(),0)
      report.checks.push('large: reused dialog receives newly calculated 1500-entry state; HTML in values remains literal text')
      // Observe the original receiver's missing sender validation with a real
      // cross-origin, trusted offline sender. No injected executable HTML.
      const foreignPromise=context.waitForEvent('page')
      await popup.evaluate(url=>window.open(url,'foreign-dialog-test'),inspector+'/foreign-dialog-test')
      const foreign=await foreignPromise;await foreign.waitForURL(inspector+'/foreign-dialog-test')
      await foreign.evaluate(()=>opener.postMessage({title:'wrong-target',body:'<p>wrong target</p>'},'https://wrong-target.invalid'))
      await new Promise(r=>setTimeout(r,100));assert.equal(await popup.title(),'POPUP state')
      report.checks.push('original transport: wrong targetOrigin is not delivered')
      await foreign.evaluate(origin=>opener.postMessage({title:'trusted foreign-origin probe',body:'<p>Non-executable test marker</p>'},origin),virtualHost)
      await popup.waitForFunction(()=>document.title==='trusted foreign-origin probe')
      const observed=await popup.evaluate(()=>window.__dialogMessages.at(-1))
      assert.equal(observed.origin,inspector);assert.equal(observed.sourceIsOpener,false)
      report.receiverOriginLimitation=observed
      report.checks.push('original receiver limitation reproduced: foreign origin/non-opener message accepted; no receiver check claimed')
      await foreign.close();await buttons.nth(1).click()
      await popup.waitForFunction(()=>document.title==='POPUP state'&&document.querySelector('.page').textContent.includes('Fixture <b>escaped</b> & >'))
      assert.equal(context.pages().length,before)
      report.checks.push('regular sender restores computed state using the same dialog after the controlled foreign-message probe')
      await popup.close()
      await hostFrame.evaluate(()=>{window.__fixtureOpen=window.open;window.open=()=>null})
      await buttons.nth(1).click();await frame.locator('#failure').getByText(/location/).waitFor()
      assert.equal(context.pages().length,1)
      await hostFrame.evaluate(()=>{window.open=window.__fixtureOpen;delete window.__fixtureOpen})
      report.checks.push('blocked popup: original sender failure remains visible; no fallback receiver or extra privilege')
    }else await popup.close()
    report.cases.push({mode,entryCount:neighborhood.length,aspectCount:aspects.length,htmlBytes:Buffer.byteLength(originalReceiverBody)})
  }
  assert.deepEqual(report.unexpectedRequests,[]);report.checks.push('All execution stayed offline; no editing, publication or new network service')
  report.status='PASS'
}catch(error){report.status='FAIL';report.failure={message:error.message,stack:error.stack};throw error}
finally{
  fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2)+'\n')
  if(browser)await browser.close();fs.writeFileSync(stop,'')
  await new Promise(resolve=>{if(child.exitCode!==null)resolve();else{child.once('exit',resolve);setTimeout(()=>{child.kill('SIGTERM');resolve()},5000).unref()}})
  await new Promise(r=>host.close(r));fs.closeSync(log)
}
console.log(JSON.stringify({status:report.status,checks:report.checks,cases:report.cases}))
