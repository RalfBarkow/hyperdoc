// Explicit read-only acquisition of the exact external imports used by the
// offline browser test. Do not invoke from Story rendering or Lisp TEST-OP.
// Usage: node THIS <external-cache-directory>
import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import {fileURLToPath} from 'node:url'
const cache = process.argv[2]
if (!cache) throw Error('Supply an external cache directory')
const repo = fileURLToPath(new URL('../', import.meta.url))
const target = path.resolve(cache)
if (target === path.resolve(repo) || target.startsWith(path.resolve(repo) + path.sep)) throw Error('Keep execution/cache artifacts outside the source repository')
fs.mkdirSync(target, {recursive: true})
for (const asset of JSON.parse(fs.readFileSync(new URL('../tests/fedwiki-mech-browser-assets.json', import.meta.url)))) {
  const response = await fetch(asset.url)
  if (!response.ok) throw Error(`${asset.url}: HTTP ${response.status}`)
  const bytes = Buffer.from(await response.arrayBuffer())
  const digest = crypto.createHash('sha256').update(bytes).digest('hex')
  if (digest !== asset.sha256) throw Error(`${asset.url}: digest changed (${digest}); no unverified cache entry written`)
  fs.writeFileSync(path.join(target, asset.name), bytes)
}
