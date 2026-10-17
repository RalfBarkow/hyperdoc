// An Inspector link, tab or button is in the page before its click handler is bound: the server
// inserts the view's HTML first and then, element by element, attaches the handlers
// (clog-moldable-inspector, SET-EVENT-HANDLERS). A click in between is lost without a trace.
// Measured: the binding follows the insertion by 7 to 24 ms for a link of Work Breakdown, and a click
// delivered before it opened no pane in 6 of 6 trials, while a click after it opened one in 3 of 3.
// installBoundClicks makes every Locator.click wait until the element's handler is bound. It is a
// check of readiness, not a retry: the click is made once.
const waitForBinding=(el,limit)=>new Promise(resolve=>{
  const jq=window.jQuery
  if(!jq||!jq._data)return resolve({bound:true,relevant:false})
  const selector='[id^="inspect-"],[id^="eval-"],[id^="action-"]'
  const relevant=el.tagName==='BUTTON'||el.matches('.inspector-inspect, .inspector-inspect *')||!!el.closest(selector)||!!el.querySelector(selector)
  if(!relevant)return resolve({bound:true,relevant:false})
  const targets=()=>[el,...el.querySelectorAll(selector),el.closest(selector)].filter(Boolean)
  const bound=()=>targets().some(x=>{const ev=jq._data(x,'events');return !!(ev&&ev.click)})
  const start=performance.now()
  const poll=()=>{if(bound())return resolve({bound:true,relevant:true,waitedMs:Math.round(performance.now()-start)})
    if(performance.now()-start>limit)return resolve({bound:false,relevant:true,waitedMs:Math.round(performance.now()-start)})
    setTimeout(poll,2)}
  poll()
})
export const readiness={waited:0,unbound:0,maxWaitMs:0,settledReads:0,unsettled:0}
// A second window of the same kind: a pane that is opened with a view selected renders its default view,
// then the selected one, so a read of its text between the two can see a part of it. (Seen once in 20 runs
// of the proposal script, at the pane of the recorded trial; the explanation fits what the screenshot
// showed and has not been proven.) A text read therefore waits until two reads, 50 ms apart, agree.
const settle=async(original,locator,options)=>{
  let previous=await original.call(locator,options)
  for(let n=0;n<40;n++){
    await new Promise(r=>setTimeout(r,50))
    const current=await original.call(locator,options)
    if(current===previous){readiness.settledReads++;return current}
    previous=current
  }
  readiness.unsettled++;return previous
}
export function installBoundClicks(page,{limitMs=3000}={}){
  const Locator=page.locator('body').constructor
  if(Locator.prototype.__boundClicks)return
  const original=Locator.prototype.click
  Locator.prototype.click=async function(options){
    const result=await this.evaluate(waitForBinding,limitMs)
    if(result.relevant){readiness.waited++;readiness.maxWaitMs=Math.max(readiness.maxWaitMs,result.waitedMs||0)}
    if(!result.bound){readiness.unbound++;console.error('inspector-ready: no click handler bound after '+limitMs+' ms for '+this)}
    return original.call(this,options)
  }
  const originalInnerText=Locator.prototype.innerText
  Locator.prototype.innerText=function(options){return settle(originalInnerText,this,options)}
  Locator.prototype.__boundClicks=true
}
