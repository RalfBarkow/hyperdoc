function message_emit({ elem, command, args, state }) {
  if (args.length < 1) return state.api.trouble(elem, `MESSAGE expects argument, an action.`)
  const topic = args[0]
  const message = {
    action: 'publishSourceData',
    topic,
    name: topic,
  }
  window.postMessage(message, '*')
  // elem.innerHTML = command + ` ⇒ sent`
  state.api.status(elem, command, ` ⇒ sent`)
}
