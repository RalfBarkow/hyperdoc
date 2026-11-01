import test from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import {browserCandidates, detectBrowser, checkNode, demoFaslCache, catalogStartupTimeoutMs} from './commands.mjs'

test('Darwin detects system and per-user app executables; explicit selection is exclusive',()=>{
  const candidates = browserCandidates('darwin',{},'/Users/test')
  assert(candidates.includes('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'))
  assert(candidates.includes('/Users/test/Applications/Chromium.app/Contents/MacOS/Chromium'))
  assert.deepEqual(browserCandidates('darwin',{HYPERDOC_FEDWIKI_BROWSER:'/chosen/browser'},'/Users/test'),['/chosen/browser'])
})

test('browser executable paths with spaces are probed without shell expansion; invalid override fails',()=>{
  const work = fs.mkdtempSync(path.join(os.tmpdir(),'wiki-browser-probe-'))
  try {
    const executable = path.join(work,'Fake Chrome for version probe')
    fs.writeFileSync(executable,'#!/bin/sh\n[ "$1" = "--version" ] || exit 1\necho "Google Chrome 150.0.0.0"\n',{mode:0o755})
    assert.deepEqual(detectBrowser({HYPERDOC_FEDWIKI_BROWSER:executable}),{executable,version:'Google Chrome 150.0.0.0'})
    assert.throws(()=>detectBrowser({HYPERDOC_FEDWIKI_BROWSER:path.join(work,'missing')}),/No verified Chrome/)
  } finally {fs.rmSync(work,{recursive:true})}
})

test('Node 20 is refused before the ESM dependency tree loads',()=>{
  assert.throws(()=>checkNode('20.18.1'),/Node 24 is required/)
  assert.doesNotThrow(()=>checkNode('24.22.1'))
})


test('Catalog startup deadline is bounded, configurable and longer than cold compile',()=>{
  assert.equal(catalogStartupTimeoutMs({}),900000)
  assert.equal(catalogStartupTimeoutMs({HYPERDOC_FEDWIKI_CATALOG_START_TIMEOUT_SECONDS:'120'}),120000)
  assert.throws(()=>catalogStartupTimeoutMs({HYPERDOC_FEDWIKI_CATALOG_START_TIMEOUT_SECONDS:'0'}),/30..3600/)
  assert.throws(()=>catalogStartupTimeoutMs({HYPERDOC_FEDWIKI_CATALOG_START_TIMEOUT_SECONDS:'99999'}),/30..3600/)
})

test('Interactive demo FASLs remain in an independent reusable, runtime-scoped cache',()=>{
  const work = fs.mkdtempSync(path.join(os.tmpdir(),'wiki-fasl-cache-test-'))
  try {
    const env = {HYPERDOC_FEDWIKI_FASL_CACHE_ROOT:work,CL_SOURCE_REGISTRY:'/nix/store/example//'}
    const a = demoFaslCache('/nix/store/sbcl-a/bin/sbcl',env,work,'darwin')
    const b = demoFaslCache('/nix/store/sbcl-a/bin/sbcl',env,work,'darwin')
    const c = demoFaslCache('/nix/store/sbcl-b/bin/sbcl',env,work,'darwin')
    assert.equal(a,b)
    assert.notEqual(a,c)
    assert(a.startsWith(work+path.sep))
    assert(fs.statSync(a).isDirectory())
  } finally {fs.rmSync(work,{recursive:true,force:true})}
})
