// Two-page TRAVERSE example: runs an unchanged discourse-profile Mech bundle in Node and records
// every stage. Usage: node example-driver.mjs <client/mech.js>  > example-run.json
// No network: fetch throws; pages come from the fixture below. The clock is frozen.
import fs from 'node:fs'
import crypto from 'node:crypto'
import assert from 'node:assert/strict'
import { pathToFileURL } from 'node:url'

const bundle = process.argv[2]
const bundleSha256 = crypto.createHash('sha256').update(fs.readFileSync(bundle)).digest('hex')
const NOW = 1792540800000 // 2026-10-20T00:00:00Z, frozen
const site = 'companion.example'
const clone = x => JSON.parse(JSON.stringify(x))

// Fixture: two pages; the first has a Claims pagefold followed by exactly one Wiki link.
const pages = {
  question: {
    title: 'Question',
    story: [
      { type: 'pagefold', id: 'f000000000000001', text: 'Claims' },
      { type: 'paragraph', id: 'p000000000000002', text: '[[Claim A]]' },
      { type: 'pagefold', id: 'f000000000000003', text: 'Graph' },
      { type: 'mech', id: 'm000000000000004', text: 'NEIGHBORS\nEXTRACT\nTRAVERSE claim\nSOLO' },
    ],
    journal: [{ type: 'create', date: NOW - 2000 }],
  },
  'claim-a': {
    title: 'Claim A',
    story: [{ type: 'paragraph', id: 'p000000000000005', text: 'A statement offered as a claim.' }],
    journal: [{ type: 'create', date: NOW - 1000 }],
  },
}
// Sitemap entries as wiki-server derives them: [[x]] -> asSlug(x); the domain is added by the client.
const sitemap = [
  { domain: site, slug: 'question', title: 'Question', date: NOW - 2000, synopsis: '', links: { 'claim-a': 'p000000000000002' } },
  { domain: site, slug: 'claim-a', title: 'Claim A', date: NOW - 1000, synopsis: 'A statement offered as a claim.' },
]

const OriginalDate = Date
globalThis.Date = class extends OriginalDate {
  constructor(...a) { super(...(a.length ? a : [NOW])) }
  static now() { return NOW }
}
let networkAttempts = 0
globalThis.fetch = () => { networkAttempts++; throw new Error('NETWORK DISABLED') }
const log = console.log
console.log = () => {}

const elemPage = { id: 'question', dataset: { key: 'k-question' } }
const pageObject = {
  getSlug: () => 'question', getTitle: () => 'Question', getRemoteSite: host => host,
  getRawPage: () => ({ ...clone(pages.question), site, slug: 'question' }), isRemote: () => false,
}
globalThis.location = { host: site }
globalThis.document = { querySelectorAll: () => [elemPage], getElementById: () => null }
globalThis.wiki = { lineup: { atKey: () => pageObject } }
const batches = []
globalThis.window = {
  origin: 'https://' + site, isOwner: false, plugins: {},
  addEventListener() {},
  open: (url, name) => ({ location: { pathname: '/plugins/solo/dialog/' }, postMessage: data => batches.push({ url, name, data: clone(data) }) }),
}

const mech = await import(pathToFileURL(bundle))
const elements = {}, statuses = [], troubles = [], fetches = [], publications = []
const state = { context: { pageKey: 'k-question', title: 'Question', page: pageObject.getRawPage(), itemId: 'm000000000000004' } }
state.api = {
  element: key => (elements[key] ??= { id: key, innerHTML: '', previousElementSibling: { innerHTML: '', addEventListener() {} }, closest: () => elemPage }),
  neighborhood: () => [clone(sitemap)],
  jfetch: async url => {
    fetches.push(url)
    const slug = url.match(/^\/\/companion\.example\/(.+)\.json$/)?.[1]
    return slug && pages[slug] ? clone(pages[slug]) : null
  },
  trouble: (elem, message) => troubles.push({ block: elem.id, message }),
  status: (elem, command, text) => statuses.push({ block: elem.id, text: command + text }),
  inspect() {}, response() {}, report() {},
  publishSourceData: (elem, topic, data) => publications.push({ block: elem.id, topic, data: clone(data) }),
  host: () => site,
  lineupPages: () => [pageObject],
  thisLineupKey: () => 'k-question',
  lineupAtKey: () => pageObject,
  ago: () => 'fixture',
}

const nest = mech.tree(pages.question.story[3].text.split('\n'), [], 0)
nest.forEach((part, i) => (part.key = 'b' + i))
const stage = {}
await mech.run([nest[0]], state); stage.neighbors = clone(state.neighborhood)
await mech.run([nest[1]], state); stage.extract = clone(state.discourse)
await mech.run([nest[2]], state); stage.traverseBlock = { traversal: clone(state.traversal), aspect: clone(state.aspect) }
await mech.run([nest[3]], state)
await new Promise(resolve => setTimeout(resolve, 900)) // solo_emit waits 750 ms before opening the dialog

// The same computation through the exported functions, one stage at a time.
const root = `${site}+question`
const resolved = mech.resolveEdges(stage.extract.edges, stage.neighbors)
const traversed = mech.traverse(resolved, [root], ['claim'])
const graph = mech.presentGraph(traversed)
assert.deepEqual(clone(traversed), stage.traverseBlock.traversal.edges, 'TRAVERSE block and exported traverse agree')
assert.deepEqual(clone(graph), stage.traverseBlock.aspect[0].result[0].graph, 'TRAVERSE block and exported presentGraph agree')

console.log = log
process.stdout.write(JSON.stringify({
  kind: 'traverse-companion-example/1',
  bundle: { path: bundle, sha256: bundleSha256 },
  frozenNow: NOW,
  networkAttempts,
  fixture: { site, pages, sitemap },
  program: pages.question.story[3].text.split('\n'),
  stages: {
    observedLink: { page: 'question', item: clone(pages.question.story[1]), fold: clone(pages.question.story[0]) },
    neighbors: stage.neighbors,
    extract: stage.extract,
    resolveEdges: clone(resolved),
    traverse: clone(traversed),
    presentGraph: clone(graph),
    traverseBlock: stage.traverseBlock,
    solo: batches,
  },
  statuses: statuses.map(s => s.text),
  troubles,
  fetches,
  publications: publications.map(p => ({ block: p.block, topic: p.topic })),
}, null, 2) + '\n')
