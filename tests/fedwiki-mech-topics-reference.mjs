// Trusted offline oracle. Only the original module's import location is bound
// to the exact retained original helper excerpt; walks/Graph are not rewritten.
import fs from 'node:fs'
import crypto from 'node:crypto'
import assert from 'node:assert/strict'
const root = new URL('./fixtures/mech-topics/', import.meta.url)
export const provenance = JSON.parse(fs.readFileSync(new URL('provenance.json', root)))
export const hash = value => crypto.createHash('sha256').update(value).digest('hex')
for (const record of provenance.files) {
  const bytes = fs.readFileSync(new URL(record.path, root))
  assert.equal(hash(bytes), record.sha256, record.path)
  if (record.gitBlob) assert.equal(crypto.createHash('sha1').update(Buffer.concat([
    Buffer.from('blob ' + bytes.length + '\0'), bytes])).digest('hex'), record.gitBlob)
}
export const originalLibrary = fs.readFileSync(new URL('ward-library.js', root), 'utf8')
export const topicsRegion = originalLibrary.slice(originalLibrary.indexOf('  function topics('), originalLibrary.indexOf('\n}\n', originalLibrary.indexOf('  function topics(')))
assert.equal(hash(topicsRegion), provenance.topicsRegionSha256)
export const insertion = '\n  // Source-faithful WALK topics intake: Ward c858eff1e655e913418bfe86ddecab6053ce38b5.\n' + topicsRegion + '\n'
assert.equal(hash(insertion), provenance.insertionSha256)
const importLine = "import { uniq, delay, asSlug } from './mech.js'"
assert(originalLibrary.startsWith(importLine))
const referenceLibrary = originalLibrary.replace(importLine,
  `import { uniq, delay, asSlug } from '${new URL('ward-helpers.mjs', root).href}'`)
export const ward = await import('data:text/javascript;base64,' + Buffer.from(referenceLibrary).toString('base64'))
export const originalPage = JSON.parse(fs.readFileSync(new URL('pattern-machinery.json', root)))
export const originalSitemap = JSON.parse(fs.readFileSync(new URL('ward-sitemap.json', root)))
export const page = {site: 'ward.voices.ustawi.wiki', slug: 'pattern-machinery'}
export function snapshot(mode = 'ready') {
  return {version: 1, scope: 'page-origin-and-context', page,
    sites: [{domain: page.site, sourceUrl: provenance.files.find(r => r.path === 'ward-sitemap.json').url,
      state: mode, sitemap: mode === 'ready' ? structuredClone(originalSitemap) : mode === 'empty' ? [] : null,
      message: mode === 'failed' ? 'Recorded test failure; no source substituted' : null}].map(s => ({...s, state: mode === 'empty' ? 'ready' : mode}))}
}
export function seededRandom(seed) {
  let value = seed >>> 0
  return () => ((value = (Math.imul(value, 1664525) + 1013904223) >>> 0) / 4294967296)
}
const stable = value => Array.isArray(value) ? value.map(stable) : value && typeof value === 'object'
  ? Object.fromEntries(Object.keys(value).sort().map(k => [k, stable(value[k])])) : value
// Preserve node properties/site/date, directed edges and multiplicity, while
// ignoring random node IDs and aspect/edge enumeration. Verify adjacency too.
export function graphContent(aspects, includeNames = true) {
  return aspects.map(({name, graph}) => {
    const keys = graph.nodes.map(n => JSON.stringify(stable({type: n.type, props: n.props})))
    assert.equal(new Set(keys).size, keys.length, 'Oracle requires distinguishable graph nodes')
    graph.nodes.forEach((node, i) => {
      assert.deepEqual([...node.in].sort((a,b) => a-b), graph.rels.flatMap((r,j) => r.to === i ? [j] : []))
      assert.deepEqual([...node.out].sort((a,b) => a-b), graph.rels.flatMap((r,j) => r.from === i ? [j] : []))
    })
    const rels = graph.rels.map(r => {
      assert(keys[r.from] && keys[r.to], 'Dangling graph relation')
      return JSON.stringify(stable({type:r.type, props:r.props, from:keys[r.from], to:keys[r.to]}))
    }).sort()
    return JSON.stringify({...(includeNames ? {name} : {}), nodes: keys.sort(), rels})
  }).sort()
}
