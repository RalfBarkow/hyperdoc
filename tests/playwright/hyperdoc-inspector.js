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

function activeView(currentPane) {
  return currentPane.locator(".inspector-view:not([hidden])");
}

function tableCellByExactText(container, value) {
  return container
    .locator("td")
    .filter({ hasText: exactTextPattern(value) })
    .first();
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

async function openHyperDoc(page, options = {}) {
  const expectDesktopDock = options.expectDesktopDock !== false;
  await gotoCatalog(page);
  const catalogPane = pane(page, 0);
  await tableCellByExactText(catalogPane, "HyperDoc").click();
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBeGreaterThan(1);
  const hyperdocPane = pane(page, 1);
  await expect(hyperdocPane).toBeVisible({ timeout: 20_000 });
  await expect
    .poll(
      async () => hyperdocPane.locator(".inspector-tabs button").count(),
      { timeout: 20_000 }
    )
    .toBeGreaterThan(0);
  const tabTexts = await hyperdocPane.locator(".inspector-tabs button").allTextContents();
  if (tabTexts.includes("Main page")) {
    await activatePaneTab(page, 1, "Main page");
    await expect
      .poll(
        () =>
          hyperdocPane.evaluate((paneNode) => {
            const activeView = paneNode.querySelector(".inspector-view:not([hidden])");
            const surface =
              activeView &&
              activeView.querySelector(".hyperdoc-connect-provider-surface");
            const root =
              surface &&
              surface.querySelector(".hyperdoc-connect-provider-root");
            return !!(activeView && surface && root);
          }),
        { timeout: 20_000 }
      )
      .toBe(true);
    await expect
      .poll(
        () =>
          hyperdocPane.evaluate((paneNode) => {
            const activeView = paneNode.querySelector(".inspector-view:not([hidden])");
            const root =
              activeView &&
              activeView.querySelector(".hyperdoc-connect-provider-root");
            return root?.textContent?.replace(/\s+/g, " ").trim().length || 0;
          }),
        { timeout: 20_000 }
      )
      .toBeGreaterThan(0);
    if (expectDesktopDock) {
      await expect(hyperdocPane.locator(".hyperdoc-dom-connect-toggle")).toBeVisible({
        timeout: 20_000,
      });
      await expect(
        hyperdocPane.locator(".hyperdoc-dom-connect-help-toggle")
      ).toBeVisible({
        timeout: 20_000,
      });
    } else {
      await expect(hyperdocPane.locator(".hyperdoc-capabilities-toggle")).toBeVisible({
        timeout: 20_000,
      });
    }
  } else {
    expect(tabTexts).toContain("Text pages");
  }
  await settleInspectorBindings(page);
  return hyperdocPane;
}

async function openTextPageFromHyperDoc(page, title) {
  const paneCountBefore = await page.locator(".inspector-pane").count();
  const hyperdocPane = pane(page, 1);
  await activatePaneTab(page, 1, "Text pages");
  const pageCell = tableCellByExactText(hyperdocPane, title);
  await expect(pageCell).toBeVisible();
  await settleInspectorBindings(page);
  await pageCell.click();
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBe(paneCountBefore + 1);
  const textPagePane = pane(page, 2);
  await expect
    .poll(
      () =>
        textPagePane
          .locator(".inspector-tabs button")
          .filter({ hasText: exactTextPattern("Source") })
          .count(),
      { timeout: 20_000 }
    )
    .toBeGreaterThan(0);
  await settleInspectorBindings(page);
  return textPagePane;
}

async function openTopicPageFromHyperDoc(page, title) {
  const paneCountBefore = await page.locator(".inspector-pane").count();
  const hyperdocPane = pane(page, 1);
  await activatePaneTab(page, 1, "Topics");
  const pageCell = tableCellByExactText(hyperdocPane, title);
  await expect(pageCell).toBeVisible();
  await settleInspectorBindings(page);
  await pageCell.click();
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBe(paneCountBefore + 1);
  const topicPagePane = pane(page, paneCountBefore);
  await expect(topicPagePane).toBeVisible({ timeout: 20_000 });
  await expect
    .poll(
      () =>
        topicPagePane
          .locator(".inspector-tabs button")
          .filter({ hasText: exactTextPattern("Content") })
          .count(),
      { timeout: 20_000 }
    )
    .toBeGreaterThan(0);
  await settleInspectorBindings(page);
  return topicPagePane;
}

async function openFedWikiPageFromTextPageLink(page, paneIndex, linkText) {
  const paneCountBefore = await page.locator(".inspector-pane").count();
  const sourcePane = pane(page, paneIndex);
  await waitForPaneLoadingBoundary(page, paneIndex, 45_000);
  await expect(
    sourcePane.locator(".hyperdoc-connect-provider-root").first()
  ).toBeVisible({ timeout: 20_000 });
  const reference = sourcePane
    .locator(".hyperdoc-connect-provider-root .hyperbook-reference")
    .filter({ hasText: exactTextPattern(linkText) })
    .first();
  await expect(reference).toBeVisible({ timeout: 20_000 });
  await settleInspectorBindings(page);
  await reference.click();
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBe(paneCountBefore + 1);
  const fedwikiPane = pane(page, paneCountBefore);
  await expect(fedwikiPane).toBeVisible({ timeout: 20_000 });
  await expect
    .poll(
      () =>
        fedwikiPane
          .locator(".inspector-tabs button")
          .filter({ hasText: exactTextPattern("Story") })
          .count(),
      { timeout: 20_000 }
    )
    .toBeGreaterThan(0);
  await settleInspectorBindings(page);
  return fedwikiPane;
}

async function selectSourceTab(page, paneIndex) {
  await activatePaneTab(page, paneIndex, "Source");
}

async function activatePaneTab(page, paneIndex, title) {
  const currentPane = pane(page, paneIndex);
  const tab = currentPane
    .locator(".inspector-tabs button")
    .filter({ hasText: exactTextPattern(title) })
    .first();
  const tabsToggle = currentPane.locator(".hyperdoc-inspector-tabs-toggle");
  const tabsLayerState = await currentPane.evaluate((paneNode) =>
    paneNode.getAttribute("data-inspector-tabs-layer")
  );
  if (
    (await tabsToggle.isVisible()) &&
    tabsLayerState !== "tabs-open"
  ) {
    await tabsToggle.click();
  } else if (!(await tab.isVisible()) && (await tabsToggle.isVisible())) {
    await tabsToggle.click();
  }
  await expect(tab).toBeVisible();
  let lastError = null;
  for (let attempt = 0; attempt < 5; attempt += 1) {
    await tab.click();
    try {
      await expect(
        currentPane.locator(".inspector-tabs button.active")
      ).toHaveText(exactTextPattern(title), { timeout: 3000 });
      await expect
        .poll(
          () =>
            currentPane.evaluate((paneNode) => {
              const activeView = paneNode.querySelector(".inspector-view:not([hidden])");
              if (!activeView) {
                return 0;
              }
              const textLength =
                activeView.innerText?.replace(/\s+/g, " ").trim().length || 0;
              const childCount = activeView.children?.length || 0;
              return Math.max(textLength, childCount);
            }),
          { timeout: 5000 }
        )
        .toBeGreaterThan(0);
      return;
    } catch (error) {
      lastError = error;
      await settleInspectorBindings(page, 250);
    }
  }
  throw lastError;
}

async function readPaneTitles(page) {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll(".inspector-pane")).map((paneNode, index) => {
      const activeTab = paneNode.querySelector(".inspector-tabs button.active");
      const titleNode =
        paneNode.querySelector(".inspector-title-bar-object") ||
        paneNode.querySelector(".inspector-title-bar-class");
      return {
        index,
        title: titleNode?.textContent?.trim() || null,
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
        const titleNode =
          paneNode.querySelector(".inspector-title-bar-object") ||
          paneNode.querySelector(".inspector-title-bar-class");
        return {
          index,
          title: titleNode?.textContent?.trim() || null,
          activeTab: activeTab?.textContent?.trim() || null,
        };
      }),
      latestPaneSummary: lastPane
        ? {
            title:
              (lastPane.querySelector(".inspector-title-bar-object") ||
                lastPane.querySelector(".inspector-title-bar-class"))
                ?.textContent?.trim() || null,
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

async function readConnectSessionState(page) {
  return page.evaluate(() => {
    if (!window.hyperdocDomConnect || !window.hyperdocDomConnect.readSessionState) {
      return null;
    }
    return window.hyperdocDomConnect.readSessionState();
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

async function forceNextConnectFailureMode(page, kind) {
  await page.evaluate((failureKind) => {
    if (!window.hyperdocDomConnect || !window.hyperdocDomConnect.__test) {
      throw new Error("hyperdocDomConnect test hooks are unavailable");
    }
    window.hyperdocDomConnect.__test.forceNextFailureMode(failureKind);
  }, kind);
}

async function clearConnectFailureModes(page) {
  await page.evaluate(() => {
    if (window.hyperdocDomConnect && window.hyperdocDomConnect.__test) {
      window.hyperdocDomConnect.__test.clearFailureModes();
    }
  });
}

async function resetDockPresentation(page) {
  await page.evaluate(() => {
    if (window.hyperdocDomConnect && window.hyperdocDomConnect.__test) {
      window.hyperdocDomConnect.__test.resetDockPresentation();
    }
  });
}

async function startConnectInPane(page, paneIndex) {
  const currentPane = pane(page, paneIndex);
  const button = currentPane.locator(".hyperdoc-dom-connect-toggle");
  await expect(button).toBeVisible();
  await button.click();
  await page.waitForFunction((index) => {
    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    const slot = paneNode?.querySelector(".hyperdoc-dom-connect-pane-slot");
    return slot?.dataset.connectState === "select-source";
  }, paneIndex, { timeout: 10_000 });
  return currentPane;
}

async function waitForConnectChromeState(page, paneIndex, expectedState, options = {}) {
  const requireSourceChip = options.requireSourceChip || false;
  await page.waitForFunction(
    ({ index, state, requireSourceChip: sourceChipRequired }) => {
      const paneNode = document.querySelectorAll(".inspector-pane")[index];
      const slot = paneNode?.querySelector(".hyperdoc-dom-connect-pane-slot");
      const sourceChip = slot?.querySelector(".hyperdoc-dom-connect-source-chip");
      const matchesState = slot?.dataset.connectState === state;
      if (!matchesState) {
        return false;
      }
      if (!sourceChipRequired) {
        return true;
      }
      return !!sourceChip?.textContent?.trim();
    },
    {
      index: paneIndex,
      state: expectedState,
      requireSourceChip,
    },
    { timeout: 10_000 }
  );
}

async function openConnectRequestEvidence(page, paneIndex) {
  const currentPane = pane(page, paneIndex);
  const evidenceButton = currentPane.locator(".hyperdoc-dom-connect-feedback-open-evidence");
  const paneCountBefore = await page.locator(".inspector-pane").count();
  const existingCountBefore = await page
    .locator(".inspector-title-bar-object")
    .filter({ hasText: /Connect request evidence/ })
    .count();
  await expect(evidenceButton).toBeVisible({ timeout: 20_000 });
  await evidenceButton.click();
  await expect
    .poll(
      () =>
        page.locator(".inspector-title-bar-object").filter({
          hasText: /Connect request evidence/
        }).count(),
      { timeout: 20_000 }
    )
    .toBeGreaterThan(existingCountBefore);
  const evidenceIndex = await page.evaluate(() => {
    return Array.from(document.querySelectorAll(".inspector-pane")).findIndex((paneNode) => {
      const titleNode = paneNode.querySelector(".inspector-title-bar-object");
      return !!(titleNode && /Connect request evidence/.test(titleNode.textContent || ""));
    });
  });
  expect(evidenceIndex).toBeGreaterThanOrEqual(0);
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBeGreaterThan(paneCountBefore - 1);
  await settleInspectorBindings(page);
  return {
    index: evidenceIndex,
    pane: pane(page, evidenceIndex),
  };
}

async function readInspectorPaneState(page, paneIndex) {
  return page.evaluate((index) => {
    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    const activeView = paneNode?.querySelector(".inspector-view:not([hidden])");
    const loadingNode = activeView?.querySelector(".hyperdoc-html-page-loading");
    const titleNode =
      paneNode?.querySelector(".inspector-title-bar-object") ||
      paneNode?.querySelector(".inspector-title-bar-class");
    const tables = activeView
      ? Array.from(activeView.querySelectorAll("table.inspector-table")).map((table) =>
          Array.from(table.querySelectorAll("tr")).map((row) =>
            Array.from(row.children).map((cell) =>
              cell.textContent?.replace(/\s+/g, " ").trim() || ""
            )
          )
        )
      : [];
    return {
      title: titleNode?.textContent?.trim() || null,
      activeTab:
        paneNode?.querySelector(".inspector-tabs button.active")?.textContent?.trim() ||
        null,
      tabNames: paneNode
        ? Array.from(paneNode.querySelectorAll(".inspector-tabs button")).map((button) =>
            button.textContent?.trim() || ""
          )
        : [],
      renderState: activeView?.dataset.hyperdocRenderState || null,
      loadingVisible: !!loadingNode,
      loadingMessage: loadingNode?.textContent?.replace(/\s+/g, " ").trim() || "",
      bodyText:
        activeView?.innerText?.replace(/\s+/g, " ").trim() || "",
      tables,
    };
  }, paneIndex);
}

async function waitForPaneBodyText(page, paneIndex, expectedText, timeout = 20_000) {
  await expect
    .poll(async () => (await readInspectorPaneState(page, paneIndex)).bodyText, {
      timeout,
    })
    .not.toBe("");
  if (expectedText) {
    await expect
      .poll(async () => (await readInspectorPaneState(page, paneIndex)).bodyText, {
        timeout,
      })
      .toContain(expectedText);
  }
  return readInspectorPaneState(page, paneIndex);
}

async function waitForPaneLoadingBoundary(page, paneIndex, timeout = 20_000) {
  await expect
    .poll(async () => (await readInspectorPaneState(page, paneIndex)).loadingVisible, {
      timeout,
    })
    .toBe(false);
  return readInspectorPaneState(page, paneIndex);
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
    const activeView = paneNode?.querySelector(".inspector-view:not([hidden])");
    const surface = activeView?.querySelector(".hyperdoc-connect-provider-surface");
    const titleNode =
      paneNode?.querySelector(".inspector-title-bar-object") ||
      paneNode?.querySelector(".inspector-title-bar-class");
    const lines = activeView
      ? Array.from(activeView.querySelectorAll(".hyperdoc-source-connect-line"))
      : [];
    return {
      paneCount: document.querySelectorAll(".inspector-pane").length,
      title: titleNode?.textContent?.trim() || null,
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

async function readFedWikiStoryPaneState(page, paneIndex) {
  return page.evaluate((index) => {
    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    const activeView = paneNode?.querySelector(".inspector-view:not([hidden])");
    const surface = activeView?.querySelector(".hyperdoc-connect-provider-surface");
    const titleNode =
      paneNode?.querySelector(".inspector-title-bar-object") ||
      paneNode?.querySelector(".inspector-title-bar-class");
    const items = activeView
      ? Array.from(activeView.querySelectorAll(".hyperdoc-fedwiki-story-item-anchor"))
      : [];
    return {
      paneCount: document.querySelectorAll(".inspector-pane").length,
      title: titleNode?.textContent?.trim() || null,
      activeTab:
        paneNode?.querySelector(".inspector-tabs button.active")?.textContent?.trim() ||
        null,
      providerKind: surface?.dataset.hyperdocConnectProviderKind || null,
      viewKind: surface?.dataset.hyperdocConnectViewKind || null,
      itemCount: items.length,
      firstItems: items.slice(0, 5).map((item) => ({
        label: item.dataset.hyperdocFedwikiStoryItemLabel || null,
        id: item.dataset.hyperdocFedwikiStoryItemId || null,
        type: item.dataset.hyperdocFedwikiStoryItemType || null,
        siteDomain: item.dataset.hyperdocFedwikiSiteDomain || null,
        pageSlug: item.dataset.hyperdocFedwikiPageSlug || null,
        pageTitle: item.dataset.hyperdocFedwikiPageTitle || null,
        text: item.textContent?.replace(/\s+/g, " ").trim().slice(0, 140) || "",
      })),
    };
  }, paneIndex);
}

async function waitForSourceProvider(page, paneIndex) {
  const currentPane = pane(page, paneIndex);
  await expect.poll(
    () => activeView(currentPane).locator(".hyperdoc-source-connect-line").count(),
    { timeout: 20_000 }
  ).toBeGreaterThan(5);
  await expect(
    activeView(currentPane).locator(".hyperdoc-connect-provider-surface")
  ).toHaveAttribute("data-hyperdoc-connect-provider-kind", "source-v1");
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

async function runTwoPaneContentAssociation(page, title) {
  const hyperdocPane = await openHyperDoc(page);
  const textPagePane = await openTextPageFromHyperDoc(page, title);
  await activatePaneTab(page, 1, "Main page");
  await activatePaneTab(page, 2, "Content");
  await clearDomConnectTrace(page);
  await startConnectInPane(page, 1);
  await hyperdocPane
    .locator(".hyperdoc-connect-provider-root li")
    .filter({ hasText: exactTextPattern("Text pages") })
    .click();
  const sessionAfterSource = await readConnectSessionState(page);
  await textPagePane
    .locator(".hyperdoc-connect-provider-root h1")
    .filter({ hasText: exactTextPattern(title) })
    .click();
  const trace = await waitForAssociationResult(page);
  return {
    sessionAfterSource,
    trace,
    paneTitles: await readPaneTitles(page),
  };
}

async function runHyperDocToFedWikiAssociation(
  page,
  hyperdocTitle = "Linking HyperDoc pages to FedWiki pages",
  fedwikiLinkText = "FIND"
) {
  await openHyperDoc(page);
  const textPagePane = await openTextPageFromHyperDoc(page, hyperdocTitle);
  const fedwikiPane = await openFedWikiPageFromTextPageLink(page, 2, fedwikiLinkText);
  await activatePaneTab(page, 2, "Content");
  await activatePaneTab(page, 3, "Story");
  const fedwikiState = await readFedWikiStoryPaneState(page, 3);
  await clearDomConnectTrace(page);
  await startConnectInPane(page, 2);
  await textPagePane
    .locator(".hyperdoc-connect-provider-root h1")
    .filter({ hasText: exactTextPattern(hyperdocTitle) })
    .click();
  const sessionAfterSource = await readConnectSessionState(page);
  await fedwikiPane.locator(".hyperdoc-fedwiki-story-item-anchor").nth(0).click();
  const trace = await waitForAssociationResult(page);
  return {
    fedwikiState,
    sessionAfterSource,
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
  const lineButtons = activeView(pane(page, 2)).locator(".hyperdoc-source-connect-line");
  await lineButtons.nth(0).click();
  await waitForConnectChromeState(page, 2, "select-target", {
    requireSourceChip: true,
  });
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
  clearConnectFailureModes,
  exactTextPattern,
  forceNextConnectFailureMode,
  gotoCatalog,
  openHyperDoc,
  openFedWikiPageFromTextPageLink,
  openConnectRequestEvidence,
  openTextPageFromHyperDoc,
  openTopicPageFromHyperDoc,
  pane,
  readInspectorPaneState,
  readConnectSessionState,
  readHelpPanelState,
  readDomConnectTrace,
  readFedWikiStoryPaneState,
  readPaneTitles,
  resetDockPresentation,
  readSourcePaneState,
  runContentAssociation,
  runHyperDocToFedWikiAssociation,
  runTwoPaneContentAssociation,
  runSourceAssociation,
  selectSourceTab,
  settleInspectorBindings,
  startConnectInPane,
  toggleHelpInPane,
  waitForPaneBodyText,
  waitForPaneLoadingBoundary,
  waitForAssociationResult,
  waitForSourceProvider,
};
