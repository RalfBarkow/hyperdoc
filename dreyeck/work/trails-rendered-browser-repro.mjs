// Read-only original CLICK -> CODE execution in a fresh Playwright context.
// Usage: node trails-rendered-browser-repro.mjs OUTPUT_DIRECTORY [WIKI_URL]
// Install playwright-core; optionally set TRAILS_PLAYWRIGHT_MODULE to its entry
// and TRAILS_CHROMIUM_EXECUTABLE to a Chromium executable. Default channel: chrome.
// The output retains public response bodies, diagnostics and a screenshot.
import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const require = createRequire(import.meta.url);
const {chromium} = require(process.env.TRAILS_PLAYWRIGHT_MODULE || 'playwright-core');
const dir = process.argv[2];
if (!dir) throw new Error('An output directory is required.');
fs.mkdirSync(dir, {recursive: true});
const evidence = {
  started: new Date().toISOString(),
  url: process.argv[3] || 'http://ward.voices.ustawi.wiki/view/trails-rendered',
  outcome: 'not-run', diagnostic: null, console: [], pageErrors: [],
  failedRequests: [], requests: [], responses: [], sources: []
};
const browser = await chromium.launch({headless: true,
  ...(process.env.TRAILS_CHROMIUM_EXECUTABLE
    ? {executablePath: process.env.TRAILS_CHROMIUM_EXECUTABLE} : {channel: 'chrome'})});
evidence.browser = browser.version();
const context = await browser.newContext();
const page = await context.newPage();
const pending = [];
page.on('request', r => evidence.requests.push({url: r.url(), type: r.resourceType(), at: new Date().toISOString()}));
page.on('console', m => evidence.console.push({at: new Date().toISOString(), type: m.type(), text: m.text(), location: m.location()}));
page.on('pageerror', e => evidence.pageErrors.push({name: e.name, message: e.message, stack: e.stack}));
page.on('requestfailed', r => evidence.failedRequests.push({url: r.url(), failure: r.failure(), type: r.resourceType()}));
page.on('response', r => {
  const url = r.url();
  const entry = {url, status: r.status(), type: r.request().resourceType()};
  evidence.responses.push(entry);
  if (/\/plugins\/(mech|code)\/|wardcunningham\.github\.io\/graph\/|(?:trails-rendered|welcome-visitors)\.json/.test(url)) {
    pending.push((async () => {
      try {
        const data = await r.body();
        const sha256 = crypto.createHash('sha256').update(data).digest('hex');
        const extension = path.extname(new URL(url).pathname) || '.body';
        const file = sha256 + extension;
        fs.writeFileSync(path.join(dir, file), data);
        evidence.sources.push({url, status: r.status(), sha256, file,
          headers: await r.allHeaders(), bytes: data.length});
      } catch (e) { entry.bodyError = e.message; }
    })());
  }
});
try {
  const navigation = await page.goto(evidence.url, {waitUntil: 'networkidle', timeout: 45000});
  evidence.navigation = {url: page.url(), status: navigation?.status(), headers: await navigation?.allHeaders()};
  if (!navigation?.ok()) {
    evidence.outcome = 'navigation-failed';
  } else {
    const mech = page.locator('#trails-rendered .item.mech');
    await mech.getByRole('button', {name: '▶', exact: true}).first().waitFor({timeout: 20000});
    evidence.before = await page.evaluate(() => ({url: location.href, isOwner: window.isOwner,
      items: [...document.querySelectorAll('.item')].map(e => ({page: e.closest('.page')?.id, site: e.closest('.page')?.dataset.site, id: e.dataset.id, type: e.className,
        text: e.innerText.slice(0, 200)})), scripts: [...document.scripts].map(s => s.src),
      mechLoaded: !!window.plugins?.mech, codeLoaded: !!window.plugins?.code,
      mechBuild: globalThis.__MECH_BUILD__ || null,
      lineup: [...document.querySelectorAll('.page')].map(e => {const key = $(e).data('key');
        const object = wiki.lineup.atKey(key);
        return {slug: e.id, site: $(e).data('site') || location.host, key,
          title: object?.getRawPage?.()?.title, remote: object?.isRemote?.()};})}));
    evidence.clickStarted = new Date().toISOString();
    await mech.getByRole('button', {name: '▶', exact: true}).first().click();
    await page.waitForFunction(() => [...document.querySelectorAll('#trails-rendered .item.mech')]
      .some(e => /CODE trails/.test(e.innerText) && /✖︎|⇒/.test(e.innerText)), {}, {timeout: 20000});
    evidence.after = await mech.innerText();
    const trouble = mech.getByRole('button', {name: '✖︎', exact: true}).first();
    if (await trouble.count()) {
      evidence.troubleClicked = new Date().toISOString();
      await trouble.click();
      evidence.diagnosticMessage = await mech.getByRole('button', {name: '✖︎', exact: true}).first()
        .evaluate(b => b.parentElement.nextElementSibling?.innerText || null);
      evidence.diagnostic = await mech.innerText();
      evidence.outcome = 'trouble';
    } else evidence.outcome = 'success';
    evidence.dom = await mech.innerHTML();
  }
  await page.screenshot({path: path.join(dir, 'after.png'), fullPage: true});
} catch (e) {
  evidence.outcome = 'automation-failed';
  evidence.automationError = {message: e.message, stack: e.stack};
  evidence.failedDom = await page.locator('body').innerText().catch(() => null);
  await page.screenshot({path: path.join(dir, 'after.png'), fullPage: true}).catch(() => {});
} finally {
  await Promise.allSettled(pending);
  evidence.finished = new Date().toISOString();
  fs.writeFileSync(path.join(dir, 'evidence.json'), JSON.stringify(evidence, null, 2) + '\n');
  await browser.close();
}
console.log(JSON.stringify({outcome: evidence.outcome, after: evidence.after,
  diagnostic: evidence.diagnostic, output: path.resolve(dir)}));
if (evidence.outcome === 'automation-failed') process.exitCode = 1;
