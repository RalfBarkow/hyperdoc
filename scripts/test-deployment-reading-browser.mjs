// Optional independent-browser companion to the primary Lisp contract entry:
//   (asdf:test-system "dreyeck/work/reading/tests")
// Usage: node scripts/test-deployment-reading-browser.mjs \
//   <fresh-sbcl-wrapper> <playwright-core-directory> <chromium-executable> \
//   <disposable-output-directory-outside-the-source-tree>
// The wrapper must load this checkout/dependencies in a fresh runtime, without
// authoring or user init. SERVE-BROWSER-WITNESS uses ordinary CLOG/Inspector APIs.
// Lisp owns object identity, revision provenance and warrants. Here we check
// browser-origin clicks, visible destination headings, cross-book/return routes,
// viewport geometry and isolated browser errors/network. CLOG synthetic-event
// helpers cannot supply the same independent input/viewport guarantee.
// Screenshots are diagnostic captures, not approved visual-regression baselines.
// All generated output stays in the explicitly supplied disposable directory.
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
  const click=async text=>{const count=await page.locator('.inspector-pane').count();await last().getByText(text,{exact:true}).first().click();await page.waitForFunction(c=>document.querySelectorAll('.inspector-pane').length>c,count)}
  const measure=async(name,heading)=>{
   await last().getByRole('heading',{name:heading,exact:true}).waitFor()
   await page.locator('.inspector').evaluate(e=>{e.scrollLeft=e.scrollWidth-e.clientWidth})
   const sizes=await last().locator('.deployment-reading').evaluate(e=>({width:e.clientWidth,scrollWidth:e.scrollWidth,height:e.scrollHeight}))
   assert(sizes.width>200 && sizes.scrollWidth<=sizes.width+1,`${name}: horizontal content overflow ${JSON.stringify(sizes)}`)
   const screenshot=`${width}-${name}.png`;await page.screenshot({path:path.join(output,screenshot)})
   report.cases.push({width,name,contentWidth:sizes.width,scrollWidth:sizes.scrollWidth,screenshot,status:'PASS'})
  }
  await page.getByText('Operational reading',{exact:true}).waitFor()
  await click('the Wiki package and service on wiki.ralfbarkow.ch')
  await measure('ralf-explanation','wiki.ralfbarkow.ch deployment')
  await click('wiki.ralfbarkow.ch');await measure('ralf-target','Wiki deployment target: wiki.ralfbarkow.ch')
  await click('Reported Wiki service');await measure('ralf-service','Reported wiki.service')
  await click('Return to deployment explanation');await click('wiki.ralfbarkow.ch')
  await click('Unresolved Wiki activation');await measure('ralf-target-boundary','Publication is separate from activation')
  await click('Return to deployment explanation');await click('wiki.ralfbarkow.ch')
  await click('Historical deployment observation');await measure('historical-witness','Historical RalfBarkow deployment witness')
  await click('Nix package identity');await measure('package-identity','Reported P41 Wiki package')
  await click('Reported source revision');await measure('revision-identity','Repository-qualified source revision')
  await click('flake.nix');await click('Retained deployment source'); // Evidence locations expose source-object display label.
  await measure('historical-source','flake.nix')
  await click('Return to deployment explanation');await measure('return-to-ralf','wiki.ralfbarkow.ch deployment')
  await click('wiki.ralfbarkow.ch');await click('Newer published Wiki configuration');await measure('declared-package','Newer declared Wiki package choices')
  await click('Return to deployment explanation')
  await click('Reading FedWiki Configuration and Fork Behavior');await last().getByRole('heading',{name:'Reading FedWiki Configuration and Fork Behavior',exact:true}).waitFor()
  await click('HyperDoc and the separate Dreyeck Wiki farm');await measure('dreyeck-explanation','dreyeck.ch deployment')
  await click('dreyeck.ch');await measure('hyperdoc-target','HyperDoc deployment target: dreyeck.ch')
  await click('Separate wildcard Wiki farm target');await measure('wiki-farm-target','Wiki farm deployment target: *.dreyeck.ch')
  await click('Recorded Wiki farm service');await measure('wiki-farm-service','Recorded Node Wiki farm service')
  await click('Return to deployment explanation');await click('wildcard Wiki deployment target')
  await click('Newer published farm configuration');await measure('farm-declaration','Newer declared Wiki package choices')
  await click('Return to deployment explanation');await click('dreyeck.ch')
  await click('Recorded HyperDoc process');await measure('hyperdoc-target-process','Recorded HyperDoc SBCL process')
  await click('Return to deployment explanation');await click('dreyeck.ch')
  await click('Historical HyperDoc activation');await measure('activation-evidence','Recorded update and activation — 3 October')
  await click('Return to deployment explanation');await click('Inspect its unobserved activation');await measure('activation-boundary','Publication is separate from activation')
  await click('Return to deployment explanation');await click('Return to Work Breakdown');await last().getByText('Operational reading',{exact:true}).waitFor()
  await context.close()
 }
 assert.equal(report.externalRequests.length,0);assert.equal(report.errors.length,0);report.status='PASS'
}catch(e){report.status='FAIL';report.error=e.stack;throw e}
finally{if(browser)await browser.close();fs.writeFileSync(stop,'stop');if(child.exitCode===null)await new Promise(r=>{child.once('exit',r);setTimeout(()=>{if(child.exitCode===null)child.kill('SIGTERM');r()},3000)});fs.writeFileSync(path.join(output,'results.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2))}
