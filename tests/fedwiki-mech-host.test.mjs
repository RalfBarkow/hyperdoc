import test from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import {createMechHost, root} from '../scripts/serve-fedwiki-mech-host.mjs'
const digest = b => crypto.createHash('sha256').update(b).digest('hex')
test('shipped plugin sources match bounded source identities and existing upgrade evidence', () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(root, 'provenance.json')))
  for (const asset of manifest.assets) assert.equal(digest(fs.readFileSync(path.join(root, asset.path))), asset.sha256, asset.path)
  const existing = JSON.parse(fs.readFileSync(new URL('../docs/mech-upgrade/evidence/assets.json', import.meta.url)))
  // Existing assets evidence records raw source hashes separately from stamps.
  const assets = existing.assets || existing
  for (const name of ['mech.js', 'blocks.js', 'interpreter.js', 'library.js']) {
    const asset = manifest.assets.find(a => a.path === 'plugins/mech/' + name)
    assert.equal(asset.source.oid, '0fc36fcd58a8d7c399d3e86d2ee2e9328cafba44')
    const prior = assets.find(a => a.name === name)
    assert.equal(asset.sha256, prior.sourceSha256)
  }
  assert.equal(manifest.assets.find(a => a.path.endsWith('dialog/index.html')).sha256, '5a513f70546ced3e2af7f83c4f14fb73d30e27f22a295558cbff4b078871aed8')
  assert.equal(JSON.parse(fs.readFileSync(path.join(root, 'plugins/solo/package.json'))).version, '0.1.30-1')
})
test('isolated static host has no Lisp, publication, write or traversal endpoint', async () => {
  const host = createMechHost(); await new Promise(r => host.listen(0, '127.0.0.1', r))
  const origin = `http://127.0.0.1:${host.address().port}`
  try {
    const response = await fetch(origin)
    assert.equal(response.status, 200)
    assert(response.headers.get('content-security-policy').includes("connect-src 'self' https://wardcunningham.github.io https://unpkg.com;"))
    for (const pathname of ['/clog', '/../../hyperbook.asd', '/%2e%2e/hyperbook.asd']) assert.equal((await fetch(origin + pathname)).status, 404)
    for (const method of ['POST', 'PUT', 'DELETE']) assert.equal((await fetch(origin, {method})).status, 405)
    assert.equal((await fetch(origin + '/plugins/solo/dialog/')).status, 200)
  } finally { await new Promise(r => host.close(r)) }
})
