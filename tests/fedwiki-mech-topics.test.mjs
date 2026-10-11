import test from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import {api, run} from '../assets/hyperbook/fedwiki/mech-host/plugins/mech/blocks.js'
import {tree} from '../assets/hyperbook/fedwiki/mech-host/plugins/mech/interpreter.js'
import {createNeighborhood} from '../assets/hyperbook/fedwiki/mech-host/neighborhood.js'
import {ward, topicsRegion, provenance, originalPage, originalSitemap, snapshot, page, seededRandom, graphContent} from './fedwiki-mech-topics-reference.mjs'

async function execute(commands, input = snapshot(), seed = 1) {
  const old = {wiki: globalThis.wiki, fetch: globalThis.fetch, now: Date.now, random: Math.random}
  const state = {}, elements = {}, statuses = [], published = []
  globalThis.wiki = {neighborhoodObject: createNeighborhood(input, page).neighborhoodObject}
  globalThis.fetch = () => { throw Error('No network is permitted in the trusted topics witness') }
  state.api = {...api, element: key => elements[key] ??= {id:key}, inspect() {},
    status(elem, command, text) { statuses.push(command + text) },
    trouble(elem, message) { throw Error(message) }, publishSourceData(elem, topic, value) { published.push({topic,value}) }}
  const nest = tree(commands, [], 0); nest.forEach((c,i) => c.key = 'topics-' + i)
  try {
    Date.now = () => provenance.clock; Math.random = seededRandom(seed)
    await run(nest, state, 'click')
    return {state, statuses, published}
  } finally { globalThis.wiki = old.wiki; globalThis.fetch = old.fetch; Date.now = old.now; Math.random = old.random }
}
function reference(input, seed) {
  const now = Date.now, random = Math.random
  try { Date.now = () => provenance.clock; Math.random = seededRandom(seed); return ward.walks('15', 'topics', structuredClone(input)) }
  finally { Date.now = now; Math.random = random }
}

test('original topics body and Pattern Machinery command/identity are preserved', () => {
  const current = fs.readFileSync(new URL('../assets/hyperbook/fedwiki/mech-host/plugins/mech/library.js', import.meta.url), 'utf8')
  assert(current.includes(topicsRegion))
  const item = originalPage.story.find(i => i.id === '3a62aa636c883134')
  assert.equal(item.type, 'mech'); assert(item.text.includes(' WALK 15 topics\n'))
  const nest = tree(item.text.split('\n'), [], 0)
  assert.equal(nest[1].find(c => c.command === 'WALK 15 topics').command, 'WALK 15 topics')
  assert.equal(originalSitemap.length, 45)
})

test('actual dispatcher matches direct original Ward topics on identical retained sitemap input and multiple random orders', async () => {
  let content
  const nodeOrders = new Set()
  for (const seed of [1, 2, 3, 13, 100, 999]) {
    const {state, statuses, published} = await execute(['NEIGHBORS', 'WALK 15 topics'], snapshot(), seed)
    assert.match(statuses[0], /45 pages, 1 sites/)
    assert.match(statuses[1], /WALK 15 topics ⇒ [1-9]\d* aspects/)
    const actual = state.aspect[0].result, expected = reference(state.neighborhood, seed)
    assert.deepEqual(graphContent(actual), graphContent(expected))
    assert.equal(published[0].topic, 'aspect')
    assert.deepEqual(graphContent(published[0].value), graphContent(expected))
    const graphs = graphContent(actual, false)
    if (content) assert.deepEqual(graphs, content); else content = graphs
    nodeOrders.add(JSON.stringify(actual.map(a => a.graph.nodes.map(n => n.props.name))))
    assert.deepEqual(inputSitemaps(state.neighborhood), inputSitemaps(originalSitemap))
  }
  assert(nodeOrders.size > 1, 'Witness must exercise actual randomized node enumeration')
})
function inputSitemaps(entries) { return entries.map(({domain, ...rest}) => rest).sort((a,b) => a.slug.localeCompare(b.slug)) }

test('missing, loading and failed sources remain failures; a retained empty sitemap remains genuinely empty', async () => {
  for (const mode of ['missing', 'loading', 'failed']) {
    await assert.rejects(execute(['NEIGHBORS', 'WALK 15 topics'], snapshot(mode)), new RegExp(mode + '.*NEIGHBORS cannot run'))
  }
  const empty = await execute(['NEIGHBORS', 'WALK 15 topics'], snapshot('empty'))
  assert.match(empty.statuses[0], /0 pages, 1 sites/)
  assert.match(empty.statuses[1], /0 aspects, 0 nodes/)
  assert.equal(empty.state.aspect, undefined)
})

test('POPUP requires its explicit Wiki dialog contract; data execution supplies no implicit adapter', async () => {
  await assert.rejects(execute(['POPUP state']), /wiki.dialog is not a function/)
})
