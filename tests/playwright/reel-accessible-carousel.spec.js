"use strict";

const fs = require("fs");
const path = require("path");
const { test, expect } = require("@playwright/test");
const { openHyperDoc, settleInspectorBindings } = require("./hyperdoc-inspector");

const reelScriptPath = path.join(
  __dirname,
  "..",
  "..",
  "assets",
  "hyperdoc",
  "js",
  "hyperdoc-reel.js"
);
const reelCssPath = path.join(
  __dirname,
  "..",
  "..",
  "assets",
  "hyperdoc",
  "css",
  "hyperdoc-reel.css"
);

test("multi-pane inspector renders as an accessible Reel adapter", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page);
  await settleInspectorBindings(page, 1000);

  await expect(page.locator(".hyperdoc-reel")).toHaveAttribute(
    "data-hyperdoc-reel-enhanced",
    "true"
  );
  await expect(page.locator(".hyperdoc-reel__buttons")).toBeVisible();

  const state = await page.evaluate(() => {
    const reel = document.querySelector(".hyperdoc-reel");
    const scrollable = reel?.querySelector(".hyperdoc-reel__scrollable");
    const items = Array.from(
      scrollable?.querySelectorAll(".hyperdoc-reel__item") || []
    );
    const buttons = reel?.querySelector(".hyperdoc-reel__buttons");
    const prev = reel?.querySelector(".hyperdoc-reel__prev");
    const next = reel?.querySelector(".hyperdoc-reel__next");

    return {
      reelPresent: !!reel,
      enhanced: reel?.dataset.hyperdocReelEnhanced || null,
      scrollableRole: scrollable?.getAttribute("role") || null,
      scrollableTabindex: scrollable?.getAttribute("tabindex") || null,
      overflowX: scrollable ? window.getComputedStyle(scrollable).overflowX : null,
      itemCount: items.length,
      itemRoles: items.map((item) => item.getAttribute("role")),
      buttonsHidden: !!buttons?.hidden,
      prevType: prev?.getAttribute("type") || null,
      nextType: next?.getAttribute("type") || null,
      scrollWidth: scrollable?.scrollWidth || 0,
      clientWidth: scrollable?.clientWidth || 0,
    };
  });

  await testInfo.attach("reel-live-state.json", {
    body: JSON.stringify(state, null, 2),
    contentType: "application/json",
  });

  expect(state.reelPresent).toBe(true);
  expect(state.enhanced).toBe("true");
  expect(state.scrollableRole).toBe("list");
  expect(state.scrollableTabindex).toBe("0");
  expect(state.overflowX).toBe("auto");
  expect(state.itemCount).toBeGreaterThan(1);
  expect(state.itemRoles.every((role) => role === "listitem")).toBe(true);
  expect(state.buttonsHidden).toBe(false);
  expect(state.prevType).toBe("button");
  expect(state.nextType).toBe("button");
  expect(state.scrollWidth).toBeGreaterThan(state.clientWidth);
});

test("Reel JavaScript progressively enhances native horizontal scrolling", async ({
  page,
}) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.setViewportSize({ width: 800, height: 600 });
  await page.setContent(`
    <section class="hyperdoc-reel" role="group" aria-label="Inspector views">
      <div class="hyperdoc-reel__buttons" hidden>
        <button class="hyperdoc-reel__prev" type="button">previous</button>
        <button class="hyperdoc-reel__next" type="button">next</button>
      </div>
      <div class="hyperdoc-reel__scrollable" tabindex="0" style="display:flex; overflow-x:auto; width:320px;">
        <div class="inspector-pane" style="flex:0 0 280px; height:80px;">one <button>inside one</button></div>
        <div class="inspector-pane" style="flex:0 0 280px; height:80px;">two <button>inside two</button></div>
        <div class="inspector-pane" style="flex:0 0 280px; height:80px;">three <button>inside three</button></div>
      </div>
    </section>
  `);

  const buttons = page.locator(".hyperdoc-reel__buttons");
  const prev = page.locator(".hyperdoc-reel__prev");
  const next = page.locator(".hyperdoc-reel__next");
  const scrollable = page.locator(".hyperdoc-reel__scrollable");

  await expect(buttons).toBeHidden();
  await page.evaluate((source) => {
    window.eval(source);
  }, fs.readFileSync(reelScriptPath, "utf8"));
  await expect(page.locator(".hyperdoc-reel")).toHaveAttribute(
    "data-hyperdoc-reel-enhanced",
    "true"
  );
  await expect(buttons).toBeVisible();
  await expect(prev).toBeDisabled();
  await expect(next).toBeEnabled();

  const initialScrollLeft = await scrollable.evaluate((node) => node.scrollLeft);
  await next.click();
  await expect
    .poll(() => scrollable.evaluate((node) => node.scrollLeft))
    .toBeGreaterThan(initialScrollLeft);

  await expect
    .poll(() =>
      page.locator('.hyperdoc-reel__item[data-hyperdoc-reel-inert="true"]').count()
    )
    .toBeGreaterThan(0);

  await scrollable.evaluate((node) => {
    node.scrollLeft = node.scrollWidth;
    node.dispatchEvent(new Event("scroll"));
  });
  await expect(next).toBeDisabled();
});

test("Reel assets respect reduced motion and do not define autoplay", async () => {
  const js = fs.readFileSync(reelScriptPath, "utf8");
  const css = fs.readFileSync(reelCssPath, "utf8");

  expect(js).not.toMatch(/\bsetInterval\s*\(/);
  expect(js).not.toMatch(/\brequestAnimationFrame\s*\(/);
  expect(js).toContain("prefers-reduced-motion: reduce");
  expect(css).toContain("@media (prefers-reduced-motion: no-preference)");
  expect(css).toContain("scroll-snap-type: x proximity");
});
