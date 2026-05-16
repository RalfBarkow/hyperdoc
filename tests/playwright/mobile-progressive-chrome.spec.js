"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  exactTextPattern,
  openFedWikiPageFromTextPageLink,
  openHyperDoc,
  openTextPageFromHyperDoc,
  pane,
  readConnectSessionState,
  readInspectorPaneState,
  readPaneTitles,
  waitForPaneBodyText,
  waitForPaneLoadingBoundary,
} = require("./hyperdoc-inspector");
const {
  paneChrome,
  readPaneChromeState,
} = require("./pane-chrome-harness");

const proofTitle = "DM6 AppEmbed HyperDoc Inline Proof";

async function openProofPageMobile(page) {
  await page.setViewportSize({ width: 390, height: 780 });
  await openHyperDoc(page, { expectDesktopDock: false });
  const proofPane = await openTextPageFromHyperDoc(page, proofTitle);
  await waitForPaneBodyText(page, 2, "DM6 Topic Map");
  await waitForPaneLoadingBoundary(page, 2);
  return proofPane;
}

test("mobile initial chrome collapses capabilities and inspector tabs", async ({
  page,
}, testInfo) => {
  const proofPane = await openProofPageMobile(page);
  const chrome = paneChrome(page, 2);
  const state = await readPaneChromeState(page, 2);
  await attachJson(testInfo, "mobile-proof-initial-chrome.json", state);

  expect(state.capabilitiesLayerState).toBe("capabilities-collapsed");
  expect(state.capabilitiesToggleText).toBe(")(");
  expect(state.capabilitiesExpanded).toBe("false");
  expect(state.routeCapture).toBe("inactive");
  expect(state.routeTitleText).toBe(null);
  expect(state.sourceSummaryHidden).toBe(true);
  expect(state.inspectorTabsLayerState).toBe("tabs-collapsed");
  expect(state.inspectorTabsToggleText).toBe(")(");
  expect(state.inspectorTabsExpanded).toBe("false");

  await expect(chrome.capabilitiesToggle).toBeVisible();
  await expect(chrome.connectToggle).not.toBeVisible();
  await expect(chrome.annotationButton).not.toBeVisible();
  await expect(chrome.helpToggle).not.toBeVisible();
  await expect(chrome.routeTitle).not.toBeVisible();
  await expect(chrome.tabRow).not.toBeVisible();
  await expect(chrome.inspectorTabsToggle).toBeVisible();
  await expect(proofPane.getByText("Tap a station")).toHaveCount(0);
  await expect(proofPane.getByText(/^From:/)).toHaveCount(0);
});

test("mobile link click is normal while capabilities are collapsed", async ({
  page,
}, testInfo) => {
  await openProofPageMobile(page);
  const beforeSession = await readConnectSessionState(page);
  await attachJson(testInfo, "mobile-link-before-session.json", beforeSession);
  expect(beforeSession.phase).toBe("idle");

  const fedwikiPane = await openFedWikiPageFromTextPageLink(page, 2, "This page");
  await expect(fedwikiPane).toBeVisible();

  const afterSession = await readConnectSessionState(page);
  const sourceState = await readPaneChromeState(page, 2);
  await attachJson(testInfo, "mobile-link-after-session.json", afterSession);
  await attachJson(testInfo, "mobile-link-after-source-pane.json", sourceState);

  expect(afterSession.phase).toBe("idle");
  expect(sourceState.routeCapture).toBe("inactive");
  expect(sourceState.routeTitleText).toBe(null);
  expect(sourceState.sourceSummaryHidden).toBe(true);
  expect(sourceState.sourceChipVisible).toBe(false);
});

test("mobile route capture requires capabilities then Connect", async ({
  page,
}, testInfo) => {
  const proofPane = await openProofPageMobile(page);
  const chrome = paneChrome(page, 2);

  await chrome.capabilitiesToggle.click();
  const capabilitiesOpen = await readPaneChromeState(page, 2);
  await attachJson(testInfo, "mobile-capabilities-open.json", capabilitiesOpen);
  expect(capabilitiesOpen.capabilitiesLayerState).toBe("capabilities-open");
  expect(capabilitiesOpen.routeCapture).toBe("inactive");
  await expect(chrome.connectToggle).toBeVisible();
  await expect(chrome.annotationButton).toBeVisible();
  await expect(chrome.helpToggle).toBeVisible();
  await expect(chrome.routeTitle).not.toBeVisible();

  await chrome.connectToggle.click();
  const routeReady = await readPaneChromeState(page, 2);
  await attachJson(testInfo, "mobile-route-ready.json", routeReady);
  expect(routeReady.mobileRouteState).toBe("route-introduction");
  expect(routeReady.routeCapture).toBe("active");
  expect(routeReady.routeTitleText).toBe("Tap a station");

  await proofPane
    .locator(".hyperdoc-connect-provider-root h1")
    .filter({ hasText: exactTextPattern(proofTitle) })
    .click();

  await expect
    .poll(async () => (await readPaneChromeState(page, 2)).mobileRouteState, {
      timeout: 10_000,
    })
    .toBe("source-latched");

  const sourceLatched = await readPaneChromeState(page, 2);
  await attachJson(testInfo, "mobile-source-latched.json", sourceLatched);
  expect(sourceLatched.routeTitleText).toContain("From:");
  expect(sourceLatched.routeCapture).toBe("active");

  await chrome.capabilitiesToggle.click();
  const cancelled = await readPaneChromeState(page, 2);
  await attachJson(testInfo, "mobile-route-cancelled.json", cancelled);
  expect(cancelled.routeCapture).toBe("inactive");
  expect(cancelled.mobileRouteState).toBe("idle");
  expect(cancelled.routeTitleText).toBe(null);
});

test("mobile inspector tabs toggle opens existing tabs and collapses after selection", async ({
  page,
}, testInfo) => {
  await openProofPageMobile(page);
  const chrome = paneChrome(page, 2);
  const initial = await readPaneChromeState(page, 2);
  expect(initial.inspectorTabsLayerState).toBe("tabs-collapsed");

  await chrome.inspectorTabsToggle.click();
  const opened = await readPaneChromeState(page, 2);
  await attachJson(testInfo, "mobile-tabs-open.json", opened);
  expect(opened.inspectorTabsLayerState).toBe("tabs-open");
  await expect(chrome.tabs.filter({ hasText: exactTextPattern("Source") }).first()).toBeVisible();
  await expect(chrome.tabs.filter({ hasText: exactTextPattern("Links") }).first()).toBeVisible();
  await expect(chrome.tabs.filter({ hasText: exactTextPattern("Parse tree") }).first()).toBeVisible();

  await activatePaneTab(page, 2, "Source");
  const selected = await readPaneChromeState(page, 2);
  const inspectorState = await readInspectorPaneState(page, 2);
  await attachJson(testInfo, "mobile-tabs-selected.json", selected);
  expect(inspectorState.activeTab).toBe("Source");
  expect(selected.inspectorTabsLayerState).toBe("tabs-collapsed");

  await chrome.inspectorTabsToggle.click();
  await expect(chrome.tabRow).toBeVisible();
  await chrome.inspectorTabsToggle.click();
  const collapsedAgain = await readPaneChromeState(page, 2);
  expect(collapsedAgain.inspectorTabsLayerState).toBe("tabs-collapsed");
});

test("mobile progressive chrome state, SCXML, and plan artifacts are inspectable", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ width: 390, height: 780 });
  await openHyperDoc(page, { expectDesktopDock: false });
  await openTextPageFromHyperDoc(page, "Mobile progressive chrome in HyperDoc");
  await waitForPaneBodyText(page, 2, "Operational contract");

  const docsState = await readInspectorPaneState(page, 2);
  await attachJson(testInfo, "mobile-progressive-docs.json", docsState);
  expect(docsState.bodyText).toContain("capabilities-collapsed");
  expect(docsState.bodyText).toContain("Mobile progressive chrome SCXML");
  expect(docsState.bodyText).toContain("mobile-progressive-chrome-plan");

  const paneCountBefore = await page.locator(".inspector-pane").count();
  await pane(page, 2)
    .locator(
      '.hyperdoc-deferred-reference[data-hyperdoc-expression-source="(mobile-progressive-chrome-plan)"]'
    )
    .first()
    .click();
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBe(paneCountBefore + 1);
  await expect
    .poll(() => page.locator(".hyperdoc-evaluation-pending").count(), {
      timeout: 30_000,
    })
    .toBe(0);

  const titles = await readPaneTitles(page);
  await attachJson(testInfo, "mobile-progressive-artifact-panes.json", titles);
  expect(titles.some((entry) => entry.title === "Mobile progressive chrome plan"))
    .toBe(true);
});
