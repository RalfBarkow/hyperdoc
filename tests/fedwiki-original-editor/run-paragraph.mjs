// One end-to-end case through the real Catalog: a Paragraph Item of a Wiki page, selected by identity in the Inspector,
// edited by the original Wiki text editor, reread independently by HyperDoc. No browser-side substitute for an editor or writer.
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
const [lisp, chrome, destination] = process.argv.slice(2)
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
  integrationCase:'paragraph-item', work, file, beforeSha, versions:{}, steps:[], browserErrors:[], externalRequests:[]}
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
    // Embedding is its own decision, made here for the loopback test only; the original server still authorizes writes.
    HYPERDOC_FEDWIKI_EDITOR_TEST_MODE:'isolated-loopback',
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
  const changedText = 'A paragraph changed in the original Wiki editor, with markup characters & < >.'
  await hyperdoc.getByText('Original Wiki Editor Test',{exact:true}).and(hyperdoc.locator(':visible')).first().click()
  const last = () => hyperdoc.locator('.inspector-pane').last()
  const paneCount = () => hyperdoc.locator('.inspector-pane').count()
  await last().getByRole('button',{name:'Text pages',exact:true}).click()
  await hyperdoc.locator('tr.inspector-inspect:visible').filter({hasText:'Editing One Isolated Wiki Page'}).last().click()
  await last().getByRole('heading',{name:'Editing One Isolated Wiki Page',exact:true}).waitFor()
  const demo = last()
  // 1. The page is shown by its existing Story view (transcluded); the Paragraph Item carries its coordinate.
  const story = demo.locator(`p.story-paragraph[data-fedwiki-item-id="${paragraphId}"]`)
  await story.waitFor()
  assert.equal(await story.getAttribute('data-fedwiki-site'),'fedwiki:original-editor-test.invalid')
  assert.equal(await story.getAttribute('data-fedwiki-slug'),slug)
  assert((await story.innerText()).includes(paragraph.text))
  assert.equal(await demo.locator('pre[style*="#eee"]').innerText(),code.text)
  report.steps.push('Catalog → demo page → existing Story view shows the Paragraph Item with site, slug and item id')
  // 2. Select the Item through its own reference (its identity), not by position in any markup.
  const before = await paneCount()
  await story.locator('small').getByText('paragraph',{exact:true}).click()
  await hyperdoc.waitForFunction(n=>document.querySelectorAll('.inspector-pane').length>n,before)
  const itemPane = last()
  await itemPane.getByRole('button',{name:'Original Wiki editor',exact:true}).waitFor()
  await itemPane.getByText(paragraphId,{exact:true}).waitFor()
  const itemText = await itemPane.innerText()
  assert(itemText.includes(paragraphId)); assert(itemText.includes(paragraph.text))
  report.steps.push('Paragraph Item selected as its own Inspector object')
  // 3. The original Wiki editor, in the frame.
  assert.equal(context.pages().length,1)
  await itemPane.getByRole('button',{name:'Original Wiki editor',exact:true}).click()
  await itemPane.getByRole('heading',{name:'Original Paragraph editor',exact:true}).waitFor()
  const paneText = await itemPane.innerText()
  for (const part of ['fedwiki:original-editor-test.invalid',slug,paragraphId]) assert(paneText.includes(part),part)
  const frameElement = itemPane.locator('iframe.original-paragraph-editor')
  await frameElement.waitFor()
  const src = await frameElement.getAttribute('src')
  assert.equal(new URL(src).origin,wikiOrigin)
  assert.equal(new URL(src).searchParams.get('hyperdocItem'),paragraphId)
  const boundary = await fetch(src)
  assert.equal(boundary.headers.get('content-security-policy'),`frame-ancestors ${catalogOrigin}`)
  assert.equal(boundary.headers.get('access-control-allow-origin'),null)
  const wikiPage = await (await frameElement.elementHandle()).contentFrame()
  const action = wikiPage.getByRole('button',{name:'Edit with original Wiki plugin',exact:true})
  await wikiPage.locator('#hyperdoc-code-toolbar button:not([disabled])').waitFor()
  const item = wikiPage.locator(`.item[data-id="${paragraphId}"]`)
  await item.waitFor()
  const api = await wikiPage.evaluate(() => ({
    textEditor:typeof wiki.textEditor, paragraphBind:typeof window.plugins.paragraph.bind, paragraphEditor:typeof window.plugins.paragraph.editor,
    put:typeof wiki.pageHandler.put, local:wiki.pageHandler.useLocalStorage(), owner:window.isOwner }))
  // The original paragraph plugin has no editor of its own: it binds the client's text editor to a double-click.
  assert.deepEqual(api,{textEditor:'function',paragraphBind:'function',paragraphEditor:'undefined',put:'function',local:false,owner:true})
  report.compatibility = api
  await action.scrollIntoViewIfNeeded()
  const box = await action.boundingBox(); assert(box)
  await hyperdoc.mouse.click(box.x+box.width/2,box.y+box.height/2)
  await item.locator('textarea').waitFor()
  assert.equal(await item.locator('textarea').inputValue(),paragraph.text)
  assert.equal(await wikiPage.locator('.item:visible').count(),1)
  assert.equal(context.pages().length,1)
  await hyperdoc.screenshot({path:path.join(work,'paragraph-original-editor.png'),fullPage:true})
  await item.locator('textarea').fill(changedText)
  const put = hyperdoc.context().waitForEvent('response', {predicate:r=>r.request().method()==='PUT' && r.url()===`${wikiOrigin}/page/${slug}/action`})
  await wikiPage.getByRole('status').click()
  const response = await put
  assert.equal(response.status(),200)
  const sent = JSON.parse(new URLSearchParams(response.request().postData()).get('action'))
  assert.equal(sent.type,'edit'); assert.equal(sent.id,paragraphId); assert(Number.isInteger(sent.date))
  // 4a. What the original server persisted: same Item id, new text, one appended edit Action; the Code Item untouched.
  const persisted = read()
  assert.equal(persisted.story.length,2)
  assert.deepEqual(persisted.story[0],{...paragraph,text:changedText})
  assert.deepEqual(persisted.story[1],code)
  assert.equal(persisted.journal.length,initial.journal.length+1)
  assert.deepEqual(persisted.journal.slice(0,-1),initial.journal)
  assert.deepEqual(persisted.journal.at(-1),sent)
  assert.equal(sent.item.id,paragraphId); assert.equal(sent.item.text,changedText)
  assert.equal(await wikiPage.evaluate(s=>localStorage.getItem(s),slug),null)
  assert.equal(await wikiPage.locator('.page.local').count(),0)
  assert.deepEqual(fs.readdirSync(pages),[slug])
  assert.equal(originalAssets.get('/client.js'),true)
  report.originalAssetsByteEqual = Object.fromEntries(originalAssets)
  report.steps.push('Original text editor changed the Paragraph Item; authorized PUT 200; same item id; one dated edit Action equal to the request; Code Item and earlier journal unchanged')
  // 4b. The Node writer stops; HyperDoc reads the page again by itself and shows the Story view.
  wiki.kill('SIGTERM'); await new Promise(r=>wiki.once('exit',r))
  await itemPane.getByRole('button',{name:'Read stored page again',exact:true}).click()
  await last().getByRole('heading',{name:'Stored Wiki page',exact:true}).waitFor()
  const reread = JSON.parse(await last().locator('.persisted-json').innerText())
  assert.deepEqual(reread,persisted)
  const shown = last().locator(`p.story-paragraph[data-fedwiki-item-id="${paragraphId}"]`)
  await shown.waitFor()
  assert.equal((await shown.innerText()).replace(/\s*paragraph$/,'').trim(),changedText)
  assert(!(await shown.innerText()).includes(paragraph.text))
  assert.equal(await shown.getAttribute('data-fedwiki-slug'),slug)
  assert.equal((await last().innerText()).includes(sha()),true)
  assert((await last().locator('.persisted-json').innerText()).includes('"type": "edit"'))
  await hyperdoc.screenshot({path:path.join(work,'hyperdoc-reread.png'),fullPage:true})
  // The existing Story view asks for the page origin's favicon. The test site's origin is the reserved, never resolvable
  // original-editor-test.invalid, and the context route aborts the request: it is recorded, and nothing else may leave.
  const faviconUrl = 'https://original-editor-test.invalid/favicon.png'
  report.abortedFaviconRequests = report.externalRequests.filter(u=>u===faviconUrl).length
  assert.deepEqual(report.externalRequests.filter(u=>u!==faviconUrl),[])
  assert.equal(context.pages().length,1)
  report.steps.push('Node writer stopped; HyperDoc reread the same file: Story view shows the changed text for the same item id, journal shows the edit Action')
  assert(report.browserErrors.every(e=>e === "Wiki: Cannot read properties of undefined (reading 'setup')"),JSON.stringify(report.browserErrors))
  report.knownClientLimitation = 'The original default legacy security module supplies no /security/security.js UI plugin (setup error); server authorization and editing were verified independently.'
  Object.assign(report,{afterSha:sha(),action:sent,codeItemUnchanged:true,localStorageFallback:false,passed:true})
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
