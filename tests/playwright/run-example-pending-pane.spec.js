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

    function titleForPane(paneNode) {
      const titleNode =
        paneNode?.querySelector(".inspector-title-bar-object") ||
        paneNode?.querySelector(".inspector-title-bar-class");
      return titleNode?.textContent?.replace(/\s+/g, " ").trim() || null;
    }

    function bodyForPane(paneNode) {
      const activeView = paneNode?.querySelector(".inspector-view:not([hidden])");
      return activeView?.innerText?.replace(/\s+/g, " ").trim().slice(0, 400) || "";
    }

    function capture() {
      const panes = Array.from(document.querySelectorAll(".inspector-pane"));
      const pendingNodes = Array.from(
        document.querySelectorAll(".hyperdoc-evaluation-pending")
      );
      const lastPane = panes[panes.length - 1] || null;
      snapshots.push({
        at: Date.now(),
        paneCount: panes.length,
        pendingPaneCount: pendingNodes.length,
        pendingPhases: pendingNodes.map(
          (node) => node.getAttribute("data-hyperdoc-pending-phase") || null
        ),
        pendingStatuses: pendingNodes.map(
          (node) =>
            node
              .querySelector(".hyperdoc-evaluation-pending-status")
              ?.textContent?.replace(/\s+/g, " ")
              .trim() || null
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
    const activeView = lastPane?.querySelector(".inspector-view:not([hidden])");
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

test("Run example opens a visible pending pane and then replaces it in place", async ({
  page,
}, testInfo) => {
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

  await attachJson(testInfo, "run-example-pending-pane-trace.json", {
    paneCountBefore,
    trace,
    finalState,
  });

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
  expect(
    /already assimilated|Git executable unavailable|Repository metadata unavailable|Git unavailable/i.test(
      finalState.body
    )
  ).toBe(true);
});

test("snippet playground shows a pending pane and replaces it in place", async ({
  page,
}, testInfo) => {
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
  await expect(lastPane).toContainText(/snippet playground|snippet session/i);
  await expect(lastPane).toContainText(/mech/i);
  await expect(lastPane).toContainText(/javascript/i);
  await expect(lastPane).toContainText(/lisp/i);

  const trace = await readPendingPaneTrace(page);
  const finalState = await readLastPaneState(page);
  await attachJson(testInfo, "snippet-playground-pending-trace.json", {
    paneCountBefore,
    trace,
    finalState,
  });

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

test("snippet playground crosswalk recognizes the Quick Brown Fox mech/code pair", async ({
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

  await activatePaneTab(page, snippetPaneIndex, "Source pair");
  await expect(lastPane).toContainText(/Quick Brown Fox/i);
  await expect(lastPane).toContainText(/CODE/i);
  await expect(lastPane).toContainText(/PREVIEW items/i);

  await activatePaneTab(page, snippetPaneIndex, "Code");
  await expect(lastPane).toContainText(/javascript/i);
  await expect(lastPane).toContainText(/state\.items|items/i);

  await activatePaneTab(page, snippetPaneIndex, "Crosswalk");
  await expect(lastPane).toContainText(/click/i);
  await expect(lastPane).toContainText(/neighbors next/i);
  await expect(lastPane).toContainText(/execution seam|crosswalk|translation/i);

  await activatePaneTab(page, snippetPaneIndex, "Lisp scaffold");
  await expect(lastPane).toContainText(/run scaffold|step scaffold|derived-items-of/i);

  await attachJson(testInfo, "snippet-playground-quick-brown-fox.json", {
    snippetPaneIndex,
    finalState: await readLastPaneState(page),
  });
});

test("fedwiki snippet playground opens to the right and replaces pending pane in place", async ({
  page,
}, testInfo) => {
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
  await expect(lastPane).toContainText(/snippet playground|snippet session/i);
  await expect(lastPane).toContainText(/fedwiki-page/i);
  await expect(lastPane).toContainText(/mech/i);
  await expect(lastPane).toContainText(/javascript/i);
  await expect(lastPane).toContainText(/lisp/i);

  const trace = await readPendingPaneTrace(page);
  const finalState = await readLastPaneState(page);
  await attachJson(testInfo, "fedwiki-snippet-playground-pending-trace.json", {
    fedwikiPaneIndex,
    paneCountBefore,
    trace,
    finalState,
  });

  expect(trace.some((snapshot) => snapshot.pendingPaneCount > 0)).toBe(true);
  expect(
    trace.some((snapshot) =>
      snapshot.pendingPhases.some((phase) =>
        /collecting-input|recognizing|pairing|building-session|failed/i.test(
          phase || ""
        )
      )
    )
  ).toBe(true);
  expect(finalState.title || "").toMatch(/snippet playground|snippet session/i);
});

test("fedwiki Quick Brown Fox produces snippet playground session from live story items", async ({
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

  await activatePaneTab(page, snippetPaneIndex, "Summary");
  await expect(lastPane).toContainText(/context view/i);
  await expect(lastPane).toContainText(/story/i);
  await expect(lastPane).toContainText(/origin surface/i);
  await expect(lastPane).toContainText(/fedwiki-page/i);
  await expect(lastPane).toContainText(/provider kind/i);
  await expect(lastPane).toContainText(/fedwiki-v1/i);
  await expect(lastPane).toContainText(/source label/i);
  await expect(lastPane).toContainText(/Quick Brown Fox/i);

  await activatePaneTab(page, snippetPaneIndex, "Source pair");
  await expect(lastPane).toContainText(/Quick Brown Fox/i);
  await expect(lastPane).toContainText(/CODE/i);
  await expect(lastPane).toContainText(/PREVIEW synopsis items|PREVIEW items/i);

  await activatePaneTab(page, snippetPaneIndex, "Code");
  await expect(lastPane).toContainText(/javascript/i);
  await expect(lastPane).toContainText(/state\.items|items/i);

  await activatePaneTab(page, snippetPaneIndex, "Lisp scaffold");
  await expect(lastPane).toContainText(/run scaffold|step scaffold|derived-items-of/i);

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

  expect(finalState.paneCount).toBe(paneCountBefore + 1);
  await expect(lastPane).toContainText(
    /failed|unsupported|malformed|parse|no mech snippet|no supported code snippet/i
  );
  await expect(lastPane).toContainText(/fedwiki-page/i);

  const trace = await readPendingPaneTrace(page);
  await attachJson(testInfo, "fedwiki-snippet-playground-failure-trace.json", {
    fedwikiPaneIndex,
    paneCountBefore,
    trace,
    finalState,
  });

  expect(trace.some((snapshot) => snapshot.pendingPaneCount > 0)).toBe(true);
  expect(finalState.pendingVisible).toBe(false);
});
