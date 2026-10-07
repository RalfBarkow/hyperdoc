function listen_emit({ elem, command, args, state }) {
  if (args.length < 1) return state.api.trouble(elem, `LISTEN expects argument, an action.`)
  const topic = args[0]
  let recent = Date.now()
  let count = 0
  const handler = listen
  handler.action = 'publishSourceData'
  handler.id = elem.id
  window.addEventListener('message', listen)
  $('.main').on('thumb', (evt, thumb) => console.log('jquery', { evt, thumb }))
  // elem.innerHTML = command + ` ⇒ ready`
  state.api.status(elem, command, ` ⇒ ready`)
  // window.listeners = (action=null) => {
  //   return getEventListeners(window).message
  //     .map(t => t.listener)
  //     .filter(f => f.name == 'listen')
  //     .map(f => ({action:f.action,elem:document.getElementById(f.id),count:f.count}))
  // }

  function listen(event) {
    console.log({ event })
    const { data } = event
    if (data.action == 'publishSourceData' && (data.name == topic || data.topic == topic)) {
      count++
      handler.count = count
      if (state.debug) console.log({ count, data })
      if (count <= 100) {
        const now = Date.now()
        const elapsed = now - recent
        recent = now
        // elem.innerHTML = command + ` ⇒ ${count} events, ${elapsed} ms`
        state.api.status(elem, command, ` ⇒ ${count} events, ${elapsed} ms`)
      } else {
        window.removeEventListener('message', listen)
      }
    }
  }
}
