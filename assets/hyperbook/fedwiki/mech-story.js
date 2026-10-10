// Browser bridge only. No executable Wiki text reaches a Lisp event handler.
window.mountFedwikiMech = function (view) {
  for (const container of view.querySelectorAll('.fedwiki-mech-host')) {
    if (container.dataset.mounted) continue
    container.dataset.mounted = 'true'
    const status = container.querySelector('.mech-host-status')
    if (!container.dataset.hostUrl) continue
    let url
    try {
      url = new URL(container.dataset.hostUrl)
      if (!['https:', 'http:'].includes(url.protocol) || url.username || url.password)
        throw Error('The Wiki plugin host must use an HTTP(S) origin without credentials.')
      if (url.origin === location.origin)
        throw Error('The Wiki plugin host must have a separate origin from the Lisp Inspector.')
    } catch (error) { status.textContent = error.message; return }
    url.hash = new URLSearchParams({parent: location.origin}).toString()
    const frame = document.createElement('iframe')
    frame.title = 'Mech operations — ' + container.dataset.itemId
    // Separate origin is mandatory: allow-same-origin preserves unchanged Solo
    // opener/postMessage behavior, without granting access to the Inspector DOM.
    frame.sandbox = 'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox'
    frame.referrerPolicy = 'no-referrer'
    frame.style.cssText = 'width:100%;height:260px;border:1px solid #bbb;box-sizing:border-box'
    let initialized = false
    const timeout = setTimeout(() => { if (!initialized) status.textContent = 'Wiki plugin host unavailable. No Code item has run.' }, 10000)
    const receive = event => {
      if (!frame.isConnected) { window.removeEventListener('message', receive); clearTimeout(timeout); return }
      if (event.source !== frame.contentWindow || event.origin !== url.origin) return
      if (event.data?.type === 'hyperdoc-mech-ready' && !initialized) {
        initialized = true; clearTimeout(timeout)
        frame.contentWindow.postMessage({type: 'hyperdoc-mech-page',
          page: JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(container.dataset.pageJsonBase64), c => c.charCodeAt(0)))), itemId: container.dataset.itemId,
          site: container.dataset.site, slug: container.dataset.slug}, url.origin)
        status.textContent = 'Code runs only after Play. Solo opens in a separate browser window.'
      } else if (event.data?.type === 'hyperdoc-mech-height') {
        const height = Number(event.data.height)
        if (Number.isFinite(height)) frame.style.height = Math.min(900, Math.max(180, height)) + 'px'
      } else if (event.data?.type === 'hyperdoc-mech-error') {
        status.textContent = 'Wiki plugin host: ' + String(event.data.message)
      }
    }
    window.addEventListener('message', receive)
    container.append(frame); frame.src = url.href
  }
}
