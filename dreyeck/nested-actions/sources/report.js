function report_emit({ elem, command, args, state }) {
  const key = args[0] || 'temperature'
  if (!(key in state)) return state.api.trouble(elem, `Expect "${key}" in state`)
  const value = state[key]
  const type = typeof value
  if (!['string', 'number'].includes(type))
    return state.api.trouble(elem, `Expect state.${key} to be a string or number`)
  state.api.inspect(elem, key, state)
  state.api.report(elem, command, `<div class=report>${value}</div>`)
}
