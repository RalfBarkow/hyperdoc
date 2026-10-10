// Actual fresh CLOG Story -> bridge -> unchanged Mech, trusted sitemap fixture.
// Offline; output/profiles outside the repository. No production services.
// Usage: node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
import {createMechHost} from './serve-fedwiki-mech-host.mjs'
import {fixture, reference} from '../tests/fedwiki-mech-sitemap-fixture.mjs'

const [lisp, playwrightPath, chrome, output] = process.argv.slice(2)
if (!output) throw Error('Usage: LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT')
fs.mkdirSync(output, {recursive: true})
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'mech-sitemap-browser-'))
const stop = path.join(work, 'stop')
const host = createMechHost(); await new Promise(r => host.listen(0, '127.0.0.1', r))
const hostOrigin = `http://127.0.0.1:${host.address().port}`
const probe = net.createServer(); await new Promise(r => probe.listen(0, '127.0.0.1', r))
const port = probe.address().port; await new Promise(r => probe.close(r))
const origin = `http://127.0.0.1:${port}`
const script = path.join(work, 'witness.lisp')
fs.writeFileSync(script, `(require :asdf)\n(asdf:load-system "hyperbook/fedwiki/tests")\n(hyperbook/fedwiki/tests::serve-sitemap-browser-witness ${port} "${hostOrigin}/" #p"${stop}")\n`)
const log = fs.openSync(path.join(output, 'lisp.log'), 'w')
const child = spawn(lisp, ['--load', script], {stdio: ['ignore', log, log]})
const report = {kind: 'Trusted fixtures / actual fresh Inspector boundary / unchanged Mech',
  clock: fixture.clock, scope: 'page-origin-and-context', checks: [], cases: [], unexpectedRequests: [], productionAccess: false}
let browser
try {
  for (let i = 0; i < 300; i++) {
    if (child.exitCode !== null) throw Error(fs.readFileSync(path.join(output, 'lisp.log'), 'utf8').slice(-4000))
    if (fs.readFileSync(path.join(output, 'lisp.log'), 'utf8').includes('MECH-SITEMAP-BROWSER-READY')) break
    await new Promise(r => setTimeout(r, 100))
  }
  const {chromium} = await import(pathToFileURL(path.join(playwrightPath, 'index.mjs')))
  browser = await chromium.launch({headless: true, executablePath: chrome, args: ['--no-proxy-server']})
  report.browser = browser.version()
  const locale = new Intl.DateTimeFormat().resolvedOptions()
  report.locale = locale.locale; report.timezone = locale.timeZone
  const context = await browser.newContext({serviceWorkers: 'block', locale: locale.locale, timezoneId: locale.timeZone})
  await context.addInitScript({content: `Date.now = () => ${fixture.clock};`})
  await context.route('**/*', route => {
    if ([origin, hostOrigin].includes(new URL(route.request().url()).origin)) return route.continue()
    if (route.request().resourceType() !== 'image') report.unexpectedRequests.push(route.request().url())
    return route.abort()
  })
  const page = await context.newPage()
  for (const mode of ['ready', 'empty', 'missing', 'loading', 'failed']) {
    await page.goto(origin + '/' + mode)
    const embedded = page.locator('.fedwiki-mech-host')
    await embedded.waitFor()
    const supplied = await embedded.evaluate(e => JSON.parse(new TextDecoder().decode(
      Uint8Array.from(atob(e.dataset.neighborhoodJsonBase64), c => c.charCodeAt(0)))))
    assert.equal(supplied.scope, 'page-origin-and-context')
    assert.deepEqual(supplied.sites.map(s => s.domain), fixture.sites.map(s => s.domain))
    const frame = page.frameLocator('.fedwiki-mech-host iframe')
    const button = frame.getByRole('button', {name: '▶', exact: true})
    await button.waitFor()
    assert(!(await frame.locator('.item.mech').innerText()).includes('⇒'))
    report.checks.push(`${mode}: display executes no neighborhood/graph command`)
    const result = {mode, supplied}
    if (mode === 'ready') {
      for (let i = 0; i < supplied.sites.length; i++) assert.deepEqual(supplied.sites[i].sitemap, fixture.sites[i].sitemap)
      report.checks.push('ready: lossless fields, UTF-8, link values, source, site and entry order traverse the actual Inspector bridge')
      await button.click()
      await frame.locator('.item.mech').getByText('NEIGHBORS⇒ 4 pages, 2 sites', {exact: true}).waitFor()
      const hostFrame = page.frames().find(f => f.url().startsWith(hostOrigin))
      const inputs = await hostFrame.evaluate(() => wiki.neighborhoodObject.sites)
      result.inputs = inputs
      const expected = await reference(supplied.sites)
      for (const text of expected.statuses) await frame.locator('.item.mech').getByText(text, {exact: true}).waitFor()
      result.aspects = await hostFrame.evaluate(() => JSON.parse(JSON.stringify(document.querySelector('.item.mech').aspectData())))
      assert.deepEqual(result.aspects, expected.aspects)
      for (const s of supplied.sites) {
        assert.deepEqual(inputs[s.domain].sitemap, s.sitemap)
        assert.equal(inputs[s.domain].sourceUrl, s.sourceUrl)
      }
      report.checks.push('ready: NEIGHBORS nonempty; weeks/hubs graphs equal direct unchanged-revision execution')
    } else if (mode === 'empty') {
      await button.click()
      await frame.locator('.item.mech').getByText('NEIGHBORS⇒ 0 pages, 2 sites', {exact: true}).waitFor()
      await frame.locator('.item.mech').getByText('WALK 25 hubs ⇒ 0 aspects, 0 nodes', {exact: true}).waitFor()
      assert((await frame.locator('#neighborhood-status').innerText()).includes('ready'))
      report.checks.push('empty: explicitly retained empty sitemaps execute with original zero-result semantics')
    } else {
      assert((await frame.locator('#neighborhood-status').innerText()).includes(`context.fixture.test: ${mode}`))
      await button.click()
      await frame.locator('#failure').getByText(/NEIGHBORS cannot run/).waitFor()
      assert(!(await frame.locator('.item.mech').innerText()).includes('0 pages'))
      await page.locator('.mech-host-status').getByText(/NEIGHBORS cannot run/).waitFor()
      report.checks.push(`${mode}: explicit failure in frame and Inspector; no fabricated zero/partial neighborhood`)
    }
    result.text = await frame.locator('main').innerText()
    report.cases.push(result)
  }
  assert.deepEqual(report.unexpectedRequests, [])
  report.checks.push('No public fetch, proxy or executable network dependency')
  report.status = 'PASS'
} catch (error) {
  report.status = 'FAIL'; report.failure = {message: error.message, stack: error.stack}; throw error
} finally {
  fs.writeFileSync(path.join(output, 'report.json'), JSON.stringify(report, null, 2) + '\n')
  if (browser) await browser.close()
  fs.writeFileSync(stop, '')
  await new Promise(resolve => {
    if (child.exitCode !== null) resolve()
    else { child.once('exit', resolve); setTimeout(() => {child.kill('SIGTERM'); resolve()}, 5000).unref() }
  })
  await new Promise(r => host.close(r)); fs.closeSync(log)
}
console.log(JSON.stringify({status: report.status, checks: report.checks, cases: report.cases.length}))
