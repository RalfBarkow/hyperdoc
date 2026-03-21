"use strict";

const { test, expect } = require("@playwright/test");
const {
  attachJson,
  openHyperDoc,
  readPaneTitles,
  runContentAssociation,
  runTwoPaneContentAssociation,
  runSourceAssociation,
} = require("./hyperdoc-inspector");
const {
  assertHelpPanelAttachment,
  assertProviderSurfaceSync,
  assertTabClickSafety,
  openPaneChromeHelp,
  readPaneChromeState,
} = require("./pane-chrome-harness");

test.describe.configure({ mode: "serial" });

test("content view opens an association through pane-chrome Connect", async ({
  page,
}, testInfo) => {
  const result = await runContentAssociation(page);

  await attachJson(testInfo, "content-browser-trace.json", result.trace);
  await attachJson(testInfo, "content-pane-titles.json", result.paneTitles);

  expect(result.trace.requestId).toBeTruthy();
  expect(result.trace.latestStage).toBe("pane-open-succeeded");
  expect(
    result.trace.events.some(
      (event) =>
        event.stage === "association-payload-assembled" &&
        event.details &&
        event.details.source &&
        event.details.source.providerKind === "dom-v1" &&
        event.details.target &&
        event.details.target.providerKind === "dom-v1"
    )
  ).toBe(true);
  expect(
    result.trace.events.some(
      (event) =>
        event.stage === "request-payload-written" &&
        event.details &&
        event.details.transport === "button-payload-v2"
    )
  ).toBe(true);
  expect(
    result.trace.latestPaneSummary &&
      /Association: Text pages -> Data objects/.test(
        result.trace.latestPaneSummary.body
      )
  ).toBe(true);
});

test("content view opens a cross-pane association through pane-chrome Connect", async ({
  page,
}, testInfo) => {
  const result = await runTwoPaneContentAssociation(page, "Creating a HyperDoc");

  await attachJson(testInfo, "two-pane-session-after-source.json", result.sessionAfterSource);
  await attachJson(testInfo, "two-pane-browser-trace.json", result.trace);
  await attachJson(testInfo, "two-pane-pane-titles.json", result.paneTitles);

  expect(result.sessionAfterSource).toBeTruthy();
  expect(result.sessionAfterSource.phase).toBe("choose-target");
  expect(result.sessionAfterSource.sourcePaneId).toBeTruthy();
  expect(result.trace.requestId).toBeTruthy();
  expect(result.trace.latestStage).toBe("pane-open-succeeded");
  expect(
    result.trace.events.some(
      (event) =>
        event.stage === "request-payload-written" &&
        event.details &&
        event.details.transport === "button-payload-v2" &&
        event.details.sourcePaneId &&
        event.details.targetPaneId &&
        event.details.sourcePaneId !== event.details.targetPaneId
    )
  ).toBe(true);
  expect(
    result.trace.latestPaneSummary &&
      /Association: Text pages -> Creating a HyperDoc/.test(
        result.trace.latestPaneSummary.body
      )
  ).toBe(true);
});

test("pane-chrome help opens without shifting the active view", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  const before = await readPaneChromeState(page, 1);
  const after = await openPaneChromeHelp(page, 1);

  await attachJson(testInfo, "help-before.json", before);
  await attachJson(testInfo, "help-after.json", after);

  assertHelpPanelAttachment(before, after);
});

test("main tabs stay clickable while Connect help is open", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  const states = await assertTabClickSafety(page, 1, ["Systems", "Pages", "Main page"], {
    openHelp: true,
  });

  await attachJson(testInfo, "tab-click-safety.json", states);
  expect(states[states.length - 1].paneTitles[1].activeTab).toBe("Main page");
});

test("provider-surface sync settles across a Pages round trip", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  const sync = await assertProviderSurfaceSync(page, 1, {
    connectableTab: "Main page",
    nonConnectableTab: "Pages",
    returnTab: "Main page",
  });

  await attachJson(testInfo, "provider-sync.json", sync);

  expect(sync.connectable.chrome.slotHidden).toBe(false);
  expect(sync.nonConnectable.chrome.slotHidden).toBe(true);
  expect(sync.returned.chrome.slotHidden).toBe(false);
  expect(sync.returned.paneTitles[1].activeTab).toBe("Main page");
});

test("source view exposes source anchors and opens an association", async (
  { page },
  testInfo
) => {
  test.setTimeout(35_000);
  test.fail(
    true,
    "Known current boundary: automated navigation into a text page and its Source provider is not yet reliable under Playwright in this release build."
  );

  const result = await runSourceAssociation(page, "Creating a HyperDoc");

  await attachJson(testInfo, "source-pane-state.json", result.sourceState);
  await attachJson(testInfo, "source-browser-trace.json", result.trace);
  await attachJson(testInfo, "source-pane-titles.json", result.paneTitles);

  expect(result.sourceState.providerKind).toBe("source-v1");
  expect(result.sourceState.activeTab).toBe("Source");
  expect(result.sourceState.lineCount).toBeGreaterThan(5);

  expect(result.trace.requestId).toBeTruthy();
  expect(result.trace.latestStage).toBe("pane-open-succeeded");
  expect(
    result.trace.events.some(
      (event) =>
        event.stage === "association-payload-assembled" &&
        event.details &&
        event.details.source &&
        event.details.source.providerKind === "source-v1" &&
        event.details.target &&
        event.details.target.providerKind === "source-v1"
    )
  ).toBe(true);
  expect(
    result.trace.events.some(
      (event) =>
        event.stage === "request-payload-written" &&
        event.details &&
        event.details.sourceProviderKind === "source-v1" &&
        event.details.targetProviderKind === "source-v1" &&
        event.details.transport === "button-payload-v2"
    )
  ).toBe(true);
  expect(
    result.trace.latestPaneSummary &&
      /Association: Line 1/.test(result.trace.latestPaneSummary.body)
  ).toBe(true);
});
