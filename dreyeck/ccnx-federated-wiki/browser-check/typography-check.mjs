// Reading typography in the real Catalog and Inspector, at a wide and at a narrow pane.
//
// usage: node typography-check.mjs ORIGIN OUTPUT_DIR LABEL [--measure-only]
//   ORIGIN      a running Catalog with the reading (serve.lisp), e.g. http://127.0.0.1:48851
//   OUTPUT_DIR  receives LABEL-metrics.json and one screenshot per page and width
//   --measure-only  record the measurements and the assertion results but do not exit with an error (for a state before a change)
// Needs `playwright` resolvable from the current directory; CHROMIUM=<path> selects the browser; PROXY_SERVER only if a network needs one.
// Nothing is written to the site: the Catalog is read through its Inspector.
//
// The assertions are properties of the reading, each with a reason; none is a pixel value or a pane count:
//   NO-SIDEWAYS-SCROLL    the pane body does not scroll sideways: content was out of sight (observed before: 1649 to 2479 px in a 698 px body)
//   TABLES-CONTAINED      a table is not wider than the body unless a box of its own scrolls it
//   NO-SPLIT-IDENTIFIER   inline code that is not marked as wrappable is never split across lines (it was, at hyphens)
//   NO-SPLIT-REFERENCE    a source reference (link to the pinned commit) is never split across lines
//   NO-PRE                no aligned <pre> block, which cannot wrap
//   MEASURE-LIMIT         running text is not wider than 38 em, the limit set in the style sheet
//   IDENTIFIER-SIZE       inline code is at least 85 % of the body size (it was 81 %)
//   HEADING-STEPS         h1 > h2 > h3 > body size, each step at least 2 px (it was 1.2 px)
//   EVIDENCE-LABELS       every .ev label says one of the four kinds
//   REFERENCES-VISIBLE    an Inspector reference is underlined and not the colour of the running text
import fs from 'node:fs'
import {createRequire} from 'node:module'
const require = createRequire(process.cwd() + '/')
let chromium
try { ({chromium} = require('playwright')) } catch { ({chromium} = require('playwright-core')) }
const [origin, out, label] = process.argv.slice(2); const measureOnly = process.argv.includes('--measure-only')
fs.mkdirSync(out, {recursive: true})
const browser = await chromium.launch({headless: true, args: ['--no-sandbox'],
  ...(process.env.CHROMIUM ? {executablePath: process.env.CHROMIUM} : {}),
  ...(process.env.PROXY_SERVER ? {proxy: {server: process.env.PROXY_SERVER}} : {})})
const titles = ['Reading the CCNx Federated Wiki', 'One Page From Browser to NDN and Back', 'Identity, Versions and Signatures', 'Plain Text After CCNx']
const slug = t => t.replace(/[^A-Za-z]+/g, '-').toLowerCase()
const viewports = {wide: {width: 1500, height: 1000}, narrow: {width: 520, height: 900}}
const result = {label, browser: 'Chromium ' + browser.version(), origin, pages: {}, assertions: [], pageErrors: [], failedRequests: []}
const KINDS = ['Implemented', 'Documented', 'Derived, not run', 'Open']

for (const [vname, vp] of Object.entries(viewports)) {
  const context = await browser.newContext({viewport: vp, deviceScaleFactor: 1, serviceWorkers: 'block'})
  const page = await context.newPage(); page.setDefaultTimeout(45000)
  page.on('pageerror', e => result.pageErrors.push(e.message))
  page.on('requestfailed', r => { if (new URL(r.url()).origin === new URL(origin).origin) result.failedRequests.push(r.url()) })
  for (const title of titles) {
    await page.goto(origin); await page.waitForLoadState('networkidle').catch(() => {})
    const n0 = await page.locator('.inspector-pane').count()
    await page.getByText('The CCNx Federated Wiki', {exact: true}).and(page.locator(':visible')).first().click()
    await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, n0)
    await page.locator('.inspector-pane').last().getByRole('button', {name: 'Text pages', exact: true}).click()
    const n1 = await page.locator('.inspector-pane').count()
    await page.locator('tr.inspector-inspect:visible').filter({hasText: title}).last().click()
    await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, n1)
    const pane = page.locator('.inspector-pane').last()
    await pane.getByRole('heading', {name: title, exact: true}).waitFor()
    // the style sheet is loaded asynchronously: measure only once it is in effect
    await page.waitForFunction(() => [...document.styleSheets].some(s => (s.href || '').includes('/ccnx-reading/css/reading.css') && (() => { try { return s.cssRules.length > 0 } catch (e) { return false } })()), null, {timeout: 4000}).catch(() => {}) // a state without the style sheet is measured as it is
    const m = await pane.evaluate(pane => {
      const body = pane.querySelector('.inspector-body'); const root = body.querySelector('.hyperbook-page') || body
      const size = el => parseFloat(getComputedStyle(el).fontSize)
      // lines: client rectangles whose vertical extents overlap belong to one line (a code chip and the text beside it differ in top)
      const tops = el => { const r = document.createRange(); r.selectNodeContents(el); const rs = [...r.getClientRects()].filter(x => x.width > 0).sort((a, b) => a.top - b.top); let lines = 0, bottom = -Infinity; for (const x of rs) { if (x.top >= bottom - 1) lines++; bottom = Math.max(bottom, x.bottom) } return lines }
      const inScroller = el => { for (let a = el.parentElement; a && a !== body; a = a.parentElement) { const o = getComputedStyle(a).overflowX; if (o === 'auto' || o === 'scroll') return true } return false }
      const bodyRect = body.getBoundingClientRect()
      const bodyFont = size(root)
      const textBlocks = [...root.querySelectorAll('p, ul, ol')].filter(e => !e.closest('table, dl'))
      const codes = [...root.querySelectorAll('code')].filter(c => !c.closest('pre'))
      const h = n => root.querySelector(n) && size(root.querySelector(n))
      const refs = [...root.querySelectorAll('.hyperbook-reference .inspector-inspect')]
      return {
        bodyClientWidth: body.clientWidth, bodyScrollWidth: body.scrollWidth, bodyFont,
        tables: [...root.querySelectorAll('table')].map(t => ({width: Math.round(t.getBoundingClientRect().width), escapes: t.getBoundingClientRect().right > bodyRect.right + 1 && !inScroller(t)})),
        splitIdentifiers: codes.filter(c => !c.classList.contains('wrap') && tops(c) > 1).map(c => c.textContent),
        splitReferences: [...root.querySelectorAll('a[href*="github.com"]')].filter(a => tops(a) > 1).map(a => a.textContent),
        pre: root.querySelectorAll('pre').length,
        widestTextEm: Math.max(0, ...textBlocks.map(e => e.getBoundingClientRect().width / bodyFont)),
        codeRatio: codes.length ? Math.min(...codes.map(c => size(c) / bodyFont)) : null,
        headings: {h1: h('h1'), h2: h('h2'), h3: h('h3')},
        labels: [...root.querySelectorAll('.ev')].map(e => e.textContent.trim()),
        refStyles: refs.map(r => ({underline: getComputedStyle(r).textDecorationLine.includes('underline'), differs: getComputedStyle(r).color !== getComputedStyle(root).color})),
        paragraphChars: (() => { const p = [...root.querySelectorAll('p')].sort((a, b) => b.textContent.length - a.textContent.length)[0]; return p && Math.round(p.textContent.trim().length / tops(p)) })()
      }
    })
    const key = `${slug(title)}@${vname}`; result.pages[key] = m
    const check = (name, ok, detail) => result.assertions.push({page: key, name, ok: !!ok, detail})
    check('NO-SIDEWAYS-SCROLL', m.bodyScrollWidth <= m.bodyClientWidth + 1, `scrollWidth ${m.bodyScrollWidth}, clientWidth ${m.bodyClientWidth}`)
    check('TABLES-CONTAINED', m.tables.every(t => !t.escapes), JSON.stringify(m.tables))
    check('NO-SPLIT-IDENTIFIER', m.splitIdentifiers.length === 0, m.splitIdentifiers.join(' | '))
    check('NO-SPLIT-REFERENCE', m.splitReferences.length === 0, m.splitReferences.join(' | '))
    check('NO-PRE', m.pre === 0, String(m.pre))
    check('MEASURE-LIMIT', m.widestTextEm <= 38.1, `widest ${m.widestTextEm.toFixed(1)} em`)
    check('IDENTIFIER-SIZE', m.codeRatio === null || m.codeRatio >= 0.85, `smallest code / body = ${m.codeRatio}`)
    const {h1, h2, h3} = m.headings
    check('HEADING-STEPS', h1 - (h2 ?? h1 - 2) >= 2 || h2 === null, `h1 ${h1}, h2 ${h2}, h3 ${h3}, body ${m.bodyFont}`)
    if (h2 && h3) check('HEADING-STEPS', h2 - h3 >= 2 && h3 > m.bodyFont, `h2 ${h2}, h3 ${h3}, body ${m.bodyFont}`)
    check('EVIDENCE-LABELS', m.labels.every(l => KINDS.includes(l)), m.labels.join(' | '))
    check('REFERENCES-VISIBLE', m.refStyles.every(r => r.underline && r.differs), JSON.stringify(m.refStyles.slice(0, 3)))
    await page.setViewportSize({width: vp.width, height: 4600}); await page.waitForTimeout(400)
    await page.locator('.inspector-pane').last().screenshot({path: `${out}/${label}-${slug(title)}-${vname}.png`})
    await page.setViewportSize(vp)
  }
  await context.close()
}
// Navigation: every page link and expression link of the four pages opens the object it names (title of an html-page, or the example page).
{
  const context = await browser.newContext({viewport: viewports.wide, serviceWorkers: 'block'})
  const page = await context.newPage(); page.setDefaultTimeout(45000)
  page.on('pageerror', e => result.pageErrors.push(e.message))
  await page.goto(origin); await page.waitForLoadState('networkidle').catch(() => {})
  const panes = () => page.locator('.inspector-pane')
  const nb = await panes().count()
  await page.getByText('The CCNx Federated Wiki', {exact: true}).and(page.locator(':visible')).first().click()
  await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, nb)
  await panes().last().getByRole('button', {name: 'Text pages', exact: true}).click()
  const np = await panes().count()
  await page.locator('tr.inspector-inspect:visible').filter({hasText: titles[0]}).last().click()
  await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, np)
  result.navigation = []
  let owner = panes().nth((await panes().count()) - 1)
  await owner.getByRole('heading', {name: titles[0], exact: true}).waitFor()
  const follow = async (from, text, expectTitle) => {
    const before = await panes().count()
    await from.locator('.hyperbook-reference').filter({hasText: text}).first().locator('.inspector-inspect').click()
    await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, before)
    const next = panes().nth((await panes().count()) - 1)
    if (expectTitle) await next.getByRole('heading', {name: expectTitle, exact: true}).waitFor()
    else await next.getByText('Plain text outlives the program that wrote it.', {exact: false}).first().waitFor()
    result.navigation.push({followed: text, opened: expectTitle || 'Plain Text Example (Story view)', paneAdded: (await panes().count()) === before + 1})
    return next
  }
  const pipeline = await follow(owner, titles[1], titles[1])
  const identity = await follow(pipeline, titles[2], titles[2])
  const plain = await follow(identity, titles[3], titles[3])
  const back = await follow(plain, titles[0], titles[0])
  await follow(back, 'the page as a Federated Wiki server stores it', null)
  result.assertions.push({page: 'navigation', name: 'LINKS-OPEN-TARGETS', ok: result.navigation.every(n => n.paneAdded), detail: JSON.stringify(result.navigation)})
  await context.close()
}
result.assertions.push({page: 'all', name: 'NO-PAGE-ERRORS', ok: result.pageErrors.length === 0, detail: result.pageErrors.join(' | ')})
result.assertions.push({page: 'all', name: 'NO-FAILED-INTERNAL-REQUESTS', ok: result.failedRequests.length === 0, detail: result.failedRequests.join(' | ')})
const failed = result.assertions.filter(a => !a.ok)
result.summary = {assertions: result.assertions.length, failed: failed.map(a => `${a.page}: ${a.name}`)}
fs.writeFileSync(`${out}/${label}-metrics.json`, JSON.stringify(result, null, 2) + '\n')
console.log(JSON.stringify(result.summary, null, 1))
await browser.close()
process.exit(failed.length && !measureOnly ? 1 : 0)
