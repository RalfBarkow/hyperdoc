// Launch adapters only. All editing, authorization and storage remain upstream.
import fs from 'node:fs'
import os from 'node:os'
import net from 'node:net'
import path from 'node:path'
import {createHash} from 'node:crypto'
import {spawn, spawnSync} from 'node:child_process'
import {fileURLToPath} from 'node:url'
import {slug, initialPage} from './fixture.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')

export function browserCandidates(platform, env, home) {
  if (env.HYPERDOC_FEDWIKI_BROWSER) return [env.HYPERDOC_FEDWIKI_BROWSER]
  if (platform === 'darwin') return [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    path.join(home,'Applications/Google Chrome.app/Contents/MacOS/Google Chrome'),
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
    path.join(home,'Applications/Chromium.app/Contents/MacOS/Chromium'),
  ]
  return [env.HYPERDOC_FEDWIKI_NIX_BROWSER, 'chromium', 'chromium-browser', 'google-chrome'].filter(Boolean)
}

export function findExecutable(candidate, env=process.env) {
  const candidates = candidate.includes(path.sep) ? [candidate] :
    (env.PATH || '').split(path.delimiter).map(p=>path.join(p,candidate))
  return candidates.find(p=>{try {fs.accessSync(p,fs.constants.X_OK);return fs.statSync(p).isFile()} catch {return false}})
}

export function detectBrowser(env=process.env, platform=process.platform, home=os.homedir()) {
  const failures = []
  for (const candidate of browserCandidates(platform,env,home)) {
    const executable = findExecutable(candidate,env)
    if (!executable) {failures.push(`${candidate}: not executable`);continue}
    const probe = spawnSync(executable,['--version'],{encoding:'utf8',timeout:15000,env})
    const version = (probe.stdout || '').trim()
    if (probe.status === 0 && /(?:Chromium|Google Chrome)\s+\d/.test(version)) return {executable,version}
    failures.push(`${candidate}: --version failed or did not identify Chrome/Chromium`)
  }
  throw Error('No verified Chrome/Chromium. Set HYPERDOC_FEDWIKI_BROWSER to its executable path.\n'+failures.join('\n'))
}

export function checkNode(version=process.versions.node) {
  if (Number(version.split('.')[0]) !== 24) throw Error(`Node 24 is required; got ${version}. Enter nix develop .#fedwiki-original-editor.`)
}

function checkPackages() {
  const manifest = JSON.parse(fs.readFileSync(path.join(here,'package.json')))
  for (const [name, version] of Object.entries({...manifest.dependencies,...manifest.overrides})) {
    let installed
    try {installed = JSON.parse(fs.readFileSync(path.join(here,'node_modules',name,'package.json'))).version} catch {}
    if (installed !== version) throw Error(`Missing/wrong ${name}: run npm ci --prefix tests/fedwiki-original-editor --ignore-scripts`)
  }
}

// Only this disposable demo uses the cache; SLY and normal ASDF outputs are untouched.
export function demoFaslCache(sbcl, env=process.env, home=os.homedir(), platform=process.platform) {
  const root = env.HYPERDOC_FEDWIKI_FASL_CACHE_ROOT ||
    path.join(env.XDG_CACHE_HOME || (platform === 'darwin'
      ? path.join(home,'Library','Caches') : path.join(home,'.cache')),
      'hyperdoc','fedwiki-original-editor')
  const identity = [
    fs.realpathSync(repo), sbcl, env.CL_SOURCE_REGISTRY || '',
    platform, process.arch,
    fs.readFileSync(path.join(repo,'flake.lock'),'utf8'),
    fs.readFileSync(path.join(repo,'dreyeck.asd'),'utf8'),
  ].join('\0')
  const key = createHash('sha256').update(identity).digest('hex').slice(0,24)
  const cache = path.join(root,key)
  fs.mkdirSync(cache,{recursive:true,mode:0o700})
  return cache
}

export function catalogStartupTimeoutMs(env=process.env) {
  const raw = env.HYPERDOC_FEDWIKI_CATALOG_START_TIMEOUT_SECONDS || '900'
  if (!/^\d+$/.test(raw) || +raw < 30 || +raw > 3600) {
    throw Error('HYPERDOC_FEDWIKI_CATALOG_START_TIMEOUT_SECONDS must be 30..3600')
  }
  return Number(raw)*1000
}

function lispEnvironment(work) {
  return {...process.env,
    CL_SOURCE_REGISTRY:`${repo}//:${process.env.CL_SOURCE_REGISTRY || ''}`,
    HYPERDOC_EDITOR_TEST_FASL_DIR:work+'/fasl/'}
}

async function unusedPort(requested, avoid=[]) {
  if (requested && (!/^\d+$/.test(requested) || +requested < 1024 || +requested > 65535 || +requested===8080 || avoid.includes(+requested))) {
    throw Error('Test ports must be distinct, between 1024 and 65535, and never 8080')
  }
  const server = net.createServer()
  await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(requested ? +requested : 0,'127.0.0.1',resolve)})
  const port = server.address().port
  await new Promise(r=>server.close(r))
  if (port===8080 || avoid.includes(port)) return unusedPort(undefined,avoid)
  return port
}

async function interactive(sbcl) {
  // nix develop -c removes its TMPDIR on exit; keep review evidence outside it.
  const work = fs.mkdtempSync(path.join(process.env.HYPERDOC_FEDWIKI_TMPDIR || '/tmp','hyperdoc-wiki-demo-'))
  const site = path.join(work,'site'), stop = path.join(work,'stop-catalog')
  const faslCache = demoFaslCache(sbcl)
  console.log(`Starting isolated demo. Logs and disposable data: ${work}`)
  console.log('Dedicated reusable FASL cache: '+faslCache)
  fs.mkdirSync(path.join(site,'pages'),{recursive:true}); fs.mkdirSync(path.join(work,'home'))
  fs.writeFileSync(path.join(site,'pages',slug),JSON.stringify(initialPage(),null,2)+'\n')
  const wikiPort = await unusedPort(process.env.HYPERDOC_FEDWIKI_WIKI_PORT)
  const catalogPort = await unusedPort(process.env.HYPERDOC_FEDWIKI_CATALOG_PORT,[wikiPort])
  const wikiOrigin = `http://127.0.0.1:${wikiPort}`, catalogOrigin = `http://127.0.0.1:${catalogPort}`
  const children = []
  let interrupted = false, finish
  const done = new Promise(r=>{finish=r})
  const signal = () => {interrupted=true;finish()}
  process.on('SIGINT',signal);process.on('SIGTERM',signal)
  const start = (command,args,label,env) => {
    const fd = fs.openSync(path.join(work,label+'.log'),'w')
    const child = spawn(command,args,{cwd:work,stdio:['ignore',fd,fd],env})
    fs.closeSync(fd);children.push(child)
    child.on('error',()=>finish());child.on('exit',()=>finish())
    return child
  }
  const wait = async (origin,child,label) => {
    const timeoutMs = label === 'catalog' ? catalogStartupTimeoutMs() : 120000
    const began = Date.now(), deadline = began + timeoutMs
    const logFile = path.join(work,label+'.log')
    const tail = () => {
      try {return fs.readFileSync(logFile,'utf8').trimEnd().split('\n').slice(-45).join('\n')}
      catch {return '(no log available)'}
    }
    let progressAt = began
    while (Date.now() < deadline) {
      if (interrupted) throw Error('Demo interrupted during startup')
      if (!child.pid || child.exitCode !== null || child.signalCode !== null) {
        throw Error(label+' exited before readiness (exit='+child.exitCode+
          ', signal='+child.signalCode+').\n'+tail()+'\nFull log: '+logFile)
      }
      try {
        const response = await fetch(origin,{signal:AbortSignal.timeout(1500)})
        if (response.ok) return
      } catch {}
      if (Date.now()-progressAt >= 15000) {
        progressAt = Date.now()
        const seconds = Math.round((Date.now()-began)/1000)
        let bytes = 0
        try {bytes = fs.statSync(logFile).size} catch {}
        console.log(label+' not listening yet ('+seconds+'s, '+bytes+
          ' log bytes); startup/compilation may still be active. Log: '+logFile)
      }
      await new Promise(r=>setTimeout(r,250))
    }
    throw Error(label+' startup exceeded '+Math.round(timeoutMs/1000)+
      's (process still alive). This may be a slow first compilation, not a Lisp error.\n'+
      'Last log lines:\n'+tail()+'\nFull log: '+logFile)
  }
  try {
    const wiki = start(process.execPath,[path.join(here,'server.mjs'),site,String(wikiPort),'true'],'wiki',
      {...process.env, HOME:path.join(work,'home'), HYPERDOC_FEDWIKI_INSPECTOR_ORIGIN:catalogOrigin})
    await wait(wikiOrigin,wiki,'wiki')
    if (!fs.readFileSync(path.join(work,'wiki.log'),'utf8').includes(JSON.stringify({db:path.join(site,'pages'),security_legacy:true}))) {
      throw Error(`No bind confirmation from this Wiki process; inspect ${work}/wiki.log`)
    }
    const catalog = start(sbcl,['--noinform','--no-sysinit','--no-userinit','--script',path.join(here,'serve.lisp')],'catalog',
      {...lispEnvironment(faslCache), HYPERDOC_EDITOR_TEST_CHECKOUT:repo+'/',
        HYPERDOC_EDITOR_TEST_CATALOG_PORT:String(catalogPort), HYPERDOC_EDITOR_TEST_STOP:stop,
        HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT:site+'/', HYPERDOC_FEDWIKI_EDITOR_TEST_ORIGIN:wikiOrigin,
        HYPERDOC_FEDWIKI_EDITOR_TEST_MODE:'isolated-loopback',
        HYPERDOC_FEDWIKI_SITE_ROOT:site+'/'})
    await wait(catalogOrigin,catalog,'catalog')
    if (!fs.readFileSync(path.join(work,'catalog.log'),'utf8').includes(`Listening on 127.0.0.1:${catalogPort}.`)) {
      throw Error(`No bind confirmation from this Catalog process; inspect ${work}/catalog.log`)
    }
    console.log(`Wiki: ${wikiOrigin}/view/${slug}\nCatalog: ${catalogOrigin}\nSite: ${site}\nLogs: ${work}`)
    console.log('Catalog → Original Wiki Editor Test → Text pages → Editing One Isolated Wiki Page')
    console.log('Original client: footer “wiki” enables editing, double-click Code, edit text/language, click outside to save. Then “Read stored page again” in HyperDoc.')
    console.log('Disposable unclaimed loopback site: legacy editing grant, no authenticated login. Known security UI setup error remains. Ctrl-C stops only these test processes.')
    await done
    if (!interrupted) throw Error(`A test process stopped unexpectedly; inspect ${work}`)
  } finally {
    fs.writeFileSync(stop,'stop\n')
    await Promise.all(children.map(async child=>{
      if (!child.pid || child.exitCode!==null || child.signalCode!==null) return
      const exited = new Promise(r=>child.once('exit',r))
      const term=setTimeout(()=>child.kill('SIGTERM'),3000),kill=setTimeout(()=>child.kill('SIGKILL'),6000)
      await exited;clearTimeout(term);clearTimeout(kill)
    }))
    process.off('SIGINT',signal);process.off('SIGTERM',signal)
    console.log(`Demo processes stopped. Disposable data retained at ${work}`)
  }
}

async function main() {
  checkNode();checkPackages()
  const [command,...args] = process.argv.slice(2)
  const sbcl = findExecutable(process.env.HYPERDOC_FEDWIKI_SBCL || 'sbcl')
  if (!sbcl) throw Error('No SBCL from the HyperDoc dev-shell; enter nix develop .#fedwiki-original-editor')
  if (command==='fedwiki-original-editor-demo') {
    if (args.length) throw Error('Demo takes no arguments; optional ports: HYPERDOC_FEDWIKI_WIKI_PORT / HYPERDOC_FEDWIKI_CATALOG_PORT')
    await interactive(sbcl)
  } else if (command==='fedwiki-original-editor-e2e') {
    if (args.length>1) throw Error('E2E takes at most one evidence output directory')
    const browser = detectBrowser()
    console.log(`Browser verified: ${browser.executable}\n${browser.version}`)
    const output = args[0] || fs.mkdtempSync(path.join(process.env.HYPERDOC_FEDWIKI_TMPDIR || '/tmp','hyperdoc-wiki-e2e-'))
    for (const [script,...mode] of [['run.mjs'],['run.mjs','--inspector'],['run-paragraph.mjs']]) {
      const child = spawn(process.execPath,[path.join(here,script),sbcl,browser.executable,output,...mode],
        {cwd:repo,stdio:'inherit',env:lispEnvironment(path.resolve(output))})
      const forward = () => child.kill('SIGINT')
      process.on('SIGINT',forward);process.on('SIGTERM',forward)
      const code = await new Promise((resolve,reject)=>{child.once('error',reject);child.once('exit',resolve)})
      process.off('SIGINT',forward);process.off('SIGTERM',forward)
      process.exitCode = code===null ? 1 : code
      if (process.exitCode) break
    }
  } else throw Error('Use fedwiki-original-editor-demo or fedwiki-original-editor-e2e')
}

if (process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  main().catch(error=>{console.error(error.message);process.exitCode=1})
}
