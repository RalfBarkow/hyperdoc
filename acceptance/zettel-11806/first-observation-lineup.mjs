// node first-observation-lineup.mjs <offer URL> <private fixture directory> reconcile|publish|conflict|repeat|before
// Browser check of one lineup offer for the four review cases of Zettel 11806.
// reconcile: the offer proposes :RECONCILE-TARGET and has no Play. The other modes click Play.
// before: publish at the unchanged PR head, whose offer has no decision row.
// Z11806_SCREENSHOTS=<directory> saves the offer, the result and the reopened Recent Changes entry.
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { createHash } from 'node:crypto'

const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright')
const [url, root, mode] = process.argv.slice(2)
assert(['reconcile', 'publish', 'conflict', 'repeat', 'before'].includes(mode))
const publishing = mode === 'publish' || mode === 'before'
const bytes = path => readFileSync(join(root, path))
const read = path => JSON.parse(bytes(path))
const hash = data => createHash('sha256').update(data).digest('hex')
const trace = () => bytes('requests.jsonl').toString().trim().split('\n').map(line => JSON.parse(line))
const browser = await chromium.launch({ executablePath: process.env.CHROME_BIN })
const shots = process.env.Z11806_SCREENSHOTS
const page = await browser.newPage({ deviceScaleFactor: shots ? 2 : 1 })
const shot = async name => { if (shots) await page.screenshot({ path: join(shots, name + '.png'), fullPage: true }) }
page.setDefaultTimeout(12000)
try {
  const release = read('source/release.json')
  const approved = read('source/pages/' + release.slug)
  const start = trace().length
  assert.equal((await page.goto(url)).status(), 200)
  const offer = page.getByRole('region', { name: 'Publikationsangebot', exact: true })
  await offer.waitFor()
  const facts = await offer.locator('dl dd').allTextContents()
  assert.deepEqual(facts.slice(0, 2), ['manifest-sha256=' + hash(bytes('source/release.json')), release.slug])
  assert.match(facts[2], /^[0-9a-f]{64}$/)
  const play = offer.getByRole('button', { name: 'Play', exact: true })
  await shot(mode + '-' + url.split('/').at(-1))
  assert.deepEqual(trace().slice(start), [])
  if (mode === 'reconcile') {
    assert.equal(facts[3], ':RECONCILE-TARGET')
    assert.equal(facts[4], 'keine')
    assert.equal(await play.count(), 0)
    assert.deepEqual(trace().slice(start), [])
    console.log(JSON.stringify({ url, mode, facts, playButtons: 0, requests: 0 }))
  } else {
    assert.equal(facts[3], ':PUBLISH-PAGE')
    if (mode === 'before') assert.equal(facts.length, 4)
    else assert.equal(facts[4], mode === 'repeat' ? 'keine' : 'für genau diese Zielrevision erteilt')
    const offset = trace().length
    await play.click()
    const result = page.getByRole('region', { name: 'Ergebnis', exact: true })
    await result.waitFor()
    const [id, status, puts, next, expected, actual] = await result.locator('dl dd').allTextContents()
    assert.match(id, /^lauf-[0-9a-f]+$/)
    assert.equal(expected, facts[2])
    const wire = trace().slice(offset)
    const writes = wire.filter(row => row.method === 'PUT')
    assert.equal(writes.length, publishing ? 1 : 0)
    assert.equal(Number(puts), writes.length)
    assert.deepEqual(await result.locator('li code').allTextContents(),
                     wire.map(r => r.method + ' ' + r.path + ' → HTTP ' + r.status))
    const json = JSON.parse(await result.locator('pre').innerText())
    assert.deepEqual(json, read('data/pages/' + release.slug))
    const fact = await result.locator('h3 + p code').innerText()
    assert(fact.includes(facts[0]) && fact.includes('revision=' + actual))
    const fork = { type: 'fork', site: release.sourceSite, date: release.forkDate, releaseSha256: facts[0].split('=')[1] }
    if (mode === 'conflict') {
      assert.equal(status, ':RECONCILE-TARGET')
      assert.equal(next, ':RECONCILE-TARGET')
      assert.notEqual(actual, expected)
      assert(fact.startsWith(':TARGET-CONFLICT '))
    } else {
      assert.equal(status, publishing ? ':PUBLISHED' : ':ALREADY-PUBLISHED')
      assert.equal(next, ':VERIFY-PUBLICATION')
      assert(fact.startsWith(':PUBLIC-PAGE-VERIFIED '))
      assert.deepEqual(json, { ...approved, journal: [...approved.journal, fork] })
      if (publishing) {
        assert.notEqual(actual, expected)
        assert.deepEqual(writes[0].action.forkPage, approved)
        assert.equal(writes[0].action.releaseSha256, fork.releaseSha256)
        assert.equal(writes[0].status, 200)
      } else assert.equal(actual, expected)
    }
    await shot(mode + '-' + id)
    const runURL = await result.getByRole('link', { name: id }).getAttribute('href')
    await result.getByText('Recent Changes', { exact: true }).click()
    const history = page.getByRole('region', { name: 'Recent Changes', exact: true })
    const entry = history.locator('li', { hasText: id })
    await entry.waitFor()
    const line = await entry.innerText()
    await history.getByText(id, { exact: true }).click()
    const reopened = page.getByRole('region', { name: 'Ergebnis', exact: true }).last()
    await reopened.waitFor()
    assert.equal(await reopened.getByRole('link', { name: id }).getAttribute('href'), runURL)
    await shot(mode + '-' + id + '-recent-changes')
    assert.deepEqual(trace().slice(offset), wire)
    console.log(JSON.stringify({ url, mode, facts, runURL, id, status, puts, next, expected, actual, fact,
                                 http: wire.map(r => r.method + ' ' + r.path + ' ' + r.status), recentChanges: line }))
  }
} catch (error) {
  console.error((await page.locator('body').innerText()).slice(-3500))
  throw error
} finally {
  await browser.close()
}
