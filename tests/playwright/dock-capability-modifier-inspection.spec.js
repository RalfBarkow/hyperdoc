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

test("Shift-click Connect opens a reusable runtime snapshot pane and preserves trailing panes", async ({
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
  const paneCountAfterFirstShift = await page.locator(".inspector-pane").count();
  const runtimePane = await readInspectorPaneState(page, runtimePanes[0].index);
  const titlesAfterFirstShift = await readPaneTitles(page);

  await chrome.connectToggle.click({ modifiers: ["Shift"] });

  const paneCountAfterSecondShift = await page.locator(".inspector-pane").count();
  const runtimePaneCountAfterSecondShift = (await matchingPaneTitles(
    page,
    /^Connect session/
  )).length;
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
  expect(runtimePaneCountAfterSecondShift).toBe(1);
});

test("Option/Alt-click Connect opens the model side and closes trailing panes", async ({
  page,
}, testInfo) => {
  const linkedPageTitle = "Creating a HyperDoc";
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, linkedPageTitle);
  await activatePaneTab(page, 1, "Main page");

  const chrome = paneChrome(page, 1);
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
  const titles = await readPaneTitles(page);

  await attachJson(testInfo, "connect-alt-model-pane.json", modelPane);
  await attachJson(testInfo, "connect-alt-model-titles.json", titles);

  expect(modelPane.activeTab).toBe("Comparison");
  expect(modelPane.bodyText).toContain(
    "Operational comparison of the standard association submit path and the request-evidence path"
  );
  expect(titles.some((entry) => entry.title === linkedPageTitle)).toBe(false);
});

test("Shift+Option/Alt-click Connect opens the model side and preserves trailing panes", async ({
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
  const paneCountAfter = await page.locator(".inspector-pane").count();
  const titles = await readPaneTitles(page);

  await attachJson(testInfo, "connect-shift-alt-model-pane.json", modelPane);
  await attachJson(testInfo, "connect-shift-alt-model-titles.json", titles);

  expect(paneCountAfter).toBe(paneCountBefore + 1);
  expect(modelPane.activeTab).toBe("Comparison");
  expect(titles.some((entry) => entry.title === linkedPageTitle)).toBe(true);
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
  const paneCountAfterPlainClick = await page.locator(".inspector-pane").count();

  await chrome.annotationButton.click({ modifiers: ["Shift"] });

  const paneCountAfterShiftClick = await page.locator(".inspector-pane").count();
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

test("Guide modifier-clicks open the Dock model and its claim/evidence side", async ({
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
    "Inspectable state model for the Dock as a progressive enhancement over inspector tabs"
  );
  const paneCountAfterShift = await page.locator(".inspector-pane").count();
  const titlesAfterShift = await readPaneTitles(page);

  await chrome.helpToggle.click({ modifiers: ["Alt"] });

  const evidencePanes = await waitForMatchingPane(
    page,
    /^Dock presentation state is inspectable$/
  );
  const evidencePane = await waitForPaneBodyText(
    page,
    evidencePanes[0].index,
    "The current pane snapshot and the durable Dock model make the runtime presentation state and its implementation evidence inspectable"
  );
  const titlesAfterAlt = await readPaneTitles(page);

  await attachJson(testInfo, "guide-model-pane.json", modelPane);
  await attachJson(testInfo, "guide-evidence-pane.json", evidencePane);
  await attachJson(testInfo, "guide-titles-after-shift.json", titlesAfterShift);
  await attachJson(testInfo, "guide-titles-after-alt.json", titlesAfterAlt);

  expect(paneCountAfterShift).toBe(paneCountBefore + 1);
  expect(modelPane.bodyText).toContain(
    "Inspectable state model for the Dock as a progressive enhancement over inspector tabs"
  );
  expect(
    titlesAfterShift.some((entry) => entry.title === linkedPageTitle)
  ).toBe(true);
  expect(evidencePane.bodyText).toContain(
    "The current pane snapshot and the durable Dock model make the runtime presentation state and its implementation evidence inspectable"
  );
  expect(titlesAfterAlt.some((entry) => entry.title === linkedPageTitle)).toBe(false);
});
