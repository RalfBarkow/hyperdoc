"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  exactTextPattern,
  openHyperDoc,
  openTopicPageFromHyperDoc,
  pane,
  readInspectorPaneState,
} = require("./hyperdoc-inspector");

test.describe.configure({ mode: "serial" });

function runtimeAuthoringFixtureEnabled() {
  return process.env.HYPERDOC_RUN_TOUCH_FAHRPLAN_RUNTIME_TEST === "1";
}

async function clickAndOpenPane(page, clickAction) {
  const paneCountBefore = await page.locator(".inspector-pane").count();
  await clickAction();
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBe(paneCountBefore + 1);
  return paneCountBefore;
}

async function findPaneIndexByTitle(page, titlePattern) {
  const paneCount = await page.locator(".inspector-pane").count();
  for (let index = 0; index < paneCount; index += 1) {
    const titleLocator = pane(page, index).locator(
      ".inspector-title-bar-object, .inspector-title-bar-class"
    );
    if ((await titleLocator.count()) === 0) {
      continue;
    }
    const titleText = ((await titleLocator.first().textContent()) || "").trim();
    if (titlePattern.test(titleText)) {
      return index;
    }
  }
  return -1;
}

async function clickAndSurfacePaneTitle(page, clickAction, titlePattern) {
  await clickAction();
  await expect.poll(() => findPaneIndexByTitle(page, titlePattern), {
    timeout: 20_000,
  }).toBeGreaterThan(-1);
  return findPaneIndexByTitle(page, titlePattern);
}

async function waitForDurableRouteInTouchFahrplan(page, paneIndex) {
  await expect
    .poll(async () => (await readInspectorPaneState(page, paneIndex)).bodyText, {
      timeout: 20_000,
    })
    .toContain("Durable route definition Chunk -> Local Zotero library durable route definition");
  return readInspectorPaneState(page, paneIndex);
}

function expectSingleDurableRouteRow(tableRows) {
  expect(
    tableRows.filter((row) => row.includes("Route Chunk -> Local Zotero library"))
  ).toHaveLength(1);
}

function visiblePaneButtons(currentPane) {
  return currentPane.locator(".inspector-view:not([hidden]) button");
}

test("Touch-Fahrplan runtime durable route authoring survives reload", async ({
  page,
}, testInfo) => {
  test.skip(
    !runtimeAuthoringFixtureEnabled(),
    "Set HYPERDOC_RUN_TOUCH_FAHRPLAN_RUNTIME_TEST=1 and run against the controlled runtime-authoring fixture server."
  );

  await openHyperDoc(page);
  await openTopicPageFromHyperDoc(page, "Chunk");
  await activatePaneTab(page, 2, "Touch-Fahrplan");

  const touchFahrplanPane = pane(page, 2);
  const beforeCreation = await readInspectorPaneState(page, 2);
  await attachJson(testInfo, "touch-fahrplan-before-creation.json", beforeCreation);

  expect(beforeCreation.bodyText).toContain("Source palette");
  expect(beforeCreation.bodyText).toContain("Local Zotero library");
  const createDurableRouteButtons = touchFahrplanPane.locator("button").filter({
    hasText: exactTextPattern("Create durable route"),
  });
  const createButtonCount = await createDurableRouteButtons.count();
  expect(createButtonCount).toBeLessThanOrEqual(1);

  if (createButtonCount === 1) {
    await createDurableRouteButtons.first().click();
  }

  const afterCreation = await waitForDurableRouteInTouchFahrplan(page, 2);
  await attachJson(testInfo, "touch-fahrplan-after-creation.json", afterCreation);

  expect(afterCreation.bodyText).toContain("Durable Touch-Fahrplan routes");
  expectSingleDurableRouteRow(afterCreation.tables[1] || []);
  await expect(
    touchFahrplanPane.locator("button").filter({
      hasText: exactTextPattern("Create durable route"),
    })
  ).toHaveCount(0);

  const routePaneIndex = await clickAndSurfacePaneTitle(
    page,
    async () => {
      await touchFahrplanPane
        .locator(".inspector-view:not([hidden]) .inspector-inspect")
        .filter({ hasText: exactTextPattern("Route Chunk -> Local Zotero library") })
        .first()
        .click();
    },
    /topic-source-route/
  );

  const routePane = pane(page, routePaneIndex);
  await expect(
    routePane.locator(".inspector-title-bar-class").filter({
      hasText: exactTextPattern("topic-source-route"),
    })
  ).toBeVisible({ timeout: 20_000 });
  const routeState = await readInspectorPaneState(page, routePaneIndex);
  await attachJson(testInfo, "touch-fahrplan-route.json", routeState);

  expect(routeState.bodyText).toContain("Route definition");
  expect(routeState.bodyText).toContain("Connect relation");

  const planPaneIndex = await clickAndSurfacePaneTitle(
    page,
    async () => {
      await routePane
        .locator("button")
        .filter({ hasText: exactTextPattern("Open exact plan") })
        .first()
        .click();
    },
    /topic-enrichment-query-plan/
  );

  const planPane = pane(page, planPaneIndex);
  await expect(
    planPane.locator(".inspector-title-bar-class").filter({
      hasText: exactTextPattern("topic-enrichment-query-plan"),
    })
  ).toBeVisible({ timeout: 20_000 });
  const planState = await readInspectorPaneState(page, planPaneIndex);
  await attachJson(testInfo, "touch-fahrplan-plan.json", planState);

  expect(planState.bodyText).toContain("Execution readiness");
  expect(planState.bodyText).toContain("Local Zotero library");
  expect(planState.bodyText).toContain("Chunk");

  const reportPaneIndex = await clickAndSurfacePaneTitle(
    page,
    async () => {
      await planPane
        .locator("button")
        .filter({ hasText: exactTextPattern("Run plan") })
        .first()
        .click();
    },
    /topic-enrichment-report/
  );

  const reportPane = pane(page, reportPaneIndex);
  await expect(
    reportPane.locator(".inspector-title-bar-class").filter({
      hasText: exactTextPattern("topic-enrichment-report"),
    })
  ).toBeVisible({ timeout: 20_000 });
  const reportOverviewState = await readInspectorPaneState(page, reportPaneIndex);
  await attachJson(testInfo, "touch-fahrplan-report-overview.json", reportOverviewState);

  expect(reportOverviewState.bodyText).toContain("Matched items");
  expect(reportOverviewState.bodyText).toContain("Candidate signals");
  expect(reportOverviewState.bodyText).toContain("Editorial consequences");

  await activatePaneTab(page, reportPaneIndex, "Matches");
  const reportMatchesState = await readInspectorPaneState(page, reportPaneIndex);
  await attachJson(testInfo, "touch-fahrplan-report-matches.json", reportMatchesState);

  expect(reportMatchesState.bodyText).toContain("Citation key");
  expect(reportMatchesState.bodyText).toContain("Chunk");
  expect(reportMatchesState.bodyText).toContain("10.5555/chunk.1977");

  await page.reload({ waitUntil: "domcontentloaded" });

  await openHyperDoc(page);
  await openTopicPageFromHyperDoc(page, "Chunk");
  await activatePaneTab(page, 2, "Touch-Fahrplan");

  const afterReload = await waitForDurableRouteInTouchFahrplan(page, 2);
  await attachJson(testInfo, "touch-fahrplan-after-reload.json", afterReload);

  expect(afterReload.bodyText).toContain("Durable Touch-Fahrplan routes");
  expect(afterReload.bodyText).toContain("Route Chunk -> Local Zotero library");
  expectSingleDurableRouteRow(afterReload.tables[1] || []);
  await expect(
    pane(page, 2).locator("button").filter({
      hasText: exactTextPattern("Create durable route"),
    })
  ).toHaveCount(0);

  const reopenedRoutePaneIndex = await clickAndSurfacePaneTitle(
    page,
    async () => {
      await pane(page, 2)
        .locator(".inspector-view:not([hidden]) .inspector-inspect")
        .filter({ hasText: exactTextPattern("Route Chunk -> Local Zotero library") })
        .first()
        .click();
    },
    /topic-source-route/
  );

  const reopenedRouteState = await readInspectorPaneState(page, reopenedRoutePaneIndex);
  await attachJson(testInfo, "touch-fahrplan-reopened-route.json", reopenedRouteState);

  expect(reopenedRouteState.bodyText).toContain("Route definition");
  expect(reopenedRouteState.bodyText).toContain("Connect relation");
});
