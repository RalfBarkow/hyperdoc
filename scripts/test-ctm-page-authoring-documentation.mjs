// The documentation of the Item edit path, read in an actual served Catalog (development off, policy enforced) that
// serves the local review system. Nothing is written; the site is an empty temporary directory.
//   Working on HyperDoc → Text pages → Work Breakdown → Author the CTM Plan Page → implementation state
//   → Item Edit Path in HyperDoc → class, function with Source code, system
// The Item E3 is opened both ways (the E3 link, and the page link → Page source → E3), and each way goes on:
//   Edit → Prepare edit proposal → Preview, on a temporary copy of the page, which stays unchanged.
// node THIS LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT   (TOPIC_MAPS_ROOT: the topic-maps checkout)
// CATALOG_SYSTEM=dreyeck/ctm-page-authoring runs the served-sized Catalog: same Edit path, and no writer, no execution,
// no topic-maps in the image; the steps that open objects of the local system are left out.
import {installBoundClicks,readiness} from './lib/inspector-ready.mjs'
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import net from 'node:net'
import crypto from 'node:crypto'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {pathToFileURL} from 'node:url'
const [lisp,pw,chrome,output]=process.argv.slice(2)
const topicMaps=process.env.TOPIC_MAPS_ROOT
const catalogSystem=process.env.CATALOG_SYSTEM||'dreyeck/ctm-page-authoring/local'
const servedSized=catalogSystem==='dreyeck/ctm-page-authoring'
if(!output||(!servedSized&&!topicMaps))throw Error('LISP_WRAPPER PLAYWRIGHT_DIRECTORY CHROME OUTPUT and, for the local system, TOPIC_MAPS_ROOT required')
fs.mkdirSync(output,{recursive:true})
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'ctm-documentation-browser-'))
const site=path.join(temp,'site');fs.mkdirSync(path.join(site,'pages'),{recursive:true})
const retained=path.resolve(path.dirname(new URL(import.meta.url).pathname),'../dreyeck/work/ctm-page-evidence/site/pages/ctm-and-tmdm-in-hyperdoc')
const pageFile=path.join(site,'pages','ctm-and-tmdm-in-hyperdoc');fs.copyFileSync(retained,pageFile)
const sha=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex'),before=sha(pageFile)
const port=await new Promise(r=>{const s=net.createServer();s.listen(0,'127.0.0.1',()=>{const p=s.address().port;s.close(()=>r(p))})})
const stop=path.join(temp,'stop'),script=path.join(temp,'witness.lisp'),log=path.join(output,'lisp.log')
fs.writeFileSync(script,`(require :asdf)
${topicMaps?`(pushnew #p${JSON.stringify(topicMaps.endsWith('/')?topicMaps:topicMaps+'/')} asdf:*central-registry* :test (function equal))`:''}
(asdf:load-system "dreyeck/catalog-application")
(dreyeck/catalog-application:start-catalog :port ${port} :host "127.0.0.1" :site-root ${JSON.stringify(site+'/')}
 :catalog-system ${JSON.stringify(catalogSystem)} :development nil)
(assert (dreyeck/authority-policy:policy-enforced-p))
(format t "~&PACKAGES preview=~A writer=~A execution=~A topic-maps=~A~%"
 (if (find-package "DREYECK/FEDWIKI-ITEM-EDIT-PREVIEW") "YES" "NO") (if (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING") "YES" "NO")
 (if (find-package "DREYECK/FEDWIKI-ITEM-EDIT-EXECUTION") "YES" "NO") (if (find-package "TOPIC-MAPS.TMDM") "YES" "NO"))
(format t "~&DOCUMENTATION-BROWSER-READY~%") (finish-output)
(unwind-protect (loop repeat 3000 until (probe-file #p${JSON.stringify(stop)}) do (sleep .1)) (clog:shutdown))`)
const fd=fs.openSync(log,'w'),child=spawn(lisp,['--load',script],{stdio:['ignore',fd,fd]})
const logText=()=>fs.readFileSync(log,'utf8')
const {chromium}=await import(pathToFileURL(path.join(pw,'index.mjs')))
const browser=await chromium.launch({headless:true,executablePath:chrome})
const steps=[];let syntheticInput=false   // pointer events dispatched by script are synthetic (isTrusted=false)
try{
 for(let n=0;n<6000;n++){if(child.exitCode!==null)throw Error(logText().slice(-4000));if(logText().includes('DOCUMENTATION-BROWSER-READY'))break;await new Promise(r=>setTimeout(r,100))}
 const packages=(logText().match(/PACKAGES [^\n]*/)||[''])[0]
 assert(packages.includes('preview=YES'),packages)
 assert.equal(packages.includes('writer=NO')&&packages.includes('execution=NO'),servedSized,packages)
 const context=await browser.newContext({serviceWorkers:'block'})
 await context.route('**/*',r=>new URL(r.request().url()).origin===`http://127.0.0.1:${port}`?r.continue():r.abort())
 const page=await context.newPage();page.setDefaultTimeout(60000);installBoundClicks(page)
 const errors=[];page.on('pageerror',e=>errors.push(e.message))
 const last=()=>page.locator('.inspector-pane').last()
 const click=async label=>last().getByText(label,{exact:true}).first().click()
 const heading=async label=>last().getByRole('heading',{name:label,exact:true}).waitFor()
 await page.goto(`http://127.0.0.1:${port}`)
 await page.getByText('Working on HyperDoc',{exact:true}).and(page.locator(':visible')).first().click()
 await page.getByRole('button',{name:'Text pages',exact:true}).last().click()
 await page.locator('tr.inspector-inspect:visible').filter({hasText:'Work Breakdown'}).last().click()
 await heading('Work Breakdown')
 let text=await last().innerText()
 for(const expected of ['How this page uses its terms','PMBOK Guide 2000','Agile Practice Guide 2017','HERMES Online','Reference basis'])assert(text.includes(expected),expected)
 steps.push('Work Breakdown: terms and reference basis')
 await click('Author the CTM Plan Page through HyperDoc');await heading('Authoring the CTM Plan Page')
 text=await last().innerText()
 for(const expected of ['Implementation state of packages 2 to 4','Integrated in source','Locally executable','Tested on temporary copies','Read in the local Inspector','Served on dreyeck.ch','Accepted'])assert(text.includes(expected),expected)
 steps.push('carrier page: implementation state')
 // Two links on the carrier page, two different objects: the whole page, and the Item E3 of it by its id.
 const panes=()=>page.locator('.inspector-pane')
 const carrier=await panes().count()-1
 const normalized=async pane=>(await pane.innerText()).replace(/, observed [^\n]*UTC/,'')
 await panes().nth(carrier).getByText('E3',{exact:true}).first().click()
 await panes().nth(carrier+1).getByRole('heading',{name:'Story Item ed37e9bac2fcd548',exact:true}).waitFor()
 const viaLink=await normalized(panes().nth(carrier+1));steps.push('E3 → the local-story-item')
 assert(viaLink.includes('11 of 18'));assert(viaLink.includes('Item JSON, as observed'))
 // Each way offers Edit, and Edit goes on to a proposal and a preview. A link that did not lead there would be no navigation to the Item's authoring.
 const e3='ed37e9bac2fcd548',proposed='E3 — Darstellung: documentation test text, not a decision.'
 const editPath=async item=>{
  await panes().nth(item).getByRole('button',{name:'Edit',exact:true}).first().click()
  await panes().nth(item).getByText('Prepare edit proposal',{exact:true}).first().click()
  await panes().nth(item+1).getByRole('heading',{name:`Edit proposal for ${e3}`,exact:true}).waitFor()
  const input=panes().nth(item+1).locator('input').first()
  await input.fill(proposed);await input.dispatchEvent('change');await page.waitForTimeout(500)
  await panes().nth(item+1).getByText('Preview',{exact:true}).first().click()
  await panes().nth(item+2).getByRole('heading',{name:`Preview: edit of ${e3}`,exact:true}).waitFor()
  const preview=await panes().nth(item+2).innerText()
  assert(preview.includes('Executed: no.'));assert(preview.includes(proposed))
  // The execution is the local system's: its tab is there where the system is loaded, and absent where it is not.
  const tabs=await panes().nth(item+2).getByRole('button').allInnerTexts()
  assert.equal(tabs.includes('Execution'),!servedSized,tabs.join('|'))
  assert.equal(sha(pageFile),before)}
 await editPath(carrier+1);steps.push('E3 link → Edit → Prepare edit proposal → Preview')
 if(!servedSized){
  // On to the completion, and to its tab CTM, as the documentation says: Execution → Complete the Action with a date.
  const preview=carrier+3
  await panes().nth(preview).getByRole('button',{name:'Execution',exact:true}).first().click()
  await panes().nth(preview).getByRole('button',{name:'Complete the Action with a date',exact:true}).click()
  const completion=preview+1
  await panes().nth(completion).getByRole('heading',{name:'The Action that would be authorized',exact:true}).waitFor()
  const date=(await panes().nth(completion).innerText()).match(/date added: (\d+)/)[1]   // the completion's date, to be found again in the completed Action
  const title=(await panes().nth(completion).locator('.inspector-title').first().innerText()).replace(/\s+/g,' ')
  assert(title.includes('item-edit-completion')&&title.includes('Completed Action'),title)   // the completion pane, not the completed Action
  const tabNames=(await panes().nth(completion).getByRole('button').allInnerTexts()).filter(Boolean)
  for(const tab of ['Completed Action','CTM','Slots','Print','Operations','Playground'])assert(tabNames.includes(tab),tab+' in '+tabNames.join('|'))
  await panes().nth(completion).getByRole('button',{name:'CTM',exact:true}).first().click()
  await panes().nth(completion).getByRole('heading',{name:`CTM of the completion of ${e3}`,exact:true}).waitFor()
  assert((await panes().nth(completion).innerText()).includes('completed-from(completed: the-completed-action, original: the-proposed-action) @derived'))
  await panes().nth(completion).getByText('the TMDM Topic Map',{exact:true}).first().click()
  await panes().nth(completion+1).locator('.inspector-title').filter({hasText:'TOPIC-MAP'}).first().waitFor()
  steps.push('… → Execution → Complete the Action with a date → the item-edit-completion pane (tabs '+tabNames.join(', ')+') → CTM → the TMDM Topic Map')
  // The tab Topicmap, right after CTM: the diagram at once, then real Inspector actions on it.
  const order=tabNames.slice(tabNames.indexOf('Completed Action',2));assert.deepEqual(order.slice(0,3),['Completed Action','CTM','Topicmap'],order.join('|'))
  const map=panes().nth(completion)
  const tabTopicmap=async()=>{await map.getByRole('button',{name:'Topicmap',exact:true}).first().click();await map.getByRole('heading',{name:`Topicmap of the completion of ${e3}`,exact:true}).waitFor()}
  await tabTopicmap()
  assert.equal(await map.locator('svg.dreyeck-topicmap-canvas').count(),1)
  const objects=['the-proposal','the-preview','the-proposed-action','the-completion','the-completed-action','the-expected-item','the-signed-body']
  for(const id of objects)assert.equal(await map.locator(`.dreyeck-topicmap-topic[data-topic-id="${id}"]`).count(),1,id)
  assert.equal(await map.locator('.dreyeck-topicmap-topic[data-topic-id*="("]').count(),8,'eight Associations drawn as nodes')
  // Sixteen Role edges, each from its Association node to the player named by its Role: identity and Role types, not geometry.
  const edgeIds=await map.locator('.dreyeck-topicmap-association').evaluateAll(els=>els.map(e=>e.getAttribute('data-association-id')))
  assert.equal(edgeIds.length,16,'one edge for each Role')
  const edges=edgeIds.map(id=>{const player=id.slice(id.lastIndexOf(':')+1),rest=id.slice(0,id.lastIndexOf(':')),role=rest.slice(rest.lastIndexOf(':')+1),node=rest.slice(0,rest.lastIndexOf(':'));return {node,role,player,type:node.slice(0,node.indexOf('('))}})
  const expectedEdges=[['proposes','proposal','the-proposal'],['proposes','action','the-proposed-action'],['previews','preview','the-preview'],['previews','action','the-proposed-action'],
   ['completes','completion','the-completion'],['completes','preview','the-preview'],['yields','completion','the-completion'],['yields','action','the-completed-action'],
   ['has-body','completion','the-completion'],['has-body','body','the-signed-body'],['completed-from','completed','the-completed-action'],['completed-from','original','the-proposed-action'],
   ['contains','body','the-signed-body'],['contains','content','the-expected-item'],['contains','body','the-signed-body'],['contains','content','the-completed-action']].map(e=>e.join('|')).sort()
  assert.deepEqual(edges.map(e=>[e.type,e.role,e.player].join('|')).sort(),expectedEdges)
  for(const e of edges){
   assert.equal(await map.locator(`.dreyeck-topicmap-topic[data-topic-id="${e.node}"]`).count(),1,'its Association node '+e.node)
   assert(e.node.includes(`${e.role}=${e.player}`),'the node names the Role and its player: '+e.node)
   assert.equal(await map.locator(`.dreyeck-topicmap-topic[data-topic-id="${e.player}"]`).count(),1,'its player '+e.player)}
  steps.push('Topicmap: seven objects, eight Association nodes, sixteen Role edges with the right Role types and players')
  const sign=id=>map.locator(`.dreyeck-topicmap-workspace-action[data-topic-id="${id}"]`)
  const pointAt=async id=>{await map.locator(`.dreyeck-topicmap-point-sign[data-topic-id="${id}"]`).waitFor()
   assert.equal(await map.locator('.dreyeck-topicmap-point-sign').count(),1,'one Point')
   assert.equal(await map.locator('p').filter({hasText:/^Point:/}).first().locator('code').innerText(),id)}
  const itemsOf=async pane=>{const out={};for(const tr of await pane.locator('tr').all()){const tds=await tr.locator('td').allInnerTexts();if(tds.length===2)out[tds[0].trim()]=tds[1].trim()};return out}
  // The address of a Lisp object, from its Print tab: two panes of one object show one address.
  const addressOf=async pane=>{await pane.getByRole('button',{name:'Print',exact:true}).first().click();const t=await pane.innerText();await pane.getByRole('button',{name:'Items',exact:true}).first().click();return (t.match(/\{([0-9A-F]{6,})\}/)||[])[1]}
  // 1. A click on the sign of completed-from moves the Point.
  await sign('the-completion').dispatchEvent('click');await pointAt('the-completion')
  const completedFrom='completed-from(completed=the-completed-action,original=the-proposed-action)'
  await sign(completedFrom).dispatchEvent('click');await pointAt(completedFrom)
  steps.push('Point → the-completion → completed-from (the Point sign moved)')
  // 2. The Point panel: class derived, the reason, the Topic Map's Scope not being the reason, and the two Roles with their players.
  text=await map.innerText()
  for(const expected of ['derived','Why HyperDoc states it','different objects and equal in every field but the date','The Topic Map carries the class as the Scope'])assert(text.includes(expected),expected)
  const roleRows=map.locator('tr.dreyeck-topicmap-workspace-association')
  assert.equal(await roleRows.count(),2)
  assert.deepEqual((await roleRows.locator('tt').allInnerTexts()).sort(),['completed','original'])
  const roleTable=map.locator('table').filter({hasText:'Lisp object'}).first()
  const players={};for(const tr of await roleTable.locator('tr').all()){const tds=await tr.locator('td').allInnerTexts();if(tds.length>=3)players[tds[1].trim()]=tds[2].trim()}
  assert.deepEqual(players,{completed:'the-completed-action',original:'the-proposed-action'})
  steps.push('completed-from: class derived, the reason, Roles completed → the-completed-action and original → the-proposed-action')
  // 3. Follow original to the proposed Action and completed to the completed Action, and from each to its Lisp object; History records it.
  const goRole=async(role,player)=>{await map.locator(`tr.dreyeck-topicmap-workspace-association[data-association-id$=":${role}:${player}"] .inspector-action`).first().click();await pointAt(player)}
  const titleOf=async pane=>(await pane.locator('.inspector-title').first().innerText()).replace(/\s+/g,' ')
  const lispObject=async(previousTitle)=>{await map.locator('p').filter({hasText:'Lisp object:'}).locator('.inspector-inspect').first().click()
   const pane=panes().nth(completion+1);await pane.locator('.inspector-title').filter({hasText:'HASH-TABLE'}).first().waitFor()
   // A later link replaces the pane to the right: wait until it is the new object, not the one that was there.
   for(let n=0;n<100&&await titleOf(pane)===previousTitle;n++)await page.waitForTimeout(100)
   return pane}
  await goRole('original','the-proposed-action')
  const proposedPane=await lispObject(null);const proposedTitle=await titleOf(proposedPane);const proposedAddress=await addressOf(proposedPane);const proposedItems=await itemsOf(proposedPane)
  const proposedItemPane=await (async()=>{await proposedPane.locator('tr').filter({hasText:/^item/}).locator('td').nth(1).locator('.inspector-inspect').first().click();const p=panes().nth(completion+2);await p.locator('.inspector-title').filter({hasText:'HASH-TABLE'}).first().waitFor();await page.waitForTimeout(700);return p})()
  const proposedItemAddress=await addressOf(proposedItemPane)
  const proposedItem=await itemsOf(proposedItemPane)
  await sign(completedFrom).dispatchEvent('click');await pointAt(completedFrom)   // back to the Association node
  await goRole('completed','the-completed-action')
  const completedPane=await lispObject(proposedTitle);const completedAddress=await addressOf(completedPane);const completedItems=await itemsOf(completedPane)
  const completedItemPane=await (async()=>{await completedPane.locator('tr').filter({hasText:/^item/}).locator('td').nth(1).locator('.inspector-inspect').first().click();const p=panes().nth(completion+2);await p.locator('.inspector-title').filter({hasText:'HASH-TABLE'}).first().waitFor();await page.waitForTimeout(700);return p})()
  const completedItem=await itemsOf(completedItemPane)
  // The values of the Lisp objects, not the labels of the signs: two objects, equal but for the date.
  assert.notEqual(proposedAddress,completedAddress,'the proposed and the completed Action are different Lisp objects')
  assert.equal('date' in proposedItems,false,'the proposed Action has no date')
  assert.equal(completedItems.date,String(date),'the completed Action has the completion\'s date')
  assert.deepEqual(Object.keys(proposedItems).sort(),['id','item','type']);assert.deepEqual(Object.keys(completedItems).sort(),['date','id','item','type'])
  assert.equal(proposedItems.type,completedItems.type);assert.equal(proposedItems.id,completedItems.id);assert.equal(proposedItems.id,e3)
  assert.notEqual(proposedItemAddress,await addressOf(completedItemPane),'their Items are different objects too')
  assert.deepEqual(proposedItem,completedItem,'every field of the Item is equal');assert(Object.keys(proposedItem).length>=3)
  steps.push('original → the proposed Action and completed → the completed Action: two Lisp objects, equal but for the date')
  // 4. The reason of the derived Association is found again, and the way back to its node.
  await sign(completedFrom).dispatchEvent('click');await pointAt(completedFrom)
  assert((await map.innerText()).includes('different objects and equal in every field but the date'))
  // 5. The Point stays while the pane is drawn again: the tab CTM and back, and the pane's own refresh.
  await map.getByRole('button',{name:'CTM',exact:true}).first().click()
  await map.getByRole('heading',{name:`CTM of the completion of ${e3}`,exact:true}).waitFor()
  await tabTopicmap();await pointAt(completedFrom)
  await map.locator('.inspector-title-bar .inspector-button').first().click();await page.waitForTimeout(800)
  await map.getByRole('heading',{name:`Topicmap of the completion of ${e3}`,exact:true}).waitFor();await pointAt(completedFrom)
  // The History: the Workspace pane's own slot records the Points left, most recent first.
  await map.getByText('Open the Workspace as a pane',{exact:true}).first().click()
  const workspacePane=panes().nth(completion+1);await workspacePane.locator('.inspector-title').filter({hasText:/TOPICMAP-WORKSPACE/i}).first().waitFor()
  await workspacePane.getByRole('button',{name:'Slots',exact:true}).first().click()
  const slotText=(await workspacePane.innerText()).replace(/\s+/g,' ')
  const history=slotText.slice(slotText.search(/HISTORY/i))
  const left=[...history.matchAll(/the-completion|the-proposed-action|completed-from\(/g)].map(m=>m[0])
  assert(left.includes('the-completion')&&left.includes('the-proposed-action')&&left.filter(x=>x==='completed-from(').length>=2,'History: '+history.slice(0,300))
  steps.push('the Point survives CTM and back and a refresh; the Workspace History records the Points left')
  // 6. The Point goes on from here, and the Point as a pane has Provenance and the way back to the Topicmap.
  await sign('the-proposed-action').dispatchEvent('click');await pointAt('the-proposed-action')
  assert((await map.innerText()).includes('An object of the Item edit'))
  await map.locator('h3').filter({hasText:'Point'}).first().locator('xpath=following-sibling::p[1]').locator('.inspector-inspect').first().click()
  const topicPane=panes().nth(completion+1)
  await topicPane.getByRole('heading',{name:'the-proposed-action',exact:true}).waitFor()
  assert((await topicPane.innerText()).includes('Provenance in the HyperDoc projection'))
  await topicPane.getByText('Back to the Topicmap',{exact:true}).first().click()
  await panes().nth(completion+2).getByRole('heading',{name:`Topicmap of the completion of ${e3}`,exact:true}).waitFor()
  steps.push('the Point goes on; the Point as a pane: Provenance → back to the Topicmap')
  // 7. The schema Topics are not drawn and are reachable through the legend.
  text=await map.innerText();for(const expected of ['association type','role type','occurrence type','scope: how a statement is known'])assert(text.includes(expected),expected)
  assert.equal(await map.locator('.dreyeck-topicmap-topic[data-topic-id="date"]').count(),0)
  for(const [key,use] of [['original','role type'],['completed-from','association type'],['date','occurrence type'],['derived','scope: how a statement is known']]){
   const row=map.locator('tr').filter({has:page.locator('td',{hasText:new RegExp('^'+key+'$')})}).filter({hasText:use}).first()
   await row.locator('.inspector-inspect').last().click()
   await panes().nth(completion+1).locator('.inspector-title').filter({hasText:/TOPIC/i}).first().waitFor()}
  steps.push('schema Topics: not drawn; original, completed-from, date and derived open through the legend')
  // 8. The marking menu (Zettel 5697) on the native signs. The pointer events are SYNTHETIC (dispatched by script, isTrusted=false): they go through the production
  // DOM element, the CLOG handlers, the reducer and the Operation methods, and prove nothing about a physical mouse or trackpad.
  syntheticInput=true
  const historyText=async()=>{await map.getByText('Open the Workspace as a pane',{exact:true}).first().click()
   const w=panes().nth(completion+1);await w.locator('.inspector-title').filter({hasText:/TOPICMAP-WORKSPACE/i}).first().waitFor()
   await w.getByRole('button',{name:'Slots',exact:true}).first().click();await page.waitForTimeout(300)
   const t=(await w.innerText()).replace(/\s+/g,' ');return t.slice(t.search(/HISTORY/i))}
  const press=(loc,name,button,buttons,dx,dy)=>loc.evaluate((e,a)=>{const r=e.getBoundingClientRect();const ev=new PointerEvent(a.name,{bubbles:true,pointerId:77,pointerType:'mouse',button:a.button,buttons:a.buttons,clientX:r.x+r.width/2+a.dx,clientY:r.y+r.height/2+a.dy,isPrimary:true});e.dispatchEvent(ev);return ev.isTrusted},{name,button,buttons,dx,dy})
  const gstate=loc=>loc.evaluate(e=>({state:e.dataset.topicGestureState,mode:e.dataset.topicGestureMode,menu:e.dataset.topicGestureMenuVisible,binding:e.dataset.topicGestureBinding,outcome:e.dataset.topicGestureOutcome,bound:typeof e.__disposeTopicGesture==='function'}))
  const visibleMenu=()=>page.evaluate(()=>[...document.querySelectorAll('.dreyeck-topic-gesture-menu,.dreyeck-association-gesture-menu')].filter(x=>{const c=getComputedStyle(x),b=x.getBoundingClientRect();return c.display!=='none'&&c.visibility!=='hidden'&&b.width>0}).map(x=>x.textContent).sort())
  const LEFT=[-70,0],UP=[0,-70]
  // One selection by the radial menu (press, wait for the menu, move, release) or by the learned mark (press, move, release at once).
  const select=async(loc,where,dir,rightPane)=>{
   const [dx,dy]=dir;assert.equal(await press(loc,'pointerdown',2,2,0,0),false,'synthetic: isTrusted is false')
   let labels=null
   if(where==='menu'){await page.waitForTimeout(900);labels=await visibleMenu();assert.deepEqual(await gstate(loc).then(g=>[g.state,g.menu]),['menu-visible','true'])}
   await press(loc,'pointermove',-1,2,dx,dy);await press(loc,'pointerup',2,0,dx,dy);await page.waitForTimeout(900)
   const g=await gstate(loc);assert.equal(g.state,'completed');assert.equal(g.outcome,'shown');assert.equal(g.menu,'false')
   assert.equal(g.mode,where==='menu'?'menu-visible':'marking');return {labels,binding:g.binding,title:await titleOf(rightPane)}}
  await sign('the-completion').dispatchEvent('click');await pointAt('the-completion')
  const history0=await historyText()   // opens the Workspace pane; the pane to the right is replaced again by each gesture
  const nativeResults={}
  for(const [id,left,up] of [['the-completion',/^topicTopic #the-completion/,/^item-edit-topic/],[completedFrom,/^association.*ASSOCIATION 2 roles/,/^item-edit-topic/]]){
   const loc=sign(id);await loc.scrollIntoViewIfNeeded()
   assert.equal((await gstate(loc)).bound,true,'the sign is bound to the Gesture transport: '+id)
   const rightPane=panes().nth(completion+1)
   const m1=await select(loc,'menu',LEFT,rightPane),k1=await select(loc,'mark',LEFT,rightPane)
   assert.deepEqual(m1.labels,['Inspect Topicmap sign','Inspect represented object'].sort(),'the applicable Operations, no others')
   assert.equal(m1.binding,'binding/radial-menu-inspect-represented-object');assert.equal(k1.binding,'binding/learned-mark-inspect-represented-object')
   assert(left.test(m1.title),m1.title);assert.equal(k1.title,m1.title,'menu and mark open the same Lisp object (same address)')
   const m2=await select(loc,'menu',UP,rightPane),k2=await select(loc,'mark',UP,rightPane)
   assert.equal(m2.binding,'binding/radial-menu-inspect-topicmap-sign');assert.equal(k2.binding,'binding/learned-mark-inspect-topicmap-sign')
   assert(up.test(m2.title),m2.title);assert.equal(k2.title,m2.title)
   assert((await rightPane.innerText()).includes('Provenance in the HyperDoc projection'))
   assert((await rightPane.innerText()).includes(id==='the-completion'?'the-completion':'completed-from'))
   nativeResults[id]={represented:m1.title,sign:m2.title}
  }
  // The represented objects differ by the sign that was hit, not by the Point.
  assert.notEqual(nativeResults['the-completion'].represented,nativeResults[completedFrom].represented)
  // Reading Operations: the Point and the History are as before.
  await pointAt('the-completion');assert.equal(await historyText(),history0,'the History is unchanged by SECONDARY')
  steps.push('SECONDARY on the-completion and completed-from (synthetic events): radial menu lists the two applicable Operations; menu and mark open the same objects; Point and History unchanged')
  // PRIMARY is unchanged: it moves the Point.
  await sign('the-completed-action').dispatchEvent('click');await pointAt('the-completed-action')
  assert.notEqual(await historyText(),history0,'PRIMARY records History')
  // After a redraw (the tab CTM and back) the new signs take the gesture again, and on the new Point's sign too.
  await map.getByRole('button',{name:'CTM',exact:true}).first().click();await map.getByRole('heading',{name:`CTM of the completion of ${e3}`,exact:true}).waitFor()
  await tabTopicmap();await pointAt('the-completed-action')
  const again=sign(completedFrom);await again.scrollIntoViewIfNeeded();assert.equal((await gstate(again)).bound,true)
  const rightAfter=await select(again,'mark',LEFT,panes().nth(completion+1))
  assert(/^association.*ASSOCIATION 2 roles/.test(rightAfter.title))
  await pointAt('the-completed-action')
  steps.push('PRIMARY moves the Point and records History; after CTM and back the redrawn signs take the gesture again')
  // 8. TALA: the same projection laid out again, on request, and still the same Topics and Roles.
  await map.getByRole('button',{name:'Lay out with TALA',exact:true}).click()
  const tala=panes().nth(completion+1)
  await tala.locator('.inspector-title').filter({hasText:/TALA-RENDERING|PLIST|TALA/i}).first().waitFor({timeout:120000})
  const talaTabs=(await tala.getByRole('button').allInnerTexts()).filter(Boolean)
  if(talaTabs.includes('TALA (interactive)')){
   await tala.getByRole('button',{name:'TALA (interactive)',exact:true}).click()
   await tala.locator('svg g[data-topic-id="the-completed-action"]').waitFor()
   const talaTopics=await tala.locator('svg g[data-topic-id]').evaluateAll(els=>els.map(e=>e.getAttribute('data-topic-id')).sort())
   assert.deepEqual(talaTopics,(await map.locator('.dreyeck-topicmap-topic').evaluateAll(els=>els.map(e=>e.getAttribute('data-topic-id')).sort())),'the same fifteen Topics, under the same keys')
   const talaEdges=await tala.locator('svg g[data-association-id]').evaluateAll(els=>els.map(e=>e.getAttribute('data-association-id')).sort())
   assert.deepEqual(talaEdges,[...edgeIds].sort(),'the same sixteen Role edges')
   // completed-from and its two Role edges stay reachable; a click on a Topic or an edge opens an Inspector object.
   const cfEdges=talaEdges.filter(id=>id.startsWith('completed-from('));assert.deepEqual(cfEdges.map(id=>id.split(':').slice(-2).join(':')).sort(),['completed:the-completed-action','original:the-proposed-action'])
   await tala.locator(`svg g[data-topic-id="${completedFrom}"]`).first().click()
   await panes().nth(completion+2).getByRole('heading',{name:'completed-from',exact:true}).waitFor()
   text=await panes().nth(completion+2).innerText();for(const expected of ['Provenance in the HyperDoc projection','derived','different objects and equal in every field but the date','the-completed-action','the-proposed-action'])assert(text.includes(expected),expected)
   await tala.locator(`svg g[data-association-id="${cfEdges.find(id=>id.endsWith(':original:the-proposed-action'))}"]`).first().click()
   await panes().nth(completion+2).getByRole('heading',{name:/original/}).waitFor()
   await tala.locator('svg g[data-topic-id="the-completed-action"]').first().click()
   await panes().nth(completion+2).getByRole('heading',{name:'the-completed-action',exact:true}).waitFor()
   assert((await panes().nth(completion+2).innerText()).includes('Provenance in the HyperDoc projection'))
   // The groups of TALA (interactive) take the same SECONDARY: the same Bindings, Operations and objects as the native signs.
   const grp=id=>tala.locator(`svg g[data-topic-id="${id}"]`).first()
   for(const id of ['the-completed-action',completedFrom]){
    const loc=grp(id);await loc.scrollIntoViewIfNeeded();assert.equal((await gstate(loc)).bound,true,'TALA group bound: '+id)
    const rightPane=panes().nth(completion+2)
    const m=await select(loc,'menu',LEFT,rightPane),k=await select(loc,'mark',LEFT,rightPane)
    assert.deepEqual(m.labels,['Inspect Topicmap sign','Inspect represented object'].sort())
    assert.equal(k.title,m.title,'TALA: menu and mark open the same object')
    assert(id===completedFrom?/^association.*ASSOCIATION 2 roles/.test(m.title):/^topicTopic #the-completed-action/.test(m.title),m.title)
    const u=await select(loc,'mark',UP,rightPane);assert(/^item-edit-topic/.test(u.title))
   }
   // A Role edge offers Inspect represented object, the TMDM Role it stands for, and not Inspect relation contract (it has no Relation Contract).
   const roleEdge=tala.locator(`svg g[data-association-id^="completes("][data-association-id$=":completion:the-completion"]`).first();await roleEdge.scrollIntoViewIfNeeded()
   assert.equal((await gstate(roleEdge)).bound,true,'the Role edge takes the gesture')
   const edgeSelect=async(how)=>{assert.equal(await press(roleEdge,'pointerdown',2,2,0,0),false)
    let labels=null;if(how==='menu'){await page.waitForTimeout(900);labels=await visibleMenu()}
    await press(roleEdge,'pointermove',-1,2,-70,0);await press(roleEdge,'pointerup',2,0,-70,0);await page.waitForTimeout(900)
    const g=await roleEdge.evaluate(e=>({outcome:e.dataset.associationGestureOutcome,state:e.dataset.associationGestureState,binding:e.dataset.associationGestureBinding,menu:e.dataset.associationGestureMenuVisible,mode:e.dataset.associationGestureMode}))
    return {labels,g,title:await titleOf(panes().nth(completion+2))}}
   const viaMenu=await edgeSelect('menu')
   assert.deepEqual(viaMenu.labels,['Inspect represented object'],'the menu offers Inspect represented object and not Inspect relation contract')
   assert.equal(viaMenu.g.outcome,'shown');assert.equal(viaMenu.g.binding,'binding/radial-menu-association-inspect-represented-object')
   const viaMark=await edgeSelect('mark')
   assert.equal(viaMark.g.outcome,'shown');assert.equal(viaMark.g.binding,'binding/learned-mark-association-inspect-represented-object')
   assert.equal(viaMark.title,viaMenu.title,'the mark opens the same object as the menu')
   assert(/^association-role#<ASSOCIATION-ROLE \{[0-9A-F]+\}>/.test(viaMenu.title),'the TMDM Role itself: '+viaMenu.title)
   // From the Role: its Association, its Role type and its player are inspectable.
   const rolePane=panes().nth(completion+2);await rolePane.getByRole('button',{name:'Slots',exact:true}).first().click();await page.waitForTimeout(800)
   const follow=async(slot,expected)=>{await rolePane.locator('tr').filter({hasText:new RegExp('^'+slot)}).locator('td').nth(1).locator('.inspector-inspect').first().click()
    const next=panes().nth(completion+3);await next.locator('.inspector-title').first().waitFor();for(let n=0;n<50&&!expected.test(await titleOf(next));n++)await page.waitForTimeout(100)
    assert(expected.test(await titleOf(next)),slot+' → '+await titleOf(next))}
   await follow('parent',/^association#<ASSOCIATION 2 roles/);await follow('type',/^topicTopic #completion$/);await follow('player',/^topicTopic #the-completion$/)
   // The same Role as the Association node shows in its Provenance (native drawing): one object, not a copy.
   const roleAddress=viaMenu.title.match(/\{([0-9A-F]+)\}/)[1]
   const completesNode='completes(completion=the-completion,preview=the-preview)'
   await sign(completesNode).dispatchEvent('click');await pointAt(completesNode)
   const provenance=map.locator('table').filter({hasText:'Lisp object'}).first()
   await provenance.locator('tr').filter({has:page.locator('td',{hasText:/^completion$/})}).first().locator('td').first().locator('.inspector-inspect').first().click()
   const nativeRole=panes().nth(completion+1);await nativeRole.locator('.inspector-title').filter({hasText:/ASSOCIATION-ROLE/}).first().waitFor()
   assert.equal((await titleOf(nativeRole)).match(/\{([0-9A-F]+)\}/)[1],roleAddress,'the edge and the Provenance table show the same TMDM Role object')
   steps.push('Lay out with TALA → TALA (interactive): the same 15 Topics and 16 Role edges; the Role edge completion offers Inspect represented object only (menu and mark open the TMDM Role; its Association, Role type and player open); Topic groups take the gesture too')
  }else steps.push('Lay out with TALA → no D2 here: '+talaTabs.join(', '))
  // The test page, story and journal, is as it was.
  {const now=JSON.parse(fs.readFileSync(pageFile,'utf8')),was=JSON.parse(fs.readFileSync(retained,'utf8'));assert.deepEqual(now.story,was.story);assert.deepEqual(now.journal,was.journal)}
  assert.equal(sha(pageFile),before)
 }
 await panes().nth(carrier).getByText('ctm-and-tmdm-in-hyperdoc',{exact:true}).first().click()
 await panes().nth(carrier+1).locator('.inspector-title').filter({hasText:'CTM and TMDM in HyperDoc'}).first().waitFor();steps.push('the linked FedWiki page → its local-fedwiki-page')
 // The same Item by the other way: Page source → E3. Each reading observes the file anew, so the two are equal in id, position,
 // source revision and content (the observation time aside), not the same object.
 await panes().nth(carrier+1).getByRole('button',{name:'Page source',exact:true}).first().click()
 await panes().nth(carrier+1).getByText('ed37e9bac2fcd548',{exact:true}).first().click()
 await panes().nth(carrier+2).getByRole('heading',{name:'Story Item ed37e9bac2fcd548',exact:true}).waitFor()
 assert.equal(await normalized(panes().nth(carrier+2)),viaLink);steps.push('Page source → E3: the same Item')
 await editPath(carrier+2);steps.push('Page source → E3 → Edit → Prepare edit proposal → Preview')
 if(servedSized){
  assert.deepEqual(errors,[]);assert.equal(sha(pageFile),before)
  fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',catalogSystem,servedSized,packages,development:false,policy:'ENFORCED',nothingWritten:true,steps},null,2))
  console.log('DOCUMENTATION-BROWSER-PASS (served-sized: '+packages+'): '+steps.join(' → ')+' | clicks '+JSON.stringify(readiness))
 }else{
  // back on the carrier page for the next link
  await panes().nth(carrier).getByText('Item Edit Path in HyperDoc',{exact:true}).first().click()
  await heading('Item Edit Path in HyperDoc')
  text=await last().innerText()
  for(const expected of ['The path and its objects','Three statements about an execution','ASDF systems','Operation','Known limits'])assert(text.includes(expected),expected)
  steps.push('Item Edit Path in HyperDoc')
  const docIndex=await panes().count()-1   // a captured index: last() would follow the newest pane
  // A link of the documentation pane opens its object in the pane to the right; a later link replaces that pane.
  const open=async(label,title)=>{await panes().nth(docIndex).locator('.inspector-inspect').filter({hasText:new RegExp('^'+label.replace(/[.*+?^${}()|[\]\\/]/g,'\\$&')+'$')}).first().click()   // the link, not a code word of the same text
   await panes().nth(docIndex+1).locator('.inspector-title').filter({hasText:title}).first().waitFor()}
  await open('item-edit-preview','ITEM-EDIT-PREVIEW');steps.push('item-edit-preview → the class')
  await open('execute-completed-edit','EXECUTE-COMPLETED-EDIT')
  await panes().nth(docIndex+1).getByRole('button',{name:'Source code',exact:true}).waitFor();steps.push('execute-completed-edit → the function, with its Source code')
  await open('edit-fedwiki-page-item','EDIT-FEDWIKI-PAGE-ITEM');steps.push('edit-fedwiki-page-item → the writer')
  await open('dreyeck/ctm-page-authoring/local','dreyeck/ctm-page-authoring/local');steps.push('the local system')
  assert.deepEqual(errors,[]);assert.equal(sha(pageFile),before);assert.deepEqual(fs.readdirSync(path.join(site,'pages')),['ctm-and-tmdm-in-hyperdoc'])
  fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({status:'PASS',catalogSystem,packages,syntheticPointerInput:syntheticInput,development:false,policy:'ENFORCED',nothingWritten:true,steps},null,2))
  console.log('DOCUMENTATION-BROWSER-PASS: '+steps.join(' → ')+' | clicks '+JSON.stringify(readiness))
 }
}catch(e){
 const pages=browser.contexts().flatMap(c=>c.pages());if(pages.length){fs.writeFileSync(path.join(output,'failure.txt'),await pages[0].locator('body').innerText());await pages[0].screenshot({path:path.join(output,'failure.png')})}
 throw e
}finally{
 await browser.close();fs.writeFileSync(stop,'')
 await new Promise(r=>{if(child.exitCode!==null)r();else{child.once('exit',r);setTimeout(()=>{child.kill();r()},5000).unref()}})
 fs.rmSync(temp,{recursive:true,force:true})
}
