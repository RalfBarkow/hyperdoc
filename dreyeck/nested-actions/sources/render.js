function emit($item, item) {
  if (!$("link[href='/plugins/mech/mech.css']").length) {
    $('<link rel="stylesheet" href="/plugins/mech/mech.css" type="text/css">').appendTo('head')
  }

  const lines = item.text.split(/\n/)
  const nest = tree(lines, [], 0)
  const html = format(nest)
  const $page = $item.parents('.page')
  const pageKey = $page.data('key')
  const context = {
    item,
    itemId: item.id,
    pageKey,
    page: wiki.lineup.atKey(pageKey).getRawPage(),
    origin: window.origin,
    site: $page.data('site') || window.location.host,
    slug: $page.attr('id'),
    title: $page.data('data').title,
    blocks: Object.keys(blocks),
  }
  const state = { context, api }
  $item.append(`<div style="background-color:#eee;padding:15px;border-top:8px;">${html}</div>`)
  run(nest, state)
}
