// Test process adapter only: use the original server, storage and security modules.
import http from 'node:http'
import path from 'node:path'
import {fileURLToPath} from 'node:url'
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
  const listener = http.createServer(app)
  listener.listen(Number(port), '127.0.0.1', () => {
    console.log(JSON.stringify({db: app.startOpts.db, security_legacy: app.startOpts.security_legacy}))
    app.emit('running-serv', listener)
  })
})
