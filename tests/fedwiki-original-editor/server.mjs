// Test process adapter only: use the original server, storage and security modules.
import http from 'node:http'
import path from 'node:path'
import {fileURLToPath} from 'node:url'
import fs from 'node:fs'
import {createHash} from 'node:crypto'
import server from 'wiki-server'
const [site, port, legacy] = process.argv.slice(2)
// The only items whose original editor a frame may expose: one per disposable page, by slug.
// HTML files are never involved: the frame names a Wiki page and an item of it.
const targets = {
  'original-editor-test': {id:'2222222222222222', type:'code', legacyParameter:true},
  'assessing-an-upstream-commit': {id:'5555555555555555', type:'paragraph'},
}
if (!site || !port) throw Error('SITE PORT LEGACY required')
const packages = path.join(path.dirname(fileURLToPath(import.meta.url)), 'node_modules')
const app = await server({
  root: path.join(packages, 'wiki-server'),
  data: site, db: path.join(site, 'pages'), host: '127.0.0.1', port: Number(port),
  packageDir: packages, home: 'original-editor-test',
  security_type: './security.js', security_legacy: legacy === 'true',
})
app.on('owner-set', () => {
  const listener = http.createServer(async (req,res) => {
    const url = new URL(req.url,'http://loopback.invalid')
    if (url.pathname === '/hyperdoc/code-editor.js' && req.method==='GET') {
      res.writeHead(200,{'Content-Type':'text/javascript','Cache-Control':'no-store'})
      return res.end(fs.readFileSync(new URL('./inspector-code-editor.js',import.meta.url)))
    }
    if (url.searchParams.has('hyperdocCodeItem') || url.searchParams.has('hyperdocItem')) {
      try {
        const parentOrigin = process.env.HYPERDOC_FEDWIKI_INSPECTOR_ORIGIN
        const slug = url.pathname.startsWith('/view/') ? url.pathname.slice('/view/'.length) : ''
        const target = Object.hasOwn(targets, slug) ? targets[slug] : null
        const requested = url.searchParams.get('hyperdocItem') ?? (target?.legacyParameter ? url.searchParams.get('hyperdocCodeItem') : null)
        if (req.method!=='GET' || !target || legacy!=='true' || !/^http:\/\/127\.0\.0\.1:\d+$/.test(parentOrigin || '') ||
            requested!==target.id) throw Error(`Not an authorized isolated ${target ? target.type[0].toUpperCase()+target.type.slice(1) : 'Code'} target`)
        const bytes = fs.readFileSync(path.join(site,'pages',slug))
        if (url.searchParams.get('revision')!==createHash('sha256').update(bytes).digest('hex')) throw Error('Stale inspection: read the stored page again')
        const matches = JSON.parse(bytes).story.filter(i=>i.id===target.id)
        if (matches.length!==1 || matches[0].type!==target.type) throw Error(`${target.type[0].toUpperCase()+target.type.slice(1)} target is not unique`)
        // Reuse the original page/bootstrap at its normal origin/path. Only this
        // frame response gains the bounded adapter; all JS assets stay original.
        const original = await fetch(`http://127.0.0.1:${port}/view/${slug}`)
        if (!original.ok) throw Error('Original Wiki bootstrap unavailable')
        const config = JSON.stringify({site:'fedwiki:original-editor-test.invalid',slug,id:target.id})
        const extension = `<style>
body > :not(.main):not(#hyperdoc-code-toolbar){display:none!important}
body .main{position:static!important;margin:0!important;padding:8px!important;overflow:visible!important}
.page:not(.hyperdoc-selected-page){display:none!important}
.hyperdoc-selected-page{position:static!important;width:auto!important;margin:0!important;min-height:0!important;box-shadow:none!important}
.hyperdoc-selected-page > :not(.paper){display:none!important}
.hyperdoc-selected-page > .paper > :not(.story){display:none!important}
.story > :not(.hyperdoc-selected-item){display:none!important}
#hyperdoc-code-toolbar{display:block!important;padding:8px;font:14px sans-serif}
.hyperdoc-selected-item textarea{width:95%;min-height:120px}
</style><script id="hyperdoc-code-target" type="application/json">${config}</script><script src="/hyperdoc/code-editor.js" defer></script>`
        res.writeHead(200,{'Content-Type':'text/html','Cache-Control':'no-store','Content-Security-Policy':`frame-ancestors ${parentOrigin}`})
        return res.end((await original.text()).replace('</body>',extension+'</body>'))
      } catch (error) {res.writeHead(409,{'Content-Type':'text/plain'});return res.end(error.message)}
    }
    app(req,res)
  })
  listener.listen(Number(port), '127.0.0.1', () => {
    console.log(JSON.stringify({db: app.startOpts.db, security_legacy: app.startOpts.security_legacy}))
    app.emit('running-serv', listener)
  })
})
