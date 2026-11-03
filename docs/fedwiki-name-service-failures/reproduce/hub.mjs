// Visitor path: Catalog → Working on HyperDoc → Text pages → Work Breakdown → From Two Hubs to One Trail → Dewey Alexander Trail.
import {chromium} from '/opt/node-tools/node_modules/playwright/index.mjs'
const port=process.env.PORT, pid=+process.env.CATALOG_PID
const alive=()=>{try{process.kill(pid,0);return true}catch{return false}}
const sleep=ms=>new Promise(r=>setTimeout(r,ms))
for(let n=0;;n++){try{const r=await fetch(`http://127.0.0.1:${port}/`);if(r.ok)break}catch{} if(!alive())throw Error('died while starting'); if(n>6000)throw Error('timeout');await sleep(200)}
console.log('READY')
const browser=await chromium.launch()
const page=await browser.newPage();page.setDefaultTimeout(60000)
const last=()=>page.locator('.inspector-pane').last()
const step=async(label,fn)=>{
  try{await fn()}catch(e){console.log(`STEP-ERROR ${label}: ${e.message.split('\n')[0]}`)}
  await sleep(15000)
  console.log(`AFTER ${label}: catalog ${alive()?'alive':'DEAD'}`)
  return alive()
}
await page.goto(`http://127.0.0.1:${port}`)
await page.getByText('Working on HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
await page.getByRole('button',{name:'Text pages',exact:true}).last().click()
await page.locator('tr.inspector-inspect:visible').filter({hasText:'Work Breakdown'}).last().click()
await page.getByRole('heading',{name:'Work Breakdown',exact:true}).last().waitFor()
console.log('AT Work Breakdown: catalog', alive()?'alive':'DEAD')
const ok=await step('From Two Hubs to One Trail',async()=>{
  await last().getByText('From Two Hubs to One Trail',{exact:true}).first().click()
  await last().getByRole('heading',{name:'From Two Hubs to One Trail',exact:true}).waitFor()
})
if(ok) await step('Dewey Alexander Trail',async()=>{
  await last().getByText('Dewey Alexander Trail',{exact:true}).first().click()
})
if(alive()){
  const r=await fetch(`http://127.0.0.1:${port}/`).catch(e=>e)
  console.log('HTTP after walk:', r.status ?? r.message)
}
await browser.close().catch(()=>{})
