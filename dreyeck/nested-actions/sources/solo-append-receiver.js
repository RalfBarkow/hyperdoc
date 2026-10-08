  window.addEventListener("message",event => {
    const data = event.data
    for (const graph of data.graphs)
      graph.date = Date.now()
    console.log({data})
    beam.push(...data.graphs)
    refreshBeam()
  })
