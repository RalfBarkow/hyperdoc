// Browser witness for the Paragraph Item of "Assessing an Upstream Commit": no Lisp, no Catalog.
// Needs the locked packages (npm ci --prefix tests/fedwiki-original-editor --ignore-scripts) and a Chromium:
//   node tests/fedwiki-original-editor/paragraph-witness.mjs CHROMIUM
// A disposable site is seeded from the checkout's HTML (read only). The original server.mjs / Wiki client write it
// through the original text editor; the witness asserts the stored result. It never writes the HTML source.
import assert from 'node:assert/strict'
import fs from 'node:fs'
import os from 'node:os'
import net from 'node:net'
import http from 'node:http'
import path from 'node:path'
import {spawn} from 'node:child_process'
import {createHash} from 'node:crypto'
import {fileURLToPath} from 'node:url'
import {chromium} from 'playwright-core'
import {slug, initialPage, upstreamSlug, upstreamParagraphId, upstreamPage, introductionText} from './fixture.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))
const htmlSource = path.resolve(here, '../../dreyeck/pages/upstream-intake/Assessing an Upstream Commit.html')
const chrome = process.argv[2]
assert(chrome, 'usage: node paragraph-witness.mjs CHROMIUM')
const sha = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex')
const htmlBefore = sha(htmlSource)
const freePort = async () => { const l = net.createServer(); await new Promise(r=>l.listen(0,'127.0.0.1',r))
  const p = l.address().port; await new Promise(r=>l.close(r)); return p===8080 ? freePort() : p }

const work = fs.mkdtempSync(path.join(os.tmpdir(),'hyperdoc-paragraph-witness-'))
const site = path.join(work,'site'), pages = path.join(site,'pages')
fs.mkdirSync(pages,{recursive:true}); fs.mkdirSync(path.join(work,'home'))
const seed = introductionText(fs.readFileSync(htmlSource,'utf8'))
fs.writeFileSync(path.join(pages,slug), JSON.stringify(initialPage(),null,2)+'\n')
fs.writeFileSync(path.join(pages,upstreamSlug), JSON.stringify(upstreamPage(seed),null,2)+'\n')
const file = path.join(pages,upstreamSlug), otherFile = path.join(pages,slug)
const stored = () => JSON.parse(fs.readFileSync(file,'utf8'))
const otherBefore = sha(otherFile), pageBefore = stored()

const port = await freePort(), parentPort = await freePort()
const parentOrigin = `http://127.0.0.1:${parentPort}`, origin = `http://127.0.0.1:${port}`
const parent = http.createServer((req,res)=>{ res.writeHead(200,{'Content-Type':'text/html'})
  res.end(`<iframe id="frame" src="${new URL(req.url,parentOrigin).searchParams.get('src')}" style="width:900px;height:500px"></iframe>`) })
await new Promise(r=>parent.listen(parentPort,'127.0.0.1',r))
const wiki = spawn(process.execPath,[path.join(here,'server.mjs'),site,String(port),'true'],
  {cwd:work,env:{...process.env,HOME:path.join(work,'home'),HYPERDOC_FEDWIKI_INSPECTOR_ORIGIN:parentOrigin},stdio:'ignore'})
let browser
try {
  for (let n=0;n<300;n++) { try { if ((await fetch(origin)).ok) break } catch {} await new Promise(r=>setTimeout(r,200)) }
  const frameUrl = revision => `${origin}/view/${upstreamSlug}?hyperdocItem=${upstreamParagraphId}&revision=${revision}`
  // Refusals first: stale revision, another page's item id.
  assert.equal((await fetch(frameUrl('stale'))).status, 409)
  assert.equal((await fetch(`${origin}/view/${upstreamSlug}?hyperdocItem=2222222222222222&revision=${sha(file)}`)).status, 409)

  browser = await chromium.launch({headless:true,executablePath:chrome,args:['--no-sandbox','--no-proxy-server']})
  const context = await browser.newContext({serviceWorkers:'block'})
  const page = await context.newPage(), errors = []
  page.on('pageerror', e => errors.push(e.message))
  await page.goto(`${parentOrigin}/?src=${encodeURIComponent(frameUrl(sha(file)))}`)
  const frame = page.frameLocator('#frame')
  const edit = frame.locator('#hyperdoc-code-toolbar button:not([disabled])')
  await edit.waitFor({timeout:60000})
  assert.equal(await frame.locator('.item').count(), 1, 'only the selected Item is in the frame')
  await edit.click()
  const textarea = frame.locator('.item textarea')
  await textarea.waitFor()
  assert.equal(await textarea.inputValue(), seed, 'the original editor opens on the stored text')
  const changed = seed + ' [edited in the original paragraph editor]'
  await textarea.fill(changed)
  await frame.getByRole('status').click()          // outside the Item: the original focusout handler saves
  for (let n=0;n<100 && stored().journal.length===pageBefore.journal.length;n++) await new Promise(r=>setTimeout(r,100))

  const after = stored(), action = after.journal.at(-1)
  assert.equal(after.story.length, 1)
  assert.equal(after.story[0].id, upstreamParagraphId, 'the Item ID is preserved')
  assert.equal(after.story[0].type, 'paragraph')
  assert.equal(after.story[0].text, changed)
  assert.equal(after.journal.length, pageBefore.journal.length+1, 'exactly one Action appended')
  assert.deepEqual(after.journal.slice(0,-1), pageBefore.journal, 'earlier journal untouched')
  assert.equal(action.type, 'edit'); assert.equal(action.id, upstreamParagraphId)
  assert.equal(action.item.text, changed); assert.equal(typeof action.date, 'number')
  assert.equal(sha(otherFile), otherBefore, 'the other page is untouched')
  assert.equal(sha(htmlSource), htmlBefore, 'the HTML source is untouched')
  // The one known defect of the original unclaimed-site client (see INSPECTOR-INTEGRATION.md); anything else fails.
  assert.deepEqual(errors.filter(m => !/reading 'setup'/.test(m)), [])
  console.log(JSON.stringify({passed:true, id:upstreamParagraphId, journalActions:after.journal.map(a=>a.type), text:changed}))
} finally {
  if (browser) await browser.close().catch(()=>{})
  wiki.kill('SIGTERM'); parent.close(); fs.rmSync(work,{recursive:true,force:true})
}
