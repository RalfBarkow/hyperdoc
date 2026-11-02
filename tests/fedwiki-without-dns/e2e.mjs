// The shortest way for a reader: Catalog -> demo HyperBook -> the page -> the Inspector observation, in a real browser against a local Catalog
// that names the demo explicitly. Reads two files of the checkout; no wiki site, no outgoing request (any is aborted and fails the run).
//   node e2e.mjs SBCL OUTPUT-DIRECTORY [CHROMIUM]
import assert from 'node:assert/strict'
import fs from 'node:fs'
import net from 'node:net'
import path from 'node:path'
import {spawn} from 'node:child_process'
import {fileURLToPath, pathToFileURL} from 'node:url'
const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const {chromium} = await import(pathToFileURL(path.join(repo, 'tests/fedwiki-original-editor/node_modules/playwright-core/index.mjs')).href)
const {installBoundClicks} = await import(pathToFileURL(path.join(repo, 'scripts/lib/inspector-ready.mjs')).href)
const [sbcl, output, chrome = process.env.CHROMIUM || '/opt/pw-browsers/chromium-1243/chrome-linux64/chrome'] = process.argv.slice(2)
assert(sbcl && output, 'usage: node e2e.mjs SBCL OUTPUT-DIRECTORY [CHROMIUM]')
fs.mkdirSync(output, {recursive: true})
const free = async () => { const l = net.createServer(); await new Promise(r => l.listen(0, '127.0.0.1', r)); const p = l.address().port; await new Promise(r => l.close(r)); return p === 8080 ? free() : p }
const port = await free(), origin = `http://127.0.0.1:${port}`, stop = path.join(output, 'stop-catalog')
fs.rmSync(stop, {force: true})
const logFile = path.join(output, 'catalog.log'), fd = fs.openSync(logFile, 'w')
const child = spawn(sbcl, ['--noinform', '--no-sysinit', '--no-userinit', '--script', path.join(here, 'serve.lisp')],
  {stdio: ['ignore', fd, fd], env: {...process.env, HYPERDOC_WITHOUT_DNS_PORT: String(port), HYPERDOC_WITHOUT_DNS_STOP: stop}})
const report = {steps: [], browserErrors: [], externalRequests: [], requestedOrigins: []}
let browser
try {
  const began = Date.now()
  for (;;) {
    if (child.exitCode !== null) throw Error('the Catalog exited: ' + fs.readFileSync(logFile, 'utf8').slice(-3000))
    try { if ((await fetch(origin, {signal: AbortSignal.timeout(1500)})).ok) break } catch {}
    if (Date.now() - began > 240000) throw Error('Catalog start-up exceeded 240 s: ' + fs.readFileSync(logFile, 'utf8').slice(-3000))
    await new Promise(r => setTimeout(r, 300))
  }
  const log = fs.readFileSync(logFile, 'utf8')
  assert.match(log, /DEFAULT-CATALOG \d+ HyperBooks; dreyeck\/fedwiki-without-dns-demo not among them/)
  assert.match(log, /CATALOG-WITH-DEMO \d+ HyperBooks; dreyeck\/fedwiki-without-dns-demo once/)
  report.steps.push('Catalog started with the demo named; it is not in the default membership, and present once afterwards')
  browser = await chromium.launch({headless: true, executablePath: chrome, args: ['--no-sandbox', '--no-proxy-server']})
  const context = await browser.newContext({serviceWorkers: 'block', viewport: {width: 1400, height: 1100}})
  await context.route('**/*', route => {
    const url = new URL(route.request().url())
    if (url.origin === origin) { report.requestedOrigins.push(url.origin); return route.continue() }
    report.externalRequests.push(url.href); return route.abort()
  })
  const page = await context.newPage()
  installBoundClicks(page)
  page.setDefaultTimeout(60000)
  page.on('pageerror', e => report.browserErrors.push(e.message))
  const panes = () => page.locator('.inspector-pane')
  const last = () => panes().last()
  const paneCount = () => panes().count()
  const text = async locator => (await locator.innerText())
  // 1. Catalog -> the demo HyperBook
  await page.goto(origin)
  await page.getByText('Reading a Wiki Page Without DNS', {exact: true}).and(page.locator(':visible')).first().click()
  report.steps.push('Catalog lists "Reading a Wiki Page Without DNS" and it opens')
  // 2. the HyperBook's page
  await last().getByRole('button', {name: 'Text pages', exact: true}).click()
  await page.locator('tr.inspector-inspect:visible').filter({hasText: 'Reading One Wiki Page Without DNS'}).last().click()
  await last().getByRole('heading', {name: 'Reading One Wiki Page Without DNS', exact: true}).waitFor()
  const pagePane = panes().nth((await paneCount()) - 1)   // fixed to this pane: LAST() moves on as panes open
  const pageText = await text(pagePane)
  for (const needle of ['wiki.without-dns.test', 'without-dns-test-page', 'Without DNS Test Page', 'name resolution failed', 'read; the same page',
                        'answered; no page', 'unreachable', 'read; other content', 'authenticates nothing'])
    assert(pageText.includes(needle), `the page does not show "${needle}"`)
  assert.equal(await pagePane.locator('iframe, form, input, textarea').count(), 0)
  await page.screenshot({path: path.join(output, '1-page.png'), fullPage: true})
  report.steps.push('The page shows the stored page and the six observations, with no frame, form or input')
  // 3. Inspector observation: the record, compared
  const before = await paneCount()
  await pagePane.locator('.inspector-inspect').getByText('Experiment record', {exact: true}).first().click()
  await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, before)
  await last().getByRole('heading', {name: 'One page, read by name and then through a given address', exact: true}).waitFor()
  const comparison = await text(last())
  for (const needle of ['ordinary resolution', 'endpoint 10.77.0.1 (from A)', 'the address that the resolution in observation A gave', 'failed: NS-TRY-AGAIN-ERROR',
                        'resolved 10.77.0.1', 'HTTP 200', 'HTTP 404', 'none: name-resolution', 'none: timeout', 'name resolution failed', 'read; the same page',
                        'What was observed, derived, inferred and only hypothesized', 'What this record does not show'])
    assert(comparison.includes(needle), `the comparison does not show "${needle}"`)
  assert.equal(await last().locator('table.without-dns-comparison tr.without-dns-observation').count(), 6)
  await page.screenshot({path: path.join(output, '2-comparison.png'), fullPage: true})
  report.steps.push('The Inspector compares the access paths: six observations, the failed resolution, the given endpoint and its origin')
  // 4. the same claims by warrant
  await last().getByRole('button', {name: 'Claims by warrant', exact: true}).click()
  await last().getByRole('heading', {name: 'Hypothesized', exact: true}).waitFor()
  const byWarrant = await text(last())
  for (const word of ['Observed', 'Derived', 'Inferred', 'Hypothesized']) assert(byWarrant.includes(word), `no ${word} section`)
  assert(byWarrant.includes('Assumption'), 'the inferred claim does not state its assumption')
  await page.screenshot({path: path.join(output, '3-claims-by-warrant.png'), fullPage: true})
  report.steps.push('Observed, derived, inferred and hypothesized claims are separate sections; the inferred one states its assumption')
  // 5. one observation of each path
  for (const [label, expected, shot] of [['B (ordinary, DNS failing)', ['Observation B', 'failed: USOCKET:NS-TRY-AGAIN-ERROR', 'no connection (name-resolution)', 'Endpoint used', 'none'], '4-observation-B.png'],
                                         ['C (given endpoint, DNS still failing)', ['Observation C', 'connected, HTTP 200', 'Origin of the endpoint mapping', 'derived', '10.77.0.1'], '5-observation-C.png']]) {
    await pagePane.locator('.inspector-inspect').getByText(label, {exact: true}).first().click()
    // A reference opens its object in the next pane and replaces the panes to its right, so the pane count may not grow: wait for the object.
    await last().getByRole('heading', {name: new RegExp('^' + expected[0])}).waitFor()
    const body = await text(last())
    for (const needle of expected) assert(body.includes(needle), `${expected[0]} does not show "${needle}"`)
    await page.screenshot({path: path.join(output, shot), fullPage: true})
  }
  report.steps.push('Observation B (ordinary path) and C (given endpoint) open as Inspector objects with per-field warrants')
  assert.deepEqual(report.externalRequests, [], 'a request left the Catalog')
  assert.deepEqual(report.browserErrors, [])
  report.passed = true
} catch (error) {
  report.error = String(error.stack || error)
  try { await browser?.contexts()[0]?.pages()[0]?.screenshot({path: path.join(output, 'failure.png'), fullPage: true}) } catch {}
} finally {
  fs.writeFileSync(stop, 'stop')
  await browser?.close().catch(() => {})
  await new Promise(r => { if (child.exitCode !== null) r(); else { child.once('exit', r); setTimeout(() => { child.kill('SIGTERM'); r() }, 10000) } })
  report.requestedOrigins = [...new Set(report.requestedOrigins)]
  fs.writeFileSync(path.join(output, 'e2e-report.json'), JSON.stringify(report, null, 2) + '\n')
  console.log(JSON.stringify(report, null, 2))
  if (!report.passed) process.exitCode = 1
}
