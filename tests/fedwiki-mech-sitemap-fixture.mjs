import fs from 'node:fs'
import {api, run} from '../assets/hyperbook/fedwiki/mech-host/plugins/mech/blocks.js'
import {tree} from '../assets/hyperbook/fedwiki/mech-host/plugins/mech/interpreter.js'

export const fixture = JSON.parse(fs.readFileSync(new URL('./fixtures/mech-sitemaps.json', import.meta.url)))
export const page = {site: fixture.sites[0].domain, slug: 'mech-sitemap-fixture'}
export function snapshot(mode = 'ready') {
  return {version: 1, scope: 'page-origin-and-context', page,
    sites: fixture.sites.map((s, i) => ({domain: s.domain,
      sourceUrl: `https://${s.domain}/system/sitemap.json`,
      state: i === 1 && !['ready', 'empty'].includes(mode) ? mode : 'ready',
      sitemap: mode === 'empty' ? [] : i === 1 && mode !== 'ready' ? null : structuredClone(s.sitemap),
      message: mode === 'failed' ? 'Fixture fetch failure' : null}))}
}

// Reference executes the unchanged dispatcher/graphs with an identical input.
// It does not contain a graph algorithm or reproduce the host transformation.
export async function reference(records) {
  const elements = {}, statuses = [], state = {}
  const oldWiki = globalThis.wiki
  globalThis.wiki = {neighborhoodObject: {sites: Object.fromEntries(records.map(record =>
    [record.domain, {sitemap: structuredClone(record.sitemap), sitemapRequestInflight: false}]))}}
  state.api = {...api,
    element: key => elements[key] ??= {id: key}, inspect() {},
    status(elem, command, text) { statuses.push(command + text) },
    trouble(elem, message) { throw Error(message) }, publishSourceData() {},
  }
  const nest = tree(['NEIGHBORS', 'WALK 12 weeks', 'WALK 25 hubs'], [], 0)
  nest.forEach((command, i) => command.key = 'reference-' + i)
  const oldNow = Date.now
  try { Date.now = () => fixture.clock; await run(nest, state) }
  finally { Date.now = oldNow; globalThis.wiki = oldWiki }
  return {statuses, aspects: JSON.parse(JSON.stringify(state.aspect.flatMap(s => s.result)))}
}
