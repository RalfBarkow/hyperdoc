// Real Chromium, two explicitly separate surfaces:
// node check.mjs --fixture OUT [--without-css] : static typography, no Lisp or Inspector proof
// node check.mjs --catalog ORIGIN OUT : real existing Catalog, Content/next-page/object navigation
// playwright or playwright-core must be installed; CHROMIUM selects the executable.
import fs from 'node:fs'
import {createRequire} from 'node:module'
import {fileURLToPath} from 'node:url'
const require = createRequire(process.cwd() + '/')
let chromium
try { ({chromium} = require('playwright')) } catch { ({chromium} = require('playwright-core')) }
const [mode, arg, destination] = process.argv.slice(2)
if (!['--fixture', '--catalog'].includes(mode)) throw Error('Use --fixture OUT or --catalog ORIGIN OUT')
const fixture = mode === '--fixture', origin = fixture ? null : arg, out = fixture ? arg : destination
fs.mkdirSync(out, {recursive:true})
const titles = ['Planning Remote Control for the Zettelkasten App with SHOP3', 'Model Authority and the Control Surface',
  'How SHOP3 Reads the Architecture Task', 'Case C - Two Alternative Plan Trees',
  'Cases D and E - When Planning Refuses', 'Evidence and Open Acceptance']
const pages = fileURLToPath(new URL('../../pages/remote-control-planning/', import.meta.url))
const css = fs.readFileSync(new URL('../assets/remote-control-reading/css/reading.css', import.meta.url), 'utf8')
const browser = await chromium.launch({headless:true, executablePath:process.env.CHROMIUM || '/usr/bin/chromium', args:['--no-sandbox']})
const result = {surface: fixture ? 'static typography fixture; references not executed' : 'live Catalog', browser:browser.version(),
  cssIncluded: !process.argv.includes('--without-css'), pages:[], assertions:[], pageErrors:[]}
const check = (name, ok, page) => result.assertions.push({name,ok,page})
try {
  for (const [widthName, viewport] of [['wide',{width:1500,height:1000}], ['narrow',{width:520,height:1000}]]) {
    const context = await browser.newContext({viewport, serviceWorkers:'block'})
    const page = await context.newPage(); page.setDefaultTimeout(15000)
    page.on('pageerror', e => result.pageErrors.push(e.message))
    if (!fixture) {
      await page.goto(origin)
      await page.getByText(titles[0], {exact:true}).and(page.locator(':visible')).first().click()
      await page.locator('.inspector-pane').last().getByRole('button', {name:'Text pages',exact:true}).click()
      await page.locator('tr.inspector-inspect:visible').filter({hasText:titles[0]}).last().click()
    }
    for (const [index,title] of titles.entries()) {
      const key = `${index+1}-${widthName}`
      if (fixture) {
        // Deliberately adversarial table baseline resembles the Inspector's nowrap.
        // The wrappers reproduce only a column's geometry, not an Inspector runtime.
        await page.setContent(`<style>body{font:16px Arial,sans-serif;color:#222}.inspector-body{box-sizing:border-box;padding:12px;width:${widthName==='wide'?700:360}px}.inspector-table{white-space:nowrap} h1{font-size:1.3em}h2{font-size:1.2em}</style>
          ${result.cssIncluded ? `<style>${css}</style>` : ''}<div class="inspector-pane"><div class="inspector-body"><div class="hyperbook-page">${fs.readFileSync(pages+title+'.html','utf8')}</div></div></div>`)
        // Stand-in markup only for CSS measurement; no callback or expression evaluation.
        await page.locator('in-package').evaluateAll(es => es.forEach(e=>e.remove()))
        await page.locator('a[expr],a[page]').evaluateAll(es => es.forEach(e=>{
          const s=document.createElement('span'); s.className='hyperbook-reference'
          const a=document.createElement('span'); a.className='inspector-inspect'; a.textContent=e.textContent
          s.append(a); e.replaceWith(s)
        }))
      }
      const pane = page.locator('.inspector-pane').nth((await page.locator('.inspector-pane').count())-1)
      await pane.getByRole('heading',{name:title,exact:true}).waitFor()
      if (!fixture) {
        check('Content is active on opening', (await pane.locator('button.active').first().innerText()).trim()==='Content', key)
        await page.waitForFunction(()=>[...document.styleSheets].some(s=>(s.href||'').includes('/remote-control-reading/css/reading.css')))
      }
      const m = await pane.evaluate(p => {
        const body=p.querySelector('.inspector-body'), root=p.querySelector('.remote-control-reading')
        const size=e=>parseFloat(getComputedStyle(e).fontSize), font=size(root)
        return {language:root.lang,bodyWidth:body.clientWidth, scrollWidth:body.scrollWidth, font,
          leading:parseFloat(getComputedStyle(root).lineHeight)/font,
          maxTextEm:Math.max(...[...root.querySelectorAll('p,ul,ol')].filter(e=>!e.closest('table')).map(e=>e.getBoundingClientRect().width/font)),
          tableEscapes:[...root.querySelectorAll('table')].filter(t=>t.getBoundingClientRect().right>body.getBoundingClientRect().right+1 && !t.closest('.table-scroll')).length,
          tableWidths:[...root.querySelectorAll('table')].map(t=>Math.round(t.getBoundingClientRect().width)),
          headings:[size(root.querySelector('h1')),size(root.querySelector('h2'))],
          codeRatio:Math.min(1,...[...root.querySelectorAll('code')].map(c=>size(c)/font)),
          refVisible:[...root.querySelectorAll('.hyperbook-reference .inspector-inspect')].every(e=>getComputedStyle(e).textDecorationLine.includes('underline') && getComputedStyle(e).color!==getComputedStyle(root).color)}
      })
      result.pages.push({key,title,...m})
      check('reading language is English',m.language==='en',key)
      check('column has no horizontal overflow',m.scrollWidth<=m.bodyWidth+1,key)
      check('text measure at most 38em',m.maxTextEm<=38.1,key)
      check('leading at least 1.5',m.leading>=1.5,key)
      check('heading hierarchy',m.headings[0]-m.headings[1]>=2 && m.headings[1]>m.font,key)
      check('inline code at least 85% body size',m.codeRatio>=.85,key)
      check('tables contained',m.tableEscapes===0,key)
      check('object/page references visibly marked',m.refVisible,key)
      await pane.screenshot({path:`${out}/${key}.png`})
      if (!fixture) {
        // Every EXPR link on this page must really open its object, without REPL work.
        const expressions=pane.locator('.hyperbook-reference[title^="("] .inspector-inspect')
        const n=await expressions.count()
        for(let j=0;j<n;j++) {
          const before=await page.locator('.inspector-pane').count()
          await expressions.nth(j).click()
          await page.waitForFunction(n=>document.querySelectorAll('.inspector-pane').length>n,before)
          check('object reference opens a pane',true,key)
        }
        if(index<titles.length-1) {
          await pane.locator('.hyperbook-reference').filter({hasText:`Next: ${titles[index+1]}`}).locator('.inspector-inspect').click()
        }
      }
    }
    await context.close()
  }
  check('no browser page errors',result.pageErrors.length===0,'all')
} finally {
  fs.writeFileSync(`${out}/metrics.json`,JSON.stringify(result,null,2)+'\n')
  await browser.close()
}
const failures=result.assertions.filter(a=>!a.ok)
console.log(JSON.stringify({surface:result.surface,browser:result.browser,pages:result.pages.length,assertions:result.assertions.length,failures},null,2))
if(failures.length) process.exitCode=1
