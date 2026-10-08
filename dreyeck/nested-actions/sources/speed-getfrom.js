async function fastfetch(resource) {
  const controller = new AbortController()
  const id = setTimeout(() => controller.abort(), 5000)
  const response = await fetch(resource, {signal: controller.signal})
  clearTimeout(id)
  return response
}

export async function getfrom(slug, sites) {
  let need = sites.filter(site => !sitemaps[site])
  await Promise.all(need.map(site => fastfetch(`//${site}/system/sitemap.json`)
    .then(res => res.ok ? res.json() : [])
    .catch(err => [])
    .then(infos => {sitemaps[site]=infos})))
  let site = sites.find(site => sitemaps[site].filter(info => info.slug == slug).length)
  if (site) {
    let page = await fastfetch(`//${site}/${slug}.json`).then(res => res.json())
    let refs = page.story
      .filter(item => item && item.type == 'reference')
      .reduce((set,item) => set.add(item.site), new Set([site]))
    let all = (page.journal||[])
      .filter(action => action.site)
      .reverse()
      .reduce((set,action) => set.add(action.site), refs)
    return {site, page, sites:[...all]}
  } else {
    return {}
  }
}