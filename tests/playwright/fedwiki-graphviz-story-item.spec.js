"use strict";

const { test, expect } = require("@playwright/test");
const fs = require("fs/promises");
const {
  activatePaneTab,
  attachJson,
  openFedWikiPageFromTextPageLink,
  openHyperDoc,
  openTextPageFromHyperDoc,
  pane,
  waitForPaneBodyText,
} = require("./hyperdoc-inspector");

test.describe.configure({ mode: "serial" });

const fedWikiGraphvizDemoPath = "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/graphviz-demo";

async function readFedWikiGraphvizStoryState(page, paneIndex) {
  return page.evaluate((index) => {
    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    const activeView = paneNode?.querySelector(".inspector-view:not([hidden])");
    const anchors = activeView
      ? Array.from(activeView.querySelectorAll(".hyperdoc-fedwiki-story-item-anchor"))
      : [];
    const graphviz = activeView?.querySelector(".inspector-graphviz");
    const shell = activeView?.querySelector(".hyperbook-fedwiki-graphviz-edit-shell");
    const textarea = shell?.querySelector(".hyperbook-fedwiki-graphviz-editor");
    return {
      title:
        (paneNode?.querySelector(".inspector-title-bar-object") ||
          paneNode?.querySelector(".inspector-title-bar-class"))
          ?.textContent?.trim() || null,
      activeTab:
        paneNode?.querySelector(".inspector-tabs button.active")?.textContent?.trim() ||
        null,
      itemCount: anchors.length,
      firstItemId: anchors[0]?.dataset.hyperdocFedwikiStoryItemId || null,
      firstItemType: anchors[0]?.dataset.hyperdocFedwikiStoryItemType || null,
      graphvizState: graphviz?.getAttribute("data-inspector-graphviz-state") || null,
      svgCount: graphviz?.querySelectorAll("svg").length || 0,
      errorText: graphviz?.querySelector(".inspector-graphviz-error")?.textContent || null,
      fallbackText:
        graphviz?.querySelector(".inspector-graphviz-dot-fallback pre")?.textContent || null,
      editButtonVisible: !shell
        ? false
        : !shell.querySelector(".hyperbook-fedwiki-graphviz-edit-button")?.hidden,
      editStateVisible: !!shell?.querySelector(
        ".hyperbook-fedwiki-graphviz-edit-state:not([hidden])"
      ),
      textareaValue: textarea?.value || null,
    };
  }, paneIndex);
}

test("FedWiki graphviz story item keeps render and edit parity through the shared Graphviz seam", async ({
  page,
}, testInfo) => {
  const originalContents = await fs.readFile(fedWikiGraphvizDemoPath, "utf8");
  const updatedDot = "digraph { alpha -> beta; beta -> gamma }";

  try {
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

    const initialState = await readFedWikiGraphvizStoryState(page, 3);
    await attachJson(testInfo, "fedwiki-graphviz-story-state-before-edit.json", initialState);

    expect(initialState.itemCount).toBeGreaterThan(0);
    expect(initialState.svgCount).toBeGreaterThan(0);
    expect(initialState.errorText).toBeNull();
    expect(initialState.fallbackText).toContain("digraph");
    expect(initialState.editButtonVisible).toBe(true);

    await pane(page, 3).locator(".hyperbook-fedwiki-graphviz-edit-button").click();

    await expect
      .poll(() => readFedWikiGraphvizStoryState(page, 3), { timeout: 10_000 })
      .toMatchObject({
        editStateVisible: true,
        textareaValue: initialState.fallbackText,
      });

    const stableItemId = initialState.firstItemId;
    const editor = pane(page, 3).locator(".hyperbook-fedwiki-graphviz-editor");
    await editor.fill(updatedDot);
    await pane(page, 3).locator(".hyperbook-fedwiki-graphviz-preview-button").click();

    await expect
      .poll(() => readFedWikiGraphvizStoryState(page, 3), { timeout: 20_000 })
      .toMatchObject({
        graphvizState: "rendered",
        fallbackText: updatedDot,
        firstItemId: stableItemId,
      });

    await pane(page, 3).locator(".hyperbook-fedwiki-graphviz-save-button").click();

    await expect
      .poll(() => readFedWikiGraphvizStoryState(page, 3), { timeout: 20_000 })
      .toMatchObject({
        graphvizState: "rendered",
        editStateVisible: false,
        fallbackText: updatedDot,
        firstItemId: stableItemId,
      });

    const persistedPage = JSON.parse(await fs.readFile(fedWikiGraphvizDemoPath, "utf8"));
    expect(persistedPage.story[0].id).toBe(stableItemId);
    expect(persistedPage.story[0].type).toBe("graphviz");
    expect(persistedPage.story[0].text).toBe(updatedDot);
    expect(persistedPage.journal[persistedPage.journal.length - 1].type).toBe("edit");
    expect(persistedPage.journal[persistedPage.journal.length - 1].id).toBe(stableItemId);

    await pane(page, 3).getByRole("button", { name: "Reload" }).click();

    await expect
      .poll(() => readFedWikiGraphvizStoryState(page, 3), { timeout: 20_000 })
      .toMatchObject({
        graphvizState: "rendered",
        fallbackText: updatedDot,
        firstItemId: stableItemId,
      });

    await pane(page, 3).locator(".hyperbook-fedwiki-graphviz-edit-button").click();

    await expect
      .poll(() => readFedWikiGraphvizStoryState(page, 3), { timeout: 10_000 })
      .toMatchObject({
        editStateVisible: true,
        textareaValue: updatedDot,
        firstItemId: stableItemId,
      });

    const finalState = await readFedWikiGraphvizStoryState(page, 3);
    await attachJson(testInfo, "fedwiki-graphviz-story-state-after-save.json", finalState);
  } finally {
    await fs.writeFile(fedWikiGraphvizDemoPath, originalContents, "utf8");
  }
});
