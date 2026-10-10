// Data boundary only. All neighborhood extraction and graph operations remain
// in the unchanged Mech modules. No fetch, ordering adapter or Wiki client.
export function createNeighborhood(snapshot, page) {
  if (snapshot == null) return unavailable('Sitemap snapshot missing. NEIGHBORS cannot run.')
  if (snapshot.version !== 1 || snapshot.scope !== 'page-origin-and-context' ||
      snapshot.page?.site !== page.site || snapshot.page?.slug !== page.slug ||
      !Array.isArray(snapshot.sites) || !snapshot.sites.length)
    throw Error('Invalid sitemap snapshot for the selected page.')
  const sites = Object.create(null), pending = []
  for (const record of snapshot.sites) {
    if (!record || typeof record.domain !== 'string' || !record.domain ||
        Object.hasOwn(sites, record.domain) ||
        !['ready', 'missing', 'loading', 'failed'].includes(record.state) ||
        !(record.sourceUrl == null || typeof record.sourceUrl === 'string'))
      throw Error('Invalid sitemap site record.')
    if (record.state === 'ready') {
      if (typeof record.sourceUrl !== 'string' || !record.sourceUrl ||
          !Array.isArray(record.sitemap) || record.sitemap.some(info =>
            !info || typeof info !== 'object' || Array.isArray(info)))
        throw Error(`Invalid retained sitemap for ${record.domain}.`)
    } else {
      if (record.sitemap != null) throw Error(`Unavailable sitemap supplied for ${record.domain}.`)
      pending.push(`${record.domain}: ${record.state}${record.message ? ' — ' + record.message : ''}`)
    }
    sites[record.domain] = {
      sitemap: record.state === 'ready' ? structuredClone(record.sitemap) : null,
      sitemapRequestInflight: record.state === 'loading',
      sourceUrl: record.sourceUrl, state: record.state,
    }
  }
  if (!Object.hasOwn(sites, page.site)) throw Error('Selected page origin is absent from the sitemap snapshot.')
  if (pending.length) return unavailable(`Sitemap data unavailable (${pending.join('; ')}). NEIGHBORS cannot run. Reopen Story after the data becomes available.`)
  return {
    neighborhoodObject: {sites},
    message: `Sitemap data ready: ${Object.keys(sites).join(', ')} (${snapshot.sites.reduce((n, s) => n + s.sitemap.length, 0)} pages). Scope: page origin and context.`,
  }
}

function unavailable(message) {
  return {
    message,
    neighborhoodObject: {get sites() { throw Error(message) }},
  }
}
