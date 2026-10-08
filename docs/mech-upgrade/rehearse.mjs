// Browser-only Mech asset overlay; no server files or original Code items change.
// Usage: OUTPUT_DIRECTORY ASSET_DIRECTORY_OR_DASH [URL] [solo]
// Install playwright-core/Chrome or set TRAILS_PLAYWRIGHT_MODULE to its absolute entry.
import fs from 'node:fs'; import path from 'node:path'; import crypto from 'node:crypto'; import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.TRAILS_PLAYWRIGHT_MODULE || 'playwright-core');
const [out,assetDir,url='https://hyperdoc.dreyeck.ch/view/welcome-visitors/view/trails-rendered',solo='no']=process.argv.slice(2);
if(!out||!assetDir)throw Error('Usage: OUTPUT ASSET_DIRECTORY_OR_DASH [URL] [solo]');
fs.mkdirSync(out,{recursive:true});
const e={started:new Date().toISOString(),kind:assetDir==='-'?'original-browser':'isolated-browser-asset-overlay',assetDir,url,requests:[],responses:[],console:[],pageErrors:[],failedRequests:[],overrides:[],sources:[],outcome:'not-run'};
const browser=await chromium.launch({headless:true,channel:'chrome'});e.browser=browser.version();
const context=await browser.newContext(); const pending=[];
if(assetDir!=='-')await context.route('**/plugins/mech/**',async route=>{
 const name=new URL(route.request().url()).pathname.split('/plugins/mech/')[1]; const file=path.join(assetDir,name);
 if(fs.existsSync(file)&&fs.statSync(file).isFile()){
  const body=fs.readFileSync(file);e.overrides.push({url:route.request().url(),file,sha256:crypto.createHash('sha256').update(body).digest('hex')});
  await route.fulfill({status:200,contentType:name.endsWith('.css')?'text/css':'text/javascript',body});
 }else await route.continue();
});
// Observer only: clone a batch before the original Solo receiver mutates its clone.
await context.addInitScript(()=>{window.__mechUpgradeBatches=[];window.addEventListener('message',event=>{
 if(event.data?.type==='batch')window.__mechUpgradeBatches.push({origin:event.origin,sourceIsOpener:event.source===window.opener,data:JSON.parse(JSON.stringify(event.data))});
});});
function observe(p){
 p.on('console',m=>e.console.push({page:p.url(),type:m.type(),text:m.text(),location:m.location()}));
 p.on('pageerror',err=>e.pageErrors.push({page:p.url(),message:err.message,stack:err.stack}));
 p.on('request',r=>e.requests.push({url:r.url(),method:r.method(),type:r.resourceType()}));
 p.on('requestfailed',r=>e.failedRequests.push({url:r.url(),failure:r.failure()}));
 p.on('response',r=>{const rec={url:r.url(),status:r.status()};e.responses.push(rec);if(/\/plugins\/(mech|code|solo)\/|wardcunningham.github.io\/graph\//.test(r.url()))pending.push((async()=>{try{const b=await r.body();e.sources.push({url:r.url(),status:r.status(),sha256:crypto.createHash('sha256').update(b).digest('hex'),bytes:b.length,header: b.toString('utf8',0,200)});}catch(err){rec.bodyError=err.message}})());});
}
context.on('page',observe);const page=await context.newPage();
try {
 await page.goto(url,{waitUntil:'networkidle',timeout:45000});
 const mech=page.locator('#trails-rendered .item.mech');
 await mech.getByRole('button',{name:'▶',exact:true}).first().waitFor({timeout:15000});
 e.before=await page.evaluate(()=>({url:location.href,owner:window.isOwner,build:globalThis.__MECH_BUILD__||null,
  lineup:[...document.querySelectorAll('.page')].map(el=>{const key=$(el).data('key'),obj=wiki.lineup.atKey(key);return {slug:el.id,key,remote:obj.isRemote()}})}));
 await mech.getByRole('button',{name:'▶',exact:true}).first().click();
 for(let i=0;i<80;i++){
  e.after=await mech.innerText();
  if(/CODE trails.*(?:✖︎|⇒)/.test(e.after)||e.pageErrors.length)break;
  await new Promise(r=>setTimeout(r,100));
 }
 const trouble=mech.getByRole('button',{name:'✖︎',exact:true}).first();
 if(await trouble.count()){
  await trouble.click();e.diagnostic=await mech.getByRole('button',{name:'✖︎',exact:true}).first().evaluate(b=>b.parentElement.nextElementSibling?.innerText);e.outcome='trouble';
 }else e.outcome=/CODE trails ⇒ 2 aspects/.test(e.after)?'two-aspects':e.pageErrors.length?'exception':'no-status';
 if(e.outcome==='two-aspects'&&solo==='solo'){
  const popupPromise=page.waitForEvent('popup',{timeout:15000});
  await mech.getByRole('button',{name:'▶',exact:true}).nth(1).click();
  const popup=await popupPromise;await popup.waitForLoadState('domcontentloaded');
  await popup.waitForFunction(()=>window.__mechUpgradeBatches.length>0,{},{timeout:20000});
  e.batch=await popup.evaluate(()=>window.__mechUpgradeBatches[0]);
  e.controls=await popup.locator('input[type=checkbox]').evaluateAll(xs=>xs.map(x=>({id:x.id,value:x.value})));
  await popup.locator('#n0').check();
  await popup.waitForFunction(()=>document.querySelectorAll('#target svg g.node').length===3&&document.querySelectorAll('#target svg g.edge').length===2,{},{timeout:30000});
  await popup.locator('#n1').check();
  await popup.waitForFunction(()=>document.querySelectorAll('#target svg g.node').length===5&&document.querySelectorAll('#target svg g.edge').length===4,{},{timeout:30000});
  e.render=await popup.evaluate(()=>({dot:window.dot,nodes:[...document.querySelectorAll('#target svg g.node')].map(n=>({title:n.querySelector('title')?.textContent,label:[...n.querySelectorAll('text')].map(t=>t.textContent).join('\n')})),edges:[...document.querySelectorAll('#target svg g.edge')].map(n=>({title:n.querySelector('title')?.textContent,label:[...n.querySelectorAll('text')].map(t=>t.textContent).join('\n')}))}));
 }
 e.dom=await mech.innerHTML();await page.screenshot({path:path.join(out,'after.png'),fullPage:true});
}catch(err){e.automationError={message:err.message,stack:err.stack};e.outcome='automation-failed';e.failedDom=await page.locator('body').innerText().catch(()=>null);}
finally {await Promise.allSettled(pending);e.finished=new Date().toISOString();fs.writeFileSync(path.join(out,'evidence.json'),JSON.stringify(e,null,2)+'\n');await browser.close();}
console.log(JSON.stringify({kind:e.kind,outcome:e.outcome,diagnostic:e.diagnostic,after:e.after,pageErrors:e.pageErrors,automationError:e.automationError,batchSources:e.batch?.data.sources.length,renderNodes:e.render?.nodes.length,renderEdges:e.render?.edges.length}));
