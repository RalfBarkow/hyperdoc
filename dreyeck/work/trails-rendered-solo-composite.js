const uniq = (value, index, self) => self.indexOf(value) === index

class Graph {
  constructor(nodes=[], rels=[]) {
    this.nodes = nodes;
    this.rels = rels;
  }

  addNode(type, props={}){
    const obj = {type, in:[], out:[], props};
    this.nodes.push(obj);
    return this.nodes.length-1;
  }

  addRel(type, from, to, props={}) {
    const obj = {type, from, to, props};
    this.rels.push(obj);
    const rid = this.rels.length-1;
    this.nodes[from].out.push(rid)
    this.nodes[to].in.push(rid);
    return rid;
  }

  tally(){
    const tally = list => list.reduce((s,e)=>{s[e.type] = s[e.type] ? s[e.type]+1 : 1; return s}, {});
    return { nodes:tally(this.nodes), rels:tally(this.rels)};
  }

  size(){
    return this.nodes.length + this.rels.length;
  }

  static load(obj) {
    // let obj = await fetch(url).then(res => res.json())
    return new Graph(obj.nodes, obj.rels)
  }

  static async fetch(url) {
    const obj = await fetch(url).then(res => res.json())
    return Graph.load(obj)
  }

  static async read(path) {
    const json = await Deno.readTextFile(path);
    const obj = JSON.parse(json);
    return Graph.load(obj)
  }

  stringify(...args) {
    const obj = { nodes: this.nodes, rels: this.rels }
    return JSON.stringify(obj, ...args)
  }
}

function composite(concepts) {
  const merged = {nids:[]}
  const comp = new Graph()
  for (const concept of concepts) {
    const {name,graph} = concept
    merge(comp,graph,name)
  }
  return {graph:comp, merged}


  function merge(comp,incr,source) {

    function mergeprops(into,from) {
      const keys = Object.keys(into)
        .concat(Object.keys(from))
        .filter(uniq)
      for (const key of keys) {
        if (into[key]) {
          // if (from[key] && into[key] != from[key]) {
          //   window.result.innerHTML +=
          //     `<div style="font-size:small; padding:4px; background-color:#fee; border-radius:4px; border:1px solid #aaa;">
          //       conflict for "${key}" property<br>
          //       choosing "${into[key]}" over "${from[key]}"</div>`
          // }
        }
        else {
          if(from[key]) {
            into[key] = from[key]
          }
        }
      }
    }

    const nids = {}  // incr => comp
    incr.nodes.forEach((node,id) => {
      const match = comp.nodes.find(each =>
        each.type == node.type &&
        each.props.name == node.props.name)
      if(match) {
        nids[id] = comp.nodes.findIndex(node => node === match)
        merged.nids.push(nids[id])
        mergeprops(match.props, node.props)
      } else {
        nids[id] = comp.addNode(node.type,node.props)
      }
    })
    incr.rels.forEach(rel => {
      const match = comp.rels.find(each =>
        each.type == rel.type &&
        each.from == nids[rel.from] &&
        each.to == nids[rel.to]
      )
      if(match) {
        mergeprops(match.props, rel.props)
      } else {
        rel.props.source = source
        comp.addRel(rel.type, nids[rel.from], nids[rel.to], rel.props)
      }
    })
  }
}
