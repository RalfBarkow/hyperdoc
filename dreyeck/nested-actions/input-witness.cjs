// Replays only retained implementations; assertions compare live objects before serialization.
const fs = require('fs');
const crypto = require('crypto');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
(async () => {
  const browser = await chromium.launch({
    executablePath: process.env.CHROME_EXECUTABLE || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true
  });
  try {
    const page = await (await browser.newContext()).newPage();
    const failures = [];
    page.on('pageerror', e => failures.push(String(e)));
    await page.goto(process.env.INPUT_WITNESS_URL || 'http://127.0.0.1:18740/dreyeck/nested-actions/input-witness.html');
    const [popup] = await Promise.all([
      page.waitForEvent('popup'), page.getByRole('button', { name: 'Open producer popup' }).click()
    ]);
    popup.on('pageerror', e => failures.push(String(e)));
    await popup.waitForLoadState();
    for (const [i, name] of ['Send props.title', 'Send props.name fallback'].entries()) {
      await popup.getByRole('button', { name, exact: true }).click();
      await page.waitForFunction(n => JSON.parse(document.querySelector('#capture').textContent).events.length === n, i + 1);
    }
    if (failures.length) throw Error(failures.join('\n'));
    const capture = JSON.parse(await page.locator('#capture').innerText());
    if (!capture.invocation.stateIsPriorObject || capture.invocation.body.length !== 1) throw Error('run input/body not observed');
    for (const [i, event] of capture.events.entries()) {
      if (!event.actualObjectChecksPassed || !event.listenSelection.dataIsEventData || !event.listenSelection.eventIsReceiverEvent) throw Error('identity measurement failed');
      if (event.listenSelection.count !== i + 1) throw Error('selection failed');
      if (event.receivedPayload.title !== ['Payload Title', 'Fallback Node'][i]) throw Error('producer branch failed');
      if (event.listenerEffect.automaticReportDispatches !== 0) throw Error('unexpected nested dispatch');
      if (event.independentReportProbe.value !== 'Prior Title') throw Error('retained lookup failed');
      if (event.nestedInput.value !== null || event.reportLookupTarget.value !== null) throw Error('fabricated handoff');
    }
    capture.fixtureSha256 = crypto.createHash('sha256').update(fs.readFileSync('dreyeck/nested-actions/input-witness.html')).digest('hex');
    fs.writeFileSync('dreyeck/nested-actions/input-witness.json', JSON.stringify(capture, null, 2) + '\n');
    await page.screenshot({path:'/private/tmp/nested-input-witness.png',fullPage:true});
    console.log(JSON.stringify({status:'NATIVE-INPUT-OBJECT-FLOW-PASS',events:capture.events.length,
      aliasIdentity:capture.events.map(e=>e.listenSelection.dataIsEventData),automaticNestedDispatches:0,
      independentReportTitle:capture.events.map(e=>e.independentReportProbe.value)},null,2));
  } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exit(1)});
