"use strict";

const { expect } = require("@playwright/test");
const {
  exactTextPattern,
  pane,
  readDomConnectTrace,
  readPaneTitles,
  settleInspectorBindings,
} = require("./hyperdoc-inspector");

function paneChrome(page, paneIndex) {
  const currentPane = pane(page, paneIndex);
  return {
    pane: currentPane,
    tabRow: currentPane.locator(".inspector-tabs"),
    tabs: currentPane.locator(".inspector-tabs button"),
    activeTab: currentPane.locator(".inspector-tabs button.active"),
    connectRow: currentPane.locator(".hyperdoc-dom-connect-pane-slot"),
    connectControl: currentPane.locator(".hyperdoc-dom-connect-control"),
    connectToggle: currentPane.locator(".hyperdoc-dom-connect-toggle"),
    annotationButton: currentPane.locator(".hyperdoc-dock-annotation"),
    status: currentPane.locator(".hyperdoc-dom-connect-status"),
    cue: currentPane.locator(".hyperdoc-dom-connect-cue"),
    sourceChip: currentPane.locator(".hyperdoc-dom-connect-source-chip"),
    clearButton: currentPane.locator(".hyperdoc-dom-connect-clear"),
    cancelButton: currentPane.locator(".hyperdoc-dom-connect-cancel"),
    feedback: currentPane.locator(".hyperdoc-dom-connect-feedback"),
    helpToggle: currentPane.locator(".hyperdoc-dom-connect-help-toggle"),
    helpPanel: currentPane.locator(".hyperdoc-dom-connect-help-panel"),
    touchFahrplanButton: currentPane.locator(".hyperdoc-dock-touch-fahrplan"),
    dmxButton: currentPane.locator(".hyperdoc-dock-dmx"),
    dismissButton: currentPane.locator(".hyperdoc-dock-dismiss"),
  };
}

async function readPaneChromeState(page, paneIndex) {
  return page.evaluate((index) => {
    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    const tabRow = paneNode?.querySelector(".inspector-tabs");
    const slot = paneNode?.querySelector(".hyperdoc-dom-connect-pane-slot");
    const control = slot?.querySelector(".hyperdoc-dom-connect-control");
    const toggle = slot?.querySelector(".hyperdoc-dom-connect-toggle");
    const status = slot?.querySelector(".hyperdoc-dom-connect-status");
    const cue = slot?.querySelector(".hyperdoc-dom-connect-cue");
    const sourceSummary = slot?.querySelector(".hyperdoc-dom-connect-source-summary");
    const sourceChip = slot?.querySelector(".hyperdoc-dom-connect-source-chip");
    const clearButton = slot?.querySelector(".hyperdoc-dom-connect-clear");
    const cancelButton = slot?.querySelector(".hyperdoc-dom-connect-cancel");
    const feedback = slot?.querySelector(".hyperdoc-dom-connect-feedback");
    const helpPanel = slot?.querySelector(".hyperdoc-dom-connect-help-panel");
    const stateBadge = slot?.querySelector(".hyperdoc-dock-state-badge");
    const coachmarkSummary = slot?.querySelector(".hyperdoc-dock-coachmark-summary");
    const coachmarkDetail = slot?.querySelector(".hyperdoc-dock-coachmark-detail");
    const providerHandoff = slot?.querySelector(".hyperdoc-dock-provider-handoff");
    const touchFahrplan = slot?.querySelector(".hyperdoc-dock-touch-fahrplan");
    const dmx = slot?.querySelector(".hyperdoc-dock-dmx");
    const dismiss = slot?.querySelector(".hyperdoc-dock-dismiss");
    const dockInspect = slot?.querySelector(".hyperdoc-dock-inspect");
    const connectStateInspect = slot?.querySelector(".hyperdoc-dom-connect-inspect");
    const activeView = paneNode?.querySelector(".inspector-view:not([hidden])");
    const providerSurface = activeView?.querySelector(
      ".hyperdoc-connect-provider-surface, .hyperdoc-dom-connect-surface"
    );
    const tabRowRect = tabRow?.getBoundingClientRect();
    const connectRowRect = slot?.getBoundingClientRect();
    const helpPanelRect = helpPanel?.getBoundingClientRect();
    const controlRect = control?.getBoundingClientRect();
    const activeViewRect = activeView?.getBoundingClientRect();
    return {
      activeTab:
        paneNode?.querySelector(".inspector-tabs button.active")?.textContent?.trim() ||
        null,
      slotHidden: !!slot?.hidden,
      slotHelpOpen: slot?.dataset.helpOpen || null,
      presentationState: slot?.dataset.dockPresentation || null,
      connectState: slot?.dataset.connectState || null,
      toggleMode: toggle?.dataset.mode || null,
      toggleText: toggle?.textContent?.trim() || null,
      compactActions: slot
        ? Array.from(slot.querySelectorAll(".hyperdoc-dock-compact .hyperdoc-dock-action"))
            .map((node) => node.textContent?.trim() || "")
        : [],
      statusHidden: !!status?.hidden,
      statusText: status?.textContent?.trim() || null,
      cueHidden: !!cue?.hidden,
      cueText: cue?.textContent?.trim() || null,
      sourceSummaryHidden: !!sourceSummary?.hidden,
      sourceSummaryText:
        sourceSummary?.textContent?.replace(/\s+/g, " ").trim() || null,
      sourceChipText: sourceChip?.textContent?.trim() || null,
      clearHidden: !!clearButton?.hidden,
      cancelHidden: !!cancelButton?.hidden,
      feedbackHidden: !!feedback?.hidden,
      feedbackKind: feedback?.dataset.kind || null,
      feedbackText: feedback?.textContent?.replace(/\s+/g, " ").trim() || null,
      dockInspectPresent: !!dockInspect,
      connectStateInspectPresent: !!connectStateInspect,
      coachmarkVisible:
        !!helpPanel && window.getComputedStyle(helpPanel).display !== "none",
      coachmarkBadge: stateBadge?.textContent?.trim() || null,
      coachmarkSummary: coachmarkSummary?.textContent?.replace(/\s+/g, " ").trim() || null,
      coachmarkDetail: coachmarkDetail?.textContent?.replace(/\s+/g, " ").trim() || null,
      providerHandoffHidden: !!providerHandoff?.hidden,
      providerHandoffLabels: providerHandoff
        ? Array.from(providerHandoff.querySelectorAll("button:not([hidden])"))
            .map((node) => node.textContent?.trim() || "")
        : [],
      touchFahrplanHidden: !!touchFahrplan?.hidden,
      dmxHidden: !!dmx?.hidden,
      dismissHidden: !!dismiss?.hidden,
      providerKind: providerSurface?.dataset.hyperdocConnectProviderKind || null,
      providerViewKind: providerSurface?.dataset.hyperdocConnectViewKind || null,
      helpExpanded:
        slot?.querySelector(".hyperdoc-dom-connect-help-toggle")?.getAttribute(
          "aria-expanded"
        ) || null,
      helpAriaHidden: helpPanel?.getAttribute("aria-hidden") || null,
      panelDisplay: helpPanel ? window.getComputedStyle(helpPanel).display : null,
      tabRowTop: tabRowRect?.top || null,
      tabRowBottom: tabRowRect?.bottom || null,
      tabRowHeight: tabRowRect?.height || null,
      connectRowTop: connectRowRect?.top || null,
      connectRowBottom: connectRowRect?.bottom || null,
      connectRowHeight: connectRowRect?.height || null,
      activeViewTop: activeViewRect?.top || null,
      documentScrollHeight: document.documentElement.scrollHeight,
      panelTop: helpPanelRect?.top || null,
      controlBottom: controlRect?.bottom || null,
    };
  }, paneIndex);
}

async function clearConnectEventTrace(page) {
  await page.evaluate(() => {
    window.hyperdocDomConnectEvents = [];
  });
}

async function collectConnectEventTrace(page) {
  return readDomConnectTrace(page);
}

async function openPaneChromeHelp(page, paneIndex) {
  const chrome = paneChrome(page, paneIndex);
  await expect(chrome.helpToggle).toBeVisible();
  await chrome.helpToggle.click();
  await expect(chrome.helpToggle).toHaveAttribute("aria-expanded", "true");
  return readPaneChromeState(page, paneIndex);
}

function assertHelpPanelAttachment(before, after) {
  expect(before.slotHelpOpen).toBe("false");
  expect(before.helpExpanded).toBe("false");
  expect(before.panelDisplay).toBe("none");

  expect(after.slotHelpOpen).toBe("true");
  expect(after.helpExpanded).toBe("true");
  expect(after.helpAriaHidden).toBe("false");
  expect(after.panelDisplay).toBe("block");
  expect(after.activeViewTop).toBe(before.activeViewTop);
  expect(after.documentScrollHeight).toBe(before.documentScrollHeight);
  expect(after.connectRowTop).toBeGreaterThanOrEqual(before.tabRowBottom - 1);
  expect(after.panelTop).toBeGreaterThan(after.connectRowBottom);
}

async function activatePaneTabWithChrome(page, paneIndex, title, options = {}) {
  const settleMs = options.settleMs === undefined ? 1500 : options.settleMs;
  const chrome = paneChrome(page, paneIndex);
  const tab = chrome.tabs.filter({ hasText: exactTextPattern(title) });
  await expect(tab).toBeVisible();
  await tab.click();
  await expect(chrome.activeTab).toHaveText(exactTextPattern(title));
  if (settleMs > 0) {
    await settleInspectorBindings(page, settleMs);
  }
  return {
    chrome: await readPaneChromeState(page, paneIndex),
    paneTitles: await readPaneTitles(page),
  };
}

async function waitForProviderAvailability(page, paneIndex, expectedAvailable, options = {}) {
  const timeout = options.timeout === undefined ? 10_000 : options.timeout;
  await expect
    .poll(async () => {
      const state = await readPaneChromeState(page, paneIndex);
      return !state.slotHidden;
    }, { timeout })
    .toBe(expectedAvailable);
  return readPaneChromeState(page, paneIndex);
}

async function assertTabClickSafety(page, paneIndex, titles, options = {}) {
  const states = [];
  const settleMs = options.settleMs === undefined ? 1500 : options.settleMs;
  if (options.openHelp) {
    const before = await readPaneChromeState(page, paneIndex);
    const after = await openPaneChromeHelp(page, paneIndex);
    assertHelpPanelAttachment(before, after);
    states.push({
      step: "help-opened",
      before,
      chrome: after,
    });
  }
  for (const title of titles) {
    const result = await activatePaneTabWithChrome(page, paneIndex, title, {
      settleMs,
    });
    states.push({
      step: "tab-activated",
      title,
      chrome: result.chrome,
      paneTitles: result.paneTitles,
    });
  }
  return states;
}

async function assertProviderSurfaceSync(page, paneIndex, options) {
  const connectableTab = options.connectableTab;
  const nonConnectableTab = options.nonConnectableTab;
  const returnTab = options.returnTab || connectableTab;
  const settleMs = options.settleMs === undefined ? 1500 : options.settleMs;

  const connectable = await activatePaneTabWithChrome(page, paneIndex, connectableTab, {
    settleMs,
  });
  const connectableChrome = await waitForProviderAvailability(page, paneIndex, true);

  const nonConnectable = await activatePaneTabWithChrome(page, paneIndex, nonConnectableTab, {
    settleMs,
  });
  const nonConnectableChrome = await waitForProviderAvailability(page, paneIndex, false);

  const returned = await activatePaneTabWithChrome(page, paneIndex, returnTab, {
    settleMs,
  });
  const returnedChrome = await waitForProviderAvailability(page, paneIndex, true);

  return {
    connectable: {
      tab: connectableTab,
      chrome: connectableChrome,
      paneTitles: connectable.paneTitles,
    },
    nonConnectable: {
      tab: nonConnectableTab,
      chrome: nonConnectableChrome,
      paneTitles: nonConnectable.paneTitles,
    },
    returned: {
      tab: returnTab,
      chrome: returnedChrome,
      paneTitles: returned.paneTitles,
    },
  };
}

module.exports = {
  activatePaneTabWithChrome,
  assertHelpPanelAttachment,
  assertProviderSurfaceSync,
  assertTabClickSafety,
  clearConnectEventTrace,
  collectConnectEventTrace,
  openPaneChromeHelp,
  paneChrome,
  readPaneChromeState,
  waitForProviderAvailability,
};
