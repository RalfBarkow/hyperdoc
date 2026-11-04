// Navigation in the real Catalog and Inspector: open the reading, follow its internal page links, open an example page.
// usage: node check.mjs CHROMIUM PORT OUTPUT_DIR   (the server of serve.lisp must be running)
import assert from 'node:assert/strict'
import fs from 'node:fs'
import {chromium} from '/home/user/hyperdoc/tests/fedwiki-original-editor/node_modules/playwright-core/index.mjs'
const [chrome, port, out] = process.argv.slice(2)
fs.mkdirSync(out, {recursive:true})
const origin = `http://127.0.0.1:${port}`
const browser = await chromium.launch({headless:true, executablePath:chrome, args:['--no-sandbox','--no-proxy-server']})
const context = await browser.newContext({viewport:{width:1500,height:1000}, serviceWorkers:'block'})
const external = []
await context.route('**/*', route => { const u = new URL(route.request().url())
  if (u.origin === origin) return route.continue(); external.push(u.href); return route.abort() })
const page = await context.newPage(); page.setDefaultTimeout(60000)
const errors = []; page.on('pageerror', e => errors.push(e.message))
const steps = []
const panes = () => page.locator('.inspector-pane')
const last = () => panes().last()
const heading = async title => last().getByRole('heading', {name:title, exact:true}).waitFor()
// A link of the reading is a reference span; click the one inside the pane that shows the page, then wait for the new pane.
async function follow(fromPane, linkText, targetTitle) {
  const before = await panes().count()
  await fromPane.locator('.hyperbook-reference').filter({hasText:linkText}).first().locator('.inspector-inspect').click()
  await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, before)
  assert.equal(await panes().count(), before + 1, `following ${linkText} adds exactly one pane`)
  await heading(targetTitle)
  const pane = last()
  steps.push({followed: linkText, opened: targetTitle, panes: await panes().count()})
  return pane
}
await page.goto(origin)
await page.getByText('The CCNx Federated Wiki', {exact:true}).and(page.locator(':visible')).first().click()
await last().getByRole('button', {name:'Text pages', exact:true}).click()
await page.locator('tr.inspector-inspect:visible').filter({hasText:'Reading the CCNx Federated Wiki'}).last().click()
await heading('Reading the CCNx Federated Wiki')
const reading = last()
steps.push({opened: 'Reading the CCNx Federated Wiki', panes: await panes().count()})
// 1. internal page link, reading order item 1
const pipeline = await follow(reading, 'One Page From Browser to NDN and Back', 'One Page From Browser to NDN and Back')
assert((await pipeline.innerText()).includes('The path in Main'))
// 2. from that page onwards, to the next; the link sits in its last paragraph
const identity = await follow(pipeline, 'Identity, Versions and Signatures', 'Identity, Versions and Signatures')
assert((await identity.innerText()).includes('Signatures: checked'))
// 3. and to the last page; then back to the first by its back-link
const plain = await follow(identity, 'Plain Text After CCNx', 'Plain Text After CCNx')
assert((await plain.innerText()).includes('Where is Ward'))
const back = await follow(plain, 'Reading the CCNx Federated Wiki', 'Reading the CCNx Federated Wiki')
assert((await back.innerText()).includes('The seven questions, answered briefly'))
// 4. an expression link of the same family still opens the example page object with the Story view
const before = await panes().count()
await back.getByText('the page as a Federated Wiki server stores it').click()
await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, before)
await last().getByText('Plain text outlives the program that wrote it.', {exact:false}).first().waitFor()
steps.push({followed: 'example page A (expression link)', opened: 'Plain Text Example', panes: await panes().count()})
await page.screenshot({path: `${out}/navigation.png`, fullPage:true})
assert.deepEqual([...new Set(external)].filter(u => u !== 'https://ccnx-example.invalid/favicon.png'), [], 'no external request but the example favicon')
assert.deepEqual(errors, [])
fs.writeFileSync(`${out}/navigation.json`, JSON.stringify({passed:true, browser:browser.version(), steps, abortedExternal:[...new Set(external)], pageErrors:errors}, null, 2)+'\n')
console.log(JSON.stringify({passed:true, steps}, null, 2))
await browser.close()
