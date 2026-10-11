import test from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import {api,run,blocks} from '../assets/hyperbook/fedwiki/mech-host/plugins/mech/blocks.js'
import {tree} from '../assets/hyperbook/fedwiki/mech-host/plugins/mech/interpreter.js'
import {open as dialogOpen} from '../assets/hyperbook/fedwiki/mech-host/wiki-dialog.js'
import {originalPopup,originalDialog,popupSource,clientSource} from './fedwiki-mech-popup-reference.mjs'
import {largeSitemaps} from './fedwiki-mech-dialog-fixture.mjs'
import {seededRandom} from './fedwiki-mech-topics-reference.mjs'

test('original popup_emit body and original dialog sender survive exact bounded adaptation', () => {
  const source=fs.readFileSync(new URL('../assets/hyperbook/fedwiki/mech-host/plugins/mech/blocks.js',import.meta.url),'utf8')
  assert(source.includes(popupSource));assert.equal(blocks.POPUP.emit.name,'popup_emit')
  const sender=fs.readFileSync(new URL('../assets/hyperbook/fedwiki/mech-host/wiki-dialog.js',import.meta.url),'utf8')
  assert.equal(sender.replace('export { open }','module.exports = { open }'),clientSource)
})

test('actual POPUP dispatch equals original state rendering; values escaped, null omitted, original key limitation retained', async () => {
  const state={text:'<img src=x onerror=bad()> & >',zero:0,flag:false,nested:{text:'<tag>'},missing:null,
    '<b>key</b>':'ordinary value',api:{element:()=>({innerText:'POPUP state'}),trouble:(e,m)=>{throw Error(m)}}}
  const expected=[],actual=[],old=globalThis.wiki
  try {
    originalPopup({elem:{innerText:'POPUP state'},args:['state'],state},(...args)=>expected.push(args))
    globalThis.wiki={dialog:(...args)=>actual.push(args)}
    await run(tree(['POPUP state'],[],0),state,'click')
    assert.deepEqual(actual,expected)
    assert(actual[0][1].includes('&lt;img src=x onerror=bad()&gt; &amp; &gt;'))
    assert(!actual[0][1].includes('<summary>missing</summary>'))
    // A source limitation, not a sanitization claim: keys are not escaped.
    assert(actual[0][1].includes('<summary><b>key</b></summary>'))
  } finally {globalThis.wiki=old}
})

test('1500-entry computed NEIGHBORS/topics/hubs state serializes exactly as original popup_emit', async () => {
  const fixture=largeSitemaps(),state={},calls=[],elements={},old={wiki:globalThis.wiki,now:Date.now,random:Math.random,fetch:globalThis.fetch}
  try {
    globalThis.wiki={neighborhoodObject:{sites:Object.fromEntries(fixture.sites.map(s=>[s.domain,{sitemap:s.sitemap}]))},dialog:(...args)=>calls.push(args)}
    globalThis.fetch=()=>{throw Error('No fixture network')};Date.now=()=>fixture.clock;Math.random=seededRandom(7)
    state.api={...api,element:key=>elements[key]??={id:key,innerText:'POPUP state'},inspect(){},status(){},publishSourceData(){},trouble:(e,m)=>{throw Error(m)}}
    const nest=tree(['NEIGHBORS','WALK 12 weeks','WALK 15 topics','WALK 25 hubs','POPUP state'],[],0);nest.forEach((c,i)=>c.key='large-'+i)
    await run(nest,state,'click')
    assert.equal(state.neighborhood.length,1500);assert.equal(state.aspect.length,3)
    const expected=[];originalPopup({elem:{innerText:'POPUP state'},args:['state'],state},(...args)=>expected.push(args))
    assert.deepEqual(calls,expected);assert(calls[0][1].length>150000)
  } finally {globalThis.wiki=old.wiki;globalThis.fetch=old.fetch;Date.now=old.now;Math.random=old.random}
})

function exercise(factory,pathname,blocked=false) {
  const events=[],listeners={},popup={location:{pathname},addEventListener:(type,fn)=>{events.push(['listener',type]);listeners[type]=fn},postMessage:(data,origin)=>events.push(['message',data,origin])}
  const mock={origin:'https://mech.dreyeck.ch',open:(...args)=>{events.push(['open',...args]);return blocked?null:popup}}
  const old=globalThis.window;globalThis.window=mock
  try {
    const open=factory(mock)
    if(blocked){assert.throws(()=>open('title','body'),/location/);return events}
    open('title','<details>trusted</details>')
    if(pathname!=='/dialog/'){assert.equal(events.filter(e=>e[0]==='message').length,0);listeners.load()}
    return events
  } finally {globalThis.window=old}
}
test('original popup lifecycle defers initial transfer, reuses named dialog and sends only to its own origin', () => {
  for(const pathname of ['blank','/dialog/']) {
    const actual=exercise(()=>dialogOpen,pathname),expected=exercise(originalDialog,pathname)
    assert.equal(JSON.stringify(actual),JSON.stringify(expected))
    assert.deepEqual(actual[0],['open','/dialog/#','dialog','popup,height=600,width=800'])
    assert.deepEqual(actual.at(-1),['message',{title:'title',body:'<details>trusted</details>'},'https://mech.dreyeck.ch'])
  }
})
test('blocked popup remains an explicit error, without fallback permissions or a second receiver', () => {
  assert.deepEqual(exercise(()=>dialogOpen,'blank',true),exercise(originalDialog,'blank',true))
})
test('a foreign named window cannot be read or redirected silently through the dialog sender', () => {
  const old=globalThis.window
  globalThis.window={origin:'https://mech.dreyeck.ch',open:()=>({get location(){throw new DOMException('Cross-origin WindowProxy','SecurityError')}})}
  try{assert.throws(()=>dialogOpen('state','body'),e=>e.name==='SecurityError')}finally{globalThis.window=old}
})
