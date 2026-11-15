// node scripts/test-solo-trail-layout.mjs SOLO_DIALOG OUTPUT_JSON [VIZ_MODULE]
import assert from 'node:assert/strict'
import {createHash} from 'node:crypto'
import {execFileSync, spawnSync} from 'node:child_process'
import {readFileSync, writeFileSync} from 'node:fs'
import {resolve} from 'node:path'
import {pathToFileURL} from 'node:url'
import {runInNewContext} from 'node:vm'

const [dialog, output, vizModule] = process.argv.slice(2)
if (!output) throw Error('SOLO_DIALOG and OUTPUT_JSON required, with optional VIZ_MODULE')
const revision = '6efee09afbe9bf631fd52ba74394a4b17e71f751'
const sourceURL = `https://github.com/WardCunningham/wiki-plugin-solo/blob/${revision}/client/dialog/index.html`
const pagePath = 'dreyeck/work/hubs-evidence/ward.voices.ustawi.wiki--dewey-alexander-trail.json'
const hash = text => createHash('sha256').update(text).digest('hex')
const source = readFileSync(dialog, 'utf8')
const page = readFileSync(new URL('../' + pagePath, import.meta.url), 'utf8')
assert.equal(hash(source), 'cdeaa4f5143b98eb51b98d0d63bbf3dc6da0023c08f42f5a32662940b5a165b3')
assert.equal(hash(page), '739ea473cd67f800ee748ab25107d48d53d3cb57cb2224da7ba8cdd7df7289bf')

const region = source.slice(source.indexOf('const uniq ='), source.indexOf('// embolden lines'))
const {composite, dotify} = runInNewContext(region + '\n({composite,dotify})', {
  window: {}, console: {log() {}}
})
const aspects = JSON.parse(page).story.find(item => item.type === 'solo').aspects
const trailIndex = aspects.findIndex(aspect => aspect.name === 'New Trail')
assert.equal(trailIndex, 2)
const hubs = aspects.slice(0, trailIndex)
const base = composite(structuredClone(hubs))
const withTrail = composite(structuredClone(aspects))
assert.deepEqual(Array.from(withTrail.merged.nids), [3, 6, 10, 14])

function replaceOnce(text, original, replacement) {
  assert.equal(text.split(original).length, 2, original)
  return text.replace(original, replacement)
}

// Trial change A puts the merged-node style on the regular node declarations.
// Type emphasis and explicit node colors keep their existing precedence.
const nodeStyle = replaceOnce(region,
  '  const nodes = graph.nodes.map((node,id) => {',
  '  const mergedIds = new Set(merged.nids)\n  const nodes = graph.nodes.map((node,id) => {')
const inlineStyle = replaceOnce(nodeStyle,
  'const color = emphasis[node.type] || (node.props.color ? `fillcolor="${node.props.color}"` : \'\')',
  'const color = emphasis[node.type] || (node.props.color ? `fillcolor="${node.props.color}"` : mergedIds.has(id) ? \'fillcolor=gold\' : \'\')\n    const weight = mergedIds.has(id) ? \'penwidth=2\' : \'\'')
const styledNodes = replaceOnce(inlineStyle, '[label="${label}" ${color}', '[label="${label}" ${weight} ${color}')
const candidateA = replaceOnce(styledNodes,
  "    'node [shape=box style=filled fillcolor=gold penwidth=2]',\n    ...merged.nids,\n    'node [fillcolor=palegreen penwidth=1]',",
  "    'node [shape=box style=filled fillcolor=palegreen penwidth=1]',")

// Trial change B uses the same relation set for emission and reverse lookup.
const filtered = replaceOnce(candidateA,
  "  const edges = graph.rels.map(rel => {\n    if(rel.type == 'Trail') return null",
  "  const layoutRels = graph.rels.filter(rel => rel.type !== 'Trail')\n  const edges = layoutRels.map(rel => {")
const candidateB = replaceOnce(filtered, 'if (graph.rels.find(rev', 'if (layoutRels.find(rev')
const candidateDotify = text => runInNewContext(text + '\ndotify', {window: {}, console: {log() {}}})
const renderA = candidateDotify(candidateA)
const renderB = candidateDotify(candidateB)
const nodeStatements = dot => [...dot.matchAll(/^(\d+) \[label=/gm)].map(match => match[1])
const edgeStatements = dot => dot.split('\n').filter(line => /^\d+->/.test(line))
const baseline = dotify(base)
const selected = dotify(withTrail)
assert.deepEqual(nodeStatements(baseline), nodeStatements(selected))
assert.deepEqual(edgeStatements(baseline), edgeStatements(selected))
assert.equal(nodeStatements(selected).length, 15)
assert.equal(edgeStatements(selected).length, 14)

// Hold the highlight and its width constant, changing only first declaration.
const inline = renderA(withTrail)
assert.deepEqual(nodeStatements(inline), nodeStatements(baseline))
for (const id of [3, 6, 10, 14]) {
  assert.match(inline, new RegExp('^' + id + ' \\[label="[\\s\\S]*?" penwidth=2 fillcolor=gold ', 'm'))
}
const early = selected.replace(
  /\n((?:\d+\n)+)(?=node \[fillcolor=palegreen)/,
  (_, ids) => '\n' + ids.trim().split('\n').map(id => id + ' [fillcolor=gold penwidth=1]').join('\n') + '\n')
const sameWidth = inline.replaceAll('penwidth=2', 'penwidth=1')
assert.notEqual(early, selected)
assert.deepEqual(edgeStatements(inline), edgeStatements(selected))

const reverseOf = base.graph.rels.find(edge => !base.graph.rels.some(
  other => other.from === edge.to && other.to === edge.from))
const reverse = {
  name: 'Synthetic reverse Trail',
  graph: {
    nodes: [reverseOf.to, reverseOf.from].map(id => structuredClone(base.graph.nodes[id])),
    rels: [{from: 0, to: 1, type: 'Trail', props: {}}]
  }
}
const withReverse = composite([...structuredClone(hubs), reverse])
const edgePrefix = `${reverseOf.from}->${reverseOf.to} `
const reverseStatement = dot => edgeStatements(dot).find(line => line.startsWith(edgePrefix))
const reverseControl = {
  baseline: reverseStatement(baseline),
  original: reverseStatement(dotify(withReverse)),
  candidate: reverseStatement(renderB(withReverse))
}
assert.match(reverseControl.original, /dir=both/)
assert.equal(reverseControl.baseline, reverseControl.candidate)
assert.deepEqual(edgeStatements(baseline), edgeStatements(renderB(withReverse)))

const variants = {baseline, selected, inline, early, sameWidth}
const render = vizModule
  ? await import(pathToFileURL(resolve(vizModule))).then(async ({instance}) => {
      const viz = await instance()
      return {engine: 'Graphviz WASM ' + viz.graphvizVersion, plain: dot => viz.renderString(dot, {engine: 'dot', format: 'plain'})}
    })
  : {
      engine: spawnSync('dot', ['-V'], {encoding: 'utf8'}).stderr.trim(),
      plain: dot => execFileSync('dot', ['-Tplain'], {input: dot, encoding: 'utf8'})
    }
const layouts = Object.fromEntries(Object.entries(variants).map(([key, dot]) => {
  const plain = render.plain(dot)
  const positions = Object.fromEntries(plain.split('\n').filter(line => line.startsWith('node ')).map(line => {
    const [, id, x, y] = line.split(' ')
    return [id, [Number(x), Number(y)]]
  }))
  assert.equal(Object.keys(positions).length, 15)
  return [key, {dot, plain, positions}]
}))
function moved(left, right) {
  return Object.keys(layouts[left].positions).filter(id =>
    layouts[left].positions[id].some((coordinate, index) => coordinate !== layouts[right].positions[id][index]))
}
const comparisons = {
  selectTrail: moved('baseline', 'selected'),
  candidateWithTrail: moved('baseline', 'inline'),
  sameWidthControl: moved('sameWidth', 'early')
}
assert.equal(comparisons.selectTrail.length, 15)
assert.equal(comparisons.candidateWithTrail.length, 0)
assert.equal(comparisons.sameWidthControl.length, 15)
writeFileSync(output, JSON.stringify({
  sourceURL, soloSHA256: hash(source), pagePath, pageSHA256: hash(page),
  engine: render.engine, nodeCount: 15, edgeCount: 14, earlyNodeIDs: Array.from(withTrail.merged.nids),
  comparisons, reverseControl, layouts
}, null, 2) + '\n')
console.log(`${render.engine}: 15 moved in original, 0 with candidate, 15 in equal-width control, reverse-Trail control passed`)
