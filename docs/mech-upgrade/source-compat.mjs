// Compare an isolated candidate checkout to the exact deployed base using Acorn.
// Requires the candidate development dependencies and the named historical Git objects.
import {createRequire} from 'node:module'; import path from 'node:path'; import fs from 'node:fs'; import cp from 'node:child_process'; import crypto from 'node:crypto';
const repo=path.resolve(process.argv[2] || '.'); const require=createRequire(path.join(repo,'package.json'));const {parse}=require('acorn');
const base='abd88d2da6c89029515f2a456356832dffe038ab';
const old=cp.execFileSync('git',['-C',repo,'show',base+':src/client/blocks.js'],{encoding:'utf8'});
const candidate=fs.readFileSync(repo+'/src/client/blocks.js','utf8');
const modern=cp.execFileSync('git',['-C',repo,'show','6782e4d5202888ff8ae42d1fc10343ee3cf457ae:src/client/blocks.js'],{encoding:'utf8'});
function inspect(text){const ast=parse(text,{ecmaVersion:'latest',sourceType:'module'});const funcs={},catalog={},imports=[];for(const top of ast.body){const n=top.declaration||top;if(n.type==='FunctionDeclaration')funcs[n.id.name]=text.slice(n.start,n.end);if(n.type==='VariableDeclaration')for(const d of n.declarations)if(d.id.name==='blocks'||d.id.name==='api')catalog[d.id.name]=d.init.properties.map(p=>p.key.name);if(n.type==='ImportDeclaration')imports.push(n.source.value);}return {funcs,catalog,imports};}
const a=inspect(old),b=inspect(candidate),c=inspect(modern);
const changed=Object.keys(a.funcs).filter(k=>a.funcs[k]!==b.funcs[k]),added=Object.keys(b.funcs).filter(k=>!(k in a.funcs));
if(JSON.stringify(changed.sort())!==JSON.stringify(['click_emit','run','tick_emit']))throw Error('Unexpected existing function change: '+changed);
for(const f of ['listen_emit','message_emit','solo_emit','report_emit','extract_emit','edges_emit'])if(a.funcs[f]!==b.funcs[f])throw Error('Changed compatibility function '+f);
const sourceFiles=['src/client/mech.js','src/client/interpreter.js','src/client/library.js','server/server.js','scripts/build-client.js','scripts/write-build-info.cjs'];
for(const file of sourceFiles)if(!cp.execFileSync('git',['-C',repo,'show',base+':'+file]).equals(fs.readFileSync(repo+'/'+file)))throw Error('Changed '+file);
if(JSON.stringify(a.imports)!==JSON.stringify(b.imports))throw Error('New static dependency');
const digest=s=>crypto.createHash('sha256').update(s).digest('hex');
console.log(JSON.stringify({base,candidateSourceSha256:digest(candidate),existingFunctions:Object.keys(a.funcs).length,
  changedFunctions:changed,addedFunctions:added,unchangedFunctions:Object.keys(a.funcs).filter(k=>a.funcs[k]===b.funcs[k]),
  candidateAddedBlocks:b.catalog.blocks.filter(k=>!a.catalog.blocks.includes(k)),candidateRemovedBlocks:a.catalog.blocks.filter(k=>!b.catalog.blocks.includes(k)),
  candidateAddedApi:b.catalog.api.filter(k=>!a.catalog.api.includes(k)),unchangedSourceFiles:sourceFiles,
  staticImports:{base:a.imports,candidate:b.imports,upstreamGuarded:c.imports},
  wholesaleUpgrade:{removedForkBlocks:a.catalog.blocks.filter(k=>!c.catalog.blocks.includes(k)),addedBlocks:c.catalog.blocks.filter(k=>!a.catalog.blocks.includes(k))}},null,2));
