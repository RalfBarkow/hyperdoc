  function refreshBeam() {
    const now = (new Date).getTime()
    const sections = [
      {date: now-1000*60*60*24*365*100, period: 'Years'},
      {date: now-1000*60*60*24*365, period: 'a Year'},
      {date: now-1000*60*60*24*91, period: 'a Season'},
      {date: now-1000*60*60*24*7*31, period: 'a Month'},
      {date: now-1000*60*60*24*7, period: 'a Week'},
      {date: now-1000*60*60*24, period: 'a Day'},
      {date: now-1000*60*60, period: 'an Hour'},
      {date: now-1000*60, period: 'a Minute'},
      {date: now, period: 'Seconds'}
    ]

    // this.nextdownload = null
    const want = [...window.beamlist.querySelectorAll('input[type=checkbox]:checked')]
      .map(e => +e.value)
    console.log('refreshBeam',want)
    // if (!want.length) window.dochoose({})
    const names = beam.map(poem => poem.name || poem.graph.nodes[0].type)
    let then = 1
    window.beamlist.innerHTML = names
      .map((n,i) => {
        const poem = beam[i]
        let sep = ''
        for (const section of sections) {
          if (then && poem.date && then<section.date && poem.date>=section.date) {
            sep = `<div><font color=gray>Within ${section.period}</font></div>`
          }
        }
        then = poem.date || 1
        const hover = poem.date ? `title="${new Date(poem.date).toLocaleString()}"` : ''
        const number = `<sup>${poem.graph.nodes.length}</sup>`
        return `${sep}<div><font color=gray size=1>${i}</font>
        <input type=checkbox value=${i} id=n${i} ${want.includes(i)?'checked':''}>
        <label for=n${i} ${hover}>${n}${number}</label></div>`
      })
      .join("\n")
    const last = window.beamlist.querySelector('div:last-of-type')
    if(last) last.scrollIntoView({behavior: "smooth", block: "end", inline: "nearest"})
  }
