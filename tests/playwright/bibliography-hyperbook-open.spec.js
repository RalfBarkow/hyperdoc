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

function liveZoteroEnabled() {
  return process.env.HYPERDOC_RUN_ZOTERO_LIVE_TESTS === "1";
}

function bibliographyRoute(pageId) {
  return new URL(`/3DF54-bibliography/${pageId}`, bootUrl()).toString();
}

async function attachBibliographyOpenState(testInfo, name, page, paneOpenMs) {
  await attachJson(testInfo, name, {
    currentUrl: page.url(),
    disconnectedBannerCount: await page.locator("#clog-disconnected-banner").count(),
    paneOpenMs,
    paneTitles: await readPaneTitles(page),
  });
}

test.describe("live bibliography hyperbook opening", () => {
  test.skip(
    !liveZoteroEnabled(),
    "Set HYPERDOC_RUN_ZOTERO_LIVE_TESTS=1 to enable live bibliography opening tests."
  );

  test("direct /3DF54-bibliography/coachmark opens without disconnecting", async ({
    page,
  }, testInfo) => {
    const targetRoute = bibliographyRoute("coachmark");
    const startedAt = Date.now();

    await page.goto(targetRoute, { waitUntil: "domcontentloaded", timeout: 30_000 });
    await expect(page.locator("body")).not.toContainText("502 Bad Gateway", {
      timeout: 20_000,
    });

    const bibliographyPane = page.locator(".inspector-pane").first();
    await expect(bibliographyPane).toBeVisible({ timeout: 60_000 });
    await expect(
      bibliographyPane
        .locator(".inspector-title-bar-object, .inspector-title-bar-class")
        .filter({ hasText: /coachmark/ })
        .first()
    ).toBeVisible({ timeout: 60_000 });
    await expect(
      bibliographyPane.locator(".inspector-tabs button.active")
    ).toHaveText(exactTextPattern("Collection summary"), { timeout: 60_000 });
    await expect(bibliographyPane).toContainText("Requested collection", {
      timeout: 60_000,
    });
    await expect(bibliographyPane).toContainText("coachmark", {
      timeout: 60_000,
    });
    await expect(page.locator("#clog-disconnected-banner")).toHaveCount(0);

    await settleInspectorBindings(page);
    await attachBibliographyOpenState(
      testInfo,
      "bibliography-direct-route-open.json",
      page,
      Date.now() - startedAt
    );
  });

  test("catalog Bibliography opens without disconnecting", async ({ page }, testInfo) => {
    await gotoCatalog(page);

    const catalogPane = pane(page, 0);
    const startedAt = Date.now();
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
    await expect(bibliographyPane).toBeVisible({ timeout: 30_000 });
    await expect(
      bibliographyPane
        .locator(".inspector-title-bar-object, .inspector-title-bar-class")
        .filter({ hasText: exactTextPattern("Bibliography") })
        .first()
    ).toBeVisible({ timeout: 30_000 });
    await expect(
      bibliographyPane.locator(".inspector-tabs button.active")
    ).toHaveText(exactTextPattern("URL"), { timeout: 30_000 });
    await expect(page.locator("#clog-disconnected-banner")).toHaveCount(0);

    await settleInspectorBindings(page);
    await attachBibliographyOpenState(
      testInfo,
      "bibliography-catalog-open.json",
      page,
      Date.now() - startedAt
    );
  });
});
