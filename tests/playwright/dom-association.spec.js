"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  clearConnectFailureModes,
  exactTextPattern,
  forceNextConnectFailureMode,
  openFedWikiPageFromTextPageLink,
  openConnectRequestEvidence,
  openHyperDoc,
  openTextPageFromHyperDoc,
  readConnectSessionState,
  readFedWikiStoryPaneState,
  readInspectorPaneState,
  readPaneTitles,
  runSourceAssociation,
  startConnectInPane,
  waitForAssociationResult,
} = require("./hyperdoc-inspector");
const {
  assertHelpPanelAttachment,
  assertProviderSurfaceSync,
  assertTabClickSafety,
  clearConnectEventTrace,
  openPaneChromeHelp,
  paneChrome,
  readPaneChromeState,
} = require("./pane-chrome-harness");

test.describe.configure({ mode: "serial" });

function tableRowsToMap(rows) {
  return Object.fromEntries(
    (rows || [])
      .filter((row) => row.length >= 2 && row[0])
      .map((row) => [row[0], row.slice(1).join(" ").trim()])
  );
}

test("Connect request evidence opens for a pane-open timeout classification", async ({
  page,
}, testInfo) => {
  const hyperdocPane = await openHyperDoc(page);

  await clearConnectEventTrace(page);
  await clearConnectFailureModes(page);
  await startConnectInPane(page, 1);
  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Text pages") })
    .click();
  await forceNextConnectFailureMode(page, "pane-open-timeout");
  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Data objects") })
    .click();

  const trace = await waitForAssociationResult(page);
  const chromeAfterFailure = await readPaneChromeState(page, 1);
  const evidence = await openConnectRequestEvidence(page, 1);
  const summaryPane = await readInspectorPaneState(page, evidence.index);
  const summaryRows = tableRowsToMap(summaryPane.tables[0]);

  await activatePaneTab(page, evidence.index, "Failure / Boundary");
  const failurePane = await readInspectorPaneState(page, evidence.index);

  await attachJson(testInfo, "connect-timeout-trace.json", trace);
  await attachJson(testInfo, "connect-timeout-pane-chrome.json", chromeAfterFailure);
  await attachJson(testInfo, "connect-timeout-evidence-summary.json", summaryPane);
  await attachJson(testInfo, "connect-timeout-evidence-failure.json", failurePane);

  expect(trace.latestStage).toBe("request-failed");
  expect(
    trace.events.some(
      (event) =>
        event.stage === "request-failed" &&
        event.details &&
        event.details.failureKind === "pane-open-timeout"
    )
  ).toBe(true);
  expect(chromeAfterFailure.feedbackKind).toBe("error");
  expect(chromeAfterFailure.feedbackText).toContain("Inspect request evidence");
  expect(summaryRows["Request id"]).toBe(trace.requestId);
  expect(summaryRows["Browser failure kind"]).toBe("pane-open timeout");
  expect(failurePane.bodyText).toContain(
    "No server acknowledgement arrived before the request timed out."
  );
});

test("Connect request evidence classifies websocket disconnect before acknowledgement separately", async ({
  page,
}, testInfo) => {
  const hyperdocPane = await openHyperDoc(page);

  await clearConnectEventTrace(page);
  await clearConnectFailureModes(page);
  await startConnectInPane(page, 1);
  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Text pages") })
    .click();
  await forceNextConnectFailureMode(page, "websocket-disconnect-before-acknowledgement");
  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Data objects") })
    .click();

  const trace = await waitForAssociationResult(page);
  const chromeAfterFailure = await readPaneChromeState(page, 1);
  const evidence = await openConnectRequestEvidence(page, 1);
  const summaryPane = await readInspectorPaneState(page, evidence.index);
  const summaryRows = tableRowsToMap(summaryPane.tables[0]);

  await activatePaneTab(page, evidence.index, "Failure / Boundary");
  const failurePane = await readInspectorPaneState(page, evidence.index);

  await attachJson(testInfo, "connect-disconnect-trace.json", trace);
  await attachJson(testInfo, "connect-disconnect-pane-chrome.json", chromeAfterFailure);
  await attachJson(testInfo, "connect-disconnect-evidence-summary.json", summaryPane);
  await attachJson(testInfo, "connect-disconnect-evidence-failure.json", failurePane);

  expect(trace.latestStage).toBe("request-failed");
  expect(
    trace.events.some(
      (event) =>
        event.stage === "request-failed" &&
        event.details &&
        event.details.failureKind ===
          "websocket-disconnect-before-acknowledgement"
    )
  ).toBe(true);
  expect(chromeAfterFailure.feedbackKind).toBe("error");
  expect(chromeAfterFailure.feedbackText).toContain("Inspect request evidence");
  expect(summaryRows["Request id"]).toBe(trace.requestId);
  expect(summaryRows["Browser failure kind"]).toBe(
    "websocket disconnect before acknowledgement"
  );
  expect(failurePane.bodyText).toContain(
    "WebSocket closed before any server acknowledgement for this request."
  );
});

test("content view opens an association through pane-chrome Connect", async ({
  page,
}, testInfo) => {
  const hyperdocPane = await openHyperDoc(page);
  await clearConnectEventTrace(page);
  await startConnectInPane(page, 1);
  const chromeAfterStart = await readPaneChromeState(page, 1);

  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Text pages") })
    .click();
  const chromeAfterSource = await readPaneChromeState(page, 1);

  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Data objects") })
    .click();

  const trace = await waitForAssociationResult(page);
  const chromeAfterResult = await readPaneChromeState(page, 1);
  const paneTitles = await readPaneTitles(page);

  await attachJson(testInfo, "content-chrome-after-start.json", chromeAfterStart);
  await attachJson(testInfo, "content-chrome-after-source.json", chromeAfterSource);
  await attachJson(testInfo, "content-chrome-after-result.json", chromeAfterResult);
  await attachJson(testInfo, "content-browser-trace.json", trace);
  await attachJson(testInfo, "content-pane-titles.json", paneTitles);

  expect(chromeAfterStart.connectState).toBe("select-source");
  expect(chromeAfterStart.statusText).toBe("Pick source");
  expect(chromeAfterStart.cueText).toBe("Click a source anchor.");
  expect(chromeAfterStart.sourceSummaryHidden).toBe(true);

  expect(chromeAfterSource.connectState).toBe("select-target");
  expect(chromeAfterSource.statusText).toBe("Pick target");
  expect(chromeAfterSource.sourceChipText).toBe("Text pages");
  expect(chromeAfterSource.clearHidden).toBe(false);
  expect(chromeAfterSource.cueText).toBe("Click a target anchor.");

  expect(chromeAfterResult.toggleMode).toBe("inactive");
  expect(chromeAfterResult.feedbackKind).toBe("success");
  expect(chromeAfterResult.feedbackText).toContain("Text pages");
  expect(chromeAfterResult.feedbackText).toContain("Data objects");

  expect(trace.requestId).toBeTruthy();
  expect(trace.latestStage).toBe("pane-open-succeeded");
  expect(
    trace.events.some(
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
    trace.events.some(
      (event) =>
        event.stage === "request-payload-written" &&
        event.details &&
        event.details.transport === "button-payload-v2"
    )
  ).toBe(true);
  expect(
    trace.latestPaneSummary &&
      /Association: Text pages -> Data objects/.test(
        trace.latestPaneSummary.body
      )
  ).toBe(true);
});

test("content view opens a cross-pane association through pane-chrome Connect", async ({
  page,
}, testInfo) => {
  const title = "Creating a HyperDoc";
  const hyperdocPane = await openHyperDoc(page);
  const textPagePane = await openTextPageFromHyperDoc(page, title);

  await activatePaneTab(page, 1, "Main page");
  await activatePaneTab(page, 2, "Content");
  await clearConnectEventTrace(page);
  await startConnectInPane(page, 1);

  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Text pages") })
    .click();

  const sourceChromeAfterSource = await readPaneChromeState(page, 1);
  const targetChromeAfterSource = await readPaneChromeState(page, 2);
  const sessionAfterSource = await readConnectSessionState(page);

  await textPagePane
    .locator(".hyperdoc-connect-provider-root h1")
    .filter({ hasText: exactTextPattern(title) })
    .click();

  const trace = await waitForAssociationResult(page);
  const paneTitles = await readPaneTitles(page);

  await attachJson(testInfo, "two-pane-source-chrome-after-source.json", sourceChromeAfterSource);
  await attachJson(testInfo, "two-pane-target-chrome-after-source.json", targetChromeAfterSource);
  await attachJson(testInfo, "two-pane-session-after-source.json", sessionAfterSource);
  await attachJson(testInfo, "two-pane-browser-trace.json", trace);
  await attachJson(testInfo, "two-pane-pane-titles.json", paneTitles);

  expect(sourceChromeAfterSource.statusText).toBe("Pick target");
  expect(sourceChromeAfterSource.sourceChipText).toBe("Text pages");
  expect(targetChromeAfterSource.statusText).toBe("Pick target");
  expect(targetChromeAfterSource.sourceChipText).toBe("Text pages");
  expect(targetChromeAfterSource.clearHidden).toBe(false);

  expect(sessionAfterSource).toBeTruthy();
  expect(sessionAfterSource.phase).toBe("choose-target");
  expect(sessionAfterSource.sourcePaneId).toBeTruthy();
  expect(trace.requestId).toBeTruthy();
  expect(trace.latestStage).toBe("pane-open-succeeded");
  expect(
    trace.events.some(
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
    trace.latestPaneSummary &&
      /Association: Text pages -> Creating a HyperDoc/.test(
        trace.latestPaneSummary.body
      )
  ).toBe(true);
});

test("content view opens a HyperDoc to FedWiki association through pane-chrome Connect", async ({
  page,
}, testInfo) => {
  const hyperdocTitle = "Linking HyperDoc pages to FedWiki pages";
  const fedwikiLinkText = "FIND";

  await openHyperDoc(page);
  const textPagePane = await openTextPageFromHyperDoc(page, hyperdocTitle);
  const fedwikiPane = await openFedWikiPageFromTextPageLink(page, 2, fedwikiLinkText);

  await activatePaneTab(page, 2, "Content");
  await activatePaneTab(page, 3, "Story");
  const fedwikiState = await readFedWikiStoryPaneState(page, 3);

  await clearConnectEventTrace(page);
  await startConnectInPane(page, 2);
  await textPagePane
    .locator(".hyperdoc-connect-provider-root h1")
    .filter({ hasText: exactTextPattern(hyperdocTitle) })
    .click();

  const sourceChromeAfterSource = await readPaneChromeState(page, 2);
  const fedwikiChromeAfterSource = await readPaneChromeState(page, 3);
  const sessionAfterSource = await readConnectSessionState(page);

  await fedwikiPane.locator(".hyperdoc-fedwiki-story-item-anchor").nth(0).click();

  const trace = await waitForAssociationResult(page);
  const paneTitles = await readPaneTitles(page);

  await attachJson(testInfo, "hyperdoc-fedwiki-pane-state.json", fedwikiState);
  await attachJson(testInfo, "hyperdoc-fedwiki-source-chrome-after-source.json", sourceChromeAfterSource);
  await attachJson(testInfo, "hyperdoc-fedwiki-target-chrome-after-source.json", fedwikiChromeAfterSource);
  await attachJson(testInfo, "hyperdoc-fedwiki-session-after-source.json", sessionAfterSource);
  await attachJson(testInfo, "hyperdoc-fedwiki-browser-trace.json", trace);
  await attachJson(testInfo, "hyperdoc-fedwiki-pane-titles.json", paneTitles);

  expect(fedwikiState.providerKind).toBe("fedwiki-v1");
  expect(fedwikiState.activeTab).toBe("Story");
  expect(fedwikiState.itemCount).toBeGreaterThan(0);

  expect(sourceChromeAfterSource.statusText).toBe("Pick target");
  expect(sourceChromeAfterSource.sourceChipText).toBe(hyperdocTitle);
  expect(fedwikiChromeAfterSource.statusText).toBe("Pick target");
  expect(fedwikiChromeAfterSource.sourceChipText).toBe(hyperdocTitle);

  expect(sessionAfterSource).toBeTruthy();
  expect(sessionAfterSource.phase).toBe("choose-target");
  expect(sessionAfterSource.source.providerKind).toBe("dom-v1");
  expect(sessionAfterSource.source.strategy).toBe("heading-anchor");

  expect(trace.requestId).toBeTruthy();
  expect(trace.latestStage).toBe("pane-open-succeeded");
  expect(
    trace.events.some(
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
    trace.events.some(
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
    trace.events.some(
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
    trace.latestPaneSummary &&
      /Association:/.test(trace.latestPaneSummary.body)
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

test("Connect clear and cancel restore a clean pre-selection state", async ({
  page,
}, testInfo) => {
  const hyperdocPane = await openHyperDoc(page);
  const chrome = paneChrome(page, 1);

  await startConnectInPane(page, 1);
  const chromeAfterStart = await readPaneChromeState(page, 1);

  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Text pages") })
    .click();
  const chromeAfterSource = await readPaneChromeState(page, 1);

  await expect(chrome.clearButton).toBeVisible();
  await chrome.clearButton.click();
  const chromeAfterClear = await readPaneChromeState(page, 1);

  await expect(chrome.cancelButton).toBeVisible();
  await chrome.cancelButton.click();
  const chromeAfterCancel = await readPaneChromeState(page, 1);

  await attachJson(testInfo, "connect-clear-cancel-start.json", chromeAfterStart);
  await attachJson(testInfo, "connect-clear-cancel-source.json", chromeAfterSource);
  await attachJson(testInfo, "connect-clear-cancel-clear.json", chromeAfterClear);
  await attachJson(testInfo, "connect-clear-cancel-cancel.json", chromeAfterCancel);

  expect(chromeAfterStart.statusText).toBe("Pick source");
  expect(chromeAfterSource.statusText).toBe("Pick target");
  expect(chromeAfterSource.sourceChipText).toBe("Text pages");

  expect(chromeAfterClear.connectState).toBe("select-source");
  expect(chromeAfterClear.statusText).toBe("Pick source");
  expect(chromeAfterClear.sourceSummaryHidden).toBe(true);
  expect(chromeAfterClear.clearHidden).toBe(true);
  expect(chromeAfterClear.cueText).toBe("Click a source anchor.");

  expect(chromeAfterCancel.toggleMode).toBe("inactive");
  expect(chromeAfterCancel.connectState).toBe("dormant");
  expect(chromeAfterCancel.statusHidden).toBe(true);
  expect(chromeAfterCancel.sourceSummaryHidden).toBe(true);
  expect(chromeAfterCancel.cueText).toBe("Click Connect to start.");
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
