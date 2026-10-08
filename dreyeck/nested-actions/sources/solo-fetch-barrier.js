  async function link(url) {
    const text = await fetch(url).then(res => res.text())
    const lines = text.trim().split(/\n/)
    return lines.map(line => JSON.parse(line))
  }


  let parsed
  let todo = []
  async function emit($item, item) {
    parsed = parse(item.text)
    $item.append(`<p style="background-color:#eee;padding:15px;">
      ${parsed.output}</p>`)
    todo = await Promise.all(parsed.graphs)
    $item.append(`<p>
      <button onclick="window.plugins.solo.dopopup(event)">view in solo</button></p>`)
  }
