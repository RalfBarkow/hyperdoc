"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  openHyperDoc,
  readHelpPanelState,
  readPaneTitles,
  runContentAssociation,
  runSourceAssociation,
  toggleHelpInPane,
} = require("./hyperdoc-inspector");

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
        event.details.providerKind === "dom-v1"
    )
  ).toBe(true);
  expect(
    result.trace.events.some(
      (event) =>
        event.stage === "request-payload-written" &&
        event.details &&
        event.details.transport === "button-payload-v1"
    )
  ).toBe(true);
  expect(
    result.trace.latestPaneSummary &&
      /Association: Text pages -> Data objects/.test(
        result.trace.latestPaneSummary.body
      )
  ).toBe(true);
});

test("pane-chrome help opens without shifting the active view", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  const before = await readHelpPanelState(page, 1);
  const after = await toggleHelpInPane(page, 1);

  await attachJson(testInfo, "help-before.json", before);
  await attachJson(testInfo, "help-after.json", after);

  expect(before.slotHelpOpen).toBe("false");
  expect(before.helpExpanded).toBe("false");
  expect(before.panelDisplay).toBe("none");

  expect(after.slotHelpOpen).toBe("true");
  expect(after.helpExpanded).toBe("true");
  expect(after.helpAriaHidden).toBe("false");
  expect(after.panelDisplay).toBe("block");
  expect(after.tabRowHeight).toBe(before.tabRowHeight);
  expect(after.activeViewTop).toBe(before.activeViewTop);
  expect(after.documentScrollHeight).toBe(before.documentScrollHeight);
  expect(after.panelTop).toBeGreaterThan(after.controlBottom);
});

test("Pages tab stays clickable while Connect help is open", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  const before = await readHelpPanelState(page, 1);
  const withHelp = await toggleHelpInPane(page, 1);
  await activatePaneTab(page, 1, "Pages");
  const after = await readHelpPanelState(page, 1);
  const paneTitles = await readPaneTitles(page);

  await attachJson(testInfo, "pages-tab-before.json", before);
  await attachJson(testInfo, "pages-tab-with-help.json", withHelp);
  await attachJson(testInfo, "pages-tab-after.json", after);
  await attachJson(testInfo, "pages-tab-pane-titles.json", paneTitles);

  expect(before.slotHidden).toBe(false);
  expect(withHelp.helpExpanded).toBe("true");
  expect(withHelp.helpAriaHidden).toBe("false");
  expect(paneTitles[1].activeTab).toBe("Pages");
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
        event.details.providerKind === "source-v1"
    )
  ).toBe(true);
  expect(
    result.trace.events.some(
      (event) =>
        event.stage === "request-payload-written" &&
        event.details &&
        event.details.providerKind === "source-v1" &&
        event.details.transport === "button-payload-v1"
    )
  ).toBe(true);
  expect(
    result.trace.latestPaneSummary &&
      /Association: Line 1/.test(result.trace.latestPaneSummary.body)
  ).toBe(true);
});
