"use strict";

const { test, expect } = require("@playwright/test");
const {
  openFedWikiPageFromTextPageLink,
  attachJson,
  exactTextPattern,
  openHyperDoc,
  openTextPageFromHyperDoc,
  readPaneTitles,
  resetDockPresentation,
  selectConnectSourceTab,
  settleInspectorBindings,
} = require("./hyperdoc-inspector");
const {
  openPaneChromeHelp,
  paneChrome,
  readPaneChromeState,
} = require("./pane-chrome-harness");

test("Dock coachmark states degrade chrome without removing capability", async ({
  page,
}, testInfo) => {
  const hyperdocPane = await openHyperDoc(page);
  await resetDockPresentation(page);

  const introduction = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-introduction.json", introduction);

  expect(introduction.presentationState).toBe("introduction");
  expect(introduction.introducedCapability).toBe("connect");
  expect(introduction.presentationReason).toContain("connect.");
  expect(introduction.coachmarkVisible).toBe(true);
  expect(introduction.coachmarkBadge).toBe("Introduction");
  expect(introduction.coachmarkTitle).toBe("Connect");
  expect(introduction.coachmarkSummary).toContain("Click");
  expect(introduction.compactActions).toEqual(
    expect.arrayContaining(["Connect", "Annotation"])
  );
  expect(introduction.compactActions).not.toContain("Inspect");
  expect(introduction.dockInspectPresent).toBe(false);
  expect(introduction.connectStateInspectPresent).toBe(false);

  const chrome = paneChrome(page, 1);
  await expect(chrome.dismissButton).toBeVisible();
  await chrome.dismissButton.click();

  const degraded = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-degraded.json", degraded);

  expect(degraded.presentationState).toBe("degraded");
  expect(degraded.introducedCapability).toBe("connect");
  expect(degraded.presentationReason).toContain("connect.");
  expect(degraded.coachmarkVisible).toBe(false);
  expect(degraded.compactActions).toEqual(
    expect.arrayContaining(["Connect", "Annotation"])
  );
  expect(degraded.compactActions).not.toContain("Inspect");
  expect(degraded.compactActions).not.toContain("Touch-Fahrplan");
  expect(degraded.compactActions).not.toContain("DMX");

  await expect(chrome.connectToggle).toBeVisible();
  await chrome.connectToggle.click();

  const activeAfterStart = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-active-start.json", activeAfterStart);

  expect(activeAfterStart.presentationState).toBe("active");
  expect(activeAfterStart.introducedCapability).toBe("connect");
  expect(activeAfterStart.coachmarkVisible).toBe(true);
  expect(activeAfterStart.coachmarkBadge).toBe("Active");
  expect(activeAfterStart.statusText).toBe("Pick source");
  expect(activeAfterStart.cueText).toBe("Click a source anchor.");
  expect(activeAfterStart.dockInspectPresent).toBe(false);
  expect(activeAfterStart.connectStateInspectPresent).toBe(false);
  expect(activeAfterStart.clearHidden).toBe(true);

  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Text pages") })
    .click();

  const activeAfterSource = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-active-source.json", activeAfterSource);

  expect(activeAfterSource.presentationState).toBe("active");
  expect(activeAfterSource.introducedCapability).toBe("connect");
  expect(activeAfterSource.statusText).toBe("Pick target");
  expect(activeAfterSource.sourceChipText).toBe("Text pages");
  expect(activeAfterSource.clearHidden).toBe(false);
  expect(activeAfterSource.cancelHidden).toBe(false);

  await expect(chrome.cancelButton).toBeVisible();
  await chrome.cancelButton.click();

  const degradedAfterCancel = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-degraded-after-cancel.json", degradedAfterCancel);

  expect(degradedAfterCancel.presentationState).toBe("degraded");
  expect(degradedAfterCancel.introducedCapability).toBe("connect");
  expect(degradedAfterCancel.coachmarkVisible).toBe(false);
  expect(degradedAfterCancel.statusHidden).toBe(true);
  expect(degradedAfterCancel.compactActions).toEqual(
    expect.arrayContaining(["Connect", "Annotation"])
  );
  expect(degradedAfterCancel.compactActions).not.toContain("Inspect");

  const rediscovery = await openPaneChromeHelp(page, 1);
  await attachJson(testInfo, "dock-rediscovery.json", rediscovery);

  expect(rediscovery.presentationState).toBe("rediscovery");
  expect(rediscovery.introducedCapability).toBe("connect");
  expect(rediscovery.coachmarkVisible).toBe(true);
  expect(rediscovery.coachmarkBadge).toBe("Rediscovery");
  expect(rediscovery.coachmarkDetail).toContain("compact row");
  expect(rediscovery.providerHandoffHidden).toBe(true);
  expect(rediscovery.providerHandoffLabels).not.toContain("Touch-Fahrplan");
  expect(rediscovery.providerHandoffLabels).not.toContain("DMX");
  expect(rediscovery.compactActions).not.toContain("Touch-Fahrplan");
  expect(rediscovery.compactActions).not.toContain("DMX");
  expect(rediscovery.compactActions).not.toContain("Inspect");
  expect(rediscovery.dockInspectPresent).toBe(false);
  expect(rediscovery.connectStateInspectPresent).toBe(false);
});

test("Mobile Dock route capture starts only after explicit capabilities and Connect", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ width: 390, height: 780 });
  const hyperdocPane = await openHyperDoc(page, { expectDesktopDock: false });
  await resetDockPresentation(page);

  const idle = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-mobile-route-idle.json", idle);

  expect(idle.mobileRouteMode).toBe("true");
  expect(idle.mobileRouteState).toBe("idle");
  expect(idle.capabilitiesLayerState).toBe("capabilities-collapsed");
  expect(idle.capabilitiesToggleText).toBe(")(");
  expect(idle.routeCapture).toBe("inactive");
  expect(idle.routeTitleText).toBe(null);
  expect(idle.coachmarkVisible).toBe(false);
  expect(idle.compactActions).toEqual([]);

  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Text pages") })
    .click();

  const afterBodyClick = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-mobile-document-click.json", afterBodyClick);
  expect(afterBodyClick.mobileRouteState).toBe("idle");
  expect(afterBodyClick.routeCapture).toBe("inactive");
  expect(afterBodyClick.routeTitleText).toBe(null);
  expect(afterBodyClick.sourceSummaryHidden).toBe(true);
  expect(afterBodyClick.sourceChipVisible).toBe(false);

  const chrome = paneChrome(page, 1);
  await expect(chrome.capabilitiesToggle).toBeVisible();
  await chrome.capabilitiesToggle.click();

  const capabilitiesOpen = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-mobile-capabilities-open.json", capabilitiesOpen);
  expect(capabilitiesOpen.capabilitiesLayerState).toBe("capabilities-open");
  expect(capabilitiesOpen.routeCapture).toBe("inactive");
  expect(capabilitiesOpen.compactActions).toEqual(
    expect.arrayContaining(["Connect", "Annotation"])
  );
  expect(capabilitiesOpen.routeTitleText).toBe(null);

  await expect(chrome.connectToggle).toBeVisible();
  await chrome.connectToggle.click();

  const routeReady = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-mobile-route-ready.json", routeReady);
  expect(routeReady.mobileRouteState).toBe("route-introduction");
  expect(routeReady.routeCapture).toBe("active");
  expect(routeReady.routeTitleText).toBe("Tap a station");
  expect(routeReady.cancelHidden).toBe(false);

  await expect
    .poll(async () => (await readPaneChromeState(page, 1)).mobileRouteState, {
      timeout: 10_000,
    })
    .toBe("route-introduction");

  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Text pages") })
    .click();

  await expect
    .poll(async () => (await readPaneChromeState(page, 1)).mobileRouteState, {
      timeout: 10_000,
    })
    .toBe("source-latched");

  const sourceLatched = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-mobile-route-source-latched.json", sourceLatched);

  expect(sourceLatched.routeTitleText).toBe("From: Text pages");
  expect(sourceLatched.routeDetailText).toBe("Tap target or operation");
  expect(sourceLatched.compactActions).toEqual(expect.arrayContaining(["Annotation"]));
  expect(sourceLatched.compactActions).not.toContain("Connect");
  expect(sourceLatched.cancelHidden).toBe(false);

  await paneChrome(page, 1).annotationButton.click();

  await expect
    .poll(
      async () =>
        (await readPaneTitles(page)).some((entry) =>
          /^Annotation: Text pages$/.test(entry.title || "")
        ),
      { timeout: 20_000 }
    )
    .toBe(true);

  const completed = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-mobile-route-annotation-opened.json", completed);
});

test("Dock introduces Snippet independently on first eligible Source pane", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  await resetDockPresentation(page);

  const rootIntroduction = await readPaneChromeState(page, 1);
  expect(rootIntroduction.presentationState).toBe("introduction");
  expect(rootIntroduction.introducedCapability).toBe("connect");
  await paneChrome(page, 1).dismissButton.click();

  await openTextPageFromHyperDoc(
    page,
    "Workspace-native annotations in a DMX workspace"
  );
  await selectConnectSourceTab(page, 2);
  await settleInspectorBindings(page, 1500);

  const sourceIntroduction = await readPaneChromeState(page, 2);
  await attachJson(testInfo, "dock-snippet-source-introduction.json", sourceIntroduction);

  expect(sourceIntroduction.presentationState).toBe("introduction");
  expect(sourceIntroduction.introducedCapability).toBe("snippet");
  expect(sourceIntroduction.presentationReason).toContain("snippet.");
  expect(sourceIntroduction.coachmarkTitle).toBe("Snippet");
  expect(sourceIntroduction.coachmarkSummary).toBe(
    "Open a snippet workflow for the current source surface."
  );
  expect(sourceIntroduction.coachmarkDetail).toContain(
    "compact Snippet action remains available"
  );
  expect(sourceIntroduction.compactActions).toEqual(
    expect.arrayContaining(["Connect", "Annotation", "Snippet"])
  );

  const sourceChrome = paneChrome(page, 2);
  await expect(sourceChrome.dismissButton).toBeVisible();
  await sourceChrome.dismissButton.click();

  const sourceDegraded = await readPaneChromeState(page, 2);
  await attachJson(testInfo, "dock-snippet-source-degraded.json", sourceDegraded);

  expect(sourceDegraded.presentationState).toBe("degraded");
  expect(sourceDegraded.introducedCapability).toBe("snippet");
  expect(sourceDegraded.coachmarkVisible).toBe(false);
  expect(sourceDegraded.compactActions).toContain("Snippet");

  const sourceRediscovery = await openPaneChromeHelp(page, 2);
  await attachJson(testInfo, "dock-snippet-source-rediscovery.json", sourceRediscovery);

  expect(sourceRediscovery.presentationState).toBe("rediscovery");
  expect(sourceRediscovery.introducedCapability).toBe("snippet");
  expect(sourceRediscovery.coachmarkTitle).toBe("Snippet");
  expect(sourceRediscovery.coachmarkSummary).toBe(
    "Open a snippet workflow for the current source surface."
  );
  expect(sourceRediscovery.coachmarkDetail).toContain(
    "compact Snippet action remains available"
  );
  expect(sourceRediscovery.compactActions).toContain("Snippet");
});

test("Dock introduces Snippet independently on first eligible FedWiki pane", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  await resetDockPresentation(page);

  const rootIntroduction = await readPaneChromeState(page, 1);
  expect(rootIntroduction.presentationState).toBe("introduction");
  expect(rootIntroduction.introducedCapability).toBe("connect");
  await paneChrome(page, 1).dismissButton.click();

  await openTextPageFromHyperDoc(
    page,
    "Linking to Home Away From Home"
  );
  await openFedWikiPageFromTextPageLink(page, 2, "Home Away From Home");
  await settleInspectorBindings(page, 1500);

  const fedwikiIntroduction = await readPaneChromeState(page, 3);
  await attachJson(testInfo, "dock-snippet-fedwiki-introduction.json", fedwikiIntroduction);

  expect(fedwikiIntroduction.presentationState).toBe("introduction");
  expect(fedwikiIntroduction.introducedCapability).toBe("snippet");
  expect(fedwikiIntroduction.presentationReason).toContain("snippet.");
  expect(fedwikiIntroduction.coachmarkTitle).toBe("Snippet");
  expect(fedwikiIntroduction.coachmarkSummary).toBe(
    "Open a snippet workflow for the current source surface."
  );
  expect(fedwikiIntroduction.compactActions).toEqual(
    expect.arrayContaining(["Connect", "Annotation", "Snippet"])
  );

  const fedwikiChrome = paneChrome(page, 3);
  await expect(fedwikiChrome.dismissButton).toBeVisible();
  await fedwikiChrome.dismissButton.click();

  const fedwikiDegraded = await readPaneChromeState(page, 3);
  await attachJson(testInfo, "dock-snippet-fedwiki-degraded.json", fedwikiDegraded);

  expect(fedwikiDegraded.presentationState).toBe("degraded");
  expect(fedwikiDegraded.introducedCapability).toBe("snippet");
  expect(fedwikiDegraded.coachmarkVisible).toBe(false);
  expect(fedwikiDegraded.compactActions).toContain("Snippet");

  const fedwikiRediscovery = await openPaneChromeHelp(page, 3);
  await attachJson(testInfo, "dock-snippet-fedwiki-rediscovery.json", fedwikiRediscovery);

  expect(fedwikiRediscovery.presentationState).toBe("rediscovery");
  expect(fedwikiRediscovery.introducedCapability).toBe("snippet");
  expect(fedwikiRediscovery.coachmarkTitle).toBe("Snippet");
  expect(fedwikiRediscovery.coachmarkSummary).toBe(
    "Open a snippet workflow for the current source surface."
  );
});
