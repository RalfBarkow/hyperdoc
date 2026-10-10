// Explicit standalone static host. Run at a different origin from CLOG.
// No Wiki edits, Lisp endpoints, filesystem browse, proxy or shell evaluation.
import http from 'node:http'
import fs from 'node:fs'
import path from 'node:path'
import {fileURLToPath} from 'node:url'
export const root = path.resolve(fileURLToPath(new URL('../assets/hyperbook/fedwiki/mech-host/', import.meta.url)))
export function createMechHost() {
  return http.createServer((req, res) => {
    if (req.method !== 'GET' && req.method !== 'HEAD') { res.writeHead(405); return res.end() }
    const pathname = new URL(req.url, 'http://host.invalid').pathname
    const file = path.resolve(root, '.' + (pathname.endsWith('/') ? pathname + 'index.html' : pathname))
    if (!file.startsWith(root + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) { res.writeHead(404); return res.end('Not found') }
    const types = {'.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json'}
    res.writeHead(200, {'Content-Type': types[path.extname(file)] || 'text/plain', 'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff', 'Referrer-Policy': 'no-referrer',
      // Original Solo has inline scripts and CDN imports. CODE data modules
      // and the original Graph URL are allowed here, not in the Inspector.
      'Content-Security-Policy': "default-src 'none'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' data: https://wardcunningham.github.io https://unpkg.com https://cdn.jsdelivr.net; connect-src 'self' https://wardcunningham.github.io https://unpkg.com; style-src 'self' 'unsafe-inline'; img-src 'self' data:; object-src 'none'; frame-src 'none'; base-uri 'none'; form-action 'none'"})
    res.end(req.method === 'HEAD' ? undefined : fs.readFileSync(file))
  })
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const server = createMechHost()
  server.listen(Number(process.argv[2] || 8099), '127.0.0.1', () => console.log(`Mech static host: http://127.0.0.1:${server.address().port}/`))
}
