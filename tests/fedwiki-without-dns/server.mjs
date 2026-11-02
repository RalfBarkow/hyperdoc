// The original Federated Wiki server (wiki-server and its own storage and security modules) on one given address, for the experiment in
// tests/fedwiki-without-dns. Nothing is added to the server: this is the start-up of tests/fedwiki-original-editor/server.mjs without the
// frame adapter, with the listen address as an argument. security_legacy is false: a visitor cannot write.
//   node server.mjs SITE-DIRECTORY HOST PORT
import http from 'node:http'
import path from 'node:path'
import {fileURLToPath, pathToFileURL} from 'node:url'
const [site, host, port] = process.argv.slice(2)
if (!site || !host || !port) throw Error('SITE-DIRECTORY HOST PORT required')
const here = path.dirname(fileURLToPath(import.meta.url))
const packages = path.join(here, '..', 'fedwiki-original-editor', 'node_modules')
const {default: server} = await import(pathToFileURL(path.join(packages, 'wiki-server', 'index.js')).href)
const app = await server({
  root: path.join(packages, 'wiki-server'),
  data: site, db: path.join(site, 'pages'), host, port: Number(port),
  packageDir: packages, home: 'without-dns-test-page',
  security_type: './security.js', security_legacy: false,
})
app.on('owner-set', () => {
  // The request as this server's HTTP layer received it: the evidence of which Host header arrived (host-headers.txt). Nothing else is added.
  const listener = http.createServer((req, res) => {
    console.log(JSON.stringify({request: {method: req.method, url: req.url, host: req.headers.host ?? null, remote: req.socket.remoteAddress}}))
    app(req, res)
  })
  listener.listen(Number(port), host, () => {
    console.log(JSON.stringify({listening: `${host}:${port}`, db: app.startOpts.db, security_legacy: app.startOpts.security_legacy}))
    app.emit('running-serv', listener)
  })
})
