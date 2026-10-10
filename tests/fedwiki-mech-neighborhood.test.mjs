import test from 'node:test'
import assert from 'node:assert/strict'
import {createNeighborhood} from '../assets/hyperbook/fedwiki/mech-host/neighborhood.js'
import {api, run} from '../assets/hyperbook/fedwiki/mech-host/plugins/mech/blocks.js'
import {tree} from '../assets/hyperbook/fedwiki/mech-host/plugins/mech/interpreter.js'
import {fixture, page, snapshot, reference} from './fedwiki-mech-sitemap-fixture.mjs'

test('page-scoped original sitemap fields/order/source survive without mutating the snapshot', () => {
  const input = snapshot(), before = structuredClone(input)
  const cache = createNeighborhood(input, page)
  assert.deepEqual(Object.keys(cache.neighborhoodObject.sites), fixture.sites.map(s => s.domain))
  for (const record of input.sites) {
    const received = cache.neighborhoodObject.sites[record.domain]
    assert.deepEqual(received.sitemap, record.sitemap)
    assert.equal(received.sitemapRequestInflight, false)
    assert.equal(received.sourceUrl, record.sourceUrl)
    assert.notEqual(received.sitemap, record.sitemap)
  }
  cache.neighborhoodObject.sites[page.site].sitemap[0].title = 'Browser copy'
  assert.deepEqual(input, before)
})

test('missing/loading/failed context is explicit and cannot become a partial or empty neighborhood', () => {
  assert.throws(() => createNeighborhood(null, page).neighborhoodObject.sites, /snapshot missing/)
  for (const mode of ['missing', 'loading', 'failed']) {
    const cache = createNeighborhood(snapshot(mode), page)
    assert.match(cache.message, new RegExp(`context.fixture.test: ${mode}`))
    assert.throws(() => cache.neighborhoodObject.sites, /NEIGHBORS cannot run/)
  }
  const empty = createNeighborhood(snapshot('empty'), page)
  assert.deepEqual(Object.values(empty.neighborhoodObject.sites).map(s => s.sitemap), [[], []])
  assert.match(empty.message, /ready.*0 pages/)
})

test('malformed/provenance-mismatched snapshots are rejected instead of substituted', () => {
  for (const mutate of [s => s.version = 2, s => s.scope = 'global',
    s => s.page = {...s.page, slug: 'other-page'}, s => s.sites = [],
    s => s.sites.push(s.sites[0]), s => s.sites[0].sitemap = null,
    s => s.sites[0].sitemap = [null], s => s.sites[0].sourceUrl = null,
    s => s.sites[0].state = 'unknown', s => {s.sites[0].state = 'failed'},
    s => s.sites[0].domain = 'other.fixture.test']) {
    const s = snapshot(); mutate(s)
    assert.throws(() => createNeighborhood(s, page), /sitemap|origin/)
  }
})

test('unchanged NEIGHBORS feeds weeks/hubs the same data as a direct unchanged-revision execution', async () => {
  const oldWiki = globalThis.wiki, oldFetch = globalThis.fetch, oldNow = Date.now
  const input = snapshot(), state = {}, elements = {}, statuses = []
  globalThis.wiki = {neighborhoodObject: createNeighborhood(input, page).neighborhoodObject}
  globalThis.fetch = () => { throw Error('Network forbidden in trusted fixture') }
  state.api = {...api, element: key => elements[key] ??= {id: key}, inspect() {},
    status(elem, command, text) { statuses.push(command + text) },
    trouble(elem, message) { throw Error(message) }, publishSourceData() {}}
  const nest = tree(['NEIGHBORS', 'WALK 12 weeks', 'WALK 25 hubs'], [], 0)
  nest.forEach((command, i) => command.key = 'real-' + i)
  try {
    Date.now = () => fixture.clock
    await run(nest, state)
    assert.equal(state.neighborhood.length, 4)
    assert.match(statuses[0], /4 pages, 2 sites/)
    const expected = await reference(input.sites)
    assert.deepEqual(statuses, expected.statuses)
    assert.deepEqual(JSON.parse(JSON.stringify(state.aspect.flatMap(s => s.result))), expected.aspects)
    assert(expected.aspects.length > 0)
    assert.deepEqual(input, snapshot())
  } finally { globalThis.wiki = oldWiki; globalThis.fetch = oldFetch; Date.now = oldNow }
})
