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

async function mountStickyReelFixture(page) {
  await page.setContent(`
    <style>
      ${fs.readFileSync(reelCssPath, "utf8")}

      body {
        margin: 0;
        font: 16px sans-serif;
      }

      .hyperdoc-reel {
        height: 98vh;
      }

      .hyperdoc-reel__scrollable {
        width: min(52rem, 100vw);
      }

      .pane-fixture {
        box-sizing: border-box;
        flex: 0 0 min(52rem, 100vw);
        min-height: 42rem;
        padding: 1rem;
        border: 1px solid #999;
        background: #fafafa;
      }

      .after-reel {
        height: 60rem;
      }
    </style>
    <section class="hyperdoc-reel" role="group" aria-label="Inspector views">
      <div class="hyperdoc-reel__buttons" hidden>
        <button class="hyperdoc-reel__prev" type="button" aria-label="previous">previous</button>
        <button class="hyperdoc-reel__next" type="button" aria-label="next">next</button>
      </div>
      <div class="hyperdoc-reel__scrollable" tabindex="0">
        <div class="hyperdoc-reel__item pane-fixture">ordinary page pane one</div>
        <div class="inspector-pane pane-fixture">inspector pane two</div>
        <div class="hyperdoc-reel__item pane-fixture">ordinary page pane three</div>
        <div class="inspector-pane pane-fixture">inspector pane four</div>
      </div>
    </section>
    <div class="after-reel"></div>
  `);

  await page.evaluate((source) => {
    window.eval(source);
  }, fs.readFileSync(reelScriptPath, "utf8"));
}

test("multi-pane inspector renders as an accessible Reel adapter", async ({
  page,
}, testInfo) => {
  await openHyperDoc(page, { timeout: 45_000 });
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

for (const viewport of [
  { width: 1280, height: 800 },
  { width: 1366, height: 768 },
]) {
  test(`Reel controls remain locally sticky at ${viewport.width}x${viewport.height}`, async ({
    page,
  }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.setViewportSize(viewport);
    await mountStickyReelFixture(page);

    const buttons = page.locator(".hyperdoc-reel__buttons");
    const prev = page.locator(".hyperdoc-reel__prev");
    const next = page.locator(".hyperdoc-reel__next");
    const scrollable = page.locator(".hyperdoc-reel__scrollable");

    await expect(buttons).toBeVisible();
    await expect(prev).toHaveAttribute("aria-label", "previous");
    await expect(next).toHaveAttribute("aria-label", "next");
    await expect(prev).toBeDisabled();
    await expect(next).toBeEnabled();

    await page.evaluate(() => window.scrollTo(0, 320));
    const stickyState = await page.evaluate(() => {
      const buttonsNode = document.querySelector(".hyperdoc-reel__buttons");
      const scrollableNode = document.querySelector(".hyperdoc-reel__scrollable");
      const rect = buttonsNode.getBoundingClientRect();
      const styles = window.getComputedStyle(buttonsNode);
      return {
        top: rect.top,
        bottom: rect.bottom,
        viewportHeight: window.innerHeight,
        position: styles.position,
        insetBlockStart: styles.insetBlockStart,
        backgroundColor: styles.backgroundColor,
        paddingBlockStart: styles.paddingBlockStart,
        paddingBlockEnd: styles.paddingBlockEnd,
        overflowX: window.getComputedStyle(scrollableNode).overflowX,
        scrollWidth: scrollableNode.scrollWidth,
        clientWidth: scrollableNode.clientWidth,
        pageScrollY: window.scrollY,
        children: Array.from(scrollableNode.children).map((node) => ({
          role: node.getAttribute("role"),
          isReelItem: node.classList.contains("hyperdoc-reel__item"),
          isInspectorPane: node.classList.contains("inspector-pane"),
        })),
      };
    });

    expect(stickyState.pageScrollY).toBeGreaterThan(0);
    expect(stickyState.position).toBe("sticky");
    expect(stickyState.insetBlockStart).toBe("0px");
    expect(stickyState.top).toBeGreaterThanOrEqual(-1);
    expect(stickyState.bottom).toBeLessThanOrEqual(stickyState.viewportHeight + 1);
    expect(stickyState.backgroundColor).not.toBe("rgba(0, 0, 0, 0)");
    expect(parseFloat(stickyState.paddingBlockStart)).toBeGreaterThan(0);
    expect(parseFloat(stickyState.paddingBlockEnd)).toBeGreaterThan(0);
    expect(stickyState.overflowX).toBe("auto");
    expect(stickyState.scrollWidth).toBeGreaterThan(stickyState.clientWidth);
    expect(stickyState.children.every((child) => child.role === "listitem")).toBe(true);
    expect(stickyState.children.some((child) => child.isInspectorPane)).toBe(true);
    expect(stickyState.children.every((child) => child.isReelItem)).toBe(true);

    await page.keyboard.press("Tab");
    const focusState = await page.evaluate(() => ({
      className: document.activeElement.className,
      label: document.activeElement.getAttribute("aria-label"),
      pageScrollY: window.scrollY,
    }));
    expect(focusState.className).toContain("hyperdoc-reel__next");
    expect(focusState.label).toBe("next");
    expect(focusState.pageScrollY).toBeGreaterThan(0);

    const initialScrollLeft = await scrollable.evaluate((node) => node.scrollLeft);
    const nativeScrollLeft = await scrollable.evaluate((node) => {
      node.scrollLeft = node.scrollWidth - node.clientWidth;
      node.dispatchEvent(new Event("scroll"));
      return node.scrollLeft;
    });
    expect(nativeScrollLeft).toBeGreaterThan(initialScrollLeft);
    await expect(prev).toBeEnabled();
  });
}

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
