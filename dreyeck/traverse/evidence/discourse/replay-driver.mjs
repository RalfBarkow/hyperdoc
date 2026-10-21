// Replays Mech items of the retained discourse.dreyeck.ch pages with an unchanged discourse-profile bundle.
// Usage: node replay-driver.mjs <client/mech.js> <evidence/discourse>  > replay-run.json
// No network: fetch throws; every page comes from the retained snapshot. The clock is frozen.
// A CLICK is replayed by calling the handler it registers, as a click on its button does.
// Assumption, recorded in the output: the browser's neighborhood holds discourse.dreyeck.ch; NEIGHBORS
// discourse keeps only sites whose domain contains "discourse", so other loaded sites would be dropped.
import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import { pathToFileURL } from 'node:url'

const [bundle, root] = process.argv.slice(2)
const sha256 = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')
const NOW = Date.parse('2026-10-21T06:30:00Z')
const SITE = 'discourse.dreyeck.ch'
const clone = x => JSON.parse(JSON.stringify(x))
const digest = x => crypto.createHash('sha256').update(JSON.stringify(x)).digest('hex')
const read = file => JSON.parse(fs.readFileSync(path.join(root, file), 'utf8'))
const sitemap = read('sitemap.json')
const pageOf = slug => {
  const file = path.join(root, 'site', `${slug}.json`)
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : null
}

const CASES = [
  { name: 'discourse-graphs TRAVERSE', slug: 'discourse-graphs', item: '268693278cf3e65b' },
  { name: 'discourse-graphs role WALK', slug: 'discourse-graphs', item: '44fac82ef4111fc2' },
  { name: 'can-a-wiki-page-represent-a-claim TRAVERSE', slug: 'can-a-wiki-page-represent-a-claim', item: 'fef098721ab66a3c' },
  { name: 'how-i-use-my-wiki TRAVERSE', slug: 'how-i-use-my-wiki', item: 'c215bd68a676be22' },
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
const delay = ms => new Promise(resolve => setTimeout(resolve, ms))

let current = null // the page whose Mech item is being replayed
const pageDiv = { id: 'page', dataset: { key: 'k-root' } }
const pageObject = {
  getSlug: () => current.slug, getTitle: () => current.page.title, getRemoteSite: host => host,
  getRawPage: () => ({ ...clone(current.page), site: SITE, slug: current.slug }), isRemote: () => false,
}
globalThis.location = { host: SITE }
globalThis.document = { querySelectorAll: () => [pageDiv], getElementById: () => null }
globalThis.wiki = { lineup: { atKey: () => pageObject } }
const batches = []
globalThis.window = {
  origin: 'https://' + SITE, isOwner: false, plugins: {},
  addEventListener() {},
  open: (url, name) => ({ location: { pathname: '/plugins/solo/dialog/' }, postMessage: data => batches.push({ url, name, data: clone(data) }) }),
}
const mech = await import(pathToFileURL(bundle))

// Ward's neighborhood(want), blocks.js at a028b4b, over the one site the replay assumes loaded.
const neighborhoodObject = { sites: { [SITE]: { sitemap } } }
const neighborhood = want =>
  Object.entries(neighborhoodObject.sites)
    .filter(([domain, site]) => !site.sitemapRequestInflight && (!want || domain.includes(want)))
    .map(([domain, site]) => (site.sitemap || []).map(info => Object.assign({ domain }, info)))

const keyed = (nest, prefix) =>
  nest.forEach((part, i) => (Array.isArray(part) ? keyed(part, `${prefix}${i - 1}.`) : (part.key = `${prefix}${i}`)))
const commands = (nest, out = []) => {
  for (const part of nest) Array.isArray(part) ? commands(part, out) : out.push({ key: part.key, command: part.command })
  return out
}

async function replay({ name, slug, item }) {
  const page = pageOf(slug)
  const mechItem = page.story.find(each => each.id == item)
  current = { slug, page }
  batches.length = 0
  const elements = {}, statuses = [], troubles = [], fetches = [], clicks = []
  const state = { context: { pageKey: 'k-root', title: page.title, page: pageObject.getRawPage(), itemId: item } }
  state.api = {
    element: key => (elements[key] ??= { id: key, innerHTML: '', previousElementSibling: { innerHTML: '', addEventListener() {} }, closest: () => pageDiv }),
    neighborhood: want => clone(neighborhood(want)),
    jfetch: async url => {
      fetches.push(url)
      const slug = url.match(/^\/\/discourse\.dreyeck\.ch\/(.+)\.json$/)?.[1]
      return slug ? pageOf(slug) : null
    },
    trouble: (elem, message) => troubles.push({ block: elem.id, message }),
    status: (elem, command, text) => statuses.push({ block: elem.id, text: command + text }),
    button: (elem, label, handler) => clicks.push({ block: elem.id, handler }),
    reset() {}, inspect() {}, response() {}, report() {},
    publishSourceData() {},
    host: () => undefined,
    lineupPages: () => [pageObject],
    thisLineupKey: () => 'k-root',
    lineupAtKey: () => pageObject,
    ago: () => 'replay',
  }
  const nest = mech.tree(mechItem.text.split('\n'), [], 0)
  keyed(nest, 'b')
  await mech.run(nest, state)
  const clicked = []
  for (const click of clicks) {
    clicked.push(click.block)
    click.handler({ shiftKey: false })
    await delay(1200) // a click's run is not awaited by CLICK; SOLO waits 750 ms before opening its dialog
  }
  const discourse = state.discourse ? clone(state.discourse) : null
  if (discourse) extractedEdges.push(discourse.edges)
  const traversal = state.traversal ? clone(state.traversal) : null
  let exported = null
  if (traversal) {
    const resolved = mech.resolveEdges(discourse.edges, clone(state.neighborhood))
    const traversed = mech.traverse(resolved, [traversal.root], traversal.roles)
    exported = { traverseAgrees: JSON.stringify(traversed) == JSON.stringify(traversal.edges),
                 graph: traversed.length ? clone(mech.presentGraph(traversed)) : null }
  }
  return {
    name, page: { site: SITE, slug, title: page.title }, item: clone(mechItem),
    program: mechItem.text.split('\n'), blocks: commands(nest), clicked,
    statuses: statuses.map(s => s.text), troubles,
    neighborhood: state.neighborhood
      ? { pages: state.neighborhood.length, sites: [...new Set(state.neighborhood.map(info => info.domain))],
          surveyed: state.neighborhood.filter(info => 'role' in info).length }
      : null,
    discourse: discourse && { identity: discourse.identity, metadata: discourse.metadata,
                              edgesSha256: digest(discourse.edges) },
    traversal, exported,
    aspect: state.aspect ? clone(state.aspect) : null,
    solo: clone(batches),
    fetches: fetches.length,
  }
}

const runs = [], extractedEdges = []
for (const each of CASES) runs.push(await replay(each))

// Constructed, not replayed: no Mech item on Zach's Lineup holds TRAVERSE. The exported functions are applied to
// the edges and neighborhood of the first replay, from that page, to show where links to another site end.
// Every replay extracts from the same snapshot; the edges and their resolution are recorded once.
const edges = extractedEdges[0]
if (!extractedEdges.every(each => digest(each) == digest(edges))) throw new Error('replays extracted different edges')
const extracted = { edges, sha256: digest(edges), resolved: clone(mech.resolveEdges(edges, neighborhood('discourse').flat())) }
const crossRoot = `${SITE}+zachs-lineup`
const crossResolved = mech.resolveEdges(edges, neighborhood('discourse').flat())
const crossTraversed = mech.traverse(crossResolved, [crossRoot], ['question'])
const constructed = {
  name: 'zachs-lineup question, exported functions',
  note: 'No Mech item on this page; computed with the exported resolveEdges and traverse on the recorded edges.',
  root: crossRoot, roles: ['question'],
  edges: clone(crossTraversed),
  graph: clone(mech.presentGraph(crossTraversed)),
}

// The Claim Link Survey Probe of the same site, applied to the same snapshot, beside the survey it stored.
const probe = await import(pathToFileURL(path.resolve(root, 'assets', 'ClaimLinkSurveyProbe.js')))
const probed = sitemap.map(info => probe.probe(pageOf(info.slug), info))
const tally = records => {
  const t = { pages: records.length, edges: 0, question: 0, claim: 0, support: 0, oppose: 0 }
  for (const record of records) for (const edge of record.edges || []) { t.edges++; t[edge.type]++ }
  return t
}
const surveyPage = pageOf('claim-link-survey')
const stored = surveyPage.story.find(each => each.type == 'frame').survey

console.log = log
process.stdout.write(JSON.stringify({
  kind: 'discourse-replay/1',
  bundle: { path: bundle, sha256: sha256(bundle) },
  frozenNow: NOW,
  networkAttempts,
  assumption: { neighborhood: [SITE], lineup: 'only the page that holds the Mech item' },
  extracted,
  runs,
  constructed,
  probe: {
    module: { file: 'assets/ClaimLinkSurveyProbe.js', sha256: sha256(path.join(root, 'assets', 'ClaimLinkSurveyProbe.js')) },
    storedSurvey: { page: 'claim-link-survey', item: surveyPage.story.find(each => each.type == 'frame').id, totals: tally(stored) },
    onSnapshot: { totals: tally(probed), edges: probed.flatMap(record => record.edges.map(edge => ({ ...edge }))) },
  },
}, null, 2) + '\n')
