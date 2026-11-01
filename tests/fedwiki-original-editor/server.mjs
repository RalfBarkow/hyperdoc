// Test process adapter only: use the original server, storage and security modules.
import http from 'node:http'
import path from 'node:path'
import {fileURLToPath} from 'node:url'
import fs from 'node:fs'
import {createHash} from 'node:crypto'
import server from 'wiki-server'
const [site, port, legacy] = process.argv.slice(2)
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
    if (url.searchParams.has('hyperdocCodeItem')) {
      try {
        const parentOrigin = process.env.HYPERDOC_FEDWIKI_INSPECTOR_ORIGIN
        if (req.method!=='GET' || url.pathname!=='/view/original-editor-test' || legacy!=='true' ||
            !/^http:\/\/127\.0\.0\.1:\d+$/.test(parentOrigin || '') ||
            url.searchParams.get('hyperdocCodeItem')!=='2222222222222222') throw Error('Not an authorized isolated Code target')
        const bytes = fs.readFileSync(path.join(site,'pages','original-editor-test'))
        if (url.searchParams.get('revision')!==createHash('sha256').update(bytes).digest('hex')) throw Error('Stale inspection: read the stored page again')
        const matches = JSON.parse(bytes).story.filter(i=>i.id==='2222222222222222')
        if (matches.length!==1 || matches[0].type!=='code') throw Error('Code target is not unique')
        // Reuse the original page/bootstrap at its normal origin/path. Only this
        // frame response gains the bounded adapter; all JS assets stay original.
        const original = await fetch(`http://127.0.0.1:${port}/view/original-editor-test`)
        if (!original.ok) throw Error('Original Wiki bootstrap unavailable')
        const config = JSON.stringify({site:'fedwiki:original-editor-test.invalid',slug:'original-editor-test',id:'2222222222222222'})
        const extension = `<style>
body > :not(.main):not(#hyperdoc-code-toolbar){display:none!important}
body .main{position:static!important;margin:0!important;padding:8px!important;overflow:visible!important}
.page:not(.hyperdoc-selected-page){display:none!important}
.hyperdoc-selected-page{position:static!important;width:auto!important;margin:0!important;min-height:0!important;box-shadow:none!important}
.hyperdoc-selected-page > :not(.paper){display:none!important}
.hyperdoc-selected-page > .paper > :not(.story){display:none!important}
.story > :not(.hyperdoc-selected-code){display:none!important}
#hyperdoc-code-toolbar{display:block!important;padding:8px;font:14px sans-serif}
.hyperdoc-selected-code textarea{width:95%;min-height:120px}
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
