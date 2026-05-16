"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  openHyperDoc,
  openTextPageFromHyperDoc,
  readInspectorPaneState,
  readPaneTitles,
  waitForPaneBodyText,
} = require("./hyperdoc-inspector");
const { paneChrome } = require("./pane-chrome-harness");

test.describe.configure({ mode: "serial" });

async function matchingPaneTitles(page, pattern) {
  return page.evaluate(({ source, flags }) => {
    const matcher = new RegExp(source, flags);
    return Array.from(document.querySelectorAll(".inspector-pane"))
      .map((paneNode, index) => {
        const titleNode =
          paneNode.querySelector(".inspector-title-bar-object") ||
          paneNode.querySelector(".inspector-title-bar-class");
        return {
          index,
          title: titleNode?.textContent?.trim() || null,
        };
      })
      .filter((entry) => entry.title && matcher.test(entry.title));
  }, { source: pattern.source, flags: pattern.flags });
}

async function waitForMatchingPane(page, pattern) {
  await expect
    .poll(async () => (await matchingPaneTitles(page, pattern)).length, {
      timeout: 20_000,
    })
    .toBeGreaterThan(0);
  return matchingPaneTitles(page, pattern);
}

async function waitForPaneCount(page, expectedCount) {
  await expect
    .poll(async () => page.locator(".inspector-pane").count(), {
      timeout: 20_000,
    })
    .toBe(expectedCount);
  return expectedCount;
}

test("Repeated Shift-click Connect reuses the runtime snapshot pane and preserves trailing panes", async ({
  page,
}, testInfo) => {
  const linkedPageTitle = "Creating a HyperDoc";
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, linkedPageTitle);
  await activatePaneTab(page, 1, "Main page");

  const chrome = paneChrome(page, 1);
  const paneCountBefore = await page.locator(".inspector-pane").count();

  await chrome.connectToggle.click({ modifiers: ["Shift"] });

  const runtimePanes = await waitForMatchingPane(page, /^Connect session/);
  const paneCountAfterFirstShift = await waitForPaneCount(page, paneCountBefore + 1);
  const runtimePane = await readInspectorPaneState(page, runtimePanes[0].index);
  const titlesAfterFirstShift = await readPaneTitles(page);

  await chrome.connectToggle.click({ modifiers: ["Shift"] });

  const paneCountAfterSecondShift = await waitForPaneCount(
    page,
    paneCountAfterFirstShift
  );
  await expect
    .poll(async () => (await matchingPaneTitles(page, /^Connect session/)).length, {
      timeout: 20_000,
    })
    .toBe(1);
  const titlesAfterSecondShift = await readPaneTitles(page);

  await attachJson(testInfo, "connect-shift-runtime-pane.json", runtimePane);
  await attachJson(testInfo, "connect-shift-titles-first.json", titlesAfterFirstShift);
  await attachJson(testInfo, "connect-shift-titles-second.json", titlesAfterSecondShift);

  expect(paneCountAfterFirstShift).toBe(paneCountBefore + 1);
  expect(runtimePane.title).toMatch(/^Connect session/);
  expect(runtimePane.bodyText).toContain("Snapshot of Connect phase idle");
  expect(
    titlesAfterFirstShift.some((entry) => entry.title === linkedPageTitle)
  ).toBe(true);
  expect(paneCountAfterSecondShift).toBe(paneCountAfterFirstShift);
  expect(
    titlesAfterSecondShift.some((entry) => entry.title === linkedPageTitle)
  ).toBe(true);
});

test("Option/Alt-click Connect opens the model side, closes trailing panes, and stays single-pane on repeat", async ({
  page,
}, testInfo) => {
  const linkedPageTitle = "Creating a HyperDoc";
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, linkedPageTitle);
  await activatePaneTab(page, 1, "Main page");

  const chrome = paneChrome(page, 1);
  const paneCountBefore = await page.locator(".inspector-pane").count();

  await chrome.connectToggle.click({ modifiers: ["Alt"] });

  const modelPanes = await waitForMatchingPane(
    page,
    /^Normal association submit path vs evidence path$/
  );
  const modelPane = await waitForPaneBodyText(
    page,
    modelPanes[0].index,
    "Operational comparison of the standard association submit path and the request-evidence path"
  );
  const paneCountAfterFirstAlt = await waitForPaneCount(page, paneCountBefore);
  const titlesAfterFirstAlt = await readPaneTitles(page);

  await chrome.connectToggle.click({ modifiers: ["Alt"] });

  const paneCountAfterSecondAlt = await waitForPaneCount(page, paneCountAfterFirstAlt);
  await expect
    .poll(
      async () =>
        (
          await matchingPaneTitles(
            page,
            /^Normal association submit path vs evidence path$/
          )
        ).length,
      {
        timeout: 20_000,
      }
    )
    .toBe(1);
  const titlesAfterSecondAlt = await readPaneTitles(page);

  await attachJson(testInfo, "connect-alt-model-pane.json", modelPane);
  await attachJson(testInfo, "connect-alt-model-titles-first.json", titlesAfterFirstAlt);
  await attachJson(
    testInfo,
    "connect-alt-model-titles-second.json",
    titlesAfterSecondAlt
  );

  expect(modelPane.activeTab).toBe("Comparison");
  expect(modelPane.bodyText).toContain(
    "Operational comparison of the standard association submit path and the request-evidence path"
  );
  expect(titlesAfterFirstAlt.some((entry) => entry.title === linkedPageTitle)).toBe(false);
  expect(paneCountAfterSecondAlt).toBe(paneCountAfterFirstAlt);
});

test("Repeated Shift+Option/Alt-click Connect reuses the model side and preserves trailing panes", async ({
  page,
}, testInfo) => {
  const linkedPageTitle = "Creating a HyperDoc";
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, linkedPageTitle);
  await activatePaneTab(page, 1, "Main page");

  const chrome = paneChrome(page, 1);
  const paneCountBefore = await page.locator(".inspector-pane").count();

  await chrome.connectToggle.click({ modifiers: ["Shift", "Alt"] });

  const modelPanes = await waitForMatchingPane(
    page,
    /^Normal association submit path vs evidence path$/
  );
  const modelPane = await waitForPaneBodyText(
    page,
    modelPanes[0].index,
    "Operational comparison of the standard association submit path and the request-evidence path"
  );
  const paneCountAfterFirstShiftAlt = await waitForPaneCount(page, paneCountBefore + 1);
  const titlesAfterFirstShiftAlt = await readPaneTitles(page);

  await chrome.connectToggle.click({ modifiers: ["Shift", "Alt"] });

  const paneCountAfterSecondShiftAlt = await waitForPaneCount(
    page,
    paneCountAfterFirstShiftAlt
  );
  await expect
    .poll(
      async () =>
        (
          await matchingPaneTitles(
            page,
            /^Normal association submit path vs evidence path$/
          )
        ).length,
      {
        timeout: 20_000,
      }
    )
    .toBe(1);
  const titlesAfterSecondShiftAlt = await readPaneTitles(page);

  await attachJson(testInfo, "connect-shift-alt-model-pane.json", modelPane);
  await attachJson(
    testInfo,
    "connect-shift-alt-model-titles-first.json",
    titlesAfterFirstShiftAlt
  );
  await attachJson(
    testInfo,
    "connect-shift-alt-model-titles-second.json",
    titlesAfterSecondShiftAlt
  );

  expect(paneCountAfterFirstShiftAlt).toBe(paneCountBefore + 1);
  expect(modelPane.activeTab).toBe("Comparison");
  expect(
    titlesAfterFirstShiftAlt.some((entry) => entry.title === linkedPageTitle)
  ).toBe(true);
  expect(paneCountAfterSecondShiftAlt).toBe(paneCountAfterFirstShiftAlt);
  expect(
    titlesAfterSecondShiftAlt.some((entry) => entry.title === linkedPageTitle)
  ).toBe(true);
});

test("Annotation modifier-clicks reuse the semantic pane and expose the claim/evidence side", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);

  const chrome = paneChrome(page, 1);
  const paneCountBefore = await page.locator(".inspector-pane").count();

  await chrome.annotationButton.click();

  const semanticPanes = await waitForMatchingPane(page, /^Annotation:/);
  const semanticPane = await waitForPaneBodyText(
    page,
    semanticPanes[0].index,
    "Annotation topic"
  );
  const paneCountAfterPlainClick = await waitForPaneCount(page, paneCountBefore + 1);

  await chrome.annotationButton.click({ modifiers: ["Shift"] });

  const paneCountAfterShiftClick = await waitForPaneCount(page, paneCountAfterPlainClick);
  const semanticPaneCountAfterShift = (await matchingPaneTitles(
    page,
    /^Annotation:/
  )).length;

  await chrome.annotationButton.click({ modifiers: ["Alt"] });

  const evidencePanes = await waitForMatchingPane(
    page,
    /^Annotation capability stays a semantic relation$/
  );
  const evidencePane = await waitForPaneBodyText(
    page,
    evidencePanes[0].index,
    "Modifier-click inspection on Annotation opens either the existing semantic relation or the supporting claim/evidence side"
  );
  const titlesAfterAltClick = await readPaneTitles(page);

  await attachJson(testInfo, "annotation-semantic-pane.json", semanticPane);
  await attachJson(testInfo, "annotation-evidence-pane.json", evidencePane);
  await attachJson(testInfo, "annotation-titles-after-alt.json", titlesAfterAltClick);

  expect(paneCountAfterPlainClick).toBe(paneCountBefore + 1);
  expect(semanticPane.bodyText).toContain("Annotation topic");
  expect(paneCountAfterShiftClick).toBe(paneCountAfterPlainClick);
  expect(semanticPaneCountAfterShift).toBe(1);
  expect(evidencePane.bodyText).toContain(
    "Modifier-click inspection on Annotation opens either the existing semantic relation or the supporting claim/evidence side"
  );
  expect(
    titlesAfterAltClick.some((entry) => /^Annotation:/.test(entry.title || ""))
  ).toBe(false);
});

test("Repeated Shift-click Annotation with no semantic relation reuses the generic fallback pane", async ({
  page,
}, testInfo) => {
  const linkedPageTitle = "Creating a HyperDoc";
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, linkedPageTitle);
  await activatePaneTab(page, 2, "Content");

  const chrome = paneChrome(page, 2);
  const paneCountBefore = await page.locator(".inspector-pane").count();

  await chrome.annotationButton.click({ modifiers: ["Shift"] });

  const paneCountAfterFirstShift = await waitForPaneCount(page, paneCountBefore + 1);
  const fallbackPane = await waitForPaneBodyText(
    page,
    paneCountAfterFirstShift - 1,
    "Generic route target/topic-object that classifies annotation relations"
  );
  const titlesAfterFirstShift = await readPaneTitles(page);
  const fallbackTitle = fallbackPane.title;

  await chrome.annotationButton.click({ modifiers: ["Shift"] });

  const paneCountAfterSecondShift = await waitForPaneCount(
    page,
    paneCountAfterFirstShift
  );
  await expect
    .poll(
      async () =>
        (await readPaneTitles(page)).filter((entry) => entry.title === fallbackTitle).length,
      { timeout: 20_000 }
    )
    .toBe(1);
  const titlesAfterSecondShift = await readPaneTitles(page);

  await attachJson(testInfo, "annotation-fallback-pane.json", fallbackPane);
  await attachJson(
    testInfo,
    "annotation-fallback-titles-first.json",
    titlesAfterFirstShift
  );
  await attachJson(
    testInfo,
    "annotation-fallback-titles-second.json",
    titlesAfterSecondShift
  );

  expect(paneCountAfterFirstShift).toBe(paneCountBefore + 1);
  expect(fallbackPane.bodyText).toContain(
    "Generic route target/topic-object that classifies annotation relations"
  );
  expect(paneCountAfterSecondShift).toBe(paneCountAfterFirstShift);
});

test("Repeated Shift-click Guide reuses the Dock model pane and preserves trailing panes", async ({
  page,
}, testInfo) => {
  const linkedPageTitle = "Creating a HyperDoc";
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, linkedPageTitle);
  await activatePaneTab(page, 1, "Main page");

  const chrome = paneChrome(page, 1);
  const paneCountBefore = await page.locator(".inspector-pane").count();

  await chrome.helpToggle.click({ modifiers: ["Shift"] });

  const modelPanes = await waitForMatchingPane(page, /^Dock presentation model$/);
  const modelPane = await waitForPaneBodyText(
    page,
    modelPanes[0].index,
    "desktop coachmark behavior composed with mobile capabilities and inspector-tabs progressive-enhancement layers"
  );
  const paneCountAfterFirstShift = await waitForPaneCount(page, paneCountBefore + 1);
  const titlesAfterFirstShift = await readPaneTitles(page);

  await chrome.helpToggle.click({ modifiers: ["Shift"] });

  const paneCountAfterSecondShift = await waitForPaneCount(
    page,
    paneCountAfterFirstShift
  );
  await expect
    .poll(async () => (await matchingPaneTitles(page, /^Dock presentation model$/)).length, {
      timeout: 20_000,
    })
    .toBe(1);
  const titlesAfterSecondShift = await readPaneTitles(page);

  await attachJson(testInfo, "guide-model-pane.json", modelPane);
  await attachJson(testInfo, "guide-titles-after-shift.json", titlesAfterFirstShift);
  await attachJson(
    testInfo,
    "guide-titles-after-second-shift.json",
    titlesAfterSecondShift
  );

  expect(paneCountAfterFirstShift).toBe(paneCountBefore + 1);
  expect(modelPane.bodyText).toContain(
    "desktop coachmark behavior composed with mobile capabilities and inspector-tabs progressive-enhancement layers"
  );
  expect(
    titlesAfterFirstShift.some((entry) => entry.title === linkedPageTitle)
  ).toBe(true);
  expect(paneCountAfterSecondShift).toBe(paneCountAfterFirstShift);
  expect(
    titlesAfterSecondShift.some((entry) => entry.title === linkedPageTitle)
  ).toBe(true);
});

test("Repeated Shift+Option/Alt-click Guide reuses the claim/evidence pane and preserves trailing panes", async ({
  page,
}, testInfo) => {
  const linkedPageTitle = "Creating a HyperDoc";
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, linkedPageTitle);
  await activatePaneTab(page, 1, "Main page");

  const chrome = paneChrome(page, 1);
  const paneCountBefore = await page.locator(".inspector-pane").count();

  await chrome.helpToggle.click({ modifiers: ["Shift", "Alt"] });

  const evidencePanes = await waitForMatchingPane(
    page,
    /^Dock presentation state is inspectable$/
  );
  const evidencePane = await waitForPaneBodyText(
    page,
    evidencePanes[0].index,
    "The current pane snapshot and the durable Dock model make the runtime presentation state and its implementation evidence inspectable"
  );
  const paneCountAfterFirstShiftAlt = await waitForPaneCount(page, paneCountBefore + 1);
  const titlesAfterFirstShiftAlt = await readPaneTitles(page);

  await chrome.helpToggle.click({ modifiers: ["Shift", "Alt"] });

  const paneCountAfterSecondShiftAlt = await waitForPaneCount(
    page,
    paneCountAfterFirstShiftAlt
  );
  await expect
    .poll(
      async () =>
        (await matchingPaneTitles(page, /^Dock presentation state is inspectable$/)).length,
      {
        timeout: 20_000,
      }
    )
    .toBe(1);
  const titlesAfterSecondShiftAlt = await readPaneTitles(page);

  await attachJson(testInfo, "guide-evidence-pane.json", evidencePane);
  await attachJson(
    testInfo,
    "guide-titles-after-shift-alt.json",
    titlesAfterFirstShiftAlt
  );
  await attachJson(
    testInfo,
    "guide-titles-after-second-shift-alt.json",
    titlesAfterSecondShiftAlt
  );

  expect(paneCountAfterFirstShiftAlt).toBe(paneCountBefore + 1);
  expect(evidencePane.bodyText).toContain(
    "The current pane snapshot and the durable Dock model make the runtime presentation state and its implementation evidence inspectable"
  );
  expect(
    titlesAfterFirstShiftAlt.some((entry) => entry.title === linkedPageTitle)
  ).toBe(true);
  expect(paneCountAfterSecondShiftAlt).toBe(paneCountAfterFirstShiftAlt);
  expect(
    titlesAfterSecondShiftAlt.some((entry) => entry.title === linkedPageTitle)
  ).toBe(true);
});
