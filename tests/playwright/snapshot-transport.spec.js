"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  openHyperDoc,
  openTextPageFromHyperDoc,
  readInspectorPaneState,
  waitForPaneBodyText,
  waitForPaneLoadingBoundary,
} = require("./hyperdoc-inspector");

test.describe.configure({ mode: "serial" });

async function openTextPageContent(page, title, expectedText, testInfo, attachmentPrefix) {
  const textPagePane = await openTextPageFromHyperDoc(page, title);
  const immediateState = await readInspectorPaneState(page, 2);
  await attachJson(testInfo, `${attachmentPrefix}-immediate.json`, immediateState);

  expect(immediateState.title).toBe(title);
  expect(immediateState.activeTab).toBe("Content");
  expect(immediateState.tabNames).toEqual(
    expect.arrayContaining(["Content", "Source", "Links", "Parse tree"])
  );
  expect(["loading", "ready"]).toContain(immediateState.renderState);
  if (immediateState.renderState === "loading") {
    expect(immediateState.loadingVisible).toBe(true);
    expect(immediateState.loadingMessage).toContain("Loading content");
  } else {
    expect(immediateState.loadingVisible).toBe(false);
    expect(immediateState.bodyText).not.toBe("");
  }

  await waitForPaneBodyText(page, 2, expectedText);
  const contentState = await waitForPaneLoadingBoundary(page, 2);
  await attachJson(testInfo, `${attachmentPrefix}-content.json`, contentState);
  expect(contentState.loadingVisible).toBe(false);
  expect(contentState.bodyText).toContain(expectedText);

  await activatePaneTab(page, 2, "Source");
  const sourceState = await readInspectorPaneState(page, 2);
  await attachJson(testInfo, `${attachmentPrefix}-source.json`, sourceState);

  expect(sourceState.bodyText).toContain("<h1>");
  return { textPagePane, immediateState, contentState, sourceState };
}

test("Snapshot transport page opens with rendered authored content", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  const { contentState, sourceState } = await openTextPageContent(
    page,
    "Snapshot transport",
    "Snapshot transport is the submit-boundary carrier seam",
    testInfo,
    "snapshot-transport"
  );

  expect(contentState.bodyText).toContain("data-dom-connect-snapshot-json");
  expect(contentState.bodyText).toContain("Normal association submit path vs evidence path");
  expect(sourceState.bodyText).toContain("(dom-connect-snapshot-transport)");
});

test("Normal association submit path vs evidence path eventually renders in Content", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  const { contentState, sourceState } = await openTextPageContent(
    page,
    "Normal association submit path vs evidence path",
    "This page makes the submit-boundary asymmetry explicit",
    testInfo,
    "submit-path-comparison"
  );

  expect(contentState.bodyText).toContain("writeSubmitPayload()");
  expect(contentState.bodyText).toContain("prepareEvidenceButton()");
  expect(contentState.bodyText).toContain("Snapshot transport");
  expect(sourceState.bodyText).toContain("<source-of-function>");
});
