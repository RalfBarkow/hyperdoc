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

async function readFedWikiGraphvizReadonlyState(page, paneIndex) {
  return page.evaluate((index) => {
    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    const activeView = paneNode?.querySelector(".inspector-view:not([hidden])");
    const graphviz = activeView?.querySelector(".inspector-graphviz");
    const shell = activeView?.querySelector(".hyperbook-fedwiki-graphviz-edit-shell");
    return {
      title:
        (paneNode?.querySelector(".inspector-title-bar-object") ||
          paneNode?.querySelector(".inspector-title-bar-class"))
          ?.textContent?.trim() || null,
      activeTab:
        paneNode?.querySelector(".inspector-tabs button.active")?.textContent?.trim() ||
        null,
      graphvizState: graphviz?.getAttribute("data-inspector-graphviz-state") || null,
      svgCount: graphviz?.querySelectorAll("svg").length || 0,
      errorText: graphviz?.querySelector(".inspector-graphviz-error")?.textContent || null,
      fallbackText:
        graphviz?.querySelector(".inspector-graphviz-dot-fallback pre")?.textContent || null,
      shellPresent: !!shell,
      editButtonPresent: !!shell?.querySelector(".hyperbook-fedwiki-graphviz-edit-button"),
      editorPresent: !!shell?.querySelector(".hyperbook-fedwiki-graphviz-editor"),
      saveButtonPresent: !!shell?.querySelector(".hyperbook-fedwiki-graphviz-save-button"),
      hiddenSaveSubmitPresent: !!shell?.querySelector(".hyperbook-fedwiki-graphviz-save-submit"),
    };
  }, paneIndex);
}

test("FedWiki graphviz story item is read-only outside development mode", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, "FedWiki Graphviz story item render trace");
  await waitForPaneBodyText(page, 2, "FedWiki Graphviz story item render trace");
  await openFedWikiPageFromTextPageLink(page, 2, "Graphviz Demo");
  await activatePaneTab(page, 3, "Story");

  await expect
    .poll(() => readFedWikiGraphvizReadonlyState(page, 3), { timeout: 20_000 })
    .toMatchObject({
      title: "Graphviz Demo",
      activeTab: "Story",
      graphvizState: "rendered",
      shellPresent: true,
      editButtonPresent: false,
      editorPresent: false,
      saveButtonPresent: false,
      hiddenSaveSubmitPresent: false,
    });

  const readonlyState = await readFedWikiGraphvizReadonlyState(page, 3);
  await attachJson(testInfo, "fedwiki-graphviz-story-state-readonly.json", readonlyState);

  expect(readonlyState.svgCount).toBeGreaterThan(0);
  expect(readonlyState.errorText).toBeNull();
  expect(readonlyState.fallbackText).toContain("digraph");
});
