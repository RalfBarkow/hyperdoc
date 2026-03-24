"use strict";

const { test, expect } = require("@playwright/test");

const { attachJson, gotoCatalog, pane } = require("./hyperdoc-inspector");

test.describe("catalog layout", () => {
  test("catalog keeps its left gutter visible at a narrow viewport", async ({ page }, testInfo) => {
    await page.setViewportSize({ width: 240, height: 900 });
    await gotoCatalog(page);

    const catalogPane = pane(page, 0);

    await page.waitForFunction(() => {
      const rows = Array.from(document.querySelectorAll(".inspector-pane tr"));
      return rows.length >= 1;
    });

    const metrics = await page.evaluate(() => {
      const inspector = document.querySelector(".inspector");
      const currentPane = document.querySelector(".inspector-pane");
      const titleNode =
        currentPane?.querySelector(".inspector-title-bar-object") ||
        currentPane?.querySelector(".inspector-title");
      const rows = Array.from(currentPane?.querySelectorAll("tr") || []).map((row) => {
        const cells = Array.from(row.querySelectorAll("td"));
        const indexCell = cells[0] || null;
        const labelCell = cells[1] || null;
        return {
          indexText: indexCell?.textContent?.trim() || null,
          labelText: labelCell?.textContent?.trim() || null,
          indexLeft: indexCell?.getBoundingClientRect().left ?? null,
          indexRight: indexCell?.getBoundingClientRect().right ?? null,
        };
      });
      const itemCountLabel = Array.from(currentPane?.querySelectorAll(".inspector-index") || [])
        .map((node) => node.textContent.trim())
        .find((text) => /item\(s\)$/.test(text));
      const paneRect = currentPane?.getBoundingClientRect() || null;
      const titleRect = titleNode?.getBoundingClientRect() || null;
      return {
        inspectorScrollLeft: inspector?.scrollLeft ?? null,
        inspectorClientWidth: inspector?.clientWidth ?? null,
        inspectorScrollWidth: inspector?.scrollWidth ?? null,
        paneRect,
        titleRect,
        titleText: titleNode?.textContent?.trim() || null,
        itemCountLabel,
        rows: rows.slice(0, 12),
      };
    });

    await attachJson(testInfo, "catalog-layout-metrics.json", metrics);
    await testInfo.attach("catalog-layout-pane.png", {
      body: await catalogPane.screenshot(),
      contentType: "image/png",
    });

    const expectedItemCountLabel = `${metrics.rows.length} item(s)`;

    expect(metrics.inspectorScrollLeft).toBe(0);
    expect(metrics.titleRect.left).toBeGreaterThanOrEqual(metrics.paneRect.left);
    expect(metrics.rows[0].indexText).toBe("0");
    expect(metrics.rows[0].indexLeft).toBeGreaterThanOrEqual(metrics.paneRect.left);
    expect(metrics.itemCountLabel).toBe(expectedItemCountLabel);
    expect(metrics.rows.at(-1).indexText).toBe(String(metrics.rows.length - 1));
    expect(metrics.rows.at(-1).indexLeft).toBeGreaterThanOrEqual(metrics.paneRect.left);
    if (metrics.rows.length > 10) {
      expect(metrics.rows[10].indexText).toBe("10");
      expect(metrics.rows[10].indexLeft).toBeGreaterThanOrEqual(metrics.paneRect.left);
    }
  });
});
