// The original server behind server.mjs, without Lisp or a browser: who may write, and what the frame adapter refuses.
// Needs the locked packages: npm ci --prefix tests/fedwiki-original-editor --ignore-scripts
//   node --test tests/fedwiki-original-editor/server.test.mjs
import test from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import os from 'node:os'
import net from 'node:net'
import path from 'node:path'
import {spawn} from 'node:child_process'
import {createHash} from 'node:crypto'
import {fileURLToPath} from 'node:url'
import {slug, codeId, paragraphId, code, initialPage} from './fixture.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))

async function freePort() {
  const listener = net.createServer()
  await new Promise((resolve,reject)=>{listener.once('error',reject);listener.listen(0,'127.0.0.1',resolve)})
  const port = listener.address().port
  await new Promise(r=>listener.close(r))
  return port === 8080 ? freePort() : port
}

const created = []
test.after(() => { for (const work of created) fs.rmSync(work,{recursive:true,force:true}) })

function freshSite() {
  const work = fs.mkdtempSync(path.join(os.tmpdir(),'hyperdoc-wiki-server-test-'))
  created.push(work)
  const site = path.join(work,'site')
  fs.mkdirSync(path.join(site,'pages'),{recursive:true}); fs.mkdirSync(path.join(work,'home'))
  fs.writeFileSync(path.join(site,'pages',slug),JSON.stringify(initialPage(),null,2)+'\n')
  return {work, site}
}

// Every file of the site with its bytes: what a write would change.
function snapshot(site) {
  const files = {}
  const walk = d => { for (const e of fs.readdirSync(d,{withFileTypes:true})) {
    const p = path.join(d,e.name); if (e.isDirectory()) walk(p); else files[path.relative(site,p)] = fs.readFileSync(p).toString('base64') } }
  walk(path.join(site,'pages')); return files
}

async function start({site, work, legacy, parentOrigin}) {
  const port = await freePort(), origin = `http://127.0.0.1:${port}`
  const env = {...process.env, HOME:path.join(work,'home')}
  delete env.HYPERDOC_FEDWIKI_INSPECTOR_ORIGIN
  if (parentOrigin) env.HYPERDOC_FEDWIKI_INSPECTOR_ORIGIN = parentOrigin
  const child = spawn(process.execPath,[path.join(here,'server.mjs'),site,String(port),String(legacy)],
    {cwd:work,env,stdio:['ignore','pipe','pipe']})
  let log = ''; child.stdout.on('data',d=>{log+=d}); child.stderr.on('data',d=>{log+=d})
  const began = Date.now()
  while (Date.now()-began < 60000) {
    if (child.exitCode !== null) throw Error('server.mjs exited: '+log)
    try { if ((await fetch(origin,{signal:AbortSignal.timeout(1000)})).ok) break } catch {}
    await new Promise(r=>setTimeout(r,200))
  }
  const options = log.split('\n').find(l=>l.startsWith('{"db":'))
  assert.ok(options, 'server.mjs did not report its options: '+log)
  return {origin, child, options:JSON.parse(options),
          stop: async () => { child.kill('SIGTERM'); if (child.exitCode===null) await new Promise(r=>child.once('exit',r)) }}
}

const put = (origin, page, action) => fetch(`${origin}/page/${page}/action`,{method:'PUT',
  headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({action:JSON.stringify(action)})})
const sha = site => createHash('sha256').update(fs.readFileSync(path.join(site,'pages',slug))).digest('hex')
const frame = (origin, query, init) => fetch(`${origin}/view/${slug}?${query}`, init)

test('without security_legacy the original security refuses every write and the frame adapter', async () => {
  const {work, site} = freshSite(), before = snapshot(site)
  const server = await start({site, work, legacy:false, parentOrigin:'http://127.0.0.1:41234'})
  try {
    assert.equal(server.options.db, path.join(site,'pages'))
    assert.equal(server.options.security_legacy, false)
    assert.equal((await put(server.origin, slug, {type:'edit',id:codeId,item:{...code,text:'must not persist'},date:Date.now()})).status, 403)
    assert.equal((await put(server.origin, 'another-page', {type:'create',item:{title:'Another Page',story:[]},date:Date.now()})).status, 403)
    const refused = await frame(server.origin, `hyperdocCodeItem=${codeId}&revision=${sha(site)}`)
    assert.equal(refused.status, 409)
    assert.match(await refused.text(), /Not an authorized isolated Code target/)
    assert.deepEqual(snapshot(site), before)
  } finally { await server.stop() }
})

test('the frame adapter serves the one Code item to the exact loopback parent, and refuses everything else', async () => {
  const {work, site} = freshSite(), before = snapshot(site)
  const parent = 'http://127.0.0.1:41234'
  const server = await start({site, work, legacy:true, parentOrigin:parent})
  try {
    const revision = sha(site)
    const served = await frame(server.origin, `hyperdocCodeItem=${codeId}&revision=${revision}`)
    assert.equal(served.status, 200)
    assert.equal(served.headers.get('content-security-policy'), `frame-ancestors ${parent}`)
    assert.equal(served.headers.get('access-control-allow-origin'), null)
    const body = await served.text()
    const config = JSON.parse(body.match(/<script id="hyperdoc-code-target" type="application\/json">(.*?)<\/script>/)[1])
    // Coordinates only: no editable copy of the item's text or language travels with the frame.
    assert.deepEqual(config, {site:'fedwiki:original-editor-test.invalid', slug, id:codeId})
    assert.ok(!body.includes(code.text))
    assert.ok(body.includes('<script src="/hyperdoc/code-editor.js" defer></script>'))
    // The original client bundle is served unchanged next to it.
    const client = await fetch(`${server.origin}/client.js`)
    assert.equal(Buffer.compare(Buffer.from(await client.arrayBuffer()),
      fs.readFileSync(path.join(here,'node_modules','wiki-client','client','client.js'))), 0)
    for (const [query, init] of [
      [`hyperdocCodeItem=${codeId}&revision=stale`],                    // stale observation
      [`hyperdocCodeItem=${paragraphId}&revision=${revision}`],         // another item
      [`hyperdocCodeItem=${codeId}`],                                    // no revision
      [`hyperdocCodeItem=${codeId}&revision=${revision}`, {method:'POST'}], // not a GET
    ]) {
      const response = await frame(server.origin, query, init)
      assert.equal(response.status, 409, query+' '+(init?.method||'GET'))
    }
    const other = await fetch(`${server.origin}/view/welcome-visitors?hyperdocCodeItem=${codeId}&revision=${revision}`)
    assert.equal(other.status, 409)
    assert.deepEqual(snapshot(site), before)
  } finally { await server.stop() }
})

test('the frame adapter serves the Paragraph Item of the same page by its id, and no other pairing', async () => {
  const {work, site} = freshSite(), before = snapshot(site)
  const server = await start({site, work, legacy:true, parentOrigin:'http://127.0.0.1:41234'})
  try {
    const revision = sha(site)
    const view = (query, page=slug) => fetch(`${server.origin}/view/${page}?${query}`)
    const served = await view(`hyperdocItem=${paragraphId}&revision=${revision}`)
    assert.equal(served.status, 200)
    const config = JSON.parse((await served.text()).match(/<script id="hyperdoc-code-target" type="application\/json">(.*?)<\/script>/)[1])
    assert.deepEqual(config, {site:'fedwiki:original-editor-test.invalid', slug, id:paragraphId})
    assert.equal((await view(`hyperdocItem=${codeId}&revision=${revision}`)).status, 200) // the generic parameter serves Code too
    for (const query of [`hyperdocItem=${paragraphId}&revision=stale`,
                         `hyperdocItem=${paragraphId}`,                             // no revision
                         `hyperdocItem=9999999999999999&revision=${revision}`,      // not an Item of the page
                         `hyperdocCodeItem=${paragraphId}&revision=${revision}`]) { // the legacy parameter is Code only
      assert.equal((await view(query)).status, 409, query)
    }
    assert.equal((await view(`hyperdocItem=${paragraphId}&revision=${revision}`, 'welcome-visitors')).status, 409)
    assert.equal((await fetch(`${server.origin}/view/${slug}?hyperdocItem=${paragraphId}&revision=${revision}`, {method:'POST'})).status, 409)
    assert.deepEqual(snapshot(site), before)
  } finally { await server.stop() }
})

test('the frame adapter refuses a parent that is not a loopback origin', async () => {
  const {work, site} = freshSite()
  for (const parentOrigin of ['https://dreyeck.ch', 'http://localhost:41234', undefined]) {
    const server = await start({site, work, legacy:true, parentOrigin})
    try {
      const response = await frame(server.origin, `hyperdocCodeItem=${codeId}&revision=${sha(site)}`)
      assert.equal(response.status, 409, String(parentOrigin))
    } finally { await server.stop() }
  }
})

// Why security_legacy=true is confined to the disposable loopback site: on an unclaimed site the original default
// security authorizes every visitor for every page, not only the one Code item the frame exposes.
test('security_legacy=true authorizes anyone for any page of an unclaimed site (the reason it stays loopback-only)', async () => {
  const {work, site} = freshSite()
  const server = await start({site, work, legacy:true})
  try {
    const created = await put(server.origin, 'another-page', {type:'create',item:{title:'Another Page',story:[]},date:Date.now()})
    assert.equal(created.status, 200)
    assert.ok(fs.existsSync(path.join(site,'pages','another-page')))
  } finally { await server.stop() }
})
