"use strict";

const { test, expect } = require("@playwright/test");
const {
  attachJson,
  bootUrl,
  exactTextPattern,
  gotoCatalog,
  pane,
  readPaneTitles,
  settleInspectorBindings,
} = require("./hyperdoc-inspector");

test.describe.configure({ mode: "serial" });

function bibliographyRoute(pageId) {
  return new URL(`/3DF54-bibliography/${pageId}`, bootUrl()).toString();
}

async function attachSoftFailureState(testInfo, name, page, paneOpenMs) {
  await attachJson(testInfo, name, {
    currentUrl: page.url(),
    disconnectedBannerCount: await page.locator("#clog-disconnected-banner").count(),
    paneOpenMs,
    paneTitles: await readPaneTitles(page),
  });
}

test.describe("bibliography hyperbook soft failure", () => {
  test("direct /3DF54-bibliography/coachmark fails soft when Zotero DB is missing", async ({
    page,
  }, testInfo) => {
    const startedAt = Date.now();

    await page.goto(bibliographyRoute("coachmark"), {
      waitUntil: "domcontentloaded",
      timeout: 30_000,
    });
    await expect(page.locator("body")).not.toContainText("502 Bad Gateway", {
      timeout: 20_000,
    });

    const failurePane = page.locator(".inspector-pane").first();
    await expect(failurePane).toBeVisible({ timeout: 60_000 });
    await expect(failurePane).toContainText("Requested collection", {
      timeout: 60_000,
    });
    await expect(failurePane).toContainText("coachmark", { timeout: 60_000 });
    await expect(failurePane).toContainText("Zotero database not found", {
      timeout: 60_000,
    });
    await expect(page.locator("#clog-disconnected-banner")).toHaveCount(0);

    await settleInspectorBindings(page);
    await attachSoftFailureState(
      testInfo,
      "bibliography-direct-route-soft-failure.json",
      page,
      Date.now() - startedAt
    );
  });

  test("catalog Bibliography fails soft when Zotero DB is missing", async ({ page }, testInfo) => {
    await gotoCatalog(page);

    const startedAt = Date.now();
    const catalogPane = pane(page, 0);
    await expect(
      catalogPane.locator("td").filter({ hasText: exactTextPattern("Bibliography") }).first()
    ).toBeVisible({ timeout: 20_000 });
    await catalogPane
      .locator("td")
      .filter({ hasText: exactTextPattern("Bibliography") })
      .first()
      .click();

    await expect
      .poll(() => page.locator(".inspector-pane").count(), { timeout: 30_000 })
      .toBe(2);

    const bibliographyPane = pane(page, 1);
    await expect(bibliographyPane).toBeVisible({ timeout: 60_000 });
    await expect(
      bibliographyPane
        .locator(".inspector-title-bar-object, .inspector-title-bar-class")
        .filter({ hasText: exactTextPattern("Bibliography") })
        .first()
    ).toBeVisible({ timeout: 60_000 });
    await expect(bibliographyPane).toContainText("Requested collection", {
      timeout: 60_000,
    });
    await expect(bibliographyPane).toContainText("coachmark", {
      timeout: 60_000,
    });
    await expect(bibliographyPane).toContainText("Zotero database not found", {
      timeout: 60_000,
    });
    await expect(page.locator("#clog-disconnected-banner")).toHaveCount(0);

    await settleInspectorBindings(page);
    await attachSoftFailureState(
      testInfo,
      "bibliography-catalog-soft-failure.json",
      page,
      Date.now() - startedAt
    );
  });
});
