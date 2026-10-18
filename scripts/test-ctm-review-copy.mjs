// The review start of scripts/serve-ctm-page-authoring.lisp (HYPERDOC_CTM_REVIEW_COPY=1) in a freshly started Catalog, and the start as it was.
//   Review mode: a temporary TEST COPY of the two retained pages is the site root; the start prints the mode, the site root and the commit; the path
//   Work Breakdown → Topicmap Interaction Documentation → DITA Story Item → DITA topic → the Lisp and TMDM objects leads to the objects, not only to links;
//   stopping the Catalog removes the copy. Nothing is read from or written to a wiki directory.
//   Plain mode: HYPERDOC_FEDWIKI_SITE_ROOT is read as given (here a temporary directory), no copy is made, the DITA page is not there.
//   Both set: refused.
// node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT TOPIC_MAPS_ROOT
import {installBoundClicks} from './lib/inspector-ready.mjs'
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import crypto from 'node:crypto'
import assert from 'node:assert/strict'
import {spawn,execFileSync} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,pw,chrome,output,topicMaps]=process.argv.slice(2)
if(!topicMaps)throw Error('LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT TOPIC_MAPS_ROOT required')
fs.mkdirSync(output,{recursive:true})
const repo=path.resolve(path.dirname(new URL(import.meta.url).pathname),'..')
const sha=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex')
const freePort=()=>new Promise(r=>{const s=net.createServer();s.listen(0,'127.0.0.1',()=>{const p=s.address().port;s.close(()=>r(p))})})
const retained={'ctm-and-tmdm-in-hyperdoc':path.join(repo,'dreyeck/work/ctm-page-evidence/site/pages/ctm-and-tmdm-in-hyperdoc'),
 'topicmap-inspection-dita':path.join(repo,'dreyeck/work/topicmap-inspection-docs/site/pages/topicmap-inspection-dita')}
const retainedBefore=Object.fromEntries(Object.entries(retained).map(([k,f])=>[k,sha(f)]))
const start=async(env,name)=>{
 const log=path.join(output,name+'.log'),fd=fs.openSync(log,'w')
 const child=spawn(lisp,['--load',path.join(repo,'scripts/serve-ctm-page-authoring.lisp')],{cwd:repo,stdio:['ignore',fd,fd],env:{...process.env,TOPIC_MAPS_ROOT:topicMaps,...env}})
 const text=()=>fs.readFileSync(log,'utf8')
 return {child,text,log}}
const waitFor=async(run,pattern,ms=600000)=>{for(let n=0;n<ms/100;n++){if(pattern.test(run.text()))return;if(run.child.exitCode!==null)throw Error(run.text().slice(-3000));await new Promise(r=>setTimeout(r,100))};throw Error('timeout: '+pattern)}
const stopAndWait=async run=>{run.child.kill('SIGTERM');await new Promise(r=>{if(run.child.exitCode!==null)r();else{run.child.once('exit',r);setTimeout(()=>{run.child.kill('SIGKILL');r()},30000).unref()}})}
const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
const browser=await chromium.launch({headless:true,executablePath:chrome})
const steps=[];const readiness={}
let reviewRun=null,plainRun=null,siteRoot=null,plainRoot=null
try{
 // 1. Both set: refused, and nothing is served.
 const both=await start({HYPERDOC_CTM_REVIEW_COPY:'1',HYPERDOC_FEDWIKI_SITE_ROOT:os.tmpdir(),HYPERDOC_CTM_PORT:String(await freePort())},'both')
 await new Promise(r=>both.child.once('exit',r))
 assert.notEqual(both.child.exitCode,0);assert(/do not also set HYPERDOC_FEDWIKI_SITE_ROOT/.test(both.text()),both.text().slice(-800))
 steps.push('review copy and a site root together: refused')

 // 2. The review mode.
 const port=await freePort()
 reviewRun=await start({HYPERDOC_CTM_REVIEW_COPY:'1',HYPERDOC_CTM_PORT:String(port)},'review')
 await waitFor(reviewRun,/Read the DITA topics: /)
 const out=reviewRun.text()
 assert(/REVIEW-MODE: on: a temporary TEST COPY/.test(out),out.slice(-1500))
 siteRoot=out.match(/SITE-ROOT: (\S+)/)[1]
 const commit=out.match(/HYPERDOC-COMMIT: ([0-9a-f]{7,})/)[1]
 assert.equal(commit,execFileSync('git',['-C',repo,'rev-parse','--short','HEAD']).toString().trim().slice(0,commit.length))
 assert(siteRoot.includes('TEST-COPY'),siteRoot);assert(!siteRoot.includes('/.wiki'),siteRoot)
 assert(fs.existsSync(path.join(siteRoot,'THIS-IS-A-TEST-COPY.txt')),'the copy is marked')
 assert.deepEqual(fs.readdirSync(path.join(siteRoot,'pages')).sort(),['ctm-and-tmdm-in-hyperdoc','topicmap-inspection-dita'])
 for(const [slug,file] of Object.entries(retained))assert.equal(sha(path.join(siteRoot,'pages',slug)),sha(file),slug+' is the repository file')
 const copyBefore=Object.fromEntries(Object.keys(retained).map(k=>[k,sha(path.join(siteRoot,'pages',k))]))
 steps.push('review start prints REVIEW-MODE on, SITE-ROOT (a TEST-COPY directory) and HYPERDOC-COMMIT '+commit)

 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(60000);installBoundClicks(page)
 const errors=[];page.on('pageerror',e=>errors.push(e.message))
 const panes=()=>page.locator('.inspector-pane')
 const titleOf=async pane=>(await pane.locator('.inspector-title').first().innerText()).replace(/\s+/g,' ')
 const address=title=>(title.match(/\{([0-9A-F]+)\}/)||[])[1]
 // The page of the review copy is served by /view as well.
 const view=await page.goto(`http://127.0.0.1:${port}/view/topicmap-inspection-dita`);assert.equal(view.status(),200)
 await page.goto(`http://127.0.0.1:${port}`)
 await page.getByText('Working on HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByRole('button',{name:'Text pages',exact:true}).last().click()
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'Work Breakdown'}).last().click()
 await page.locator('.inspector-pane').last().getByRole('heading',{name:'Work Breakdown',exact:true}).waitFor()
 const wb=await panes().count()-1
 // Work Breakdown → the Work item
 await panes().nth(wb).getByText('Document the Topicmap Interaction in DITA',{exact:true}).first().click()
 const work=panes().nth(wb+1);await work.getByRole('heading',{name:'Topicmap Interaction Documentation',exact:true}).waitFor()
 // → a DITA Story Item (the Item of the retained page, by its id)
 const ids={concept1:'4f1c7a92b3d85e01',concept2:'4f1c7a92b3d85e02',reference:'4f1c7a92b3d85e03',task:'4f1c7a92b3d85e04'}
 const itemJson=JSON.parse(fs.readFileSync(retained['topicmap-inspection-dita'],'utf8')).story
 const openTopic=async(label,id)=>{await work.getByText(label,{exact:true}).first().click()
  const pane=panes().nth(wb+2);await pane.locator('.inspector-title').filter({hasText:new RegExp('dita '+id)}).first().waitFor();return pane}
 const topic=await openTopic('Topicmap Signs and Represented Objects',ids.concept1)
 assert(/dita-story-item/.test(await titleOf(topic)),'the Item is read as a dita-story-item')
 // → DITA topic (structured), and the XML source as its own tab: the text of the repository's Item, not a copy of it
 await topic.getByRole('heading',{name:'Topicmap Signs and Represented Objects',exact:true}).waitFor()
 const source=itemJson.find(i=>i.id===ids.concept1)
 await topic.getByRole('button',{name:'Story item',exact:true}).first().click()
 await topic.getByRole('heading',{name:'Story Item '+ids.concept1,exact:true}).waitFor()
 const stored=await topic.innerText();assert(stored.includes('<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd">'))
 assert(stored.includes('<concept id="topicmap-signs-and-represented-objects" xml:lang="en">'));assert(source.text.includes('<concept id="topicmap-signs-and-represented-objects"'))
 await topic.getByRole('button',{name:'DITA topic',exact:true}).first().click()
 await topic.getByRole('heading',{name:'Topicmap Signs and Represented Objects',exact:true}).waitFor()
 steps.push('Work Breakdown → Topicmap Interaction Documentation → DITA Story Item (dita-story-item '+ids.concept1+') → DITA topic and its XML source')
 // → the objects the topic names: a different object for each Operation, of one chain
 const xref=(pane,href)=>pane.locator(`.dita-xref[title="${href}"] .inspector-inspect`).first()
 const objectPane=async(pane,href,index=wb+3)=>{await xref(pane,href).click();const next=panes().nth(index);await next.locator('.inspector-title').first().waitFor();await page.waitForTimeout(400);return next}
 const sign=await objectPane(topic,'hyperdoc:example:proposes-topic'),signTitle=await titleOf(sign)
 assert(/^item-edit-topic/.test(signTitle),signTitle)
 await sign.getByRole('button',{name:'Provenance',exact:true}).first().click()
 await sign.getByRole('heading',{name:'Provenance in the HyperDoc projection',exact:true}).waitFor()
 const provenance=await sign.innerText()
 for(const expected of ['An Association of the Item edit','derived','PROPOSAL-ACTION'])assert(provenance.includes(expected),expected)
 const represented=await objectPane(topic,'hyperdoc:example:proposes-association'),representedTitle=await titleOf(represented)
 assert(/^association.*ASSOCIATION 2 roles/.test(representedTitle),representedTitle)
 assert.notEqual(address(signTitle),address(representedTitle))
 const proposal=await objectPane(topic,'hyperdoc:example:proposal');assert(/ITEM-EDIT-PROPOSAL/i.test(await titleOf(proposal)))
 await (async()=>{const c=await objectPane(topic,'hyperdoc:class:dreyeck/item-edit-ctm:item-edit-topic');assert(/ITEM-EDIT-TOPIC/i.test(await titleOf(c)))})()
 steps.push('Inspect Topicmap sign → an item-edit-topic with its Provenance; Inspect represented object → a TMDM Association; two objects; the proposal and the class open')
 // the reference topic and the Operation object
 await topic.locator('.dita-xref[title="hyperdoc:item:'+ids.reference+'"] .inspector-inspect').first().click()
 const reference=panes().nth(wb+3);await reference.locator('.inspector-title').filter({hasText:new RegExp('dita '+ids.reference)}).first().waitFor()
 await reference.getByRole('heading',{name:'Topicmap Gesture Operations',exact:true}).waitFor()
 await reference.locator('.dita-xref[title="hyperdoc:operation:inspect-topicmap-sign"] .inspector-inspect').first().click()
 const operation=panes().nth(wb+4);await operation.locator('.inspector-title').first().waitFor();await page.waitForTimeout(400)
 assert(/inspect-topicmap-sign|Inspect Topicmap sign/i.test(await operation.innerText()))
 // the Role topic: the Role of the example, whose parent is the Association above
 await work.getByText('TMDM Roles and Projected Edges',{exact:true}).first().click()
 const roles=panes().nth(wb+2);await roles.locator('.inspector-title').filter({hasText:new RegExp('dita '+ids.concept2)}).first().waitFor()
 const role=await objectPane(roles,'hyperdoc:example:proposes-role-action');assert(/^association-role#<ASSOCIATION-ROLE \{[0-9A-F]+\}>/.test(await titleOf(role)),await titleOf(role))
 await role.getByRole('button',{name:'Slots',exact:true}).first().click();await page.waitForTimeout(800)
 await role.locator('tr').filter({hasText:/^parent/}).locator('td').nth(1).locator('.inspector-inspect').first().click()
 const parent=panes().nth(wb+4);await parent.locator('.inspector-title').filter({hasText:/ASSOCIATION 2 roles/}).first().waitFor()
 assert.equal(address(await titleOf(parent)),address(representedTitle),'the Role belongs to the Association that Inspect represented object opened')
 steps.push('the reference topic opens operation/inspect-topicmap-sign; the Role topic opens the Role whose parent is that Association')
 assert.deepEqual(errors,[])
 // reading wrote nothing
 for(const [slug,file] of Object.entries(retained))assert.equal(sha(path.join(siteRoot,'pages',slug)),copyBefore[slug])
 await context.close()
 // 3. Stopping the Catalog removes the copy.
 await stopAndWait(reviewRun);reviewRun=null
 assert(!fs.existsSync(siteRoot),'the temporary copy is removed when the Catalog stops')
 steps.push('stopping the Catalog removes the TEST-COPY directory')

 // 4. The start as it was: the site root is read as given; no copy.
 plainRoot=fs.mkdtempSync(path.join(os.tmpdir(),'ctm-plain-site-'));fs.mkdirSync(path.join(plainRoot,'pages'))
 fs.copyFileSync(retained['ctm-and-tmdm-in-hyperdoc'],path.join(plainRoot,'pages','ctm-and-tmdm-in-hyperdoc'))
 const plainPort=await freePort()
 plainRun=await start({HYPERDOC_FEDWIKI_SITE_ROOT:plainRoot,HYPERDOC_CTM_PORT:String(plainPort)},'plain')
 await waitFor(plainRun,/CTM page authoring review Catalog: /)
 const plainOut=plainRun.text()
 assert(/REVIEW-MODE: off/.test(plainOut),plainOut.slice(-800));assert(plainOut.includes(plainRoot))
 assert.equal(plainOut.match(/SITE-ROOT: (\S+)/)[1].replace(/\/$/,''),plainRoot.replace(/\/$/,''))   // the site root that was given, no copy
 assert.deepEqual(fs.readdirSync(path.join(plainRoot,'pages')),['ctm-and-tmdm-in-hyperdoc']);assert(!/TEST COPY/.test(plainOut.replace(/REVIEW-MODE: off[^\n]*/,'')))
 await stopAndWait(plainRun);plainRun=null
 assert(fs.existsSync(path.join(plainRoot,'pages','ctm-and-tmdm-in-hyperdoc')),'a site root that was given is never removed')
 steps.push('plain start unchanged: HYPERDOC_FEDWIKI_SITE_ROOT read as given, REVIEW-MODE off, the given directory kept, no copy made')
 for(const [slug,file] of Object.entries(retained))assert.equal(sha(file),retainedBefore[slug])
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',syntheticPointerInput:false,steps},null,2))
 console.log('REVIEW-COPY-PASS: '+steps.join(' → '))
}catch(e){
 const pages=browser.contexts().flatMap(c=>c.pages());if(pages.length){fs.writeFileSync(path.join(output,'failure.txt'),await pages[0].locator('body').innerText());await pages[0].screenshot({path:path.join(output,'failure.png')})}
 throw e
}finally{
 await browser.close()
 for(const run of [reviewRun,plainRun])if(run)await stopAndWait(run)
 if(plainRoot)fs.rmSync(plainRoot,{recursive:true,force:true})
 if(siteRoot&&fs.existsSync(siteRoot)&&siteRoot.includes('TEST-COPY'))fs.rmSync(siteRoot,{recursive:true,force:true})
}
