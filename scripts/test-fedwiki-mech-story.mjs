// Fresh actual CLOG Story + separately hosted unchanged Wiki plugins.
// All browser network stays offline: exact retained imports are supplied from
// a digest-checked external cache. No production services or source writes.
// Usage: node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME CACHE OUTPUT
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import crypto from 'node:crypto'
import {spawn} from 'node:child_process'
import {fileURLToPath, pathToFileURL} from 'node:url'
import {createMechHost, root as hostRoot} from './serve-fedwiki-mech-host.mjs'
const [lisp, playwrightPath, chrome, cache, output] = process.argv.slice(2)
if (!output) throw Error('Usage: LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME CACHE OUTPUT')
const sourceRoot = fileURLToPath(new URL('../', import.meta.url))
const hash = b => crypto.createHash('sha256').update(b).digest('hex')
const provenance = JSON.parse(fs.readFileSync(path.join(hostRoot, 'provenance.json')))
for (const asset of provenance.assets) assert.equal(hash(fs.readFileSync(path.join(hostRoot, asset.path))), asset.sha256, asset.path)
const imports = JSON.parse(fs.readFileSync(path.join(sourceRoot, 'tests/fedwiki-mech-browser-assets.json')))
for (const asset of imports) assert.equal(hash(fs.readFileSync(path.join(cache, asset.name))), asset.sha256, asset.name)
const original = fs.readFileSync(path.join(sourceRoot, 'dreyeck/work/trails-rendered-evidence/ward.voices.ustawi.wiki--trails-rendered.json'))
assert.equal(hash(original), '5fdba40fd3a68eddee00497af4dadb3847500356a2f131dbc0745afb86de9810')
const raw = JSON.parse(original)
fs.mkdirSync(output, {recursive: true})
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'mech-story-browser-'))
const stop = path.join(work, 'stop')
const host = createMechHost(); await new Promise(r => host.listen(0, '127.0.0.1', r))
const hostOrigin = `http://127.0.0.1:${host.address().port}`
const probe = net.createServer(); await new Promise(r => probe.listen(0, '127.0.0.1', r)); const port = probe.address().port; await new Promise(r => probe.close(r))
const origin = `http://127.0.0.1:${port}`
const script = path.join(work, 'witness.lisp')
fs.writeFileSync(script, `(require :asdf)\n(asdf:load-system "hyperbook/fedwiki/tests")\n(hyperbook/fedwiki/tests:serve-browser-witness ${port} "${hostOrigin}/" #p"${stop}")\n`)
const log = fs.openSync(path.join(output, 'lisp.log'), 'w')
const child = spawn(lisp, ['--load', script], {stdio: ['ignore', log, log]})
const report = {kind: 'actual HyperDoc Story / original Mech CODE / original Solo receiver', origin, hostOrigin,
  pageSource: {url: 'http://ward.voices.ustawi.wiki/trails-rendered.json', sha256: hash(original)},
  mechSource: provenance.assets[0].source, soloSource: provenance.assets.find(a => a.path.endsWith('index.html')).source,
  imports, browser: null, checks: [], console: [], pageErrors: [], unexpectedRequests: [], requests: [], productionAccess: false}
const check = (label, fn) => { fn(); report.checks.push(label) }
const {chromium} = await import(pathToFileURL(path.join(playwrightPath, 'index.mjs')))
let browser, page
try {
  for (let i = 0; i < 300; i++) {
    if (child.exitCode !== null) throw Error(fs.readFileSync(path.join(output, 'lisp.log'), 'utf8').slice(-4000))
    try { if ((await fetch(origin)).ok) break } catch {}
    await new Promise(r => setTimeout(r, 100))
  }
  browser = await chromium.launch({headless: true, executablePath: chrome, args: ['--no-proxy-server']})
  report.browser = browser.version()
  const context = await browser.newContext({serviceWorkers: 'block'})
  await context.route('**/*', async route => {
    const url = route.request().url(); report.requests.push(url)
    const asset = imports.find(a => a.url === url)
    if (asset) return route.fulfill({body: fs.readFileSync(path.join(cache, asset.name)), contentType: asset.contentType, headers: {'access-control-allow-origin': '*'}})
    if ([origin, hostOrigin].includes(new URL(url).origin)) return route.continue()
    // Original external favicon is an image, not an executable dependency.
    if (route.request().resourceType() === 'image') return route.abort()
    report.unexpectedRequests.push(url); return route.abort()
  })
  await context.addInitScript(() => {
    window.recordedSoloBatches = []
    window.addEventListener('message', e => { if (e.data?.type === 'batch') window.recordedSoloBatches.push({origin: e.origin, sourceIsOpener: e.source === opener, data: structuredClone(e.data)}) })
  })
  context.on('page', p => {
    p.on('console', m => report.console.push({url: p.url(), type: m.type(), text: m.text()}))
    p.on('pageerror', e => report.pageErrors.push({url: p.url(), message: e.message}))
  })
  page = await context.newPage(); await page.goto(origin)
  await page.getByRole('heading', {name: 'Trails Rendered', exact: true}).waitFor()
  const embedded = page.locator('.fedwiki-mech-host')
  const supplied = await embedded.evaluate(e => ({page: JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(e.dataset.pageJsonBase64), c => c.charCodeAt(0)))), itemId: e.dataset.itemId}))
  check('Full original page JSON and item identity reach Story unchanged', () => { assert.deepEqual(supplied.page, raw); assert.equal(supplied.itemId, '6405b752d1739af0') })
  const frame = page.frameLocator('.fedwiki-mech-host iframe')
  const buttons = frame.getByRole('button', {name: '▶', exact: true})
  await buttons.first().waitFor()
  await new Promise(r => setTimeout(r, 300))
  check('CLICK Play appears; displaying Story runs no Code import', () => { assert(!report.requests.includes(imports[0].url)) })
  assert.equal(await buttons.count(), 1)
  assert.match(await frame.locator('.item.mech').innerText(), /CLICK\s*▶/)
  const hostFrame = page.frames().find(f => f.url().startsWith(hostOrigin))
  const contextProof = await hostFrame.evaluate(() => ({page: wiki.lineup.atKey('hyperdoc-page').getRawPage(),
    remote: wiki.lineup.atKey('hyperdoc-page').isRemote(), owner: window.isOwner,
    site: $('.page').data('site'), slug: $('.page').attr('id'), origin: location.origin}))
  check('Unowned remote page context preserves source site, slug and all Code items', () => {
    assert.deepEqual(contextProof.page, raw); assert.equal(contextProof.remote, true); assert.equal(contextProof.owner, false)
    assert.equal(contextProof.site, 'ward.voices.ustawi.wiki'); assert.equal(contextProof.slug, 'trails-rendered')
  })
  const separate = await hostFrame.evaluate(() => { try { return !!parent.document } catch (e) { return e.name } })
  check('Host frame cannot access the Lisp Inspector DOM', () => assert.equal(separate, 'SecurityError'))
  await buttons.first().click()
  await frame.locator('.item.mech').getByText('CODE trails ⇒ 2 aspects', {exact: true}).waitFor()
  check('First real CLICK executes original trails export and original Graph import', () => assert(report.requests.includes(imports[0].url)))
  report.mechText = await frame.locator('.item.mech').innerText()
  const popupEvent = page.waitForEvent('popup')
  await buttons.nth(1).click()
  const popup = await popupEvent; await popup.waitForLoadState('domcontentloaded')
  await popup.waitForFunction(() => window.recordedSoloBatches.length === 1)
  report.batch = await popup.evaluate(() => window.recordedSoloBatches[0])
  const batch = report.batch.data
  check('Original Solo receives original two-aspect batch from its opener', () => {
    assert.equal(report.batch.sourceIsOpener, true); assert.equal(report.batch.origin, hostOrigin)
    assert.equal(batch.type, 'batch'); assert.equal(batch.pageKey, 'hyperdoc-page'); assert.equal(batch.sources.length, 1)
    assert.equal(batch.sources[0].source, 'Trails Rendered'); assert.equal(batch.sources[0].aspects.length, 2)
    for (const aspect of batch.sources[0].aspects) { assert.equal(aspect.graph.nodes.length, 3); assert.equal(aspect.graph.rels.length, 2); assert(aspect.graph.rels.every(r => r.type === 'Trail')) }
    const a = batch.sources[0].aspects[0].graph.nodes[2], b = batch.sources[0].aspects[1].graph.nodes[2]
    assert.notEqual(a, b); assert.deepEqual(a.props, b.props)
    assert.equal(a.props.name, 'Reflective\nPractice')
  })
  await popup.locator('#n0').check()
  await popup.waitForFunction(() => document.querySelectorAll('#target svg g.node').length === 3)
  await popup.locator('#n1').check()
  await popup.waitForFunction(() => document.querySelectorAll('#target svg g.node').length === 5 && document.querySelectorAll('#target svg g.edge').length === 4)
  report.render = await popup.evaluate(() => ({dot: window.dot,
    nodes: [...document.querySelectorAll('#target svg g.node')].map(n => [...n.querySelectorAll('text')].map(t => t.textContent).join(' ')),
    edges: [...document.querySelectorAll('#target svg g.edge')].map(n => ({title: n.querySelector('title').textContent, label: n.querySelector('text').textContent}))}))
  check('Original Solo composes five nodes/four Trail edges with one shared destination', () => {
    assert.equal(report.render.nodes.length, 5); assert.equal(report.render.edges.length, 4)
    assert.equal(report.render.nodes.filter(n => n.includes('Reflective')).length, 1)
    assert(report.render.edges.every(e => e.label === 'Trail'))
    const incoming = report.render.edges.map(e => e.title.split('->')[1]); assert.equal(new Set(incoming).size, 3)
  })
  await popup.screenshot({path: path.join(output, 'solo.png')})
  await popup.close()
  await buttons.nth(2).click()
  const previewFailure = "Cannot create property 'id' on string 'See [[Solo Lineup Browser]]'"
  await frame.locator('#failure').getByText(previewFailure, {exact: true}).waitFor()
  report.previewBoundary = {diagnostic: previewFailure, source: 'Unchanged candidate preview_emit assigns item.id to the string in original trails().items; no normalization or source patch.'}
  report.checks.push('Third original CLICK exposes original PREVIEW string-item failure without changing source')
  // Layout and failure behavior in the actual Inspector. A failed original
  // import is surfaced by Mech's own trouble button; no local replacement.
  await page.setViewportSize({width: 380, height: 900}); await page.reload(); await buttons.first().waitFor()
  const sizes = await embedded.evaluate(e => ({width: e.clientWidth, scroll: e.scrollWidth}))
  check('Narrow Story container does not overflow', () => assert(sizes.scroll <= sizes.width + 1))
  await context.route(imports[0].url, route => route.abort('failed'))
  await buttons.first().click()
  await frame.getByRole('button', {name: '✖︎', exact: true}).click()
  const diagnostic = await frame.locator('.item.mech').innerText()
  check('Original CODE failure remains visible in its browser frame', () => assert.match(diagnostic, /Failed to fetch dynamically imported module/))
  report.diagnostic = diagnostic
  // The Inspector remains available; this is a native link to the original
  // item, not a browser-to-Lisp code execution callback.
  const beforePanes = await page.locator('.inspector-pane').count()
  await page.waitForFunction(() => { const e = [...document.querySelectorAll('span[id^=inspect-]')].find(e => e.textContent === 'Inspect original Mech item'); return e && Object.keys($._data(e, 'events') || {}).length > 0 })
  report.nativeLink = await page.getByText('Inspect original Mech item', {exact: true}).evaluate(e => ({html: e.outerHTML, events: Object.keys($._data(e, 'events') || {})}))
  await page.getByText('Inspect original Mech item', {exact: true}).click()
  await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, beforePanes)
  report.itemPane = await page.locator('.inspector-pane').last().innerText()
  fs.writeFileSync(path.join(output, 'item-pane.html'), await page.locator('.inspector-pane').last().innerHTML())
  await page.locator('.inspector-pane').last().getByText('6405b752d1739af0', {exact: false}).waitFor()
  report.checks.push('Native item inspection remains usable after browser failure')
  check('No unexpected executable/network dependency escaped offline routes', () => assert.deepEqual(report.unexpectedRequests, []))
  check('Only the separately recorded original PREVIEW error reached browser pageerror', () => { assert.equal(report.pageErrors.length, 1); assert.equal(report.pageErrors[0].message, previewFailure) })
  report.status = 'PASS'
} catch (error) {
  if (page) { fs.writeFileSync(path.join(output, 'failed-page.html'), await page.content()); fs.writeFileSync(path.join(output, 'failed-page.txt'), await page.locator('body').innerText()); await page.screenshot({path:path.join(output, 'failed-page.png')}) }
  report.status = 'FAIL'; report.failure = {message: error.message, stack: error.stack}; throw error
} finally {
  fs.writeFileSync(path.join(output, 'report.json'), JSON.stringify(report, null, 2) + '\n')
  if (browser) await browser.close()
  fs.writeFileSync(stop, '')
  await new Promise(resolve => { if (child.exitCode !== null) resolve(); else { child.once('exit', resolve); setTimeout(() => {child.kill('SIGTERM'); resolve()}, 5000).unref() } })
  await new Promise(r => host.close(r)); fs.closeSync(log)
}
console.log(JSON.stringify({status: report.status, checks: report.checks, nodes: report.render.nodes.length, edges: report.render.edges.length}))
