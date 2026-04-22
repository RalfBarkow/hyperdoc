"use strict";

const { test, expect } = require("@playwright/test");
const {
  attachJson,
  openHyperDoc,
  openTextPageFromHyperDoc,
  selectSourceTab,
  settleInspectorBindings,
} = require("./hyperdoc-inspector");
const { readPaneChromeState } = require("./pane-chrome-harness");

async function readSourcePaneLayout(page, paneIndex) {
  return page.evaluate((index) => {
    function rectData(node) {
      if (!node) {
        return null;
      }
      const rect = node.getBoundingClientRect();
      return {
        top: rect.top,
        left: rect.left,
        right: rect.right,
        bottom: rect.bottom,
        width: rect.width,
        height: rect.height,
      };
    }

    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    const slot = paneNode?.querySelector(".hyperdoc-dom-connect-pane-slot");
    const control = slot?.querySelector(
      ".hyperdoc-dom-connect-control.hyperdoc-dock-control"
    );
    const activeView = paneNode?.querySelector(".inspector-view:not([hidden])");
    const sourcePane = activeView?.querySelector(".hyperdoc-source-pane");
    const sourceView = activeView?.querySelector(".hyperdoc-source-connect-view");
    const firstLine = sourceView?.querySelector(".hyperdoc-source-connect-line");
    const sourcePaneStyle = sourcePane && window.getComputedStyle(sourcePane);
    const sourceViewStyle = sourceView && window.getComputedStyle(sourceView);

    return {
      slotHidden: !!slot?.hidden,
      controlPresent: !!control,
      controlText: control?.textContent?.replace(/\s+/g, " ").trim() || "",
      slotRect: rectData(slot),
      activeViewRect: rectData(activeView),
      sourcePanePresent: !!sourcePane,
      sourcePaneRect: rectData(sourcePane),
      sourcePaneDisplay: sourcePaneStyle?.display || null,
      sourceViewPresent: !!sourceView,
      sourceViewRect: rectData(sourceView),
      sourceViewOverflowY: sourceViewStyle?.overflowY || null,
      sourceViewBorderTopWidth: sourceViewStyle?.borderTopWidth || null,
      firstLinePresent: !!firstLine,
      firstLineRect: rectData(firstLine),
    };
  }, paneIndex);
}

test("HTML Source keeps dock chrome above a full-width source pane", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(
    page,
    "Workspace-native annotations in a DMX workspace"
  );
  await selectSourceTab(page, 2);
  await settleInspectorBindings(page, 1500);

  const chrome = await readPaneChromeState(page, 2);
  const layout = await readSourcePaneLayout(page, 2);

  await attachJson(testInfo, "html-source-pane-layout.json", {
    chrome,
    layout,
  });

  expect(chrome.activeTab).toBe("Source");
  expect(chrome.slotHidden).toBe(false);
  expect(layout.controlPresent).toBe(true);
  expect(layout.controlText).toContain("Connect");
  expect(layout.controlText).toContain("Annotation");
  expect(chrome.compactActions).toContain("Snippet");
  expect(chrome.snippetHidden).toBe(false);
  expect(layout.controlText).toContain("Guide");
  expect(layout.sourcePanePresent).toBe(true);
  expect(layout.sourceViewPresent).toBe(true);
  expect(layout.firstLinePresent).toBe(true);
  expect(layout.sourcePaneDisplay).toBe("block");
  expect(layout.sourceViewOverflowY).toBe("visible");
  expect(layout.sourceViewBorderTopWidth).toBe("0px");
  expect(layout.sourcePaneRect?.width || 0).toBeGreaterThan(200);
  expect(layout.sourcePaneRect?.height || 0).toBeGreaterThan(80);
  expect(layout.sourceViewRect?.width || 0).toBeGreaterThan(200);
  expect(layout.sourceViewRect?.height || 0).toBeGreaterThan(80);
  expect(layout.firstLineRect?.height || 0).toBeGreaterThan(0);
  expect(layout.sourcePaneRect?.top || 0).toBeGreaterThanOrEqual(
    (layout.slotRect?.bottom || 0) - 1
  );
  expect(layout.sourcePaneRect?.width || 0).toBeGreaterThan(
    ((layout.activeViewRect?.width || 0) * 0.6)
  );
  expect(layout.sourcePaneRect?.left || 0).toBeLessThanOrEqual(
    (layout.activeViewRect?.left || 0) + 8
  );
  expect((layout.activeViewRect?.right || 0) - (layout.sourcePaneRect?.right || 0))
    .toBeLessThanOrEqual(8);
  expect(layout.sourceViewRect?.left || 0).toBeLessThanOrEqual(
    (layout.activeViewRect?.left || 0) + 8
  );
  expect((layout.activeViewRect?.right || 0) - (layout.sourceViewRect?.right || 0))
    .toBeLessThanOrEqual(8);
  expect(layout.sourceViewRect?.width || 0).toBeGreaterThan(
    ((layout.activeViewRect?.width || 0) * 0.9)
  );
  expect(layout.sourceViewRect?.height || 0).toBeGreaterThan(
    ((layout.sourcePaneRect?.height || 0) * 0.95)
  );
});

test("snippet playground opens in a fresh pane to the right without collapsing the source pane", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, "Mech CODE Block analysis");
  await selectSourceTab(page, 2);
  await settleInspectorBindings(page, 1500);

  const panesBefore = page.locator(".inspector-pane");
  const paneCountBefore = await panesBefore.count();
  const sourcePaneBefore = panesBefore.last();
  const sourceBoxBefore = await sourcePaneBefore.boundingBox();
  const chromeBefore = await readPaneChromeState(page, 2);

  const snippetButton = sourcePaneBefore.locator(
    '[data-hyperdoc-snippet-playground-submit="true"]'
  );
  await expect(snippetButton).toBeVisible({ timeout: 20_000 });
  await snippetButton.click();

  await expect
    .poll(async () => page.locator(".inspector-pane").count(), { timeout: 30_000 })
    .toBe(paneCountBefore + 1);

  const panesAfter = page.locator(".inspector-pane");
  const sourcePaneAfter = panesAfter.nth(paneCountBefore - 1);
  const snippetPane = panesAfter.last();

  const sourceBoxAfter = await sourcePaneAfter.boundingBox();
  const snippetBox = await snippetPane.boundingBox();

  await attachJson(testInfo, "snippet-playground-pane-layout.json", {
    paneCountBefore,
    sourceBoxBefore,
    sourceBoxAfter,
    snippetBox,
    chromeBefore,
  });

  expect(sourceBoxBefore).toBeTruthy();
  expect(sourceBoxAfter).toBeTruthy();
  expect(snippetBox).toBeTruthy();

  expect(snippetBox.x).toBeGreaterThan(sourceBoxAfter.x);
  expect(snippetBox.x).toBeGreaterThan(
    (sourceBoxAfter.x || 0) + ((sourceBoxAfter.width || 0) * 0.5)
  );

  await expect(sourcePaneAfter).toContainText(/Mech CODE Block analysis/i);
  await expect(snippetPane).toContainText(/snippet playground|snippet session/i);
});
