"use strict";

const { test, expect } = require("@playwright/test");
const {
  attachJson,
  exactTextPattern,
  openHyperDoc,
  resetDockPresentation,
} = require("./hyperdoc-inspector");
const { paneChrome, readPaneChromeState } = require("./pane-chrome-harness");

test("Dock coachmark states degrade chrome without removing capability", async ({
  page,
}, testInfo) => {
  const hyperdocPane = await openHyperDoc(page);
  await resetDockPresentation(page);

  const introduction = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-introduction.json", introduction);

  expect(introduction.presentationState).toBe("introduction");
  expect(introduction.coachmarkVisible).toBe(true);
  expect(introduction.coachmarkBadge).toBe("Introduction");
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
  expect(activeAfterSource.statusText).toBe("Pick target");
  expect(activeAfterSource.sourceChipText).toBe("Text pages");
  expect(activeAfterSource.clearHidden).toBe(false);
  expect(activeAfterSource.cancelHidden).toBe(false);

  await expect(chrome.cancelButton).toBeVisible();
  await chrome.cancelButton.click();

  const degradedAfterCancel = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-degraded-after-cancel.json", degradedAfterCancel);

  expect(degradedAfterCancel.presentationState).toBe("degraded");
  expect(degradedAfterCancel.coachmarkVisible).toBe(false);
  expect(degradedAfterCancel.statusHidden).toBe(true);
  expect(degradedAfterCancel.compactActions).toEqual(
    expect.arrayContaining(["Connect", "Annotation"])
  );
  expect(degradedAfterCancel.compactActions).not.toContain("Inspect");

  await expect(chrome.helpToggle).toBeVisible();
  await chrome.helpToggle.click();

  const rediscovery = await readPaneChromeState(page, 1);
  await attachJson(testInfo, "dock-rediscovery.json", rediscovery);

  expect(rediscovery.presentationState).toBe("rediscovery");
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
