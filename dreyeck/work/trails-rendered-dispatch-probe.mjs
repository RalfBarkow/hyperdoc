// Source-level reduction of the observed unsupported-CODE branch, not a plugin replacement.
// Usage: node trails-rendered-dispatch-probe.mjs [REPOSITORY_ROOT]
// Executes the retained failing run() and its actual catalog declaration.
// Other command handlers are throwing sentinels; none may be reached by CODE.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const root = process.argv[2] || process.cwd();
const file = 'dreyeck/work/trails-rendered-browser-evidence/hyperdoc.blocks.js';
const source = fs.readFileSync(path.join(root, file), 'utf8');
const sha256 = crypto.createHash('sha256').update(source).digest('hex');
assert.equal(sha256, '1b69037fda8c89a0c06f333e3b8a3bb11925b1371daf8c1dfda32835d757652b');
const runStart = source.indexOf('export async function run(nest, state) {');
const runEnd = source.indexOf('// B L O C K S', runStart);
const catalogStart = source.indexOf('export const blocks = {');
const catalogEnd = source.indexOf('\n}\n', catalogStart) + 2;
assert.ok(runStart >= 0 && runEnd > runStart && catalogStart >= 0 && catalogEnd > catalogStart);
const runSource = source.slice(runStart, runEnd).replace(/^export /, '');
const catalogSource = source.slice(catalogStart, catalogEnd).replace(/^export const blocks = /, '');
let handlerCalls = 0;
const bindings = {};
for (const match of catalogSource.matchAll(/emit:\s*([A-Za-z_][A-Za-z_0-9]*)/g)) {
  bindings[match[1]] = () => { handlerCalls++; throw new Error('Unexpected command handler invocation'); };
}
const blocks = vm.runInNewContext('(' + catalogSource + ')', bindings);
const keys = Object.keys(blocks);
assert.equal(keys.length, Object.keys(bindings).length);
const run = vm.runInNewContext(runSource + '\nrun', {blocks});
const producer = {command: 'CODE trails', key: 'controlled-code-block'};
const diagnostics = [];
await run([producer], {api: {
  element: key => ({id: key}),
  trouble: (element, message) => diagnostics.push({element: element.id, message})
}});
assert.equal(handlerCalls, 0);
assert.equal(diagnostics.length, 1);
assert.equal(diagnostics[0].message, "CODE doesn't name a block we know.");
console.log(JSON.stringify({
  kind: 'source-level-dispatch-reduction', source: {file, sha256}, producer,
  registry: {keys, hasCode: Object.hasOwn(blocks, 'CODE')}, diagnostics, handlerCalls,
  scope: 'Retained run and catalog declarations; fake element/trouble API and sentinel handlers. No browser, module import, trails(), Graph, Wiki navigation, Solo or retained-capture mutation.'
}, null, 2));
