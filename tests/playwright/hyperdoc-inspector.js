"use strict";

const { expect } = require("@playwright/test");

const defaultPort = process.env.HYPERDOC_PORT || "18080";
const defaultBootUrl = `http://127.0.0.1:${defaultPort}/boot.html`;

function bootUrl() {
  return process.env.HYPERDOC_BASE_URL || defaultBootUrl;
}

function pane(page, index) {
  return page.locator(".inspector-pane").nth(index);
}

function exactTextPattern(value) {
  return new RegExp(`^${value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`);
}

async function attachJson(testInfo, name, value) {
  await testInfo.attach(name, {
    body: JSON.stringify(value, null, 2),
    contentType: "application/json",
  });
}

async function gotoCatalog(page) {
  await page.goto(bootUrl(), { waitUntil: "domcontentloaded" });
  await expect(pane(page, 0)).toBeVisible();
}

async function settleInspectorBindings(page, timeout = 1500) {
  await page.waitForTimeout(timeout);
}

async function openHyperDoc(page) {
  await gotoCatalog(page);
  const catalogPane = pane(page, 0);
  await catalogPane
    .locator("tr")
    .filter({ hasText: exactTextPattern("3HyperDoc") })
    .first()
    .click();
  const hyperdocPane = pane(page, 1);
  await expect(hyperdocPane.locator(".hyperdoc-connect-provider-surface")).toBeVisible();
  await expect(
    hyperdocPane.locator(".inspector-tabs button.active")
  ).toHaveText(exactTextPattern("Main page"));
  await settleInspectorBindings(page);
  return hyperdocPane;
}

async function openTextPageFromHyperDoc(page, title) {
  const paneCountBefore = await page.locator(".inspector-pane").count();
  const hyperdocPane = pane(page, 1);
  await activatePaneTab(page, 1, "Text pages");
  const pageRow = hyperdocPane
    .locator("tr")
    .filter({ hasText: exactTextPattern(title) })
    .first();
  await expect(pageRow).toBeVisible();
  await settleInspectorBindings(page);
  await pageRow.click();
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBe(paneCountBefore + 1);
  const textPagePane = pane(page, 2);
  await expect(
    textPagePane.locator(".inspector-tabs button").filter({
      hasText: exactTextPattern("Source"),
    })
  ).toBeVisible({ timeout: 20_000 });
  await settleInspectorBindings(page);
  return textPagePane;
}

async function selectSourceTab(page, paneIndex) {
  await activatePaneTab(page, paneIndex, "Source");
}

async function activatePaneTab(page, paneIndex, title) {
  const currentPane = pane(page, paneIndex);
  const tab = currentPane
    .locator(".inspector-tabs button")
    .filter({ hasText: exactTextPattern(title) });
  await expect(tab).toBeVisible();
  await tab.click();
  await expect(
    currentPane.locator(".inspector-tabs button.active")
  ).toHaveText(exactTextPattern(title));
}

async function readPaneTitles(page) {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll(".inspector-pane")).map((paneNode, index) => {
      const activeTab = paneNode.querySelector(".inspector-tabs button.active");
      return {
        index,
        title:
          paneNode.querySelector(".inspector-title-bar-class")?.textContent?.trim() ||
          null,
        activeTab: activeTab?.textContent?.trim() || null,
      };
    })
  );
}

async function readHelpPanelState(page, paneIndex) {
  return page.evaluate((index) => {
    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    const slot = paneNode?.querySelector(".hyperdoc-dom-connect-pane-slot");
    const control = slot?.querySelector(".hyperdoc-dom-connect-control");
    const helpPanel = slot?.querySelector(".hyperdoc-dom-connect-help-panel");
    const activeView = paneNode?.querySelector(".inspector-view:not([hidden])");
    return {
      slotHidden: !!slot?.hidden,
      slotHelpOpen: slot?.dataset.helpOpen || null,
      helpExpanded:
        slot?.querySelector(".hyperdoc-dom-connect-help-toggle")?.getAttribute(
          "aria-expanded"
        ) || null,
      helpAriaHidden: helpPanel?.getAttribute("aria-hidden") || null,
      panelDisplay: helpPanel ? window.getComputedStyle(helpPanel).display : null,
      tabRowHeight:
        paneNode?.querySelector(".inspector-tabs")?.getBoundingClientRect().height || null,
      activeViewTop: activeView?.getBoundingClientRect().top || null,
      documentScrollHeight: document.documentElement.scrollHeight,
      panelTop: helpPanel?.getBoundingClientRect().top || null,
      controlBottom: control?.getBoundingClientRect().bottom || null,
    };
  }, paneIndex);
}

async function readDomConnectTrace(page) {
  return page.evaluate(() => {
    const events = window.hyperdocDomConnectEvents || [];
    const requestId = events[0]?.requestId || null;
    const filtered = requestId
      ? events.filter((event) => event.requestId === requestId)
      : events;
    const latest = filtered[filtered.length - 1] || null;
    const panes = Array.from(document.querySelectorAll(".inspector-pane"));
    const lastPane = panes[panes.length - 1] || null;
    return {
      requestId,
      latestStage: latest?.stage || null,
      events: filtered,
      paneCount: panes.length,
      paneTitles: panes.map((paneNode, index) => {
        const activeTab = paneNode.querySelector(".inspector-tabs button.active");
        return {
          index,
          title:
            paneNode.querySelector(".inspector-title-bar-class")?.textContent?.trim() ||
            null,
          activeTab: activeTab?.textContent?.trim() || null,
        };
      }),
      latestPaneSummary: lastPane
        ? {
            title:
              lastPane.querySelector(".inspector-title-bar-class")?.textContent?.trim() ||
              null,
            body:
              lastPane.querySelector(".inspector-view")?.innerText
                ?.replace(/\s+/g, " ")
                .trim()
                .slice(0, 240) || "",
          }
        : null,
    };
  });
}

async function clearDomConnectTrace(page) {
  await page.evaluate(() => {
    window.hyperdocDomConnectEvents = [];
  });
}

async function waitForAssociationResult(page) {
  await page.waitForFunction(() => {
    const events = window.hyperdocDomConnectEvents || [];
    const requestId = events[0]?.requestId;
    if (!requestId) {
      return false;
    }
    const filtered = events.filter((event) => event.requestId === requestId);
    const latest = filtered[filtered.length - 1];
    return (
      latest &&
      (latest.stage === "pane-open-succeeded" || latest.stage === "request-failed")
    );
  }, { timeout: 20_000 });
  return readDomConnectTrace(page);
}

async function startConnectInPane(page, paneIndex) {
  const currentPane = pane(page, paneIndex);
  const button = currentPane.locator(".hyperdoc-dom-connect-toggle");
  await expect(button).toBeVisible();
  await button.click();
  return currentPane;
}

async function toggleHelpInPane(page, paneIndex) {
  const currentPane = pane(page, paneIndex);
  const helpToggle = currentPane.locator(".hyperdoc-dom-connect-help-toggle");
  await expect(helpToggle).toBeVisible();
  await helpToggle.click();
  await expect(helpToggle).toHaveAttribute("aria-expanded", "true");
  return readHelpPanelState(page, paneIndex);
}

async function readSourcePaneState(page, paneIndex) {
  return page.evaluate((index) => {
    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    const surface = paneNode?.querySelector(".hyperdoc-connect-provider-surface");
    const lines = paneNode
      ? Array.from(paneNode.querySelectorAll(".hyperdoc-source-connect-line"))
      : [];
    return {
      paneCount: document.querySelectorAll(".inspector-pane").length,
      title:
        paneNode?.querySelector(".inspector-title-bar-class")?.textContent?.trim() || null,
      activeTab:
        paneNode?.querySelector(".inspector-tabs button.active")?.textContent?.trim() ||
        null,
      providerKind: surface?.dataset.hyperdocConnectProviderKind || null,
      viewKind: surface?.dataset.hyperdocConnectViewKind || null,
      lineCount: lines.length,
      firstLines: lines.slice(0, 5).map((line) => ({
        line: line.dataset.hyperdocSourceStartLine || null,
        label: line.dataset.hyperdocSourceLabel || null,
        value: line.dataset.hyperdocSourceValue || null,
        text: line.textContent?.replace(/\s+/g, " ").trim().slice(0, 120) || "",
      })),
    };
  }, paneIndex);
}

async function waitForSourceProvider(page, paneIndex) {
  const currentPane = pane(page, paneIndex);
  await expect.poll(
    () => currentPane.locator(".hyperdoc-source-connect-line").count(),
    { timeout: 20_000 }
  ).toBeGreaterThan(5);
  await expect(currentPane.locator(".hyperdoc-connect-provider-surface")).toHaveAttribute(
    "data-hyperdoc-connect-provider-kind",
    "source-v1"
  );
  return readSourcePaneState(page, paneIndex);
}

async function runContentAssociation(page) {
  const hyperdocPane = await openHyperDoc(page);
  await clearDomConnectTrace(page);
  await startConnectInPane(page, 1);
  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Text pages") })
    .click();
  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Data objects") })
    .click();
  const trace = await waitForAssociationResult(page);
  return {
    trace,
    paneTitles: await readPaneTitles(page),
  };
}

async function runSourceAssociation(page, title) {
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, title);
  await selectSourceTab(page, 2);
  const sourceState = await waitForSourceProvider(page, 2);
  await clearDomConnectTrace(page);
  await startConnectInPane(page, 2);
  const lineButtons = pane(page, 2).locator(".hyperdoc-source-connect-line");
  await lineButtons.nth(0).click();
  await lineButtons.nth(2).click();
  const trace = await waitForAssociationResult(page);
  return {
    sourceState,
    trace,
    paneTitles: await readPaneTitles(page),
  };
}

module.exports = {
  activatePaneTab,
  attachJson,
  bootUrl,
  exactTextPattern,
  gotoCatalog,
  openHyperDoc,
  openTextPageFromHyperDoc,
  pane,
  readHelpPanelState,
  readDomConnectTrace,
  readPaneTitles,
  readSourcePaneState,
  runContentAssociation,
  runSourceAssociation,
  selectSourceTab,
  settleInspectorBindings,
  startConnectInPane,
  toggleHelpInPane,
  waitForAssociationResult,
  waitForSourceProvider,
};
