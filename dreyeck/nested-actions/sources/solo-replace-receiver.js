  window.addEventListener("message",event => {
    const data = event.data
    console.log({data})
    pageKey = data.pageKey
    beam.splice(0)
    for (const source of data.sources){
      source.date = Date.now()
      beam.push(...source.aspects)}
    console.log({data,beam})
    refreshBeam()
  })
