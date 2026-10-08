// Execute retained functions only on disposable inputs. No Wiki, DOM, fetch or layout.
import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import vm from 'node:vm'
import assert from 'node:assert/strict'
const root = process.argv[2]
const manifest = JSON.parse(fs.readFileSync(path.join(root,'dreyeck/work/trails-rendered-following-provenance.json')))
function verified(record) {
  const bytes = fs.readFileSync(path.join(root,record.file))
  assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),record.sha256)
  return bytes.toString('utf8')
}
const page = JSON.parse(verified(manifest.source))
const solo = verified(manifest.files['solo-source'])
const code = id => page.story.find(item => item.id === id).text
const api = vm.runInNewContext(solo+'\n'+code(manifest.source.trailsCode).replace(/^export /,'')+'\n'+code(manifest.source.builderCode)+'\n({trails,composite})',{})
const clone = value => JSON.parse(JSON.stringify(value))
const state = {context:{page:clone(page),itemId:'controlled-witness-item'}}
const status = api.trails.call(state)
const aspects = clone(state.aspect[0].result)
const batch = JSON.parse(fs.readFileSync(path.join(root,'dreyeck/work/trails-rendered-solo-batch.json')))
const beam = JSON.parse(fs.readFileSync(path.join(root,'dreyeck/work/trails-rendered-solo-beam.json')))
assert.deepEqual(aspects,batch.sources[0].aspects)
const input = clone(beam)
const complex = api.composite(input)
const nodeMap = input.flatMap((aspect,aspectIndex) => aspect.graph.nodes.map((node,nodeIndex) => {
  const outputIndex = complex.graph.nodes.findIndex(each => each.type===node.type && each.props.name===node.props.name)
  const output = complex.graph.nodes[outputIndex]
  return {aspectIndex,nodeIndex,outputIndex,sameNodeObject:node===output,samePropsObject:node.props===output.props}
}))
const summary = graph => ({nodes:graph.nodes.map(n=>({type:n.type,name:n.props.name})),rels:graph.rels.map(r=>({type:r.type,from:r.from,to:r.to}))})
const recorded = JSON.parse(verified(manifest.files.render))
assert.deepEqual(clone(summary(complex.graph)),recorded.render.graph)
function control(field,value) {
  const trial = clone(beam)
  const node = trial[1].graph.nodes[2]
  if(field==='name') node.props.name=value
  else node.type=value
  const output = api.composite(trial)
  assert.equal(output.graph.nodes.length,6)
  assert.equal(output.graph.rels.length,4)
  assert.notEqual(output.graph.rels[1].to,output.graph.rels[3].to)
  return {field,value,nodeCount:output.graph.nodes.length,relationCount:output.graph.rels.length,output:clone(output.graph)}
}
console.log(JSON.stringify({
  status:'executed-controlled-witness',
  graphDependency:'Retained Solo embedded Graph; the original unpinned graph.js import is not replayed.',
  originAssignments:'Positional/value derivation only; original paragraph IDs are not preserved in the emitted graphs or batch.',
  sourceParagraphs:page.story.filter(item=>item.type==='paragraph' && item.text.startsWith('[[')),
  trailsStatus:status,aspects,sourceAspect:clone(state.aspect),
  sourceItemsShareResult:state.items[0].aspects===state.aspect[0].result,
  matchesCapturedBatch:true, input:beam,output:clone(complex.graph),nodeMap,
  inputReflectiveNodesIdentical:input[0].graph.nodes[2]===input[1].graph.nodes[2],
  outputReflectiveTargetShared:complex.graph.rels[1].to===complex.graph.rels[3].to,
  matchesRecordedRenderFields:true,
  controls:[control('name','Reflective\nPractice (control)'),control('type','control-type')],
  limitations:manifest.limits
},null,2))
