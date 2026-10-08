  const dopopup = event => {
    const graphs = todo.shift()
    todo.push(graphs)
    const doing = {type:'batch', graphs}
    const popup = window.open('/plugins/solo/dialog/#','solo','popup,height=720,width=1280')
    if (popup.location.pathname != '/plugins/solo/dialog/'){
      console.log('launching new dialog')
      popup.addEventListener('load', event => {
        console.log('launched and loaded')
        popup.postMessage(doing, window.origin)
      })
    }
    else {
      console.log('reusing existing dialog')
      popup.postMessage(doing, window.origin)
    }
  }
