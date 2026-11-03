// Item-specific frame adapter (Code and Paragraph Items alike: the type is read from the hydrated Item). No editor markup, Action serializer or PUT shim.
// The original Wiki client loads/hydrates the page and owns every write.
(async () => {
  const config = JSON.parse(document.getElementById('hyperdoc-code-target').textContent)
  const toolbar = document.createElement('header')
  toolbar.id = 'hyperdoc-code-toolbar'
  const label = document.createElement('p')
  label.textContent = `${config.site} / ${config.slug} / ${config.id}`
  const action = document.createElement('button')
  action.textContent = 'Edit with original Wiki plugin'
  action.disabled = true
  const status = document.createElement('p')
  status.setAttribute('role','status');status.textContent = 'Waiting for the original Wiki runtime…'
  toolbar.append(label, action, status);document.body.prepend(toolbar)
  try {
    let $item, item
    for (let n=0;n<600;n++) {
      const $ = window.jQuery
      if ($ && window.wiki) {
        $item = $(`.page#${config.slug} .item[data-id="${config.id}"]`)
        item = $item.data('item')
        if ($item.length===1 && item?.id===config.id && window.plugins?.[item.type] && $item.hasClass('emit')) break
      }
      await new Promise(r=>setTimeout(r,50))
    }
    if (!$item || $item.length!==1 || !item || item.id!==config.id || !window.plugins?.[item.type]) throw Error('Original client did not hydrate the selected Item')
    const $page = $item.closest('.page')
    if (window.isOwner !== true || wiki.pageHandler.useLocalStorage() || $page.hasClass('local') || $page.data('site')==='local') throw Error('Server writing is not authorized; refusing browser-only editing')
    const plugin = await wiki.getPlugin(item.type)
    // Code has a plugin.editor. Paragraph has none: its original plugin binds a double-click to the client's
    // wiki.textEditor, so the original binding is triggered, not reimplemented.
    const dispatch = async () => {
      if (typeof plugin.editor === 'function') return plugin.editor($item,item)
      if (typeof plugin.bind === 'function') {
        $item.trigger('dblclick')
        if (!$item.hasClass('textEditing')) throw Error('The original double-click binding opened no editor')
        return
      }
      throw Error(`The original ${item.type} plugin has no editor`)
    }
    // Keep the existing page, lineup key, item data, story and journal in place.
    // Suppress their unrelated UI; the original editor still finds its real .page.
    $item.addClass('hyperdoc-selected-item')
    $item.closest('.page').addClass('hyperdoc-selected-page')
    const gate = document.querySelector('.editEnable')
    if (!gate) throw Error('Original edit-enable gate is absent')
    toolbar.append(gate);window.jQuery(gate).show()
    action.disabled = false
    status.textContent = 'Ready. The original client loaded this Item from the Wiki JSON page.'
    action.addEventListener('click', async () => {
      try {
        const dispatched = await wiki.getPlugin(item.type)
        if (dispatched !== plugin) throw Error('Unexpected plugin dispatch')
        await dispatch()
        status.textContent = 'Original editor opened. Click outside the Item to save; then use HyperDoc “Read stored page again”.'
      } catch (error) {status.textContent=error.message}
    })
  } catch (error) {status.textContent=error.message}
})()
