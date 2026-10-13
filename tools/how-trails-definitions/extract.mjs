// Bounded, parse-only extraction from one digest-identified HTML script.
import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import assert from 'node:assert/strict'
import {fileURLToPath} from 'node:url'
const here=path.dirname(fileURLToPath(import.meta.url))
export const root=path.resolve(here,'../..')
export const sourcePath=path.join(root,'assets/hyperbook/fedwiki/mech-host/plugins/solo/dialog/index.html')
export const outputPath=path.join(root,'dreyeck/work/how-trails-definitions.json')
export const identity=Object.freeze({repository:'https://github.com/WardCunningham/wiki-plugin-solo',oid:'17915844349bada64c901bd5ea73472702c446f9',path:'client/dialog/index.html',sha256:'5a513f70546ced3e2af7f83c4f14fb73d30e27f22a295558cbff4b078871aed8'})
export const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex')
const lock=JSON.parse(fs.readFileSync(path.join(here,'vendor/acorn-lock.json')))
for(const [name,digest] of Object.entries(lock.files))
 assert.equal(sha(fs.readFileSync(path.join(here,'vendor/acorn-8.16.0',name))),digest,'Parser dependency integrity')
const acorn=await import('./vendor/acorn-8.16.0/acorn.mjs')
assert.equal(acorn.version,lock.version)
export function extract(bytes, provenance=identity) {
 assert.deepEqual(provenance,identity,'Wrong source identity')
 assert.equal(sha(bytes),identity.sha256,'Solo source digest mismatch')
 const html=bytes.toString('utf8'), lines=html.split('\n')
 // This boundary is explicit and protected by the full-file digest, not an HTML parser.
 assert.equal(lines[31],'<script type="module">'); assert.equal(lines[583],'</script>')
 const start=lines.slice(0,32).join('\n').length+1
 const end=lines.slice(0,583).join('\n').length+1
 const script=html.slice(start,end)
 const ast=acorn.parse(script,{ecmaVersion:2022,sourceType:'module',locations:true})
 const scriptIdentity={ordinal:4,ordinalBase:0,type:'module',startUtf16:start,endUtf16:end,startByte:Buffer.byteLength(html.slice(0,start)),endByte:Buffer.byteLength(html.slice(0,end)),sha256:sha(script)}
 const definitions=[]
 function walk(node,scope=[]) {
  if(!node||typeof node!=='object')return
  if(node.type==='FunctionDeclaration') {
   const name=node.id.name, chain=[...scope,name]
   if(['composite','composite/merge','composite/merge/mergeprops'].includes(chain.join('/'))) {
    const fileStart=start+node.start,fileEnd=start+node.end
    definitions.push({key:chain.join('/'),name,nodeType:node.type,scope:scope.length?scope.join('/'):'module',parent:scope.length?scope.join('/'):null,
     astStart:node.start,astEnd:node.end,offsetUnit:'UTF-16 code units; end exclusive',
     fileStartUtf16:fileStart,fileEndUtf16:fileEnd,fileStartByte:Buffer.byteLength(html.slice(0,fileStart)),fileEndByte:Buffer.byteLength(html.slice(0,fileEnd)),
     startLine:node.loc.start.line+32,startColumn:node.loc.start.column,endLine:node.loc.end.line+32,endColumn:node.loc.end.column,
     text:script.slice(node.start,node.end)})
   }
   scope=chain
  }
  for(const [k,v] of Object.entries(node)) {
   if(k==='loc')continue
   if(Array.isArray(v))v.forEach(child=>walk(child,scope))
   else if(v&&typeof v==='object')walk(v,scope)
  }
 }
 walk(ast)
 assert.deepEqual(definitions.map(d=>[d.key,d.startLine,d.endLine]),[['composite',318,378],['composite/merge',328,377],['composite/merge/mergeprops',330,349]])
 return {schema:1,source:identity,parser:{name:'acorn',version:acorn.version,sha256:lock.files['acorn.mjs'],ecmaVersion:2022,sourceType:'module'},script:scriptIdentity,definitions}
}
export const serialize=record=>JSON.stringify(record,null,2)+'\n'
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
 const result=serialize(extract(fs.readFileSync(sourcePath)))
 if(process.argv[2]==='--check')assert.equal(fs.readFileSync(outputPath,'utf8'),result,'Definitions differ: regenerate and review')
 else {assert.equal(process.argv.length,2,'Use no argument to regenerate or --check');fs.writeFileSync(outputPath,result)}
 console.log('PASS: deterministic parse-only definitions; source and parser digests verified')
}
