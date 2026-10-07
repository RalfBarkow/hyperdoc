export async function run(nest, state, initiator) {
  const scope = nest.slice()
  while (scope.length) {
    const code = scope.shift()
    if ('command' in code) {
      const command = code.command
      const elem = state.api ? state.api.element(code.key) : document.getElementById(code.key)
      const [op, ...args] = code.command.split(/ +/)
      const next = scope[0]
      const body = next && 'command' in next ? null : scope.shift()
      const stuff = { command, op, args, body, elem, state, initiator }
      if (state.debug) console.log(stuff)
      if (blocks[op]) await blocks[op].emit.apply(null, [stuff])
      else if (op.match(/^[A-Z]+$/)) state.api.trouble(elem, `${op} doesn't name a block we know.`)
      else if (code.command.match(/\S/)) state.api.trouble(elem, `Expected line to begin with all-caps keyword.`)
    }
  }
}
