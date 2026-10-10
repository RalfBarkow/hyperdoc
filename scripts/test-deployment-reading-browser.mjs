// Real ordinary CLOG Inspector in a disposable fresh Lisp process. No production URL.
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,playwrightPath,browserPath,output]=process.argv.slice(2)
if(!output)throw Error('Usage: LISP_WRAPPER PLAYWRIGHT_CORE BROWSER OUTPUT_DIRECTORY')
const {chromium}=await import(pathToFileURL(path.join(playwrightPath,'index.mjs')))
const work=fs.mkdtempSync(path.join(os.tmpdir(),'deployment-reader-browser-'));fs.mkdirSync(output,{recursive:true})
const listener=net.createServer();await new Promise(r=>listener.listen(0,'127.0.0.1',r));const port=listener.address().port;await new Promise(r=>listener.close(r))
const stop=path.join(work,'stop');const script=path.join(work,'witness.lisp')
fs.writeFileSync(script,`(require :asdf)\n(asdf:load-system "dreyeck/work/reading/tests")\n(dreyeck/work/deployment-inspection/tests:serve-browser-witness ${port} #p"${stop}")\n`)
const log=fs.openSync(path.join(output,'lisp.log'),'w');const child=spawn(lisp,['--load',script],{stdio:['ignore',log,log]})
const report={kind:'Fresh ordinary Inspector browser reader/layout witness',browser:null,origin:`http://127.0.0.1:${port}`,cases:[],errors:[],externalRequests:[],productionAccess:false,sourceWrites:false}
let browser
try {
 for(let i=0;i<300;i++){if(child.exitCode!==null)throw Error(fs.readFileSync(path.join(output,'lisp.log'),'utf8').slice(-3000));try{if((await fetch(report.origin)).ok)break}catch{};await new Promise(r=>setTimeout(r,100))}
 browser=await chromium.launch({headless:true,executablePath:browserPath,args:['--no-proxy-server']});report.browser=browser.version()
 for(const width of [1440,380]){
  const context=await browser.newContext({viewport:{width,height:1000},serviceWorkers:'block'})
  await context.route('**/*',route=>{const url=new URL(route.request().url());if(url.origin===report.origin)return route.continue();report.externalRequests.push(url.href);return route.abort()})
  const page=await context.newPage();page.on('pageerror',e=>report.errors.push(e.message));await page.goto(report.origin)
  const last=()=>page.locator('.inspector-pane').last()
  const click=async text=>{const count=await page.locator('.inspector-pane').count();await last().getByText(text,{exact:true}).first().click();await page.waitForFunction(c=>document.querySelectorAll('.inspector-pane').length>c,count);await page.waitForTimeout(120)}
  const measure=async(name,expected)=>{
   await last().locator('.deployment-reading').waitFor();assert((await last().innerText()).includes(expected))
   await page.locator('.inspector').evaluate(e=>{e.scrollLeft=e.scrollWidth-e.clientWidth})
   const sizes=await last().locator('.deployment-reading').evaluate(e=>({width:e.clientWidth,scrollWidth:e.scrollWidth,height:e.scrollHeight,text:e.textContent}))
   assert(sizes.width>200 && sizes.scrollWidth<=sizes.width+1,`${name}: horizontal content overflow ${JSON.stringify(sizes)}`)
   const screenshot=`${width}-${name}.png`;await page.screenshot({path:path.join(output,screenshot)})
   report.cases.push({width,name,contentWidth:sizes.width,scrollWidth:sizes.scrollWidth,screenshot,status:'PASS'})
  }
  await page.getByText('Operational reading',{exact:true}).waitFor()
  await click('the Wiki package and service on wiki.ralfbarkow.ch')
  await measure('ralf-explanation','What was running on wiki.ralfbarkow.ch')
  await click('Inspect the historical deployment witness');await measure('historical-witness','capture time was supplied')
  await click('Nix package identity');await measure('package-identity','immutable Nix store path')
  await click('Reported source revision');await measure('revision-identity','b42eb888d6e5d59803667c6320e0779523fc265c')
  await click('flake.nix');await click('Retained deployment source'); // Evidence locations expose source-object display label.
  await measure('historical-source','Retained exact source bytes')
  await click('Return to deployment explanation');await measure('return-to-ralf','What was running')
  await click('Compare the newer declared configuration');await measure('declared-package','not evidence of host activation')
  await click('Return to deployment explanation')
  await click('Reading FedWiki Configuration and Fork Behavior');await last().getByText('A Federated Wiki installation',{exact:false}).first().waitFor()
  await click('HyperDoc and the separate Dreyeck Wiki farm');await measure('dreyeck-explanation','Which applications serve dreyeck.ch')
  await click('Inspect the two operations and their result');await measure('activation-evidence','commands are recorded evidence')
  await click('Return to deployment explanation');await click('Inspect its unobserved activation');await measure('activation-boundary','No service update')
  await click('Return to deployment explanation');await click('Return to Work Breakdown');await last().getByText('Operational reading',{exact:true}).waitFor()
  await context.close()
 }
 assert.equal(report.externalRequests.length,0);assert.equal(report.errors.length,0);report.status='PASS'
}catch(e){report.status='FAIL';report.error=e.stack;throw e}
finally{if(browser)await browser.close();fs.writeFileSync(stop,'stop');if(child.exitCode===null)await new Promise(r=>{child.once('exit',r);setTimeout(()=>{if(child.exitCode===null)child.kill('SIGTERM');r()},3000)});fs.writeFileSync(path.join(output,'results.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2))}
