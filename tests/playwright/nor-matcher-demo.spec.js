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

test("NOR matcher teaching story source blocks resolve and examples run", async ({
  page,
}, testInfo) => {
  const browserErrors = installBrowserErrorTrace(page);
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, "NOR Matcher Teaching Story");
  await settleInspectorBindings(page, 1000);

  const storyPane = page.locator(".inspector-pane").nth(2);
  const sourceNames = [
    "nor-demo-empty-success",
    "nor-demo-simple-success",
    "nor-demo-simple-failure",
    "nor-demo-make-matcher",
    "nor-demo-original-query-positive",
    "nor-demo-original-query-negative",
  ];

  for (const name of sourceNames) {
    await expect(storyPane).toContainText(name);
  }
  await expect(storyPane).not.toContainText(/undefined function|lookup issue/i);

  const expectedResults = [
    ["nor-demo-empty-success", "T", ["Any target string."]],
    ["nor-demo-simple-success", "T", ["The moon landing was a triumph."]],
    [
      "nor-demo-simple-failure",
      "NIL",
      ["The shuttle program is a joke, though."],
    ],
    [
      "nor-demo-original-query-positive",
      "T",
      ["triumph of technology."],
    ],
    [
      "nor-demo-original-query-negative",
      "NIL",
      ["space", "landing", "The shuttle program is a joke, though."],
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
  await testInfo.attach("nor-matcher-demo-example-results.json", {
    body: JSON.stringify({ results, errors }, null, 2),
    contentType: "application/json",
  });
  expect(errors).toEqual([]);
});
