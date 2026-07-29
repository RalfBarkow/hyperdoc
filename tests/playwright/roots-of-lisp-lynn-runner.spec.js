"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  bootUrl,
  exactTextPattern,
  gotoCatalog,
  pane,
  settleInspectorBindings,
} = require("./hyperdoc-inspector");

test.setTimeout(240_000);

const pageTitle = "Roots of Lisp runner comparison";
const expectedResult = "(a m (a m c) d)";

function routeUrl(relativePath) {
  return new URL(relativePath, bootUrl()).toString();
}

const expectedRunnerTeardownAbortPaths = new Set([
  "/roots-of-lisp-lynn/compiler/reply.js",
  "/roots-of-lisp-lynn/compiler/runme.js",
  "/roots-of-lisp-lynn/compiler/runme.css",
  "/roots-of-lisp-lynn/compiler/doh.wasm",
  "/roots-of-lisp-lynn/compiler/Charser.ob",
]);

function runnerRequestFailures(diagnostics) {
  return diagnostics.failedRequests.filter((entry) =>
    entry.url.includes("/roots-of-lisp-lynn/")
  );
}

function expectedRunnerTeardownAbort(entry) {
  let pathname;

  try {
    pathname = new URL(entry.url).pathname;
  } catch {
    return false;
  }

  return (
    entry.failure?.errorText === "net::ERR_ABORTED" &&
    expectedRunnerTeardownAbortPaths.has(pathname)
  );
}

function collectDiagnostics(page) {
  const diagnostics = {
    consoleErrors: [],
    pageErrors: [],
    failedRequests: [],
    runnerResponses: [],
    iframeUrls: [],
  };
  page.on("console", (message) => {
    if (message.type() === "error") {
      diagnostics.consoleErrors.push(message.text());
    }
  });
  page.on("pageerror", (error) => {
    diagnostics.pageErrors.push(error.message);
  });
  page.on("requestfailed", (request) => {
    diagnostics.failedRequests.push({
      url: request.url(),
      method: request.method(),
      failure: request.failure(),
    });
  });
  page.on("response", (response) => {
    if (response.url().includes("/roots-of-lisp-lynn/")) {
      diagnostics.runnerResponses.push({
        url: response.url(),
        status: response.status(),
        contentType: response.headers()["content-type"] || null,
      });
    }
  });
  return diagnostics;
}

async function exerciseSubst(frame, label) {
  const input = frame.locator("#input");
  const output = frame.locator("#output");
  await expect(frame.locator("#substB"), `${label}: Subst control`).toBeVisible();
  await expect(frame.locator("#evalB"), `${label}: Run control`).toBeVisible();
  await frame.locator("#substB").click();
  await expect(input, `${label}: source fixture`).toHaveValue(/\(defun subst/);
  await frame.locator("#evalB").click();
  await expect
    .poll(() => output.inputValue(), {
      timeout: 45_000,
      message: `${label}: compiled interpreter output`,
    })
    .toContain(expectedResult);
  return {
    label,
    url: frame.url(),
    output: await output.inputValue(),
  };
}

async function contentFrame(container, selector = "iframe") {
  const iframe = container.locator(selector).first();
  await expect(iframe).toBeVisible({ timeout: 20_000 });
  const handle = await iframe.elementHandle();
  const frame = await handle.contentFrame();
  expect(frame).not.toBeNull();
  return frame;
}

async function openRootsHyperDoc(page) {
  await gotoCatalog(page);
  const catalogPane = pane(page, 0);
  const cell = catalogPane
    .locator("td")
    .filter({ hasText: exactTextPattern("Roots of Lisp") })
    .first();
  await expect(cell).toBeVisible({ timeout: 20_000 });
  await cell.click();
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBe(2);
  await expect(
    pane(page, 1).locator(".inspector-tabs button").filter({
      hasText: exactTextPattern("Text pages"),
    })
  ).toBeVisible({ timeout: 20_000 });
}

async function openComparisonPage(page) {
  await activatePaneTab(page, 1, "Text pages");
  const cell = pane(page, 1)
    .locator("td")
    .filter({ hasText: exactTextPattern(pageTitle) })
    .first();
  await expect(cell).toBeVisible({ timeout: 20_000 });
  await cell.click();
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBe(3);
  await activatePaneTab(page, 2, "Content");
}

async function inspectExpression(page, expressionSource) {
  const sourcePaneIndex = 2;
  const destinationPaneIndex = sourcePaneIndex + 1;

  const reference = pane(page, sourcePaneIndex)
    .locator(
      `[data-hyperdoc-expression-source="${expressionSource}"]`
    )
    .first();

  await expect(reference).toBeVisible({ timeout: 20_000 });
  await expect(reference).toHaveAttribute(
    "data-hyperdoc-eval-bound",
    "true",
    { timeout: 20_000 }
  );

  await reference.click();

  // A normal HyperDoc click closes all panes to the right of the
  // source pane and opens the destination immediately to its right.
  await expect
    .poll(() => page.locator(".inspector-pane").count(), {
      timeout: 30_000,
    })
    .toBe(destinationPaneIndex + 1);

  await settleInspectorBindings(page);

  return destinationPaneIndex;
}

async function withRunnerDiagnostics(page, testInfo, body) {
  const diagnostics = collectDiagnostics(page);
  const observations = [];
  let thrown = null;
  try {
    await body(diagnostics, observations);
  } catch (error) {
    thrown = error;
    await testInfo.attach("roots-lynn-failure.png", {
      body: await page.screenshot({ fullPage: true }),
      contentType: "image/png",
    });
  } finally {
    diagnostics.iframeUrls = page.frames().slice(1).map((frame) => frame.url());
    await attachJson(testInfo, "roots-lynn-diagnostics", diagnostics);
    await attachJson(testInfo, "roots-lynn-observations", observations);
  }
  if (thrown) {
    throw thrown;
  }
}

test("pinned Lynn runner executes through the direct stable route", async ({
  page,
}, testInfo) => {
  await withRunnerDiagnostics(page, testInfo, async (diagnostics, observations) => {
    const wasmResponse = await page.request.get(
      routeUrl("/roots-of-lisp-lynn/compiler/doh.wasm")
    );
    expect(wasmResponse.ok()).toBe(true);
    expect(wasmResponse.headers()["content-type"] || "").toContain(
      "application/wasm"
    );

    await page.goto(routeUrl("/roots-of-lisp-lynn/lambda/lisp.html"), {
      waitUntil: "domcontentloaded",
    });
    observations.push(await exerciseSubst(page.mainFrame(), "direct route"));
    expect(diagnostics.pageErrors).toEqual([]);
    expect(runnerRequestFailures(diagnostics)).toEqual([]);
  });
});

test("Lynn runner executes through native, FedWiki, and side-by-side views", async ({
  page,
}, testInfo) => {
  await withRunnerDiagnostics(page, testInfo, async (diagnostics, observations) => {
    await openRootsHyperDoc(page);
    await openComparisonPage(page);

    const artifactPaneIndex = await inspectExpression(
      page,
      "(hyperdoc-graham-roots-of-lisp:make-roots-lynn-runner-artifact)"
    );
    await activatePaneTab(page, artifactPaneIndex, "Runner");
    const artifactPane = pane(page, artifactPaneIndex);
    await expect(artifactPane.locator(".roots-lynn-trust-boundary")).toContainText(
      "not a compute sandbox"
    );
    observations.push(
      await exerciseSubst(
        await contentFrame(
          artifactPane,
          "iframe[title='Ben Lynn Roots of Lisp browser runner']"
        ),
        "native HyperDoc Runner view"
      )
    );

    await activatePaneTab(page, 2, "Content");
    const surfacePaneIndex = await inspectExpression(
	page,
	"(hyperdoc-graham-roots-of-lisp:make-roots-lynn-runner-surface)"
    );
    await activatePaneTab(page, surfacePaneIndex, "Browser");
    const surfacePane = pane(page, surfacePaneIndex);
    const fedwikiPanel = surfacePane.locator(
      "[data-roots-lynn-panel='fedwiki']"
    );
    const nativePanel = surfacePane.locator(
      "[data-roots-lynn-panel='native']"
    );
    await expect(fedwikiPanel).toContainText("Federated Wiki frame representation");
    await expect(nativePanel).toContainText("Native HyperDoc runner representation");
    await expect(fedwikiPanel.locator("[data-story-item-type='frame']")).toBeVisible();
    await expect(surfacePane.locator("iframe")).toHaveCount(2);

    observations.push(
      await exerciseSubst(
        await contentFrame(fedwikiPanel),
        "FedWiki frame representation"
      )
    );
    observations.push(
      await exerciseSubst(
        await contentFrame(nativePanel),
        "native side-by-side representation"
      )
    );

    expect(diagnostics.pageErrors).toEqual([]);

      const runnerFailures = runnerRequestFailures(diagnostics);

      const expectedTeardownAborts = runnerFailures.filter(
	  expectedRunnerTeardownAbort
      );

      const unexpectedRunnerFailures = runnerFailures.filter(
	  (entry) => !expectedRunnerTeardownAbort(entry)
      );

      const unsuccessfulRunnerResponses = diagnostics.runnerResponses.filter(
	  (entry) => entry.status >= 400
      );

      observations.push({
	  label: "runner request failure classification",
	  expectedTeardownAborts,
	  unexpectedRunnerFailures,
	  unsuccessfulRunnerResponses,
      });

      expect(unsuccessfulRunnerResponses).toEqual([]);
      expect(unexpectedRunnerFailures).toEqual([]);
  });
});
