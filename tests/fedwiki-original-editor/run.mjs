// One end-to-end case. No browser-side substitute for a plugin, editor or writer.
import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'
import net from 'node:net'
import {spawn} from 'node:child_process'
import {fileURLToPath} from 'node:url'
import {createHash} from 'node:crypto'
import {chromium} from 'playwright-core'
import {installBoundClicks} from '../../scripts/lib/inspector-ready.mjs'
import {catalogStartupTimeoutMs} from './commands.mjs'
import {slug, paragraphId, codeId, paragraph, code, initialPage} from './fixture.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const [lisp, chrome, destination, mode] = process.argv.slice(2)
const inspectorCase = mode === "--inspector"
assert(!mode || inspectorCase, "Unknown integration case")
assert(destination, 'usage: node run.mjs LISP_WRAPPER CHROMIUM OUTPUT_OUTSIDE_CHECKOUT')
const output = path.resolve(destination)
assert(!output.startsWith(repo + path.sep) && output !== repo)
fs.mkdirSync(output, {recursive:true})
const work = fs.mkdtempSync(path.join(output, 'run-'))
const site = path.join(work, 'site'), pages = path.join(site, 'pages')
fs.mkdirSync(pages, {recursive:true})
const initial = initialPage()
const file = path.join(pages, slug)
fs.writeFileSync(file, JSON.stringify(initial, null, 2) + '\n')
const read = () => JSON.parse(fs.readFileSync(file, 'utf8'))
const sha = () => createHash('sha256').update(fs.readFileSync(file)).digest('hex')
const beforeSha = sha()
const report = {passed:false, sourceBase:'f03d9a15234b5fdbb7c339c480d021e4a854b38a',
  integrationCase:inspectorCase ? 'inspector' : 'standalone', work, file, beforeSha, versions:{}, steps:[], browserErrors:[], externalRequests:[]}
for (const name of ['wiki','wiki-client','wiki-server','wiki-plugin-code','wiki-plugin-paragraph']) {
  report.versions[name] = JSON.parse(fs.readFileSync(path.join(here,'node_modules',name,'package.json'))).version
}
const children = [], contexts = []
const stopFile = path.join(work,'stop-catalog')
let browser
let interrupted = false
const abort = () => {
  interrupted = true
  for (const child of children) if (child.pid && child.exitCode===null && child.signalCode===null) child.kill('SIGTERM')
  if (browser) browser.close().catch(()=>{})
}
process.once('SIGINT',abort);process.once('SIGTERM',abort)
const freePort = async (avoid=[]) => {
  const listener = net.createServer()
  await new Promise(r=>listener.listen(0,'127.0.0.1',r))
  const port = listener.address().port
  await new Promise(r=>listener.close(r))
  if (port===8080 || avoid.includes(port)) return freePort(avoid)
  return port
}
const start = (command, args, label, env={}) => {
  const fd = fs.openSync(path.join(work,label+'.log'),'w')
  const child = spawn(command,args,{cwd:work,stdio:['ignore',fd,fd],
    env:{...process.env, HOME:path.join(work,'home'), ...env}})
  fs.closeSync(fd); children.push(child)
  child.on('error', e => { report.processError = String(e) })
  return child
}
const waitHTTP = async (origin, child, label) => {
  const maxMs = label==='catalog' ? catalogStartupTimeoutMs() : 120000
  const began = Date.now()
  const logFile = path.join(work,label+'.log')
  while (Date.now()-began < maxMs) {
    if (interrupted || child.exitCode !== null || child.signalCode !== null || report.processError) {
      throw Error(report.processError ||
        label+' exited before HTTP readiness. '+fs.readFileSync(logFile,'utf8').slice(-5000))
    }
    try {if ((await fetch(origin,{signal:AbortSignal.timeout(1500)})).ok) return} catch {}
    await new Promise(r=>setTimeout(r,250))
  }
  throw Error(label+' HTTP startup exceeded '+maxMs/1000+'s. Last log lines:\n'+
    fs.readFileSync(logFile,'utf8').slice(-5000))
}
try {
  fs.mkdirSync(path.join(work,'home'))
  // Negative control: the very same original server refuses writes without its legacy grant.
  const deniedPort = await freePort(), deniedOrigin = `http://127.0.0.1:${deniedPort}`
  const denied = start(process.execPath,[path.join(here,'server.mjs'),site,String(deniedPort),'false'],'denied')
  await waitHTTP(deniedOrigin,denied,'denied')
  const deniedResponse = await fetch(`${deniedOrigin}/page/${slug}/action`,{
    method:'PUT',headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:new URLSearchParams({action:JSON.stringify({type:'edit',id:codeId,item:{...code,text:'must not persist'},date:Date.now()})})})
  assert.equal(deniedResponse.status,403); assert.equal(sha(),beforeSha)
  denied.kill('SIGTERM'); await new Promise(r=>denied.once('exit',r))
  report.steps.push('Original security denies PUT without grant: 403 and unchanged page bytes')

  const wikiPort = await freePort(), catalogPort = await freePort([wikiPort])
  const wikiOrigin = `http://127.0.0.1:${wikiPort}`, catalogOrigin = `http://127.0.0.1:${catalogPort}`
  Object.assign(report,{wikiOrigin,catalogOrigin,authorization:'original default security, unclaimed isolated loopback site, security_legacy=true'})
  const wiki = start(process.execPath,[path.join(here,'server.mjs'),site,String(wikiPort),'true'],'wiki',{HYPERDOC_FEDWIKI_INSPECTOR_ORIGIN:catalogOrigin})
  await waitHTTP(wikiOrigin,wiki,'wiki')
  const opts = fs.readFileSync(path.join(work,'wiki.log'),'utf8').split('\n').find(l=>l.startsWith('{"db":'))
  assert.equal(JSON.parse(opts).db,pages)
  const catalog = start(lisp,['--noinform','--no-sysinit','--no-userinit','--script',path.join(here,'serve.lisp')],'catalog',{
    HYPERDOC_EDITOR_TEST_CHECKOUT:repo+'/', HYPERDOC_EDITOR_TEST_CATALOG_PORT:String(catalogPort),
    HYPERDOC_EDITOR_TEST_STOP:stopFile,
    HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT:site+'/', HYPERDOC_FEDWIKI_EDITOR_TEST_ORIGIN:wikiOrigin,
    HYPERDOC_FEDWIKI_SITE_ROOT:site+'/'})
  await waitHTTP(catalogOrigin,catalog,'catalog')
  browser = await chromium.launch({headless:true,executablePath:chrome,args:['--no-sandbox','--no-proxy-server']})
  report.browser = browser.version()
  const context = await browser.newContext({serviceWorkers:'block',viewport:{width:1400,height:1000}})
  contexts.push(context)
  const originalAssets = new Map()
  context.on('response', async response => {
    const pathname = new URL(response.url()).pathname
    const source = {'/client.js':'wiki-client/client/client.js','/plugins/code/code.js':'wiki-plugin-code/client/code.js'}[pathname]
    if (source && response.ok()) {
      const body = await response.body()
      originalAssets.set(pathname, body.equals(fs.readFileSync(path.join(here,'node_modules',source))))
    }
  })
  await context.route('**/*',route=>{
    const url = new URL(route.request().url())
    if ([wikiOrigin,catalogOrigin].includes(url.origin)) return route.continue()
    report.externalRequests.push(url.href); return route.abort()
  })
  // Observe browser persistence without replacing the client's storage decisions.
  await context.addInitScript(() => {
    window.__testStorageWrites = []
    const original = Storage.prototype.setItem
    Storage.prototype.setItem = function(key,value) {
      if (this === localStorage) window.__testStorageWrites.push(key)
      return original.call(this,key,value)
    }
  })
  const hyperdoc = await context.newPage()
  installBoundClicks(hyperdoc)
  hyperdoc.setDefaultTimeout(45000)
  hyperdoc.on('pageerror',e=>report.browserErrors.push((e.stack?.includes(wikiOrigin) ? 'Wiki: ' : 'HyperDoc: ')+e.message))
  await hyperdoc.goto(catalogOrigin)
  await hyperdoc.getByText('Original Wiki Editor Test',{exact:true}).and(hyperdoc.locator(':visible')).first().click()
  const last = () => hyperdoc.locator('.inspector-pane').last()
  await last().getByRole('button',{name:'Text pages',exact:true}).click()
  await hyperdoc.locator('tr.inspector-inspect:visible').filter({hasText:'Editing One Isolated Wiki Page'}).last().click()
  await last().getByRole('heading',{name:'Editing One Isolated Wiki Page',exact:true}).waitFor()
  const demo = hyperdoc.locator('.inspector-pane').nth((await hyperdoc.locator('.inspector-pane').count())-1)
  assert.equal(await demo.locator('pre[style*="#eee"]').innerText(),code.text)
  const paneCount = await hyperdoc.locator('.inspector-pane').count()
  await demo.locator('.inspector-inspect').getByText('code',{exact:true}).click()
  await hyperdoc.waitForFunction(n=>document.querySelectorAll('.inspector-pane').length>n,paneCount)
  await last().getByRole('button',{name:'Data',exact:true}).waitFor()
  await last().getByText(codeId,{exact:true}).waitFor()
  assert((await last().innerText()).includes(codeId))
  assert((await last().innerText()).includes('lisp'))
  report.steps.push('Catalog → demo → original generic grey Code renderer → code Inspector reference')
  let wikiPage
  const codePane = hyperdoc.locator('.inspector-pane').nth((await hyperdoc.locator('.inspector-pane').count())-1)
  if (inspectorCase) {
    assert.equal(context.pages().length,1)
    for (const query of [`hyperdocCodeItem=${codeId}&revision=stale`, `hyperdocCodeItem=${paragraphId}&revision=${beforeSha}`]) {
      const refused = await fetch(`${wikiOrigin}/view/${slug}?${query}`)
      assert.equal(refused.status,409)
      assert.equal(sha(),beforeSha)
    }
    await codePane.getByRole('button',{name:'Original Wiki editor',exact:true}).click()
    await codePane.getByRole('heading',{name:'Original Code plugin editor',exact:true}).waitFor()
    const frameElement = codePane.locator('iframe.original-code-editor')
    await frameElement.waitFor()
    const src = await frameElement.getAttribute('src')
    assert.equal(new URL(src).origin,wikiOrigin)
    assert.equal(new URL(src).searchParams.get('hyperdocCodeItem'),codeId)
    const boundary = await fetch(src)
    assert.equal(boundary.headers.get('content-security-policy'),`frame-ancestors ${catalogOrigin}`)
    assert.equal(boundary.headers.get('access-control-allow-origin'),null)
    const handle = await frameElement.elementHandle()
    wikiPage = await handle.contentFrame()
    await wikiPage.getByRole('button',{name:'Edit with original Wiki plugin',exact:true}).waitFor()
  } else {
    const clientLink = demo.getByRole('link',{name:'Open original Wiki client'})
    assert.equal(await clientLink.getAttribute('href'),`${wikiOrigin}/view/${slug}`)
    const [popup] = await Promise.all([context.waitForEvent('page'), clientLink.click()])
    wikiPage = popup
    wikiPage.on('pageerror',e=>report.browserErrors.push('Wiki: '+e.message))
  }
  const item = wikiPage.locator(`.item[data-id="${codeId}"]`)
  await item.waitFor()
  const api = await wikiPage.evaluate(() => ({
    emit:typeof window.plugins.code.emit,bind:typeof window.plugins.code.bind,editor:typeof window.plugins.code.editor,
    doPlugin:typeof wiki.doPlugin,put:typeof wiki.pageHandler.put,renderFrom:typeof wiki.renderFrom,
    local:wiki.pageHandler.useLocalStorage(), owner:window.isOwner,
  }))
  assert.deepEqual(api,{emit:'function',bind:'function',editor:'function',doPlugin:'function',put:'function',renderFrom:'function',local:false,owner:true})
  report.compatibility = api
  if (inspectorCase) {
    const action = wikiPage.getByRole('button',{name:'Edit with original Wiki plugin',exact:true})
    await action.waitFor({state:'visible'})
    // Observe and delegate to the shipped function, never supply editor markup.
    await wikiPage.locator('#hyperdoc-code-toolbar button:not([disabled])').waitFor()
    const originalSource = await wikiPage.evaluate(() => {
      const plugin = window.plugins.code, original = plugin.editor
      window.__originalEditorCalls = 0
      plugin.editor = function(...args) {window.__originalEditorCalls++;return original.apply(this,args)}
      return original.toString()
    })
    assert(originalSource.includes('code-language'))
    report.originalEditorFunctionSHA256 = createHash('sha256').update(originalSource).digest('hex')
    // Inspector's jQuery binding helper is inapplicable to this frame's native
    // addEventListener control. Use actual browser pointer input after readiness.
    await action.scrollIntoViewIfNeeded()
    const box = await action.boundingBox()
    assert(box)
    await hyperdoc.mouse.click(box.x+box.width/2,box.y+box.height/2)
    await item.locator('textarea').waitFor()
    assert.equal(await wikiPage.evaluate(()=>window.__originalEditorCalls),1)
    assert.equal(await item.locator('textarea').inputValue(),code.text)
    assert.equal(await wikiPage.locator('.item:visible').count(),1)
    assert.equal(context.pages().length,1)
    assert((await codePane.innerText()).includes(codeId))
    assert((await codePane.innerText()).includes('fedwiki:original-editor-test.invalid'))
    await hyperdoc.screenshot({path:path.join(work,'inspector-original-editor.png'),fullPage:true})
    report.inspector = {target:['fedwiki:original-editor-test.invalid',slug,codeId],originalEditorCalls:1,browserPages:context.pages().length,visibleItems:1,staleAndWrongTargetRefused:true,frameAncestors:catalogOrigin,additionalCORS:false}
  } else {
    if (!(await wikiPage.locator('.editEnable').isVisible())) await wikiPage.locator('footer').getByText('wiki',{exact:false}).click()
    await item.dblclick()
  }
  await item.locator('textarea').fill('(defun square (x) (expt x 2))')
  await item.locator('#code-language').fill('commonlisp')
  const put = hyperdoc.context().waitForEvent('response', {predicate:r=>r.request().method()==='PUT' && r.url()===`${wikiOrigin}/page/${slug}/action`})
  if (inspectorCase) await wikiPage.getByRole('status').click()
  else await wikiPage.locator('h1').first().click()
  const response = await put
  assert.equal(response.status(),200)
  const sent = JSON.parse(new URLSearchParams(response.request().postData()).get('action'))
  assert.equal(sent.type,'edit'); assert.equal(sent.id,codeId); assert(Number.isInteger(sent.date))
  const persisted = read()
  assert.equal(persisted.story.length,2)
  assert.deepEqual(persisted.story[0],paragraph)
  assert.deepEqual(persisted.story[1],{...code,text:'(defun square (x) (expt x 2))',language:'commonlisp'})
  assert.equal(persisted.journal.length,initial.journal.length+1)
  assert.deepEqual(persisted.journal.slice(0,-1),initial.journal)
  assert.deepEqual(persisted.journal.at(-1),sent)
  assert.equal(await wikiPage.evaluate(s=>localStorage.getItem(s),slug),null)
  assert(!(await wikiPage.evaluate(()=>window.__testStorageWrites)).includes(slug))
  assert.equal(await wikiPage.locator('.page.local').count(),0)
  assert.deepEqual(fs.readdirSync(pages),[slug])
  assert.equal(originalAssets.get('/client.js'),true)
  assert.equal(originalAssets.get('/plugins/code/code.js'),true)
  report.originalAssetsByteEqual = Object.fromEntries(originalAssets)
  report.steps.push('Original code plugin edited text and language; authorized PUT 200; disk Item and dated journal match request; no localStorage page/fallback')
  // Stop the sole writer before HyperDoc's independent reread.
  wiki.kill('SIGTERM'); await new Promise(r=>wiki.once('exit',r))
  if (inspectorCase) await codePane.getByRole('button',{name:'Read stored page again',exact:true}).click()
  else await demo.getByRole('button',{name:'Read stored page again',exact:true}).click()
  await last().getByRole('heading',{name:'Stored Wiki page',exact:true}).waitFor()
  const reread = JSON.parse(await last().locator('.persisted-json').innerText())
  assert.deepEqual(reread,persisted)
  assert.equal(await last().locator('pre[style*="#eee"]').innerText(),persisted.story[1].text)
  assert((await last().innerText()).includes(sha()))
  await hyperdoc.screenshot({path:path.join(work,'hyperdoc-reread.png'),fullPage:true})
  assert(fs.readFileSync(path.join(work,'catalog.log'),'utf8').includes('PARSE-TREE-REFERENCE'))
  assert.deepEqual(report.externalRequests,[])
  if (inspectorCase) assert.equal(context.pages().length,1)
  report.steps.push('Node writer stopped; HyperDoc independently reread the same file, matching JSON, journal, SHA-256 and generic rendering; explicit P coordinate checked in Lisp parse tree')
  // Default legacy security has no browser security plugin. Do not hide it with a shim.
  assert(report.browserErrors.every(e=>e === "Wiki: Cannot read properties of undefined (reading 'setup')"),JSON.stringify(report.browserErrors))
  report.knownClientLimitation = 'The original default legacy security module supplies no /security/security.js UI plugin (setup error); server authorization and code editing were verified independently.'
  Object.assign(report,{afterSha:sha(),action:sent,paragraphUnchanged:true,localStorageFallback:false,passed:true})
} catch (error) {
  report.failure = error.stack
  process.exitCode = 1
  if (browser) {
    for (const [i,page] of contexts.flatMap(c=>c.pages()).entries()) {
      try {
        fs.writeFileSync(path.join(work,`failure-${i}.html`),await page.content())
        await page.screenshot({path:path.join(work,`failure-${i}.png`),fullPage:true})
      } catch {}
    }
  }
} finally {
  if (browser) await browser.close()
  fs.writeFileSync(stopFile,'stop\n')
  await Promise.all(children.map(async child => {
    if (child.exitCode!==null || child.signalCode!==null || !child.pid) return
    const exited = new Promise(r=>child.once('exit',r))
    if (child !== children.at(-1)) child.kill('SIGTERM')
    const timer = setTimeout(()=>child.kill('SIGTERM'),5000), kill = setTimeout(()=>child.kill('SIGKILL'),8000)
    await exited; clearTimeout(timer);clearTimeout(kill)
  }))
  process.removeListener('SIGINT',abort);process.removeListener('SIGTERM',abort)
  fs.writeFileSync(path.join(work,'report.json'),JSON.stringify(report,null,2)+'\n')
  console.log(JSON.stringify({passed:report.passed,report:path.join(work,'report.json'),failure:report.failure},null,2))
}
