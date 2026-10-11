// Offline actual fresh CLOG Story -> original Pattern Machinery CLICK ->
// bounded topics intake. Original page bytes preserved; only the loaded Ward
// sitemap is selected in the explicit ready control. Full context is unavailable.
// Usage: node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
import {createMechHost} from './serve-fedwiki-mech-host.mjs'
import {reference} from '../tests/fedwiki-mech-sitemap-fixture.mjs'
import {ward, provenance, originalPage, originalSitemap, seededRandom, graphContent} from '../tests/fedwiki-mech-topics-reference.mjs'
const [lisp, playwrightPath, chrome, output] = process.argv.slice(2)
if (!output) throw Error('Usage: LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT')
fs.mkdirSync(output, {recursive:true})
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'mech-topics-browser-')), stop = path.join(work, 'stop')
const host = createMechHost(); await new Promise(r => host.listen(0,'127.0.0.1',r))
const hostOrigin = `http://127.0.0.1:${host.address().port}`
const probe = net.createServer(); await new Promise(r => probe.listen(0,'127.0.0.1',r))
const port = probe.address().port; await new Promise(r => probe.close(r))
const origin = `http://127.0.0.1:${port}`
const script = path.join(work, 'witness.lisp')
fs.writeFileSync(script, `(require :asdf)\n(asdf:load-system "hyperbook/fedwiki/tests")\n(hyperbook/fedwiki/tests::serve-topics-browser-witness ${port} "${hostOrigin}/" #p"${stop}")\n`)
const log = fs.openSync(path.join(output,'lisp.log'),'w')
const child = spawn(lisp,['--load',script],{stdio:['ignore',log,log]})
const report = {kind:'Offline actual Inspector / original Pattern Machinery / retained original Ward sitemap',
  upstream:provenance.upstream, clock:provenance.clock, selection:provenance.browserSelection,
  checks:[], cases:[], unexpectedRequests:[], productionAccess:false}
let browser
try {
  for (let i=0; i<300; i++) {
    if (child.exitCode !== null) throw Error(fs.readFileSync(path.join(output,'lisp.log'),'utf8').slice(-4000))
    if (fs.readFileSync(path.join(output,'lisp.log'),'utf8').includes('MECH-TOPICS-BROWSER-READY')) break
    await new Promise(r => setTimeout(r,100))
  }
  const {chromium} = await import(pathToFileURL(path.join(playwrightPath,'index.mjs')))
  browser = await chromium.launch({headless:true,executablePath:chrome,args:['--no-proxy-server']});report.browser=browser.version()
  const context = await browser.newContext({serviceWorkers:'block',locale:'en-US',timezoneId:'UTC'})
  report.locale='en-US';report.timezone='UTC'
  await context.addInitScript({content:`Date.now = () => ${provenance.clock};`})
  await context.route('**/*', route => {
    if ([origin,hostOrigin].includes(new URL(route.request().url()).origin)) return route.continue()
    if (route.request().resourceType() !== 'image') report.unexpectedRequests.push(route.request().url())
    return route.abort()
  })
  const page = await context.newPage()
  for (const mode of ['ready','missing','loading','failed','context']) {
    await page.goto(origin+'/'+mode)
    const embedded = page.locator('.fedwiki-mech-host');await embedded.waitFor()
    const wire = await embedded.evaluate(e => {
      const decode = s => JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(s),c=>c.charCodeAt(0))))
      return {page:decode(e.dataset.pageJsonBase64),snapshot:decode(e.dataset.neighborhoodJsonBase64),itemId:e.dataset.itemId}
    })
    assert.deepEqual(wire.page,originalPage);assert.equal(wire.itemId,'3a62aa636c883134')
    const frame = page.frameLocator('.fedwiki-mech-host iframe')
    const buttons = frame.getByRole('button',{name:'▶',exact:true});await buttons.first().waitFor()
    assert.equal(await buttons.count(),3)
    assert(!(await frame.locator('.item.mech').innerText()).includes('⇒'))
    report.checks.push(`${mode}: original page/item, three CLICK controls; display executes no Mech program`)
    const result = {mode,snapshot:wire.snapshot}
    if (mode === 'ready') {
      assert.equal(wire.snapshot.sites.length,1)
      assert.deepEqual(wire.snapshot.sites[0].sitemap,originalSitemap)
      const hostFrame = page.frames().find(f => f.url().startsWith(hostOrigin))
      // Reset after parser/control setup: its key generation also uses random.
      const seed=23
      result.random={seed,algorithm:'LCG 1664525/1013904223, uint32',reset:'after formatter/setup and before explicit CLICK'}
      await hostFrame.evaluate(src => {Math.random=(0,eval)(src)(23)},'('+seededRandom.toString()+')')
      await buttons.first().click()
      await frame.locator('.item.mech').getByText('NEIGHBORS⇒ 45 pages, 1 sites',{exact:true}).first().waitFor()
      await frame.locator('.item.mech').getByText(/^WALK 25 hubs ⇒/).waitFor()
      const actual = await hostFrame.evaluate(() => JSON.parse(JSON.stringify(document.querySelector('.item.mech').aspectData())))
      const previous = await reference(wire.snapshot.sites)
      const input = wire.snapshot.sites.flatMap(s => s.sitemap.map(info => ({domain:s.domain,...info}))).sort((a,b)=>b.date-a.date)
      const oldNow=Date.now, oldRandom=Math.random, oldLocale=Date.prototype.toLocaleDateString
      let topics
      try {
        Date.now=()=>provenance.clock;Math.random=seededRandom(seed)
        Date.prototype.toLocaleDateString=function(){return oldLocale.call(this,'en-US',{timeZone:'UTC'})}
        topics=ward.walks('15','topics',input)
      } finally {Date.now=oldNow;Math.random=oldRandom;Date.prototype.toLocaleDateString=oldLocale}
      assert(topics.length>0)
      // Existing periods driver shares machine locale/timezone; compare those
      // unchanged graphs by content and topic labels with the fixed oracle separately.
      assert.deepEqual(graphContent(actual,false),graphContent([...previous.aspects,...topics],false))
      const labelledActual = graphContent(actual)
      for (const labelledTopic of graphContent(topics)) {
        const index = labelledActual.indexOf(labelledTopic)
        assert(index >= 0, 'Original topic name must remain attached to its equivalent graph')
        labelledActual.splice(index,1)
      }
      result.topicCount=topics.length;result.aspectCount=actual.length
      result.graphContent=graphContent(topics)
      report.checks.push('ready: actual original WALK 15 topics dispatch, randomized directed graph content equals direct Ward c858 execution on identical input')
      report.checks.push('ready: weeks/hubs still execute in the unchanged original Pattern Machinery CLICK sequence')
      const popupPromise=context.waitForEvent('page')
      await buttons.nth(1).click()
      const popup=await popupPromise;await popup.waitForURL(hostOrigin+'/dialog/#')
      await popup.waitForFunction(()=>document.title==='POPUP state' && document.querySelector('details'))
      assert((await popup.locator('.page').innerText()).includes('neighborhood'))
      await popup.close()
      report.checks.push('ready: original POPUP state uses the regular named Wiki dialog receiver')
    } else {
      if (mode === 'context') {
        assert.equal(wire.snapshot.sites.length,3)
        assert.deepEqual(wire.snapshot.sites.map(s=>s.state),['ready','missing','missing'])
      }
      await buttons.first().click()
      await frame.locator('#failure').getByText(/NEIGHBORS cannot run/).waitFor()
      assert(!(await frame.locator('.item.mech').innerText()).includes('0 pages'))
      assert(!(await frame.locator('.item.mech').innerText()).includes('WALK 15 topics ⇒'))
      report.checks.push(`${mode}: unavailable sitemap data is explicit; no partial neighborhood or fabricated topics success`)
    }
    result.text=await frame.locator('main').innerText();report.cases.push(result)
  }
  assert.deepEqual(report.unexpectedRequests,[]);report.checks.push('No public fetch or new executable network dependency')
  report.status='PASS'
} catch (error) {report.status='FAIL';report.failure={message:error.message,stack:error.stack};throw error}
finally {
  fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2)+'\n')
  if(browser) await browser.close()
  fs.writeFileSync(stop,'')
  await new Promise(resolve=>{if(child.exitCode!==null)resolve();else{child.once('exit',resolve);setTimeout(()=>{child.kill('SIGTERM');resolve()},5000).unref()}})
  await new Promise(r=>host.close(r));fs.closeSync(log)
}
console.log(JSON.stringify({status:report.status,checks:report.checks,cases:report.cases.length}))
