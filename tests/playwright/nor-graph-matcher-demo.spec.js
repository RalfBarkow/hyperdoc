"use strict";

const { test, expect } = require("@playwright/test");
const {
  openHyperDoc,
  openTextPageFromHyperDoc,
  settleInspectorBindings,
} = require("./hyperdoc-inspector");

function installBrowserErrorTrace(page) {
  const errors = [];
  const onPageError = (error) => errors.push(error?.message || String(error));
  const onConsole = (message) => {
    if (message.type() === "error") {
      errors.push(message.text());
    }
  };
  page.on("pageerror", onPageError);
  page.on("console", onConsole);
  return {
    read() {
      return errors.slice();
    },
    dispose() {
      page.off("pageerror", onPageError);
      page.off("console", onConsole);
    },
  };
}

async function readLastPaneState(page) {
  return page.evaluate(() => {
    const panes = Array.from(document.querySelectorAll(".inspector-pane"));
    const lastPane = panes[panes.length - 1] || null;
    const titleNode =
      lastPane?.querySelector(".inspector-title-bar-object") ||
      lastPane?.querySelector(".inspector-title-bar-class");
    const activeView =
      lastPane?.querySelector(".inspector-view:not([hidden])") || null;
    const pending = activeView?.querySelector(".hyperdoc-evaluation-pending");
    return {
      paneCount: panes.length,
      title: titleNode?.textContent?.replace(/\s+/g, " ").trim() || null,
      body: activeView?.innerText?.replace(/\s+/g, " ").trim() || "",
      pendingVisible: !!pending,
    };
  });
}

function resultPattern(expectedResult) {
  return new RegExp(
    `RESULT\\s+(?:\\d+\\s+)?(?:COMMON-LISP:)?${expectedResult}\\b`,
    "i"
  );
}

function resultStateMatches(state, expectedResult, fragments) {
  return (
    !state.pendingVisible &&
    resultPattern(expectedResult).test(state.body) &&
    fragments.every((fragment) => state.body.includes(fragment))
  );
}

async function openHyperDocWithColdStartRetry(page) {
  let lastError = null;
  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      return await openHyperDoc(page);
    } catch (error) {
      lastError = error;
      await page.goto("about:blank");
      await page.waitForTimeout(1500);
    }
  }
  throw lastError;
}

test("NOR graph matcher teaching story source blocks resolve and examples run", async ({
  page,
}, testInfo) => {
  await openHyperDocWithColdStartRetry(page);
  const browserErrors = installBrowserErrorTrace(page);
  await openTextPageFromHyperDoc(page, "NOR Graph Matcher Teaching Story");
  await settleInspectorBindings(page, 1000);

  const storyPane = page.locator(".inspector-pane").nth(2);
  const sourceNames = [
    "nor-graph-active-pair-leaf-success",
    "nor-graph-active-pair-nor-failure",
    "nor-graph-normal-form-success",
    "nor-graph-normal-form-failure",
    "nor-graph-run",
    "nor-graph-make-nor-matcher",
    "nor-graph-evaluate-leaf",
  ];

  for (const name of sourceNames) {
    await expect(storyPane).toContainText(name);
  }
  const activeStoryView = storyPane.locator(".inspector-view:not([hidden])");
  await expect(activeStoryView).not.toContainText(
    /undefined function|No page|Unresolvable reference/i
  );

  const expectedResults = [
    [
      "nor-graph-active-pair-leaf-success",
      "T",
      ["EDGE-LEFTY-RITA", "ACTIVE-ALIVE-PAIR", "LEFTY", "RITA"],
    ],
    [
      "nor-graph-active-pair-nor-failure",
      "NIL",
      ["EDGE-LEFTY-RITA", "NOR-SHORT-CIRCUIT", "ACTIVE-ALIVE-PAIR"],
    ],
    [
      "nor-graph-normal-form-success",
      "T",
      ["ANY-ACTIVE-ALIVE-PAIR", "MATCHED-P", "EVIDENCE"],
    ],
    [
      "nor-graph-normal-form-failure",
      "NIL",
      ["EDGE-LEFTY-RITA", "ANY-ACTIVE-ALIVE-PAIR", "ALIVE-P"],
    ],
  ];
  const runButtons = storyPane.locator("button.inspector-action[title='Run example']");
  await expect(runButtons).toHaveCount(expectedResults.length);

  const results = [];
  for (let index = 0; index < expectedResults.length; index += 1) {
    const [name, expectedResult, fragments] = expectedResults[index];
    const button = runButtons.nth(index);
    await button.scrollIntoViewIfNeeded();
    await button.click();

    await expect
      .poll(async () => {
        const state = await readLastPaneState(page);
        return resultStateMatches(state, expectedResult, fragments);
      }, { timeout: 30_000 })
      .toBe(true);

    results.push({
      name,
      expectedResult,
      finalState: await readLastPaneState(page),
    });
  }

  const errors = browserErrors.read();
  browserErrors.dispose();
  await testInfo.attach("nor-graph-matcher-demo-example-results.json", {
    body: JSON.stringify({ results, errors }, null, 2),
    contentType: "application/json",
  });
  expect(errors).toEqual([]);
});
