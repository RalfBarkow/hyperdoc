"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  openFedWikiPageFromTextPageLink,
  openHyperDoc,
  openTextPageFromHyperDoc,
  waitForPaneBodyText,
} = require("./hyperdoc-inspector");

test.describe.configure({ mode: "serial" });

async function readFedWikiGraphvizStoryState(page, paneIndex) {
  return page.evaluate((index) => {
    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    const activeView = paneNode?.querySelector(".inspector-view:not([hidden])");
    const anchors = activeView
      ? Array.from(activeView.querySelectorAll(".hyperdoc-fedwiki-story-item-anchor"))
      : [];
    const graphviz = activeView?.querySelector(".inspector-graphviz");
    return {
      title:
        (paneNode?.querySelector(".inspector-title-bar-object") ||
          paneNode?.querySelector(".inspector-title-bar-class"))
          ?.textContent?.trim() || null,
      activeTab:
        paneNode?.querySelector(".inspector-tabs button.active")?.textContent?.trim() ||
        null,
      itemCount: anchors.length,
      firstItemType: anchors[0]?.dataset.hyperdocFedwikiStoryItemType || null,
      graphvizState: graphviz?.getAttribute("data-inspector-graphviz-state") || null,
      svgCount: graphviz?.querySelectorAll("svg").length || 0,
      errorText: graphviz?.querySelector(".inspector-graphviz-error")?.textContent || null,
      fallbackText:
        graphviz?.querySelector(".inspector-graphviz-dot-fallback pre")?.textContent || null,
    };
  }, paneIndex);
}

test("FedWiki graphviz story item renders through the shared Graphviz seam", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, "FedWiki Graphviz story item render trace");
  await waitForPaneBodyText(page, 2, "FedWiki Graphviz story item render trace");
  await openFedWikiPageFromTextPageLink(page, 2, "Graphviz Demo");
  await activatePaneTab(page, 3, "Story");

  await expect
    .poll(() => readFedWikiGraphvizStoryState(page, 3), { timeout: 20_000 })
    .toMatchObject({
      title: "Graphviz Demo",
      activeTab: "Story",
      firstItemType: "graphviz",
      graphvizState: "rendered",
    });

  const state = await readFedWikiGraphvizStoryState(page, 3);
  await attachJson(testInfo, "fedwiki-graphviz-story-state.json", state);

  expect(state.itemCount).toBeGreaterThan(0);
  expect(state.svgCount).toBeGreaterThan(0);
  expect(state.errorText).toBeNull();
  expect(state.fallbackText).toContain("digraph");
});
