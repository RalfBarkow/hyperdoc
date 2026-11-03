// A real browser over the served Catalog: the case of Konrad Hinsen's 58a2b2c, from the commit to the decision, by references only, with nothing run.
// node THIS PLAYWRIGHT_CORE_DIRECTORY CHROME_OR_DEFAULT OUTPUT_DIRECTORY (--executable HYPERDOC_CATALOG | --origin http://127.0.0.1:PORT)
// With --origin it uses a Catalog that is already running as the service runs it (no development mode). Read-only: the script clicks references and tabs, never a
// run button, and fails if the page offers one.
// The path (each step opens the next pane from the pane before it):
//   page "Assessing an Upstream Commit" -> the link -> the commit -> the change -> the fork's definition (initialize-fedwiki) -> the ownership judgement
//   -> an ASDF system -> a decision -> a claim.
// It then reads the commit at a narrow width and fails if anything is cut off: a pane that scrolls sideways, or an identifier cut by the page's own style.
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
import {installBoundClicks} from './lib/inspector-ready.mjs'
const [pw,chrome,output,mode,target]=process.argv.slice(2)
assert(output && (mode==='--executable'||mode==='--origin') && target,'usage: PLAYWRIGHT CHROME_OR_DEFAULT OUTPUT (--executable PATH | --origin URL)')
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),'..')
fs.mkdirSync(output,{recursive:true})
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'upstream-assessment-browser-'))
const steps=[],errors=[],external=[],started=new Date().toISOString()
let child=null,origin=target,fd=null
if(mode==='--executable'){
 const sock=net.createServer();await new Promise(r=>sock.listen(0,'127.0.0.1',r));const port=sock.address().port;await new Promise(r=>sock.close(r))
 origin=`http://127.0.0.1:${port}`
 fd=fs.openSync(path.join(output,'catalog.log'),'w')
 child=spawn(target,[String(port)],{cwd:temp,stdio:['ignore',fd,fd],env:{PATH:process.env.PATH,HOME:path.join(temp,'home'),TMPDIR:process.env.TMPDIR||'/tmp',
  HYPERDOC_CATALOG_HOST:'127.0.0.1',HYPERDOC_FEDWIKI_SITE_ROOT:path.join(root,'dreyeck/tests/fixtures/local-fedwiki-view-site')}})
 fs.mkdirSync(path.join(temp,'home'),{recursive:true})
}
let browser,success=false,failure=null
try {
 for(let n=0;n<9000;n++){
  if(child&&child.exitCode!==null)throw Error(fs.readFileSync(path.join(output,'catalog.log'),'utf8').slice(-5000))
  try{if((await fetch(origin)).ok)break}catch{}
  if(n===8999)throw Error('Catalog did not answer')
  await new Promise(r=>setTimeout(r,100))
 }
 const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
 browser=await chromium.launch(chrome==='default'?{headless:true,args:['--no-proxy-server']}:{headless:true,executablePath:chrome,args:['--disable-background-networking','--no-proxy-server']})
 const session=async width=>{
  const context=await browser.newContext({serviceWorkers:'block',viewport:{width,height:1000}})
  await context.route('**/*',r=>{const u=new URL(r.request().url());if(u.origin===origin||u.protocol==='ws:')return r.continue();external.push(u.href);return r.abort()})
  const page=await context.newPage();page.setDefaultTimeout(60000);installBoundClicks(page);page.on('pageerror',e=>errors.push(e.message))
  return page
 }
 const page=await session(1280)
 const panes=()=>page.locator('.inspector-pane')
 const pane=i=>panes().nth(i)
 const count=()=>panes().count()
 // Click TARGET (a locator inside pane I) and wait until the next pane, I+1, exists; return its index.
 const follow=async(i,target)=>{await target.first().click();await page.waitForFunction(n=>document.querySelectorAll('.inspector-pane').length>=n,i+2);await page.waitForTimeout(400);return i+1}
 // A pane is empty until its view is computed (an ASDF system's can take seconds): read it once it has text.
 const textOf=async i=>{for(let k=0;k<200;k++){const x=await pane(i).innerText();if(x.replace(/\s+/g,' ').length>60&&/\n/.test(x.trim())&&x.split('\n').length>6)return x;await page.waitForTimeout(100)}return pane(i).innerText()}
 const has=(text,parts,where)=>{for(const part of parts)assert(text.includes(part),`${where}: missing ${JSON.stringify(part)}; the pane reads: ${text.slice(0,1500)}`)}
 const hasNot=(text,parts,where)=>{for(const part of parts)assert(!text.includes(part),`${where}: must not contain ${JSON.stringify(part)}`)}

 // 1. The page, as a served Catalog shows it.
 await page.goto(origin)
 await page.getByText('Upstream Intake',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByRole('button',{name:'Text pages',exact:true}).first().waitFor()
 await page.getByRole('button',{name:'Text pages',exact:true}).first().click()
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'Assessing an Upstream Commit'}).last().click()
 await page.waitForFunction(()=>[...document.querySelectorAll('.inspector-pane')].some(p=>p.innerText.includes('Five words that are not the same thing')))
 const pageIndex=(await count())-1,pagePane=pane(pageIndex),pageText=await textOf(pageIndex)
 has(pageText,['Five words that are not the same thing','Git fork','Library dependency','Local definition','Dreyeck extension','Code ownership','The case, in five steps','Not run here'],'page')
 has(pageText,['RalfBarkow/hyperdoc#21','not integrated'],'page')
 const markers=await pagePane.locator('[title^="Not run here: no operation contract"]').count()
 assert(markers>=2,`the examples' run buttons are shown as markers (${markers})`)
 const runButtons=(await pagePane.locator('button').allInnerTexts()).filter(t=>/^[▶►▷]/.test(t.trim())||/run/i.test(t.trim()))
 assert.deepEqual(runButtons,[],'a served page offers no run button')
 steps.push(`Catalog → Upstream Intake → Text pages → Assessing an Upstream Commit: the five terms, the case in five steps, ${markers} examples with the marker "Not run here: no operation contract", no run button`)
 await page.screenshot({path:path.join(output,'1-page.png')})

 // 2. The link: navigation, not execution.
 const commit=await follow(pageIndex,pagePane.getByText("Assess 58a2b2c against this checkout's source"))
 let t=await textOf(commit)
 has(t,['58a2b2c66 Catch more name service errors','58a2b2c66f0f5a0900a32910e5991e7d1833d9ed','Changed definitions (1)','changed function:make-fedwiki','the changed text stands in other definitions of the fork',
        'Changed text stands in','function:initialize-fedwiki','hyperbook/fedwiki','Recorded','defer (proposed)','prepare-upstream-contribution (proposed)'],'commit')
 hasNot(t,['replaced'],'commit')
 assert.equal(await pane(commit).locator('table').count(),0,'the commit view has no table')
 steps.push('the link evaluated when the page rendered: the commit pane opens (no run button was clicked; none exists)')
 await page.screenshot({path:path.join(output,'2-commit.png')})

 // 3. The changed definition: the upstream change.
 const change=await follow(commit,pane(commit).getByText('What 58a2b2c66 changed in function:make-fedwiki',{exact:true}))
 t=await textOf(change)
 has(t,['Upstream change to function:make-fedwiki','usocket:ns-host-not-found-error','usocket:ns-error','Handler 1, unchanged','Handler 2, changed','fetch-sitemap'],'upstream change')
 steps.push('commit → the upstream change: the type list before and after, handler 1 unchanged, handler 2 changed')
 await page.screenshot({path:path.join(output,'3-change.png')})

 // 4. The dreyeck counterpart: the fork's definition, as an object with its source and its ASDF system.
 const counterpart=await follow(commit,pane(commit).locator('.ua-id').getByText('function:initialize-fedwiki',{exact:true}))
 t=await textOf(counterpart)
 has(t,['function:initialize-fedwiki','this checkout','hyperbook-fedwiki/fedwiki.lisp','hyperbook/fedwiki','Digest','(defun initialize-fedwiki','usocket:ns-host-not-found-error'],'fork definition')
 steps.push('commit → function:initialize-fedwiki (a reference): file, ASDF system, digest and source of the fork\'s definition, where the changed type list stands')
 await page.screenshot({path:path.join(output,'4-definition.png')})

 // 5. The ownership judgement: derived, stated, proposed; and undecided.
 const ownership=await follow(commit,pane(commit).getByText(/^upstream-owned by the path rule/))
 t=await textOf(ownership)
 has(t,['Ownership of function:make-fedwiki','By the path rule','Stated in this checkout','Proposed elsewhere','Intended owner','Not decided for this definition','docs/hyperdoc-upstream-boundary.md',
        'RalfBarkow/hyperdoc#21','not in force','reusable-extension','pending'],'ownership')
 steps.push('commit → Ownership: ASDF system now, path rule, what this checkout states, what #21 proposes (not in force), and "Not decided for this definition"')
 await page.screenshot({path:path.join(output,'5-ownership.png')})
 const system=await follow(ownership,pane(ownership).getByText('hyperbook/fedwiki',{exact:true}))
 t=await textOf(system)
 has(t,['hyperbook/fedwiki'],'ASDF system')
 steps.push('Ownership → the ASDF system hyperbook/fedwiki (an object of the image): the owner is reachable')

 // 6. The decision, with its evidence by epistemic status.
 const decision=await follow(commit,pane(commit).getByText('prepare-upstream-contribution (proposed)',{exact:true}))
 t=await textOf(decision)
 has(t,['A decision is not its execution','Rationale','Evidence','Required migration','Verification','observed in the source','mechanically derived'],'decision')
 steps.push('commit → the decision prepare-upstream-contribution: rationale, evidence by status, required migration, verification; a proposal, not accepted')
 await page.screenshot({path:path.join(output,'6-decision.png')})
 const claim=await follow(decision,pane(decision).locator('.ua-status').first())
 has(await textOf(claim),['Basis'],'claim')
 steps.push('decision → a claim: its text and its basis')

 // 7. The change view of the case: the open questions, each with its evidence.
 const changeView=await follow(pageIndex===0?commit:commit,pane(commit).getByText('changed function:make-fedwiki',{exact:true}))
 t=await textOf(changeView)
 has(t,['1. What upstream changed','2. Where it stands in the fork now','3. ASDF owner now, and who should own it','4. What may be affected','5. Decision','Open','dreyeck/wiki-link/tests','get-fedwiki'],'change view')
 steps.push('commit → the change: five parts and the list of what is still open')
 await page.screenshot({path:path.join(output,'7-change-view.png'),fullPage:false})

 // 8. Nothing is cut off at a narrow width: the pane does not scroll sideways, the style has no clipping, identifiers are whole.
 const narrow=await session(520)
 await narrow.goto(origin)
 await narrow.getByText('Upstream Intake',{exact:true}).and(narrow.locator(':visible')).first().click()
 await narrow.getByRole('button',{name:'Text pages',exact:true}).first().waitFor()
 await narrow.getByRole('button',{name:'Text pages',exact:true}).first().click()
 await narrow.locator('tr.inspector-inspect:visible').filter({hasText:'Assessing an Upstream Commit'}).last().click()
 await narrow.waitForFunction(()=>[...document.querySelectorAll('.inspector-pane')].some(p=>p.innerText.includes('The case, in five steps')))
 const np=(await narrow.locator('.inspector-pane').count())-1
 await narrow.locator('.inspector-pane').nth(np).getByText("Assess 58a2b2c against this checkout's source").first().click()
 await narrow.waitForFunction(i=>document.querySelectorAll('.inspector-pane').length>=i+2,np)
 await narrow.waitForTimeout(800)
 const measured=await narrow.locator('.inspector-pane').nth(np+1).evaluate(el=>{
  const body=el.querySelector('.inspector-body')||el,ua=el.querySelector('.ua')
  const clipped=[...ua.querySelectorAll('*')].filter(e=>{const s=getComputedStyle(e);return s.textOverflow==='ellipsis'||(s.overflowX==='hidden'&&e.scrollWidth>e.clientWidth+1)||(s.whiteSpace==='nowrap'&&e.scrollWidth>e.clientWidth+1)}).map(e=>e.className||e.tagName)
  const ids=[...ua.querySelectorAll('code,.ua-id')].filter(e=>e.scrollWidth>e.clientWidth+1).map(e=>e.textContent.slice(0,60))
  return {bodyScroll:body.scrollWidth,bodyClient:body.clientWidth,uaScroll:ua.scrollWidth,uaClient:ua.clientWidth,clipped,ids,measure:parseFloat(getComputedStyle(ua).maxWidth)/parseFloat(getComputedStyle(ua).fontSize)}
 })
 assert(measured.bodyScroll<=measured.bodyClient+1,`the pane scrolls sideways at 520px: ${JSON.stringify(measured)}`)
 assert(measured.uaScroll<=measured.uaClient+1,`the reading overflows its container at 520px: ${JSON.stringify(measured)}`)
 assert.deepEqual(measured.clipped,[],'no element clips its text')
 assert.deepEqual(measured.ids,[],'no identifier is wider than its box')
 assert(Math.abs(measured.measure-44)<0.01,`the measure is 44rem: ${measured.measure}`)
 steps.push(`at 520px wide: the commit pane does not scroll sideways (${measured.bodyScroll} <= ${measured.bodyClient}), no element clips its text, no identifier is wider than its box`)
 await narrow.screenshot({path:path.join(output,'8-commit-narrow.png')})

 assert.deepEqual(errors,[],'browser errors');assert.deepEqual(external,[],'external requests')
 success=true
} catch(e) {failure=String(e.stack||e);console.error(failure)}
finally {
 if(browser)await browser.close()
 if(child){child.kill('SIGTERM');for(let n=0;n<150&&child.exitCode===null;n++)await new Promise(r=>setTimeout(r,100));fs.closeSync(fd)}
 fs.writeFileSync(path.join(output,'upstream-assessment-browser.json'),JSON.stringify({kind:'served-Catalog-read-only-case-58a2b2c',startedAtUTC:started,finishedAtUTC:new Date().toISOString(),mode,origin,success,failure,steps,errors,externalRequests:external},null,1)+'\n')
}
if(!success)process.exitCode=1
