async function solo_emit({ elem, command, state }) {
  if (!('aspect' in state)) return state.api.trouble(elem, `"SOLO" expects "aspect" state, like from "WALK".`)
  inspect(elem, 'aspect', state)
  // elem.innerHTML = command
  state.api.status(elem, command, '')
  const todo = state.aspect.map(each => ({
    source: each.source || each.id,
    aspects: each.result,
  }))
  const aspects = todo.reduce((sum, each) => sum + each.aspects.length, 0)
  // elem.innerHTML += ` ⇒ ${todo.length} sources, ${aspects} aspects`
  state.api.status(elem, command, ` ⇒ ${todo.length} sources, ${aspects} aspects`)

  // from Solo plugin, client/solo.js
  const pageKey = elem.closest('.page').dataset.key
  const doing = { type: 'batch', sources: todo, pageKey }
  // console.log({ pageKey, doing })

  if (typeof window.soloListener == 'undefined' || window.soloListener == null) {
    console.log('**** Adding solo listener')
    window.soloListener = soloListener
    window.addEventListener('message', soloListener)
  }

  await delay(750)
  const popup = window.open('/plugins/solo/dialog/#', 'solo', 'popup,height=720,width=1280')
  if (popup.location.pathname != '/plugins/solo/dialog/') {
    console.log('launching new dialog')
    popup.addEventListener('load', event => {
      console.log('launched and loaded')
      popup.postMessage(doing, window.origin)
    })
  } else {
    console.log('reusing existing dialog')
    popup.postMessage(doing, window.origin)
  }
}
