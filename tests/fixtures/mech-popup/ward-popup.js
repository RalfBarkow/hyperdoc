function popup_emit({ elem, args, state }) {
  const expand = text => text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  const html = []
  switch (args[0]) {
    case 'state':
      for (const key in state) {
        let value = state[key]
        if (value == null) continue
        if (typeof value != 'string') value = JSON.stringify(state[key], null, 2)
        html.push(
          `<details>
            <summary>${key}</summary>
            <pre style="white-space: pre-wrap;">${expand(value)}</pre>
          </details>`,
        )
      }
      break
    case 'images':
      if (!state.commons)
        return state.api.trouble(elem, `POPUP images expects "commons" state, like from "GET" "COMMONS"`)
      const where = args[1] == 'all' ? state.commons.all : state.commons.here
      for (const item of where.items) {
        html.push(`<span><img height=200 src=/assets/plugins/image/${item}></span>`)
      }
      break
    default:
      return state.api.trouble(elem, `POPUP doesn't know "${args[0]}".`)
  }
  wiki.dialog(elem.innerText, html.join('\n'))
}
