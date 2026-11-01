import test from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import {browserCandidates, detectBrowser, checkNode} from './commands.mjs'

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
