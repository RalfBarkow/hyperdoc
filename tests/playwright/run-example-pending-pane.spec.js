"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  openFedWikiPageFromTextPageLink,
  openHyperDoc,
  openTextPageFromHyperDoc,
  selectSourceTab,
  settleInspectorBindings,
} = require("./hyperdoc-inspector");

async function installPendingPaneTrace(page) {
  await page.evaluate(() => {
    const inspector = document.querySelector(".inspector");
    const snapshots = [];
    const nodeIds = new WeakMap();
    let nextNodeId = 1;

    function nodeId(node, prefix) {
      if (!node) {
        return null;
      }
      if (!nodeIds.has(node)) {
        nodeIds.set(node, `${prefix}-${nextNodeId++}`);
      }
      return nodeIds.get(node);
    }

    function activeViewForPane(paneNode) {
      return (
        paneNode?.querySelector(
          ":scope > .inspector-body > .inspector-view:not([hidden])"
        ) || null
      );
    }

    function titleForPane(paneNode) {
      const titleNode =
        paneNode?.querySelector(".inspector-title-bar-object") ||
        paneNode?.querySelector(".inspector-title-bar-class");
      return titleNode?.textContent?.replace(/\s+/g, " ").trim() || null;
    }

    function bodyForPane(paneNode) {
      const activeView = activeViewForPane(paneNode);
      return activeView?.innerText?.replace(/\s+/g, " ").trim().slice(0, 400) || "";
    }

    function capture() {
      const panes = Array.from(document.querySelectorAll(".inspector-pane"));
      const pendingNodes = Array.from(
        document.querySelectorAll(".hyperdoc-evaluation-pending")
      );
      const lastPane = panes[panes.length - 1] || null;
      const activeView = activeViewForPane(lastPane);
      const pendingInLastPane =
        activeView?.querySelector(".hyperdoc-evaluation-pending") || null;
      snapshots.push({
        at: Date.now(),
        paneCount: panes.length,
        pendingPaneCount: pendingNodes.length,
        pendingNodeIds: pendingNodes.map((node) => nodeId(node, "pending")),
        lastPaneActiveViewNodeId: nodeId(activeView, "view"),
        lastPanePendingNodeId: nodeId(pendingInLastPane, "pending"),
        pendingPhases: pendingNodes.map(
          (node) => node.getAttribute("data-hyperdoc-pending-phase") || null
        ),
        pendingRequestIds: pendingNodes.map(
          (node) => node.getAttribute("data-hyperdoc-pending-request-id") || null
        ),
        pendingStatuses: pendingNodes.map(
          (node) =>
            node
              .querySelector(".hyperdoc-evaluation-pending-status")
              ?.textContent?.replace(/\s+/g, " ")
              .trim() || null
        ),
        pendingStageLogs: pendingNodes.map(
          (node) =>
            node
              .querySelector(".hyperdoc-evaluation-stage-log pre")
              ?.textContent?.replace(/\s+/g, " ")
              .trim() || null
        ),
        pendingStageLogsRaw: pendingNodes.map(
          (node) =>
            node.querySelector(".hyperdoc-evaluation-stage-log pre")
              ?.textContent || null
        ),
        lastPaneTitle: titleForPane(lastPane),
        lastPaneBody: bodyForPane(lastPane),
      });
    }

    window.__hyperdocPendingPaneTrace = snapshots;
    window.__hyperdocPendingPaneObserver?.disconnect?.();
    const observer = new MutationObserver(capture);
    observer.observe(inspector, {
      subtree: true,
      childList: true,
      attributes: true,
      characterData: true,
      attributeFilter: ["class", "hidden", "data-hyperdoc-pending-phase"],
    });
    window.__hyperdocPendingPaneObserver = observer;
    capture();
  });
}

async function readPendingPaneTrace(page) {
  return page.evaluate(() => {
    window.__hyperdocPendingPaneObserver?.disconnect?.();
    return window.__hyperdocPendingPaneTrace || [];
  });
}

async function readLastPaneState(page) {
  return page.evaluate(() => {
    const panes = Array.from(document.querySelectorAll(".inspector-pane"));
    const lastPane = panes[panes.length - 1] || null;
    const titleNode =
      lastPane?.querySelector(".inspector-title-bar-object") ||
      lastPane?.querySelector(".inspector-title-bar-class");
    const activeView =
      lastPane?.querySelector(
        ":scope > .inspector-body > .inspector-view:not([hidden])"
      ) || null;
    const pending = activeView?.querySelector(".hyperdoc-evaluation-pending");
    return {
      paneCount: panes.length,
      title: titleNode?.textContent?.replace(/\s+/g, " ").trim() || null,
      body: activeView?.innerText?.replace(/\s+/g, " ").trim() || "",
      pendingVisible: !!pending,
      pendingPhase: pending?.getAttribute("data-hyperdoc-pending-phase") || null,
    };
  });
}

function installPageErrorTrace(page) {
  const errors = [];
  const onPageError = (error) => {
    const message = error?.message || String(error);
    errors.push(message);
  };
  page.on("pageerror", onPageError);
  return {
    read() {
      return errors.slice();
    },
    dispose() {
      page.off("pageerror", onPageError);
    },
  };
}

async function openSnippetPlaygroundFixture(page, title) {
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, title);
  await selectSourceTab(page, 2);
  await settleInspectorBindings(page, 1500);
}

async function openFedWikiSnippetPlaygroundFixture(page, title, fedwikiLinkText) {
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, title);
  await settleInspectorBindings(page, 1000);
  await openFedWikiPageFromTextPageLink(page, 2, fedwikiLinkText);
  const fedwikiPaneIndex = (await page.locator(".inspector-pane").count()) - 1;
  await activatePaneTab(page, fedwikiPaneIndex, "Story");
  await settleInspectorBindings(page, 1500);
  return fedwikiPaneIndex;
}

async function clickSnippetPlayground(page, paneIndex = 2) {
  const button = page
    .locator(".inspector-pane")
    .nth(paneIndex)
    .locator('[data-hyperdoc-snippet-playground-submit="true"]');
  await expect(button).toBeVisible({ timeout: 20_000 });
  await button.click();
}

function activePaneView(paneLocator) {
  return paneLocator
    .locator(":scope > .inspector-body > .inspector-view:not([hidden])")
    .first();
}

function expectStablePendingDomIdentity(trace) {
  const pendingSnapshots = trace.filter(
    (snapshot) =>
      snapshot.pendingPaneCount > 0 &&
      snapshot.lastPanePendingNodeId &&
      snapshot.lastPaneActiveViewNodeId
  );
  expect(pendingSnapshots.length).toBeGreaterThan(1);

  const pendingNodeIds = new Set(
    pendingSnapshots.map((snapshot) => snapshot.lastPanePendingNodeId)
  );
  const activeViewNodeIds = new Set(
    pendingSnapshots.map((snapshot) => snapshot.lastPaneActiveViewNodeId)
  );
  expect(pendingNodeIds.size).toBe(1);
  expect(activeViewNodeIds.size).toBe(1);
}

function expectPendingProgressTextAdvances(trace) {
  const pendingSnapshots = trace.filter((snapshot) => snapshot.pendingPaneCount > 0);
  expect(pendingSnapshots.length).toBeGreaterThan(0);

  const pendingTextSamples = pendingSnapshots.map((snapshot) =>
    JSON.stringify({
      status: snapshot.pendingStatuses?.[0] || null,
      stageLog: snapshot.pendingStageLogs?.[0] || null,
    })
  );
  const distinctPendingTextSamples = new Set(pendingTextSamples);
  const distinctPendingPhases = new Set(
    pendingSnapshots.map((snapshot) => snapshot.pendingPhases?.[0] || null)
  );

  if (distinctPendingPhases.size > 1) {
    expect(distinctPendingTextSamples.size).toBeGreaterThan(1);
    return;
  }

  const sampleForNonEmptyCheck = JSON.parse(pendingTextSamples[0] || "{}");
  expect(
    ((sampleForNonEmptyCheck.status || "").length > 0) ||
      ((sampleForNonEmptyCheck.stageLog || "").length > 0)
  ).toBe(true);
}

function expectPendingStageLogAdvancesWhenAvailable(trace) {
  const pendingSnapshots = trace.filter((snapshot) => snapshot.pendingPaneCount > 0);
  const stageLogSamples = pendingSnapshots
    .map((snapshot) => (snapshot.pendingStageLogs?.[0] || "").trim())
    .filter((sample) => sample.length > 0);
  const distinctPendingPhases = new Set(
    pendingSnapshots
      .map((snapshot) => snapshot.pendingPhases?.[0] || null)
      .filter((phase) => phase)
  );

  if (stageLogSamples.length > 1 && distinctPendingPhases.size > 1) {
    const stageLogChanged = new Set(stageLogSamples).size > 1;
    if (!stageLogChanged) {
      const statusSamples = pendingSnapshots
        .map((snapshot) => (snapshot.pendingStatuses?.[0] || "").trim())
        .filter((sample) => sample.length > 0);
      expect(new Set(statusSamples).size).toBeGreaterThan(1);
    }
  }
}

function expectPendingMultilineStageLog(trace) {
  const pendingSnapshots = trace.filter((snapshot) => snapshot.pendingPaneCount > 0);
  const rawStageLogSamples = pendingSnapshots
    .map((snapshot) => snapshot.pendingStageLogsRaw?.[0] || "")
    .filter((sample) => sample.length > 0);
  expect(rawStageLogSamples.some((sample) => sample.includes("\n"))).toBe(true);
}

function expectNoPendingSerializationSyntaxErrors(pageErrors) {
  const pendingSerializationErrors = pageErrors.filter((message) =>
    /SyntaxError:.*string literal contains an unescaped line break/i.test(message)
  );
  expect(pendingSerializationErrors).toEqual([]);
}

test("Run example opens a visible pending pane and then replaces it in place", async ({
  page,
}, testInfo) => {
  const pageErrorTrace = installPageErrorTrace(page);
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, "Graphviz story item upstream assimilation example");
  await settleInspectorBindings(page, 1000);

  const paneCountBefore = await page.locator(".inspector-pane").count();
  const examplePane = page.locator(".inspector-pane").nth(2);
  const runButton = examplePane
    .locator("button.inspector-action[title='Run example']")
    .first();

  await expect(runButton).toBeVisible({ timeout: 20_000 });
  await installPendingPaneTrace(page);
  await runButton.click();

  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBe(paneCountBefore + 1);

  await page.waitForFunction(
    () =>
      (window.__hyperdocPendingPaneTrace || []).some(
        (snapshot) =>
          snapshot.pendingPaneCount > 0 &&
          snapshot.pendingStatuses.some((status) =>
            /Running example|Evaluating/.test(status || "")
          )
      ),
    { timeout: 20_000 }
  );

  await expect
    .poll(async () => {
      const state = await readLastPaneState(page);
      return (
        state.paneCount === paneCountBefore + 1 &&
        !state.pendingVisible &&
        state.body.length > 0
      );
    }, { timeout: 30_000 })
    .toBe(true);

  const trace = await readPendingPaneTrace(page);
  const finalState = await readLastPaneState(page);
  const pageErrors = pageErrorTrace.read();
  pageErrorTrace.dispose();

  await attachJson(testInfo, "run-example-pending-pane-trace.json", {
    paneCountBefore,
    trace,
    finalState,
    pageErrors,
  });

  expectStablePendingDomIdentity(trace);
  expectPendingProgressTextAdvances(trace);
  expectPendingStageLogAdvancesWhenAvailable(trace);
  expectPendingMultilineStageLog(trace);
  expectNoPendingSerializationSyntaxErrors(pageErrors);

  expect(trace.some((snapshot) => snapshot.pendingPaneCount > 0)).toBe(true);
  expect(
    trace.some((snapshot) =>
      snapshot.pendingStatuses.some((status) =>
        /Running example|Evaluating|Waiting for Git/.test(status || "")
      )
    )
  ).toBe(true);
  expect(finalState.paneCount).toBe(paneCountBefore + 1);
  expect(finalState.pendingVisible).toBe(false);
  expect(finalState.body).not.toContain("Running example...");
  expect(finalState.body).not.toContain("Evaluating...");
  expect(finalState.body.length).toBeGreaterThan(0);
});

test("snippet playground shows a pending pane and replaces it in place", async ({
  page,
}, testInfo) => {
  const pageErrorTrace = installPageErrorTrace(page);
  await openSnippetPlaygroundFixture(page, "Mech CODE Block analysis");
  await installPendingPaneTrace(page);

  const paneCountBefore = await page.locator(".inspector-pane").count();

  await clickSnippetPlayground(page);

  await page.waitForFunction(
    () =>
      (window.__hyperdocPendingPaneTrace || []).some(
        (snapshot) => snapshot.pendingPaneCount > 0
      ),
    { timeout: 20_000 }
  );

  await expect
    .poll(async () => {
      return page.locator(".hyperdoc-evaluation-pending").count();
    }, { timeout: 30_000 })
    .toBe(0);

  const paneCountAfter = await page.locator(".inspector-pane").count();
  expect(paneCountAfter).toBe(paneCountBefore + 1);

  const lastPane = page.locator(".inspector-pane").last();
  const activeView = activePaneView(lastPane);
  await expect(lastPane).toContainText(/snippet playground|snippet session/i);
  await expect(activeView).toContainText(/constructed transformation unit/i);
  await expect(activeView).toContainText(/Interface:\s*state\.items/i);

  const trace = await readPendingPaneTrace(page);
  const finalState = await readLastPaneState(page);
  const pageErrors = pageErrorTrace.read();
  pageErrorTrace.dispose();
  await attachJson(testInfo, "snippet-playground-pending-trace.json", {
    paneCountBefore,
    trace,
    finalState,
    pageErrors,
  });

  expectStablePendingDomIdentity(trace);
  expectPendingStageLogAdvancesWhenAvailable(trace);
  expectPendingMultilineStageLog(trace);
  expectNoPendingSerializationSyntaxErrors(pageErrors);
  expect(
    trace.some(
      (snapshot) =>
        snapshot.pendingPaneCount > 0 &&
        snapshot.pendingPhases.some((phase) => phase)
    )
  ).toBe(true);

  const finalSnapshot = trace[trace.length - 1];
  expect(finalSnapshot.pendingPaneCount).toBe(0);
  expect(finalState.title || "").toMatch(/snippet playground|snippet session/i);
});

test("snippet playground turns malformed or unsupported input into an inspectable failure", async ({
  page,
}, testInfo) => {
  await openSnippetPlaygroundFixture(page, "Mechs at Sea");
  await installPendingPaneTrace(page);

  const paneCountBefore = await page.locator(".inspector-pane").count();

  await clickSnippetPlayground(page);

  await page.waitForFunction(
    () =>
      (window.__hyperdocPendingPaneTrace || []).some(
        (snapshot) => snapshot.pendingPaneCount > 0
      ),
    { timeout: 20_000 }
  );

  await expect
    .poll(async () => {
      const state = await readLastPaneState(page);
      if (state.pendingVisible) {
        return "";
      }
      return state.body;
    }, { timeout: 30_000 })
    .toMatch(/failed|unsupported|malformed|parse|no mech snippet|no supported code snippet/i);

  const finalState = await readLastPaneState(page);
  expect(finalState.paneCount).toBe(paneCountBefore + 1);

  const lastPane = page.locator(".inspector-pane").last();
  await expect(lastPane).toContainText(
    /failed|unsupported|malformed|parse|no mech snippet|no supported code snippet/i
  );

  const trace = await readPendingPaneTrace(page);
  await attachJson(testInfo, "snippet-playground-failure-trace.json", {
    paneCountBefore,
    trace,
    finalState,
  });

  expect(trace.some((snapshot) => snapshot.pendingPaneCount > 0)).toBe(true);
  expect(finalState.pendingVisible).toBe(false);
});

test("snippet playground summary stays sparse while foregrounding the transformation unit", async ({
  page,
}, testInfo) => {
  await openSnippetPlaygroundFixture(page, "Mech CODE Block analysis");

  await clickSnippetPlayground(page);

  await expect
    .poll(async () => {
      const state = await readLastPaneState(page);
      return state.pendingVisible ? "" : state.title || "";
    }, { timeout: 30_000 })
    .toMatch(/snippet playground|snippet session/i);

  const snippetPaneIndex = (await page.locator(".inspector-pane").count()) - 1;
  const lastPane = page.locator(".inspector-pane").last();
  const activeView = activePaneView(lastPane);

  await activatePaneTab(page, snippetPaneIndex, "Summary");
  await expect(activeView).toContainText(/Constructed transformation unit from Mech #\d+ and JavaScript #\d+\./i);
  await expect(activeView).toContainText(/Interface:\s*state\.items/i);
  await expect(activeView).not.toContainText(/provider kind|origin surface|recognized mech snippets|recognized code snippets|selected mech evidence|selected code evidence|run|source file|context view/i);
  await expect(activeView).not.toContainText(/snippet playground pair|Dreyeck/i);

  await activatePaneTab(page, snippetPaneIndex, "Behavior");
  await expect(
    activeView.locator('[data-hyperdoc-snippet-machine-scxml="true"]')
  ).toBeVisible();
  await expect(activeView).toContainText(/snippet_playground_run/i);
  await expect(activeView).toContainText(/snippet-click/i);
  await expect(activeView).toContainText(/html-source/i);
  await expect(activeView).toContainText(/fedwiki-page/i);
  await expect(activeView).toContainText(/<scxml/i);

  await attachJson(testInfo, "snippet-playground-quick-brown-fox.json", {
    snippetPaneIndex,
    finalState: await readLastPaneState(page),
  });
});

test("snippet playground comparison layout places Lefty left and Rita right", async ({
  page,
}, testInfo) => {
  await openSnippetPlaygroundFixture(page, "Mech CODE Block analysis");

  await clickSnippetPlayground(page);

  await expect
    .poll(async () => {
      const state = await readLastPaneState(page);
      return state.pendingVisible ? "" : state.title || "";
    }, { timeout: 30_000 })
    .toMatch(/snippet playground|snippet session/i);

  const snippetPaneIndex = (await page.locator(".inspector-pane").count()) - 1;
  const lastPane = page.locator(".inspector-pane").last();
  const activeView = activePaneView(lastPane);
  const leftColumn = activeView.locator(".hyperdoc-snippet-comparison-left");
  const centerColumn = activeView.locator(".hyperdoc-snippet-comparison-center");
  const rightColumn = activeView.locator(".hyperdoc-snippet-comparison-right");
  const transformationUnit = activeView.locator(
    ".hyperdoc-snippet-transformation-unit"
  );

  await activatePaneTab(page, snippetPaneIndex, "Comparison");
  await expect(page.locator(".hyperdoc-evaluation-pending")).toHaveCount(0);
  await expect(leftColumn).toContainText(/JavaScript/i);
  await expect(leftColumn).toContainText(/export default|async function|const text/i);
  await expect(leftColumn).toContainText(/this\.items|state\.items/i);
  await expect(centerColumn).toContainText(/Mech/i);
  await expect(centerColumn).toContainText(/CODE/i);
  await expect(centerColumn).toContainText(/PREVIEW (synopsis )?items/i);
  await expect(rightColumn).toContainText(/Lisp/i);
  await expect(rightColumn).toContainText(/Quick Brown Fox/i);
  await expect(rightColumn).toContainText(/derived-items-of|let\*/i);
  const [leftBox, centerBox, rightBox] = await Promise.all([
    leftColumn.boundingBox(),
    centerColumn.boundingBox(),
    rightColumn.boundingBox(),
  ]);
  expect(leftBox).toBeTruthy();
  expect(centerBox).toBeTruthy();
  expect(rightBox).toBeTruthy();
  expect(centerBox.y).toBeLessThan(leftBox.y);
  expect(centerBox.y).toBeLessThan(rightBox.y);
  expect(leftBox.x).toBeLessThan(rightBox.x);
  expect(centerBox.width).toBeGreaterThan(leftBox.width);
  expect(centerBox.width).toBeGreaterThan(rightBox.width);
  expect(
    await activeView.locator("h3", { hasText: /^Mech$/ }).count()
  ).toBe(1);
  await expect(transformationUnit).toContainText(/Transformation unit/i);
  await expect(transformationUnit).toContainText(/Interface/i);
  await expect(transformationUnit).toContainText(/state\.items/i);
  await expect(transformationUnit).toContainText(/Operation/i);
  await expect(transformationUnit).toContainText(/Output/i);
  await expect(transformationUnit).toContainText(/Preview/i);
  await expect(activeView).not.toContainText(/provider kind|origin surface|recognized mech snippets|run|Dreyeck/i);

  await activatePaneTab(page, snippetPaneIndex, "Lisp scaffold");
  await expect(page.locator(".hyperdoc-evaluation-pending")).toHaveCount(0);
  await expect(activeView).toContainText(/Scaffold source/i);
  await expect(activeView).toContainText(/Quick Brown Fox/i);
  await expect(activeView).toContainText(/derived-items-of|let\*/i);
  await expect(activeView).not.toContainText(/translation-error/i);

  await activatePaneTab(page, snippetPaneIndex, "Layout");
  await expect(
    activeView.locator('[data-hyperdoc-snippet-layout-relations="true"]')
  ).toBeVisible();
  await expect(activeView).toContainText(/comparison-pane contains-left lefty-javascript/i);
  await expect(activeView).toContainText(/comparison-pane contains-center shared-mech/i);
  await expect(activeView).toContainText(/comparison-pane contains-right rita-lisp/i);
  await expect(activeView).toContainText(/shared-mech above lefty-javascript/i);
  await expect(activeView).toContainText(/shared-mech above rita-lisp/i);
  await expect(activeView).toContainText(/result-pane right-of origin-pane/i);
  await expect(activeView).toContainText(/ready-pane replaces pending-pane/i);

  await attachJson(testInfo, "snippet-playground-comparison-view.json", {
    snippetPaneIndex,
    finalState: await readLastPaneState(page),
  });
});

test("fedwiki snippet playground opens to the right and replaces pending pane in place", async ({
  page,
}, testInfo) => {
  const pageErrorTrace = installPageErrorTrace(page);
  const fedwikiPaneIndex = await openFedWikiSnippetPlaygroundFixture(
    page,
    "Mech CODE Block analysis",
    "Quick Brown Fox"
  );
  await installPendingPaneTrace(page);

  const paneCountBefore = await page.locator(".inspector-pane").count();
  await clickSnippetPlayground(page, fedwikiPaneIndex);

  await page.waitForFunction(
    () =>
      (window.__hyperdocPendingPaneTrace || []).some(
        (snapshot) => snapshot.pendingPaneCount > 0
      ),
    { timeout: 20_000 }
  );

  await expect
    .poll(async () => page.locator(".hyperdoc-evaluation-pending").count(), {
      timeout: 30_000,
    })
    .toBe(0);

  const paneCountAfter = await page.locator(".inspector-pane").count();
  expect(paneCountAfter).toBe(paneCountBefore + 1);

  const lastPane = page.locator(".inspector-pane").last();
  const activeView = activePaneView(lastPane);
  await expect(lastPane).toContainText(/snippet playground|snippet session/i);
  await expect(activeView).toContainText(/constructed transformation unit/i);
  await expect(activeView).toContainText(/Interface:\s*state\.items/i);

  const trace = await readPendingPaneTrace(page);
  const finalState = await readLastPaneState(page);
  const pageErrors = pageErrorTrace.read();
  pageErrorTrace.dispose();
  await attachJson(testInfo, "fedwiki-snippet-playground-pending-trace.json", {
    fedwikiPaneIndex,
    paneCountBefore,
    trace,
    finalState,
    pageErrors,
  });

  expectStablePendingDomIdentity(trace);
  expectPendingStageLogAdvancesWhenAvailable(trace);
  expectPendingMultilineStageLog(trace);
  expectNoPendingSerializationSyntaxErrors(pageErrors);
  expect(trace.some((snapshot) => snapshot.pendingPaneCount > 0)).toBe(true);
  expect(
    trace.some((snapshot) =>
      snapshot.pendingPhases.some((phase) => (phase || "").length > 0) ||
      snapshot.pendingStatuses.some((status) => (status || "").length > 0) ||
      snapshot.pendingStageLogs.some((stageLog) => (stageLog || "").length > 0)
    )
  ).toBe(true);
  expect(finalState.title || "").toMatch(/snippet playground|snippet session/i);
});

test("fedwiki Quick Brown Fox produces transformation unit with execution interface state.items", async ({
  page,
}, testInfo) => {
  const fedwikiPaneIndex = await openFedWikiSnippetPlaygroundFixture(
    page,
    "Mech CODE Block analysis",
    "Quick Brown Fox"
  );

  await clickSnippetPlayground(page, fedwikiPaneIndex);

  await expect
    .poll(async () => {
      const state = await readLastPaneState(page);
      return state.pendingVisible ? "" : state.title || "";
    }, { timeout: 30_000 })
    .toMatch(/snippet playground|snippet session/i);

  const snippetPaneIndex = (await page.locator(".inspector-pane").count()) - 1;
  const lastPane = page.locator(".inspector-pane").last();
  const activeView = activePaneView(lastPane);

  await activatePaneTab(page, snippetPaneIndex, "Summary");
  await expect(activeView).toContainText(/Constructed transformation unit from Mech #\d+ and JavaScript #\d+\./i);
  await expect(activeView).toContainText(/Interface:\s*state\.items/i);
  await expect(activeView).not.toContainText(/provider kind|origin surface|source label|context view|run|Dreyeck/i);

  await activatePaneTab(page, snippetPaneIndex, "Evidence");
  await expect(lastPane).toContainText(/Quick Brown Fox/i);
  await expect(lastPane).toContainText(/CODE/i);
  await expect(lastPane).toContainText(/PREVIEW synopsis items|PREVIEW items/i);

  await activatePaneTab(page, snippetPaneIndex, "Details");
  await expect(lastPane).toContainText(/provider kind/i);
  await expect(lastPane).toContainText(/fedwiki-v1/i);
  await expect(lastPane).toContainText(/origin surface/i);
  await expect(lastPane).toContainText(/fedwiki-page/i);

  await activatePaneTab(page, snippetPaneIndex, "Behavior");
  await expect(
    activeView.locator('[data-hyperdoc-snippet-machine-scxml="true"]')
  ).toBeVisible();
  await expect(activeView).toContainText(/snippet_playground_run/i);
  await expect(activeView).toContainText(/html-source/i);
  await expect(activeView).toContainText(/fedwiki-page/i);
  await expect(activeView).toContainText(/<scxml/i);

  await activatePaneTab(page, snippetPaneIndex, "Comparison");
  const comparisonView = activePaneView(lastPane);
  await expect(
    comparisonView.locator(".hyperdoc-snippet-comparison-left")
  ).toContainText(/JavaScript/i);
  await expect(
    comparisonView.locator(".hyperdoc-snippet-comparison-center")
  ).toContainText(/Mech/i);
  await expect(
    comparisonView.locator(".hyperdoc-snippet-comparison-right")
  ).toContainText(/Lisp/i);
  expect(
    await comparisonView.locator("h3", { hasText: /^Mech$/ }).count()
  ).toBe(1);
  await expect(
    comparisonView.locator(".hyperdoc-snippet-transformation-unit")
  ).toContainText(/state\.items/i);

  await attachJson(testInfo, "fedwiki-snippet-playground-quick-brown-fox.json", {
    fedwikiPaneIndex,
    snippetPaneIndex,
    finalState: await readLastPaneState(page),
  });
});

test("malformed fedwiki input produces inspectable failure", async ({
  page,
}, testInfo) => {
  const fedwikiPaneIndex = await openFedWikiSnippetPlaygroundFixture(
    page,
    "FedWiki Graphviz story item render trace",
    "Graphviz Demo"
  );
  await installPendingPaneTrace(page);

  const paneCountBefore = await page.locator(".inspector-pane").count();
  await clickSnippetPlayground(page, fedwikiPaneIndex);

  await page.waitForFunction(
    () =>
      (window.__hyperdocPendingPaneTrace || []).some(
        (snapshot) => snapshot.pendingPaneCount > 0
      ),
    { timeout: 20_000 }
  );

  await expect
    .poll(async () => {
      const state = await readLastPaneState(page);
      return state.pendingVisible ? "" : state.body;
    }, { timeout: 30_000 })
    .toMatch(
      /failed|unsupported|malformed|parse|no mech snippet|no supported code snippet/i
    );

  const finalState = await readLastPaneState(page);
  const lastPane = page.locator(".inspector-pane").last();
  const snippetPaneIndex = (await page.locator(".inspector-pane").count()) - 1;

  expect(finalState.paneCount).toBeGreaterThanOrEqual(paneCountBefore + 1);
  await expect(lastPane).toContainText(
    /failed|unsupported|malformed|parse|no mech snippet|no supported code snippet/i
  );

  await activatePaneTab(page, snippetPaneIndex, "Details");
  await expect(lastPane).toContainText(/origin surface/i);
  await expect(lastPane).toContainText(/fedwiki-page/i);

  const trace = await readPendingPaneTrace(page);
  await attachJson(testInfo, "fedwiki-snippet-playground-failure-trace.json", {
    fedwikiPaneIndex,
    snippetPaneIndex,
    paneCountBefore,
    trace,
    finalState,
  });

  expect(trace.some((snapshot) => snapshot.pendingPaneCount > 0)).toBe(true);
  expect(finalState.pendingVisible).toBe(false);
});
