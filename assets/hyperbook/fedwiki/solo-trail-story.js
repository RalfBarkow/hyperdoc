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
      restoreSoloPaint(source, svg)
    }
  }
})()
