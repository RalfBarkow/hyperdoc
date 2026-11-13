import assert from 'node:assert/strict'
import {fileURLToPath} from 'node:url'
import {test} from 'node:test'

// Like scripts/test-solo-trail-identity.mjs, use an explicitly installed
// Playwright and Chromium when they are outside this checkout.
const playwright = process.env.HYPERDOC_PLAYWRIGHT || 'playwright'
const {chromium} = await import(playwright)
const script = fileURLToPath(new URL('../assets/hyperbook/fedwiki/solo-trail-story.js', import.meta.url))

const node = (id, label, x, y) =>
  '<g class="node"><title>' + id + '</title><polygon fill="white" stroke="black" points="' +
  [x - 8, y - 6, x + 8, y - 6, x + 8, y + 6, x - 8, y + 6].join(' ') +
  '"/><text x="' + x + '" y="' + y + '">' + label + '</text></g>'
const source = '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="180">' +
  '<g transform="translate(20 20) scale(1.25)">' +
  node(3, 'Howard Becker', 20, 20) + node(6, 'Donald Schön', 50, 90) +
  node(10, 'Erin Kissane', 110, 60) + node(14, 'Natural Order', 150, 90) +
  '<path id="trail" d="M20 20 Q40 70 50 90 Q80 55 110 60 T150 90" ' +
  'style="fill:none;stroke:red;stroke-width:5;" marker-end="url(#arrow)"/>' +
  '<path d="M20 20 L50 90" fill="none" stroke="black"/>' +
  '</g></svg>'
const esc = text => text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')

test('preserves the Solo curve through sanitization and draws a new ordered trail', async () => {
  const browser = await chromium.launch({
    executablePath: process.env.HYPERDOC_CHROMIUM,
    headless: true
  })
  try {
    const page = await browser.newPage()
    const storyItem = item => '<section class="fedwiki-inline-svg" data-site="ward.example" ' +
      'data-slug="dewey-alexander-trail" data-item="' + item + '">' +
      '<template>' + esc(source) + '</template></section>'
    await page.setContent('<main>' + storyItem('first') + storyItem('second') + '</main>')
    await page.addScriptTag({path: script})
    await page.evaluate(() => {
      const view = document.querySelector('main')
      window.mountFedwikiSoloTrailStory(view)
      window.mountFedwikiSoloTrailStory(view)
    })

    const item = page.locator('section').first()
    const path = item.locator('path[d^="M20 20 Q"]')
    const paint = await path.evaluate(path => {
      const style = getComputedStyle(path)
      const marker = path.getAttribute('marker-end').slice(5, -1)
      return {
        fill: style.fill, stroke: style.stroke, width: style.strokeWidth,
        marker, hasMarker: path.ownerSVGElement.querySelector('#' + marker) !== null
      }
    })
    assert.deepEqual(paint, {
      fill: 'none', stroke: 'rgb(255, 0, 0)', width: '5px',
      marker: 'fedwiki-solo-arrow-1', hasMarker: true
    })
    assert.equal(await page.locator('section').last().locator('marker[id]').getAttribute('id'),
      'fedwiki-solo-arrow-2')
    assert.equal(await item.locator('path[d="M20 20 L50 90"]').getAttribute('stroke'), 'black')
    assert.equal(await item.getByRole('button', {name: 'Trail', exact: true}).count(), 1)

    await item.getByRole('button', {name: 'Trail', exact: true}).click()
    await item.getByRole('button', {name: 'Finish trail'}).click()
    assert.match(await item.getByRole('status').textContent(), /at least two/)
    const firstStation = item.getByRole('button', {name: 'Howard Becker'}).locator('polygon')
    await firstStation.click({position: {x: 2, y: 2}})
    const point = await item.getByRole('button', {name: 'Donald Schön'}).locator('polygon').boundingBox()
    await page.mouse.move(point.x + point.width / 2, point.y + point.height / 2)
    assert.equal((await item.locator('polyline').getAttribute('points')).split(' ').length, 2)
    for (const name of ['Donald Schön', 'Erin Kissane', 'Natural Order']) {
      await item.getByRole('button', {name, exact: true}).locator('polygon').click({position: {x: 2, y: 2}})
    }
    assert.equal((await item.locator('polyline').getAttribute('points')).split(' ').length, 4)
    await item.getByRole('button', {name: 'Undo station'}).click()
    assert.match(await item.getByRole('status').textContent(), /3 selected/)
    await item.getByRole('button', {name: 'Natural Order'}).press('Enter')
    await item.getByRole('textbox', {name: 'Trail name'}).fill('New Trail')
    await item.getByRole('textbox', {name: 'Trail name'}).press('Enter')
    const aspect = JSON.parse(await item.getByRole('textbox', {name: 'Completed Solo aspect (JSON)'}).inputValue())
    assert.equal(aspect.name, 'New Trail')
    assert.deepEqual(aspect.graph.nodes.map(node => node.props.sourceNode.graphNode), ['3', '6', '10', '14'])
    assert.deepEqual(aspect.graph.nodes[0].props.sourceNode, {
      site: 'ward.example', page: 'dewey-alexander-trail', item: 'first', graphNode: '3'
    })
    assert.deepEqual(aspect.graph.rels.map(rel => [rel.type, rel.from, rel.to]),
      [['Trail', 0, 1], ['Trail', 1, 2], ['Trail', 2, 3]])
    await item.getByRole('button', {name: 'Trail', exact: true}).click()
    await item.getByRole('button', {name: 'Cancel'}).click()
    assert.equal(await item.getByRole('textbox', {name: 'Completed Solo aspect (JSON)'}).inputValue(),
      JSON.stringify(aspect, null, 2))
  } finally {
    await browser.close()
  }
})
