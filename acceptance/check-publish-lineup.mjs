// node check-publish-lineup.mjs <offer URL> <private fixture directory> open|conflict|publish
// In conflict mode, send a newline after the operator has edited the target in SLY.
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { createHash } from 'node:crypto'
import { createInterface } from 'node:readline/promises'

const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright')
const [url, root, mode] = process.argv.slice(2)
assert(['open', 'conflict', 'publish'].includes(mode))
const bytes = path => readFileSync(join(root, path))
const read = path => JSON.parse(bytes(path))
const hash = data => createHash('sha256').update(data).digest('hex')
const trace = () => bytes('requests.jsonl').toString().trim().split('\n').map(line => JSON.parse(line))
const browser = await chromium.launch({ executablePath: process.env.CHROME_BIN })
const page = await browser.newPage()
page.setDefaultTimeout(12000)
try {
  const release = read('source/release.json')
  const approved = read('source/pages/' + release.slug)
  const start = trace().length
  const http = await page.goto(url)
  assert.equal(http.status(), 200)
  const offer = page.getByRole('region', { name: 'Publikationsangebot', exact: true })
  const play = offer.getByRole('button', { name: 'Play', exact: true })
  await play.waitFor()
  const facts = await offer.locator('dl dd').allTextContents()
  assert.deepEqual(facts.slice(0, 2), ['manifest-sha256=' + hash(bytes('source/release.json')), release.slug])
  assert.match(facts[2], /^[0-9a-f]{64}$/)
  assert.equal(facts[3], ':PUBLISH-PAGE')
  assert.deepEqual(trace().slice(start), [])
  console.log(JSON.stringify({url, facts, requestsOnOpen: 0}))
  if (mode === 'conflict') {
    const input = createInterface({input:process.stdin,output:process.stdout})
    try { await input.question('Ready for the target edit. Send a newline to click Play.\n') }
    finally {input.close()}
  }
  if (mode !== 'open') {
    const offset = trace().length
    await play.click()
    const result = page.getByRole('region', { name: 'Ergebnis', exact: true })
    await result.waitFor()
    const fields = await result.locator('dl dd').allTextContents()
    const [id,status,puts,next,expected,actual] = fields
    assert.match(id,/^lauf-[0-9a-f]+$/)
    assert.equal(expected,facts[2])
    assert.notEqual(actual, expected)
    const wire = trace().slice(offset)
    const writes = wire.filter(row => row.method === 'PUT')
    assert.equal(writes.length,mode === 'conflict' ? 0 : 1)
    assert.equal(Number(puts), writes.length)
    const httpRows = await result.locator('li code').allTextContents()
    assert.deepEqual(httpRows,wire.map(r => r.method+' '+r.path+' → HTTP '+r.status))
    const json = JSON.parse(await result.locator('pre').innerText())
    assert.deepEqual(json,read('data/pages/'+release.slug))
    assert.equal(wire.at(-1).path,'/'+release.slug+'.json')
    assert.equal(wire.at(-1).status,200)
    const fact = await result.locator('h3 + p code').innerText()
    assert(fact.includes(facts[0]) && fact.includes('revision='+actual))
    if (mode === 'conflict') {
      assert.equal(status,':RECONCILE-TARGET')
      assert.equal(next,':RECONCILE-TARGET')
      assert(fact.startsWith(':TARGET-CONFLICT '))
      assert.equal(json.journal.at(-1).type,'edit')
    } else {
      assert.equal(status,':PUBLISHED')
      assert.equal(next,':VERIFY-PUBLICATION')
      assert(fact.startsWith(':PUBLIC-PAGE-VERIFIED '))
      assert.deepEqual(writes[0].action.forkPage,approved)
      assert.equal(writes[0].status,200)
      assert.deepEqual(json,{...approved,journal:[...approved.journal,
        {type:'fork',site:release.sourceSite,date:release.forkDate,releaseSha256:facts[0].split('=')[1]}]})
    }
    const runURL = await result.getByRole('link',{name:id}).getAttribute('href')
    await result.getByText('Recent Changes',{exact:true}).click()
    const history = page.getByRole('region',{name:'Recent Changes',exact:true})
    const link = history.getByText(id,{exact:true})
    await link.waitFor()
    await link.click()
    const reopened = page.getByRole('region',{name:'Ergebnis',exact:true}).last()
    await reopened.waitFor()
    assert.equal(await reopened.getByRole('link',{name:id}).getAttribute('href'),runURL)
    assert.deepEqual(trace().slice(offset),wire)
    console.log(JSON.stringify({url,runURL,id,status,puts,next,expected,actual,fact,httpRows,json,recentChanges:id}))
  }
} catch (error) {
  console.error((await page.locator('body').innerText()).slice(-3500))
  throw error
} finally {
  await browser.close()
}
