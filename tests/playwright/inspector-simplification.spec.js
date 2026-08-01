"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  exactTextPattern,
  openHyperDoc,
  openTextPageFromHyperDoc,
  readConnectSessionState,
  waitForPaneLoadingBoundary,
} = require("./hyperdoc-inspector");
const { paneChrome } = require("./pane-chrome-harness");

const pageTitle = "Mobile progressive chrome in HyperDoc";
const fileLinkSelector =
  'a[href^="file:" i],area[href^="file:" i],[formaction^="file:" i]';

function captureConsoleErrors(page) {
  const errors = [];
  page.on("console", (message) => {
    if (message.type() === "error") {
      errors.push(message.text());
    }
  });
  return errors;
}

async function openRegressionPage(page, options = {}) {
  await openHyperDoc(page, options);
  const currentPane = await openTextPageFromHyperDoc(page, pageTitle);
  await expect(
    currentPane.getByRole("heading", { name: pageTitle, exact: true })
  ).toBeVisible();
  await waitForPaneLoadingBoundary(page, 2);
  return currentPane;
}

async function expectNoFileLinks(page, consoleErrors) {
  await expect(page.locator(fileLinkSelector)).toHaveCount(0);
  expect(
    consoleErrors.filter((message) => /may not load or link to file:\/\//i.test(message))
  ).toEqual([]);
}

test("desktop Inspector discloses secondary views and keeps Connect non-blocking", async ({
  page,
}) => {
  const consoleErrors = captureConsoleErrors(page);
  const currentPane = await openRegressionPage(page);
  const chrome = paneChrome(page, 2);
  const tabs = currentPane.locator(".inspector-tabs");
  const contentTab = tabs.getByRole("button", { name: "Content", exact: true });
  const sourceTab = tabs.getByRole("button", { name: "Source", exact: true });
  const linksTab = tabs.getByRole("button", { name: "Links", exact: true });

  await expect(contentTab).toBeVisible();
  await expect(sourceTab).toBeVisible();
  await expect(chrome.inspectToggle).toBeVisible();
  await expect(chrome.inspectToggle).toHaveAccessibleName("Inspect secondary views");
  await expect(chrome.inspectToggle).toHaveAttribute("aria-expanded", "false");
  await expect(linksTab).not.toBeVisible();

  await chrome.inspectToggle.focus();
  await page.keyboard.press("Enter");
  await expect(chrome.inspectToggle).toBeFocused();
  await expect(chrome.inspectToggle).toHaveAttribute("aria-expanded", "true");
  await expect(linksTab).toBeVisible();
  await linksTab.focus();
  await expect(linksTab).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(currentPane.locator(".inspector-tabs button.active")).toHaveText(
    exactTextPattern("Links")
  );
  await expect(chrome.inspectToggle).toHaveAttribute("aria-expanded", "false");
  await expect(chrome.inspectToggle).toBeFocused();
  await activatePaneTab(page, 2, "Content");

  const lead = currentPane.locator(".hyperbook-page p").first();
  const localPath = currentPane.locator(".hyperbook-local-file-path").first();
  await expect(lead).toBeVisible();
  await expect(localPath).toBeVisible();
  await expect(chrome.helpPanel).not.toBeVisible();

  await chrome.connectToggle.click();
  await expect(chrome.connectToggle).toHaveAttribute("aria-pressed", "true");
  await expect(chrome.connectHint).toBeVisible();
  await expect(chrome.connectHint).toHaveText(
    "Select a part of the page to connect. Press Escape to cancel."
  );
  const overlap = await page.evaluate(() => {
    const hint = document.querySelectorAll(".inspector-pane")[2]
      ?.querySelector("[data-hyperdoc-connect-hint]")
      ?.getBoundingClientRect();
    const paragraph = document.querySelectorAll(".inspector-pane")[2]
      ?.querySelector(".hyperbook-page p")
      ?.getBoundingClientRect();
    return !!hint && !!paragraph &&
      hint.left < paragraph.right && hint.right > paragraph.left &&
      hint.top < paragraph.bottom && hint.bottom > paragraph.top;
  });
  expect(overlap).toBe(false);

  await lead.click();
  await expect
    .poll(async () => (await readConnectSessionState(page)).phase)
    .toBe("choose-target");
  await page.keyboard.press("Escape");
  await expect
    .poll(async () => (await readConnectSessionState(page)).phase)
    .toBe("idle");
  await expect(chrome.connectHint).not.toBeVisible();
  await expect(chrome.connectToggle).toHaveAttribute("aria-pressed", "false");
  await expect(chrome.connectToggle).toBeFocused();

  await expectNoFileLinks(page, consoleErrors);
  expect(consoleErrors).toEqual([]);
});

test("mobile 375x667 keeps one active pane, content, Dock, and navigation in view", async ({
  page,
}) => {
  const consoleErrors = captureConsoleErrors(page);
  await page.setViewportSize({ width: 375, height: 667 });
  const currentPane = await openRegressionPage(page, { expectDesktopDock: false });
  const chrome = paneChrome(page, 2);
  const heading = currentPane
    .locator(".hyperdoc-connect-provider-root h1")
    .filter({ hasText: exactTextPattern(pageTitle) });
  const lead = currentPane.locator(".hyperbook-page p").first();

  await heading.scrollIntoViewIfNeeded();
  await expect(heading).toBeVisible();
  await lead.scrollIntoViewIfNeeded();
  await expect(lead).toBeVisible();

  const initialGeometry = await page.evaluate(() => {
    const paneNode = document.querySelectorAll(".inspector-pane")[2];
    const body = paneNode?.querySelector(":scope > .inspector-body");
    const activeView = body?.querySelector(":scope > .inspector-view:not([hidden])");
    const pageContent = activeView?.querySelector(".hyperbook-page");
    const rect = paneNode?.getBoundingClientRect();
    const visibleControls = Array.from(
      paneNode?.querySelectorAll(
        ".inspector-title-bar button,.inspector-title-bar [role='button']," +
        ".hyperdoc-inspector-tabs-toggle,.hyperdoc-capabilities-toggle"
      ) || []
    ).filter((node) => {
      const style = window.getComputedStyle(node);
      const nodeRect = node.getBoundingClientRect();
      return style.display !== "none" && style.visibility !== "hidden" &&
        nodeRect.width > 0 && nodeRect.height > 0;
    }).map((node) => {
      const nodeRect = node.getBoundingClientRect();
      return { left: nodeRect.left, right: nodeRect.right };
    });
    return {
      viewportWidth: window.innerWidth,
      documentScrollWidth: document.documentElement.scrollWidth,
      pane: rect && { left: rect.left, right: rect.right, width: rect.width },
      bodyClientWidth: body?.clientWidth || 0,
      bodyScrollWidth: body?.scrollWidth || 0,
      viewClientWidth: activeView?.clientWidth || 0,
      viewScrollWidth: activeView?.scrollWidth || 0,
      contentClientWidth: pageContent?.clientWidth || 0,
      contentScrollWidth: pageContent?.scrollWidth || 0,
      visibleControls,
    };
  });

  expect(initialGeometry.pane.width).toBeLessThanOrEqual(375);
  expect(initialGeometry.pane.left).toBeGreaterThanOrEqual(0);
  expect(initialGeometry.pane.right).toBeLessThanOrEqual(375);
  expect(initialGeometry.documentScrollWidth).toBeLessThanOrEqual(375);
  expect(initialGeometry.bodyScrollWidth).toBeLessThanOrEqual(
    initialGeometry.bodyClientWidth + 1
  );
  expect(initialGeometry.viewScrollWidth).toBeLessThanOrEqual(
    initialGeometry.viewClientWidth + 1
  );
  expect(initialGeometry.contentScrollWidth).toBeLessThanOrEqual(
    initialGeometry.contentClientWidth + 1
  );
  expect(initialGeometry.visibleControls.length).toBeGreaterThan(0);
  for (const control of initialGeometry.visibleControls) {
    expect(control.left).toBeGreaterThanOrEqual(0);
    expect(control.right).toBeLessThanOrEqual(375);
  }

  await expect(chrome.capabilitiesToggle).toBeVisible();
  await chrome.capabilitiesToggle.click();
  await expect(chrome.connectToggle).toBeVisible();
  await chrome.connectToggle.click();
  await expect(chrome.connectToggle).toHaveAttribute("aria-pressed", "true");
  await expect(chrome.connectHint).toBeVisible();
  await expect(chrome.helpPanel).not.toBeVisible();

  const activeGeometry = await page.evaluate(() => {
    const paneNode = document.querySelectorAll(".inspector-pane")[2];
    const hint = paneNode?.querySelector("[data-hyperdoc-connect-hint]")
      ?.getBoundingClientRect();
    const paragraph = paneNode
      ?.querySelector(".hyperbook-page p")
      ?.getBoundingClientRect();
    const heading = paneNode?.querySelector(".hyperdoc-connect-provider-root h1")
      ?.getBoundingClientRect();
    const reelButtons = Array.from(
      document.querySelectorAll(".hyperdoc-reel__buttons button:not([hidden])")
    ).filter((node) => window.getComputedStyle(node).display !== "none")
      .map((node) => {
        const rect = node.getBoundingClientRect();
        return { left: rect.left, right: rect.right };
      });
    return {
      overlap: !!hint && !!paragraph &&
        hint.left < paragraph.right && hint.right > paragraph.left &&
        hint.top < paragraph.bottom && hint.bottom > paragraph.top,
      headingOverlap: !!hint && !!heading &&
        hint.left < heading.right && hint.right > heading.left &&
        hint.top < heading.bottom && hint.bottom > heading.top,
      reelButtons,
    };
  });
  expect(activeGeometry.overlap).toBe(false);
  expect(activeGeometry.headingOverlap).toBe(false);
  expect(activeGeometry.reelButtons.length).toBeGreaterThan(0);
  for (const button of activeGeometry.reelButtons) {
    expect(button.left).toBeGreaterThanOrEqual(0);
    expect(button.right).toBeLessThanOrEqual(375);
  }

  await page.keyboard.press("Escape");
  await expect(chrome.connectHint).not.toBeVisible();
  await expect(chrome.connectToggle).toHaveAttribute("aria-pressed", "false");
  await expect(chrome.connectToggle).toBeFocused();
  await expectNoFileLinks(page, consoleErrors);
  expect(consoleErrors).toEqual([]);
});
