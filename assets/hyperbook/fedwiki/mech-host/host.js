// Minimal read-only Wiki client contract. Parser, catalog, emit and execution
// are the original pinned plugin; this host does not implement Mech commands.
const parentOrigin = new URLSearchParams(location.hash.slice(1)).get('parent')
if (!parentOrigin || parentOrigin === location.origin) throw Error('A separate Inspector origin is required.')
const send = (type, fields = {}) => parent.postMessage({type, ...fields}, parentOrigin)
const fail = error => {
  const message = String(error?.message || error)
  document.querySelector('#failure').textContent = message
  send('hyperdoc-mech-error', {message})
}
window.addEventListener('error', event => fail(event.error || event.message))
window.addEventListener('unhandledrejection', event => fail(event.reason))
window.isOwner = false
window.plugins = {}
let initialized = false
window.addEventListener('message', async event => {
  if (event.source !== parent || event.origin !== parentOrigin || event.data?.type !== 'hyperdoc-mech-page' || initialized) return
  initialized = true
  try {
    const {page, itemId, site, slug} = event.data
    const item = page?.story?.find(item => item.id === itemId && item.type === 'mech')
    if (!item || typeof item.text !== 'string') throw Error('The original Mech item is unavailable in the supplied page.')
    const key = 'hyperdoc-page'
    const pageObject = {getRawPage: () => page, getSlug: () => slug, isRemote: () => true}
    const unavailable = () => { throw Error('Editing and Wiki publication are unavailable in this read-only host.') }
    window.wiki = {
      lineup: {atKey: candidate => { if (candidate !== key) throw Error('Unknown lineup key'); return pageObject }},
      neighborhoodObject: {sites: {}}, pageHandler: {context: [site]},
      textEditor: unavailable, showResult: unavailable, newPage: unavailable,
    }
    const section = document.createElement('section')
    section.className = 'page'; section.id = slug; section.dataset.key = key
    $(section).data('key', key).data('site', site).data('data', page)
    const div = document.createElement('div')
    div.className = 'item mech'; div.dataset.id = item.id
    section.append(div); document.querySelector('main').append(section)
    const mech = await import('./plugins/mech/mech.js')
    // Original emit initializes the real CLICK buttons. Only passive CLICK
    // roots may initialize on display; all other scripts need an explicit run.
    // The original parser defines the nesting. No duplicated dispatch table.
    const nest = mech.tree(item.text.split('\n'), [], 0)
    const passive = nest.every(part => Array.isArray(part) || !part.command.trim() || part.command.split(/ +/)[0] === 'CLICK')
    const emit = () => window.plugins.mech.emit($(div), item)
    if (passive) emit()
    else {
      const source = document.createElement('pre'); source.textContent = item.text
      const play = document.createElement('button'); play.textContent = 'Run Mech ▶'
      play.onclick = () => { div.replaceChildren(); emit() }
      div.append(source, play)
    }
    new ResizeObserver(() => send('hyperdoc-mech-height', {height: document.body.scrollHeight + 20})).observe(document.body)
  } catch (error) { fail(error) }
})
send('hyperdoc-mech-ready')
