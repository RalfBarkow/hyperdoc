"use strict";

const fs = require("fs");
const path = require("path");
const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  exactTextPattern,
  openHyperDoc,
  openTextPageFromHyperDoc,
  pane,
  readInspectorPaneState,
  settleInspectorBindings,
} = require("./hyperdoc-inspector");

test.describe.configure({ mode: "serial" });
test.setTimeout(180_000);

const scxmlPath = path.join(
  __dirname,
  "..",
  "..",
  "hyperdoc",
  "example-source-artifact-inspector.scxml"
);

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function scxmlLogItems(label) {
  const source = fs.readFileSync(scxmlPath, "utf8");
  const pattern = new RegExp(
    `<log\\s+label="${escapeRegExp(label)}"\\s+expr="([^"]*)"\\s*/>`
  );
  const match = source.match(pattern);
  if (!match) {
    throw new Error(`Missing SCXML log label: ${label}`);
  }
  return match[1].split("|").filter(Boolean);
}

async function visibleTabLabels(page, paneIndex) {
  return page.evaluate((index) => {
    const paneNode = document.querySelectorAll(".inspector-pane")[index];
    return Array.from(paneNode?.querySelectorAll(".inspector-tabs button") || [])
      .filter((button) => {
        const style = window.getComputedStyle(button);
        const rect = button.getBoundingClientRect();
        return (
          style.display !== "none" &&
          style.visibility !== "hidden" &&
          rect.width > 0 &&
          rect.height > 0
        );
      })
      .map((button) => button.textContent?.trim() || "");
  }, paneIndex);
}

async function clearInspectorScxmlTrace(page) {
  await page.evaluate(() => {
    window.hyperdocInspectorScxmlEvents = [];
  });
}

async function readInspectorScxmlTrace(page) {
  return page.evaluate(() => window.hyperdocInspectorScxmlEvents || []);
}

function expectTraceEvent(trace, kind, fields = {}) {
  expect(
    trace.some((entry) => {
      if (entry.kind !== kind) {
        return false;
      }
      return Object.entries(fields).every(([key, value]) => entry[key] === value);
    })
  ).toBe(true);
}

async function openFixtureContent(page) {
  const textPagePane = await openTextPageFromHyperDoc(
    page,
    "Example source artifact inspector contract"
  );
  await activatePaneTab(page, 2, "Content");
  return textPagePane;
}

async function clickFixtureReference(page, label, expectedPaneText) {
  const reference = pane(page, 2)
    .locator(".hyperdoc-deferred-reference")
    .filter({ hasText: exactTextPattern(label) })
    .first();
  await expect(reference).toBeVisible({ timeout: 20_000 });
  await expect(reference).toHaveAttribute("data-hyperdoc-eval-bound", "true", {
    timeout: 20_000,
  });
  await reference.click();
  await expect
    .poll(async () => {
      const count = await page.locator(".inspector-pane").count();
      if (count <= 2) {
        return "";
      }
      const state = await readInspectorPaneState(page, count - 1);
      return [
        state.title || "",
        state.activeTab || "",
        state.bodyText || "",
      ].join("\n");
    }, { timeout: 60_000 })
    .toContain(expectedPaneText);
  await settleInspectorBindings(page);
  return (await page.locator(".inspector-pane").count()) - 1;
}

test("example-source-artifact inspector follows hyperdoc/example-source-artifact-inspector.scxml", async ({
  page,
}, testInfo) => {
  const expectedTabs = scxmlLogItems("visible-tabs");
  const forbiddenTabs = scxmlLogItems("forbidden-tabs");
  const sourceRequired = scxmlLogItems("source-code-required-content");
  const sourceForbidden = scxmlLogItems("source-code-forbidden-content");
  const metaRequired = scxmlLogItems("meta-required-content");

  await openHyperDoc(page);
  await openFixtureContent(page);

  await clearInspectorScxmlTrace(page);
  const artifactPaneIndex = await clickFixtureReference(
    page,
    "Open example source artifact fixture",
    "hyperdoc:defexample"
  );

  await expect
    .poll(() => visibleTabLabels(page, artifactPaneIndex), { timeout: 20_000 })
    .toEqual(expectedTabs);

  const artifactTabs = await visibleTabLabels(page, artifactPaneIndex);
  expect(artifactTabs.filter((label) => label === "Source code")).toHaveLength(1);
  for (const forbidden of forbiddenTabs) {
    expect(artifactTabs).not.toContain(forbidden);
  }

  let artifactState = await readInspectorPaneState(page, artifactPaneIndex);
  expect(artifactState.activeTab).toBe("Source code");
  for (const required of sourceRequired) {
    expect(artifactState.bodyText).toContain(required);
  }
  for (const forbidden of sourceForbidden) {
    expect(artifactState.bodyText).not.toContain(forbidden);
  }

  await activatePaneTab(page, artifactPaneIndex, "Meta");
  artifactState = await readInspectorPaneState(page, artifactPaneIndex);
  expect(artifactState.activeTab).toBe("Meta");
  for (const required of metaRequired) {
    expect(artifactState.bodyText).toContain(required);
  }

  let trace = await readInspectorScxmlTrace(page);
  for (const kind of [
    "scxml-loaded",
    "state-entered",
    "event-dispatched",
    "transition-selected",
    "guard-evaluated",
    "action-invoked",
    "pane-tabs-rendered",
  ]) {
    expectTraceEvent(trace, kind);
  }
  expectTraceEvent(trace, "event-dispatched", { event: "select.meta" });
  expectTraceEvent(trace, "event-dispatched", { event: "tabs.rendered" });
  expectTraceEvent(trace, "transition-selected", {
    event: "tabs.rendered",
    target: "inspecting-example-source-artifact",
  });
  expectTraceEvent(trace, "action-invoked", {
    event: "tabs.rendered",
    action: "render-pane-tabs",
  });
  expectTraceEvent(trace, "transition-selected", {
    event: "select.meta",
    target: "meta-selected",
  });
  expectTraceEvent(trace, "action-invoked", {
    event: "select.meta",
    action: "select-meta-view",
  });

  await activatePaneTab(page, artifactPaneIndex, "Source code");
  artifactState = await readInspectorPaneState(page, artifactPaneIndex);
  expect(artifactState.activeTab).toBe("Source code");
  for (const required of sourceRequired) {
    expect(artifactState.bodyText).toContain(required);
  }
  for (const forbidden of sourceForbidden) {
    expect(artifactState.bodyText).not.toContain(forbidden);
  }

  await activatePaneTab(page, 2, "Content");
  await clearInspectorScxmlTrace(page);
  const resultPaneIndex = await clickFixtureReference(
    page,
    "Open example result fixture",
    "hyperdoc:defexample"
  );
  await activatePaneTab(page, resultPaneIndex, "Summary");
  const resultState = await readInspectorPaneState(page, resultPaneIndex);
  expect(resultState.activeTab).toBe("Summary");

  const sourceLink = pane(page, resultPaneIndex)
    .locator(".inspector-inspect")
    .filter({ hasText: /topic source artifact/ })
    .first();
  await expect(sourceLink).toBeVisible({ timeout: 20_000 });
  const paneCountBeforeSource = await page.locator(".inspector-pane").count();
  await sourceLink.click();
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBe(paneCountBeforeSource + 1);
  const resultSourcePaneIndex = paneCountBeforeSource;
  await expect
    .poll(
      async () => (await readInspectorPaneState(page, resultSourcePaneIndex)).activeTab,
      { timeout: 60_000 }
    )
    .toBe("Source code");
  await expect
    .poll(
      async () => (await readInspectorPaneState(page, resultSourcePaneIndex)).bodyText,
      { timeout: 60_000 }
    )
    .toContain("hyperdoc:defexample");

  const resultSourceTabs = await visibleTabLabels(page, resultSourcePaneIndex);
  expect(resultSourceTabs).toEqual(expectedTabs);
  const resultSourceState = await readInspectorPaneState(
    page,
    resultSourcePaneIndex
  );
  expect(resultSourceState.activeTab).toBe("Source code");
  for (const required of sourceRequired) {
    expect(resultSourceState.bodyText).toContain(required);
  }
  for (const forbidden of sourceForbidden) {
    expect(resultSourceState.bodyText).not.toContain(forbidden);
  }

  trace = await readInspectorScxmlTrace(page);
  expectTraceEvent(trace, "event-dispatched", {
    event: "inspect.example-result.source",
  });
  expectTraceEvent(trace, "transition-selected", {
    event: "inspect.example-result.source",
    target: "result-source-opened",
  });
  expectTraceEvent(trace, "action-invoked", {
    event: "inspect.example-result.source",
    action: "open-artifact-source-code",
  });

  await attachJson(testInfo, "example-source-artifact-scxml-trace.json", {
    scxmlPath,
    expectedTabs,
    artifactTabs,
    resultSourceTabs,
    trace,
  });
});
