import fs from 'node:fs'
import assert from 'node:assert/strict'
import os from 'node:os'
import path from 'node:path'
import {fileURLToPath} from 'node:url'
import {spawnSync} from 'node:child_process'
import {extract,serialize,identity,sourcePath,outputPath} from './extract.mjs'
const bytes=fs.readFileSync(sourcePath), before=fs.readFileSync(outputPath,'utf8')
const first=extract(bytes)
assert.equal(serialize(first),serialize(extract(bytes)))
assert.equal(serialize(first),before)
assert.throws(()=>extract(bytes,{...identity,path:'another.html'}),/Wrong source identity/)
assert.throws(()=>extract(bytes,{...identity,oid:'0'.repeat(40)}),/Wrong source identity/)
const changed=Buffer.from(bytes);changed[1500]^=1
assert.throws(()=>extract(changed),/Solo source digest mismatch/)
for(const def of first.definitions) {
 assert.equal(bytes.subarray(def.fileStartByte,def.fileEndByte).toString('utf8'),def.text)
 assert.equal(def.nodeType,'FunctionDeclaration')
 assert.equal(def.text.endsWith('}'),true)
}
assert.equal(fs.readFileSync(outputPath,'utf8'),before)
console.log('PASS: offline deterministic AST extraction, three full definitions, wrong file/revision/source rejected; retained output unchanged')

// Corrupt only a disposable parser copy; integrity must fail before import.
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'solo-parser-control-'))
try {
 const here=path.dirname(fileURLToPath(import.meta.url))
 fs.cpSync(here,temp,{recursive:true})
 fs.appendFileSync(path.join(temp,'vendor/acorn-8.16.0/acorn.mjs'),'\n// changed\n')
 const failed=spawnSync(process.execPath,[path.join(temp,'extract.mjs'),'--check'],{encoding:'utf8'})
 assert.notEqual(failed.status,0)
 assert.match(failed.stderr,/Parser dependency integrity/)
 console.log('PASS: altered offline parser rejected before loading it')
} finally {fs.rmSync(temp,{recursive:true,force:true})}
