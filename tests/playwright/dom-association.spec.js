"use strict";

const { test, expect } = require("@playwright/test");
const {
  attachJson,
  openHyperDoc,
  readPaneTitles,
  runContentAssociation,
  runHyperDocToFedWikiAssociation,
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

test("content view opens a HyperDoc to FedWiki association through pane-chrome Connect", async ({
  page,
}, testInfo) => {
  const result = await runHyperDocToFedWikiAssociation(page);

  await attachJson(testInfo, "hyperdoc-fedwiki-pane-state.json", result.fedwikiState);
  await attachJson(
    testInfo,
    "hyperdoc-fedwiki-session-after-source.json",
    result.sessionAfterSource
  );
  await attachJson(testInfo, "hyperdoc-fedwiki-browser-trace.json", result.trace);
  await attachJson(testInfo, "hyperdoc-fedwiki-pane-titles.json", result.paneTitles);

  expect(result.fedwikiState.providerKind).toBe("fedwiki-v1");
  expect(result.fedwikiState.activeTab).toBe("Story");
  expect(result.fedwikiState.itemCount).toBeGreaterThan(0);

  expect(result.sessionAfterSource).toBeTruthy();
  expect(result.sessionAfterSource.phase).toBe("choose-target");
  expect(result.sessionAfterSource.source.providerKind).toBe("dom-v1");
  expect(result.sessionAfterSource.source.strategy).toBe("heading-anchor");

  expect(result.trace.requestId).toBeTruthy();
  expect(result.trace.latestStage).toBe("pane-open-succeeded");
  expect(
    result.trace.events.some(
      (event) =>
        event.stage === "target-selected" &&
        event.details &&
        event.details.providerKind === "fedwiki-v1" &&
        event.details.anchor &&
        event.details.anchor.strategy === "fedwiki-story-item" &&
        event.details.anchor.siteDomain === "wiki.ralfbarkow.ch" &&
        event.details.anchor.pageSlug === "find" &&
        !!event.details.anchor.storyItemId
    )
  ).toBe(true);
  expect(
    result.trace.events.some(
      (event) =>
        event.stage === "association-payload-assembled" &&
        event.details &&
        event.details.source &&
        event.details.source.providerKind === "dom-v1" &&
        event.details.target &&
        event.details.target.providerKind === "fedwiki-v1" &&
        event.details.target.strategy === "fedwiki-story-item" &&
        event.details.target.siteDomain === "wiki.ralfbarkow.ch" &&
        event.details.target.pageSlug === "find" &&
        !!event.details.target.storyItemId
    )
  ).toBe(true);
  expect(
    result.trace.events.some(
      (event) =>
        event.stage === "request-payload-written" &&
        event.details &&
        event.details.transport === "button-payload-v2" &&
        event.details.sourceProviderKind === "dom-v1" &&
        event.details.targetProviderKind === "fedwiki-v1" &&
        event.details.sourcePaneId &&
        event.details.targetPaneId &&
        event.details.sourcePaneId !== event.details.targetPaneId
    )
  ).toBe(true);
  expect(
    result.trace.latestPaneSummary &&
      /Association:/.test(result.trace.latestPaneSummary.body)
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
