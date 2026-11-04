// Read-only browser acceptance of the CCNx reading in a served Catalog.
// usage: node accept.mjs OUTPUT_DIR [ORIGIN]        (ORIGIN defaults to https://dreyeck.ch)
// Needs the `playwright` (or `playwright-core`) package resolvable from the current directory and a Chromium:
//   CHROMIUM=/path/to/chromium   optional; Playwright's own browser is used when unset
//   PROXY_SERVER=http://host:port   optional; only if your network needs one. No credentials are read or stored here.
// Writes OUTPUT_DIR/acceptance.json, texts.json and numbered screenshots. It only reads the site; nothing is written to it.
import fs from 'node:fs'
import assert from 'node:assert/strict'
import {createRequire} from 'node:module'
const require = createRequire(process.cwd() + '/')
let chromium
try { ({chromium} = require('playwright')) } catch { ({chromium} = require('playwright-core')) }
const out = process.argv[2]; fs.mkdirSync(out,{recursive:true})
const origin = process.argv[3] || 'https://dreyeck.ch'
const browser = await chromium.launch({headless:true, args:['--no-sandbox'],
  ...(process.env.CHROMIUM ? {executablePath: process.env.CHROMIUM} : {}),
  ...(process.env.PROXY_SERVER ? {proxy:{server:process.env.PROXY_SERVER}} : {})})
const context = await browser.newContext({viewport:{width:1500,height:1000}, deviceScaleFactor:1, serviceWorkers:'block'})
const page = await context.newPage(); page.setDefaultTimeout(45000)
const log = {browser:'Chromium '+browser.version(), userAgent:null, console:[], pageErrors:[], failed:[], badStatus:[], externalRequests:[], steps:[], reference:{}, results:{}}
page.on('console', m => { if (['error','warning'].includes(m.type())) log.console.push(`${m.type()}: ${m.text()}`) })
page.on('pageerror', e => log.pageErrors.push(e.message))
page.on('requestfailed', r => log.failed.push(`${r.method()} ${r.url()} ${r.failure()?.errorText}`))
page.on('request', r => { const u=new URL(r.url()); if (u.origin!==origin && u.protocol.startsWith('http')) log.externalRequests.push(r.url()) })
page.on('response', r => { if (r.status() >= 400) log.badStatus.push(`${r.status()} ${r.url()}`) })
const panes = () => page.locator('.inspector-pane'), last = () => panes().last()
const fixed = async () => panes().nth((await panes().count()) - 1)
const heading = t => last().getByRole('heading', {name:t, exact:true}).waitFor()
const refs = async pane => [...new Set(await pane.locator('.hyperbook-reference').allInnerTexts())].map(s=>s.trim())
async function follow(from, text, title, kind='page') {
  const before = await panes().count()
  await from.locator('.hyperbook-reference').filter({hasText:text}).first().locator('.inspector-inspect').click()
  await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, before)
  const after = await panes().count()
  assert.equal(after, before+1, `${text}: one pane added`)
  if (title) await heading(title)
  log.steps.push({followed:text, kind, opened:title||'(object)', panesBefore:before, panesAfter:after})
  return fixed()
}
const titles = ['Reading the CCNx Federated Wiki','One Page From Browser to NDN and Back','Identity, Versions and Signatures','Plain Text After CCNx']
await page.goto(origin); await page.waitForLoadState('networkidle').catch(()=>{})
log.userAgent = await page.evaluate(()=>navigator.userAgent)
await page.screenshot({path:`${out}/00-catalog.png`})
// membership: exactly one entry in the Catalog list, reached by the regular path, nothing forced
await page.getByText('The CCNx Federated Wiki', {exact:true}).and(page.locator(':visible')).first().waitFor()
log.reference.catalogEntries = await page.getByText('The CCNx Federated Wiki', {exact:true}).and(page.locator(':visible')).count()
const nb = await panes().count()
await page.getByText('The CCNx Federated Wiki', {exact:true}).and(page.locator(':visible')).first().click()
await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, nb)
const book = await fixed()
log.steps.push({step:'Catalog -> The CCNx Federated Wiki', panes: await panes().count(), bookPaneText: (await book.innerText()).slice(0,120)})
await book.getByRole('button',{name:'Main page',exact:true}).click().catch(()=>{})
await page.waitForTimeout(500)
log.reference.mainPageTabHeading = await book.getByRole('heading').allInnerTexts()
await book.getByRole('button', {name:'Text pages', exact:true}).click()
const listed = await book.locator('tr.inspector-inspect:visible, .inspector-inspect:visible').allInnerTexts()
log.reference.textPages = listed.map(s=>s.trim()).filter(Boolean)
const np = await panes().count()
await page.locator('tr.inspector-inspect:visible').filter({hasText:titles[0]}).last().click()
await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, np)
await heading(titles[0])
let pane = await fixed()
log.steps.push({step:'Text pages -> '+titles[0], panes: await panes().count()})
await page.screenshot({path:`${out}/01-reading.png`})
const texts = {}, links = {}
texts[titles[0]] = await pane.innerText(); links[titles[0]] = await refs(pane)
// the four pages in reading order, then back to the main page
const main = pane
const pipeline = await follow(main, titles[1], titles[1]); texts[titles[1]] = await pipeline.innerText(); links[titles[1]] = await refs(pipeline)
await page.screenshot({path:`${out}/02-pipeline.png`})
const identity = await follow(pipeline, titles[2], titles[2]); texts[titles[2]] = await identity.innerText(); links[titles[2]] = await refs(identity)
await page.screenshot({path:`${out}/03-identity.png`})
const plain = await follow(identity, titles[3], titles[3]); texts[titles[3]] = await plain.innerText(); links[titles[3]] = await refs(plain)
await page.screenshot({path:`${out}/04-plain.png`})
const back = await follow(plain, titles[0], titles[0])
assert((await back.innerText()).includes('The seven questions, answered briefly'))
log.steps.push({backToMain:true})
// every link of every page that names one of the four pages leads to that page
for (const [from, ls] of Object.entries(links)) {
  const targets = ls.filter(t => titles.includes(t) && t !== from)
  log.reference['linksFrom: '+from] = {all: ls, followedTargets: targets}
}
// expression links to the example page
const e1 = await follow(back, 'the page as a Federated Wiki server stores it', null, 'expr')
await last().getByText('Plain text outlives the program that wrote it.', {exact:false}).first().waitFor()
texts['Example A'] = await e1.innerText()
await page.screenshot({path:`${out}/05-example-a.png`})
const b2 = await panes().count()
await back.locator('.hyperbook-reference').filter({hasText:'the same page as the Main code leaves it in IndexedDB'}).first().locator('.inspector-inspect').click()
log.steps.push({followed:'the same page as the Main code leaves it in IndexedDB', kind:'expr (from a non-last pane)', panesBefore:b2})
await last().getByText('Plain text outlives the program that wrote it.', {exact:false}).first().waitFor()
log.steps[log.steps.length-1].panesAfter = await panes().count()
texts['Example B'] = await last().innerText()
await page.screenshot({path:`${out}/06-example-b.png`})

// Every reference of each page, followed once from its own pane, last pane first (a click in an earlier pane replaces the panes after it).
log.reference.allLinks = []
for (const k of [6,5,4,3,2]) {
  const total = await panes().count()
  const owner = panes().nth(k)
  const title = (await owner.getByRole('heading').first().innerText()).trim()
  for (const text of await refs(owner)) {
    const before = await panes().count()
    await panes().nth(k).locator('.hyperbook-reference').filter({hasText:text}).first().locator('.inspector-inspect').click()
    await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length >= n, k+2)
    await page.waitForTimeout(400)
    const after = await panes().count()
    const target = panes().nth(after-1)
    const heads = (await target.getByRole('heading').allInnerTexts()).map(x=>x.trim()).slice(0,3)
    const body = (await target.innerText()).replace(/\s+/g,' ').slice(0,90)
    log.reference.allLinks.push({from:title, paneIndex:k, link:text, panesAfter:after, targetHeadings:heads, targetStart:body})
  }
}
log.reference.finalPanes = await panes().count()
fs.writeFileSync(`${out}/texts.json`, JSON.stringify(texts,null,1))
fs.writeFileSync(`${out}/acceptance.json`, JSON.stringify(log,null,2))
console.log(JSON.stringify(log,null,2)); await browser.close()
