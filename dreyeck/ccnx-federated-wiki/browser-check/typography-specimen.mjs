// A specimen of confusable characters and identifiers, set in the running-text face and in the code face of the Inspector, and the fonts
// Chromium actually used for them (CDP CSS.getPlatformFontsForNode). Fonts differ by machine: the result describes the machine that ran it.
// usage: node typography-specimen.mjs ORIGIN OUTPUT_DIR LABEL    (LABEL 'after' opens the reading first, so that its style sheet is loaded)
import fs from 'node:fs'
import {createRequire} from 'node:module'
const require = createRequire(process.cwd() + '/')
const {chromium} = require('playwright')
const [origin, out, label, extraCss] = process.argv.slice(2); fs.mkdirSync(out,{recursive:true})
const browser = await chromium.launch({headless:true, args:['--no-sandbox']})
const page = await (await browser.newContext({viewport:{width:900,height:500}, deviceScaleFactor:2})).newPage()
await page.goto(origin); await page.waitForLoadState('networkidle').catch(()=>{})
if (label==='after') { const n0 = await page.locator('.inspector-pane').count(); await page.getByText('The CCNx Federated Wiki', {exact:true}).and(page.locator(':visible')).first().click(); await page.waitForFunction(n => document.querySelectorAll('.inspector-pane').length > n, n0); await page.locator('.inspector-pane').last().getByRole('button',{name:'Main page',exact:true}).click(); await page.locator('.ccnx-reading').first().waitFor() }
const strings = ['Il1 O0 rn m', 'IndexedDB', 'ContentObject', 'pageHandler', 'excludes version', 'b5506b1aba3da7761b0f', '/wiki/page/<slug>.json/<version>', '1700000000004']
await page.evaluate(([strings, extraCss]) => {
  const d = document.createElement('div'); d.id='specimen'; d.className='hyperbook-page ccnx-reading'; d.style.cssText='position:fixed;top:0;left:0;background:#fff;z-index:99999;padding:8px;width:880px'
  if (extraCss) { const s=document.createElement('style'); s.textContent=extraCss; document.head.appendChild(s) }
  for (const [tag, label] of [['p','body text'],['code','inline code']]) {
    const row = document.createElement('div'); row.style.margin='6px 0'
    const l = document.createElement('small'); l.textContent = label+': '; row.appendChild(l)
    for (const s of strings) { const e = document.createElement(tag); e.textContent = s; e.style.display='inline-block'; e.style.margin='0 14px 0 0'; row.appendChild(e) }
    d.appendChild(row)
  }
  document.body.appendChild(d)
}, [strings, extraCss || ''])
const cdp = await page.context().newCDPSession(page); await cdp.send('DOM.enable'); await cdp.send('CSS.enable')
const doc = await cdp.send('DOM.getDocument', {depth:-1})
const fonts = {}
for (const sel of ['#specimen p', '#specimen code']) {
  const {nodeId} = await cdp.send('DOM.querySelector', {nodeId: doc.root.nodeId, selector: sel})
  const f = await cdp.send('CSS.getPlatformFontsForNode', {nodeId}); fonts[sel] = f.fonts.map(x => `${x.familyName} (${x.isCustomFont?'custom':'system'}, ${x.glyphCount} glyphs)`)
}
const css = await page.evaluate(() => ({p:getComputedStyle(document.querySelector('#specimen p')).fontFamily + ' ' + getComputedStyle(document.querySelector('#specimen p')).fontSize, code:getComputedStyle(document.querySelector('#specimen code')).fontFamily + ' ' + getComputedStyle(document.querySelector('#specimen code')).fontSize}))
await page.locator('#specimen').screenshot({path:`${out}/${label}-specimen.png`})
fs.writeFileSync(`${out}/${label}-specimen.json`, JSON.stringify({browser:'Chromium '+browser.version(), css, platformFonts:fonts},null,1)); console.log(JSON.stringify({css,fonts},null,1))
await browser.close()
