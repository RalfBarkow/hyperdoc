window.dostart = async function (event) {
done = Date.now() + 10000
window.result.innerText = ''
all = [all[0]]
pick = all[0]
seen = new Set([pick.page.title])
dot = []
hue = 0.5001
color = {} // site => hsv
addcolor(pick)

try {
  while (Date.now() < done) {
    let remain = Math.ceil((done - Date.now())/1000)
    let links = visit(pick.page).filter(title => !seen.has(title))
    if (links.length) {
      let link = any(links)
      seen.add(link)
      let next = await getfrom(asSlug(link),pick.sites)
      if (next && next.page) {
        addcolor(next)
        dot.push(`${quote(pick.page.title)} -> ${quote(next.page.title)}`)
        all.push(next)
        window.result.innerHTML += `${remain} <span onclick=doview(event)>${next.site} — ${link}</span>\n`
        pick = next 
      } else {
        window.result.innerHTML += `  <span style="color:gray;">fail ${link}</span>\n`
        // pick = any(all) // can't find page for link
      }
    } else {
      all = all.filter(place => !(place.site == pick.site && place.page.title == pick.page.title))
      if (!all.length) break
      window.result.innerHTML += `  <span style="color:gray;">done ${pick.page.title}</span>\n`
      pick = any(all) // can't find new link on page
    }
  }
}
catch(err) {
  window.result.innerHTML += `
  ${err.message}
  ${err.stack}`
}

window.result.innerHTML += "\n\n"+Object.entries(sitemaps).map(([site,infos]) => `${infos.length} — ${site}`).join("\n")
let text = `digraph {\nnode [shape=box style=filled fillcolor=white]\n${dot.join("\n")}\n}`
let story = [
  {type:'paragraph', text: `Random journey rooted from ${reference.title} and proceeding for ${all.length} pages travelling through ${Object.keys(color).length} sites.`},
  {type:'graphviz', text}
]

open({title:"Speed Bot Journey",story},event.shiftKey,Object.keys(color))

}
