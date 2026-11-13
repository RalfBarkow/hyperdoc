// Keep the original Wiki HTML as text until the browser has sanitized it.
(() => {
  const svgNamespace = 'http://www.w3.org/2000/svg'
  let markerNumber = 0

  function svgElement(name, attributes) {
    const element = document.createElementNS(svgNamespace, name)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }

  function restoreSoloPaint(source, svg) {
    const original = new DOMParser().parseFromString(source, 'image/svg+xml').documentElement
    if (original.namespaceURI !== svgNamespace || original.localName !== 'svg') return

    // Match the Solo export signature. Only these fixed presentation values
    // cross the sanitization boundary. No source CSS or URLs are copied.
    const paths = [...original.querySelectorAll('path[id="trail"][d]')].filter(path =>
      path.style?.fill === 'none' && path.style.stroke === 'red' &&
      ['5', '5px'].includes(path.style.strokeWidth) &&
      path.getAttribute('marker-end') === 'url(#arrow)')
    if (!paths.length) return

    const trailGeometry = new Set(paths.map(path => path.getAttribute('d')))
    const renderedPaths = [...svg.querySelectorAll('path[d]')].filter(path =>
      trailGeometry.has(path.getAttribute('d')))
    if (!renderedPaths.length) return

    // The default sanitizer can remove ids, and multiple Story panes may
    // display the same source. Install a fresh, document-local marker.
    let id
    do {
      id = 'fedwiki-solo-arrow-' + ++markerNumber
    } while (document.getElementById(id))
    const defs = svgElement('defs', {})
    const marker = svgElement('marker', {
      id, viewBox: '0 0 10 10', refX: 5, refY: 5, markerWidth: 6,
      markerHeight: 6, orient: 'auto-start-reverse', fill: 'red'
    })
    marker.append(svgElement('path', {d: 'M 0 0 L 10 5 L 0 10 Z'}))
    defs.append(marker)
    svg.prepend(defs)
    for (const path of renderedPaths) {
      path.setAttribute('fill', 'none')
      path.setAttribute('stroke', 'red')
      path.setAttribute('stroke-width', '5')
      path.setAttribute('pointer-events', 'none')
      path.setAttribute('marker-end', 'url(#' + id + ')')
    }
    return true
  }

  function graphNodes(svg) {
    const nodes = new Map()
    for (const group of svg.querySelectorAll('g')) {
      const id = group.querySelector(':scope > title')?.textContent.trim()
      const name = [...group.querySelectorAll('text')]
        .map(label => label.textContent).join('\n')
      if (id && /^\d+$/.test(id) && name) {
        nodes.set(group, {id, name})
      }
    }
    return nodes
  }

  function soloAspect(name, stations, source) {
    return {
      name,
      graph: {
        nodes: stations.map(({id, name}, index) => ({
          type: '',
          in: index ? [index - 1] : [],
          out: index + 1 < stations.length ? [index] : [],
          props: {name, sourceNode: {...source, graphNode: id}}
        })),
        rels: stations.slice(1).map((_, index) => ({
          type: 'Trail', from: index, to: index + 1, props: {}
        }))
      }
    }
  }

  function mountTrail(container, svg) {
    const nodes = graphNodes(svg)
    if (nodes.size < 2) return

    const controls = document.createElement('div')
    const button = document.createElement('button')
    const undo = document.createElement('button')
    const cancel = document.createElement('button')
    const name = document.createElement('input')
    const status = document.createElement('p')
    const result = document.createElement('textarea')
    button.type = undo.type = cancel.type = 'button'
    undo.textContent = 'Undo station'
    cancel.textContent = 'Cancel'
    name.placeholder = 'Trail name'
    name.setAttribute('aria-label', 'Trail name')
    status.setAttribute('role', 'status')
    result.readOnly = true
    result.rows = 8
    result.cols = 60
    result.setAttribute('aria-label', 'Completed Solo aspect (JSON)')
    result.hidden = true
    controls.append(button, undo, cancel, name, status, result)
    container.prepend(controls)

    const line = svgElement('polyline', {
      fill: 'none', stroke: '#af1b39', 'stroke-width': 3,
      'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'pointer-events': 'none'
    })
    svg.append(line)
    const source = {
      site: container.dataset.site,
      page: container.dataset.slug,
      item: container.dataset.item
    }
    let draft = null
    let completed = []

    // Like Hauptsache Connect, follow the pointer from the selected anchor.
    // Keep earlier stations until the user explicitly completes the trail.

    function toSvg(point) {
      return point.matrixTransform(svg.getScreenCTM().inverse())
    }

    function stationPoint(group) {
      const box = group.getBBox()
      const center = new DOMPoint(box.x + box.width / 2, box.y + box.height / 2)
      return toSvg(center.matrixTransform(group.getScreenCTM()))
    }

    function paint(pointer) {
      const points = (draft ?? completed).map(stationPoint)
      if (points.length && pointer) points.push(pointer)
      line.setAttribute('points', points.map(point => point.x + ',' + point.y).join(' '))
    }

    function update(message = '') {
      const active = draft !== null
      button.textContent = active ? 'Finish trail' : 'Trail'
      undo.hidden = cancel.hidden = name.hidden = !active
      undo.disabled = !draft?.length
      status.textContent = message || (active
        ? draft.length + ' selected. Choose a station or finish the trail.'
        : '')
      for (const [group, node] of nodes) {
        if (active) {
          group.setAttribute('tabindex', '0')
          group.setAttribute('role', 'button')
          group.setAttribute('aria-label', node.name.replaceAll('\n', ' '))
          group.style.cursor = 'pointer'
        } else {
          for (const attribute of ['tabindex', 'role', 'aria-label']) group.removeAttribute(attribute)
          group.style.removeProperty('cursor')
        }
      }
      paint()
    }

    function finish() {
      if (draft.length < 2) {
        update('Choose at least two stations to finish.')
        return
      }
      completed = draft
      draft = null
      const title = name.value.trim() || 'New Trail'
      result.value = JSON.stringify(soloAspect(title, completed.map(group => nodes.get(group)), source), null, 2)
      result.hidden = false
      update(title + ' completed. Solo aspect JSON is available below.')
      button.focus()
    }

    function selectStation(group) {
      if (draft.at(-1) === group) return
      draft.push(group)
      update()
    }

    function cancelDraft() {
      draft = null
      update('Trail cancelled.')
      button.focus()
    }

    function clickedNode(target) {
      for (let current = target; current && current !== svg; current = current.parentElement) {
        if (nodes.has(current)) return current
      }
      return null
    }

    button.addEventListener('click', () => {
      if (draft !== null) {
        finish()
      } else {
        draft = []
        name.value = ''
        update('Choose the first station.')
      }
    })
    undo.addEventListener('click', () => {
      if (!draft?.length) return
      draft.pop()
      update()
    })
    cancel.addEventListener('click', cancelDraft)
    container.addEventListener('keydown', event => {
      if (draft === null) return
      if (event.key === 'Escape') {
        event.preventDefault()
        cancelDraft()
      } else if (event.target === name && event.key === 'Enter') {
        event.preventDefault()
        finish()
      } else if (nodes.has(event.target) && ['Enter', ' '].includes(event.key)) {
        event.preventDefault()
        selectStation(event.target)
      }
    })
    svg.addEventListener('click', event => {
      if (draft === null) return
      const group = clickedNode(event.target)
      if (!group) return
      event.preventDefault()
      event.stopPropagation()
      selectStation(group)
    }, true)
    svg.addEventListener('mousemove', event => {
      if (draft?.length) paint(toSvg(new DOMPoint(event.clientX, event.clientY)))
    })
    svg.addEventListener('mouseleave', () => {
      if (draft?.length) paint()
    })
    update()
  }

  window.mountFedwikiSoloTrailStory = function (view) {
    for (const container of view.querySelectorAll('.fedwiki-inline-svg')) {
      const template = container.querySelector('template')
      if (!template) continue
      const source = template.content.textContent
      const output = document.createElement('div')
      output.setHTML(source)
      template.replaceWith(output)

      const svg = output.querySelector(':scope > svg')
      if (!svg) continue
      if (restoreSoloPaint(source, svg)) mountTrail(container, svg)
    }
  }
})()
