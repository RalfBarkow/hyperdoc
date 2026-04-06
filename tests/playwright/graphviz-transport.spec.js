"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  openHyperDoc,
  openTextPageFromHyperDoc,
  pane,
  waitForPaneBodyText,
} = require("./hyperdoc-inspector");

test.describe.configure({ mode: "serial" });

async function readGraphvizPaneState(page, paneIndex) {
  return page.evaluate((index) => {
    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    const activeView = paneNode?.querySelector(".inspector-view:not([hidden])");
    const graphviz = activeView?.querySelector(".inspector-graphviz");
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
      outerHtml: graphviz?.outerHTML?.slice(0, 4000) || null,
    };
  }, paneIndex);
}

async function findGraphvizPaneState(page, titleFragment) {
  return page.evaluate((expectedTitle) => {
    const panes = Array.from(document.querySelectorAll(".inspector-pane"));
    for (let index = 0; index < panes.length; index += 1) {
      const paneNode = panes[index];
      const title =
        (paneNode.querySelector(".inspector-title-bar-object") ||
          paneNode.querySelector(".inspector-title-bar-class"))
          ?.textContent?.trim() || null;
      const activeTab =
        paneNode.querySelector(".inspector-tabs button.active")?.textContent?.trim() || null;
      const activeView = paneNode.querySelector(".inspector-view:not([hidden])");
      const graphviz = activeView?.querySelector(".inspector-graphviz");

      if (!title || !title.includes(expectedTitle)) {
        continue;
      }

      return {
        index,
        title,
        activeTab,
        graphvizState: graphviz?.getAttribute("data-inspector-graphviz-state") || null,
        svgCount: graphviz?.querySelectorAll("svg").length || 0,
        errorText:
          graphviz?.querySelector(".inspector-graphviz-error")?.textContent || null,
        fallbackText:
          graphviz?.querySelector(".inspector-graphviz-dot-fallback pre")?.textContent || null,
      };
    }
    return null;
  }, titleFragment);
}

test("Shared Graphviz transport renders live and entity-sensitive DOT", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  const textPagePane = await openTextPageFromHyperDoc(page, "Code path graphs in HyperDoc");
  await waitForPaneBodyText(page, 2, "Code path graphs in HyperDoc");

  const paneCountBefore = await page.locator(".inspector-pane").count();
  const liveGraphvizReference = textPagePane
    .locator(".hyperbook-reference")
    .filter({ hasText: /dmx-workspace-journal-reconcile-call-graph.*Graphviz/ })
    .first();

  await expect(liveGraphvizReference).toBeVisible({ timeout: 20_000 });
  await liveGraphvizReference.click({ modifiers: ["Alt"] });
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBe(paneCountBefore + 1);

  const graphPaneIndex = paneCountBefore;
  await waitForPaneBodyText(page, graphPaneIndex, "Deferred authored expression");
  await pane(page, graphPaneIndex)
    .locator("button")
    .filter({ hasText: /^Evaluate$/ })
    .click();
  await expect
    .poll(() => findGraphvizPaneState(page, "DMX workspace journal reconcile call graph"), {
      timeout: 20_000,
    })
    .not.toBeNull();

  const graphObjectPane = await findGraphvizPaneState(
    page,
    "DMX workspace journal reconcile call graph"
  );
  await activatePaneTab(page, graphObjectPane.index, "Graphviz");
  await expect
    .poll(() => findGraphvizPaneState(page, "DMX workspace journal reconcile call graph"), {
      timeout: 20_000,
    })
    .toMatchObject({ activeTab: "Graphviz", graphvizState: "rendered" });

  const liveState = await findGraphvizPaneState(
    page,
    "DMX workspace journal reconcile call graph"
  );
  await attachJson(testInfo, "graphviz-live-pane.json", liveState);

  expect(liveState.title).toContain("DMX workspace journal reconcile call graph");
  expect(liveState.activeTab).toBe("Graphviz");
  expect(liveState.errorText).toBeNull();
  expect(liveState.svgCount).toBeGreaterThan(0);
  expect(liveState.fallbackText).toContain("digraph");

  const fixtureResult = await page.evaluate(async (index) => {
    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    const activeView = paneNode?.querySelector(".inspector-view:not([hidden])");
    const dot =
      'digraph "Entity & Quote" {\n' +
      '  "node" [label="A \\"quoted\\" & routed"];\n' +
      '}\n';
    const encodeHtml = (text) =>
      text
        .replace(/&/g, "&amp;")
        .replace(/"/g, "&quot;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/\n/g, "&#10;");

    const encodedDot = encodeHtml(dot);
    const host = document.createElement("div");
    host.innerHTML =
      '<div class="inspector-graphviz" ' +
      'data-inspector-graphviz="true" ' +
      'data-inspector-graphviz-state="pending" ' +
      `data-inspector-graphviz-dot="${encodedDot}">` +
      '<div class="inspector-graphviz-canvas">' +
      '<p class="inspector-graphviz-pending">Rendering Graphviz diagram...</p>' +
      "</div>" +
      '<details class="inspector-graphviz-dot-fallback">' +
      "<summary>Derived DOT source</summary>" +
      `<pre>${encodedDot}</pre>` +
      "</details>" +
      "</div>";

    const placeholder = host.firstElementChild;
    activeView.appendChild(placeholder);
    await window.inspectorGraphviz.renderPlaceholder(placeholder);

    return {
      originalDot: dot,
      transportedDot: placeholder.getAttribute("data-inspector-graphviz-dot"),
      fallbackDot:
        placeholder.querySelector(".inspector-graphviz-dot-fallback pre")?.textContent || null,
      graphvizState: placeholder.getAttribute("data-inspector-graphviz-state"),
      errorText: placeholder.querySelector(".inspector-graphviz-error")?.textContent || null,
      svgCount: placeholder.querySelectorAll("svg").length,
      svgText: Array.from(placeholder.querySelectorAll("svg text")).map((node) =>
        node.textContent || ""
      ),
    };
  }, liveState.index);

  await attachJson(testInfo, "graphviz-entity-fixture.json", fixtureResult);

  expect(fixtureResult.transportedDot).toBe(fixtureResult.originalDot);
  expect(fixtureResult.fallbackDot).toBe(fixtureResult.originalDot);
  expect(fixtureResult.graphvizState).toBe("rendered");
  expect(fixtureResult.errorText).toBeNull();
  expect(fixtureResult.svgCount).toBeGreaterThan(0);
});
