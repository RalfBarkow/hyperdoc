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

async function mountReadingReelFixture(page) {
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
        min-height: 0;
        border: 1px solid #999;
        background: #fafafa;
        display: flex;
        flex-direction: column;
      }

      .pane-title {
        flex: 0 0 auto;
        padding: 0.5rem 0.75rem;
        background: #ddd;
      }

      .inspector-body {
        flex: 1 1 auto;
        min-height: 0;
        overflow: auto;
        padding: 1rem;
      }

      .long-reading-content {
        min-height: 72rem;
      }

      .after-reel {
        height: 60rem;
      }
    </style>
    <section class="hyperdoc-reel" role="group" aria-label="Inspector views">
      <div class="hyperdoc-reel__viewport">
        <div class="hyperdoc-reel__buttons" hidden>
          <button class="hyperdoc-reel__prev" type="button" aria-label="previous">previous</button>
          <button class="hyperdoc-reel__next" type="button" aria-label="next">next</button>
        </div>
        <div class="hyperdoc-reel__scrollable" tabindex="0">
          <div class="hyperdoc-reel__item pane-fixture">
            <div class="pane-title">ordinary page pane one</div>
            <div class="inspector-body"><div class="long-reading-content">ordinary body one</div></div>
          </div>
          <div class="inspector-pane pane-fixture">
            <div class="pane-title">inspector pane two</div>
            <div class="inspector-body"><div class="long-reading-content">inspector body two</div></div>
          </div>
          <div class="hyperdoc-reel__item pane-fixture">
            <div class="pane-title">ordinary page pane three</div>
            <div class="inspector-body"><div class="long-reading-content">ordinary body three</div></div>
          </div>
          <div class="inspector-pane pane-fixture">
            <div class="pane-title">inspector pane four</div>
            <div class="inspector-body"><div class="long-reading-content">inspector body four</div></div>
          </div>
        </div>
      </div>
    </section>
    <div class="after-reel"></div>
  `);

  await page.evaluate((source) => {
    window.eval(source);
  }, fs.readFileSync(reelScriptPath, "utf8"));
}

async function scrollReadingPaneAndMeasureRail(page, paneIndex = 1) {
  return page.evaluate((index) => {
    const reel = document.querySelector(".hyperdoc-reel");
    const scrollable = reel?.querySelector(".hyperdoc-reel__scrollable");
    const buttons = reel?.querySelector(".hyperdoc-reel__buttons");
    const prev = reel?.querySelector(".hyperdoc-reel__prev");
    const next = reel?.querySelector(".hyperdoc-reel__next");
    const paneCandidates = Array.from(document.querySelectorAll(".inspector-pane"))
      .map((pane, candidateIndex) => {
        const activeView = pane.querySelector(".inspector-view:not([hidden])");
        const readingScroller =
          pane.querySelector(".inspector-body") ||
          activeView ||
          pane;
        const maxScrollTop = Math.max(
          0,
          (readingScroller?.scrollHeight || 0) -
            (readingScroller?.clientHeight || 0)
        );
        return { pane, readingScroller, maxScrollTop, candidateIndex };
      });
    const requested = paneCandidates[index];
    const selected =
      (requested && requested.maxScrollTop > 0 && requested) ||
      paneCandidates.find((candidate) => candidate.maxScrollTop > 0) ||
      requested ||
      paneCandidates[0] ||
      {};
    const pane = selected.pane;
    const readingScroller = selected.readingScroller;
    const maxScrollTop = Math.max(
      0,
      (readingScroller?.scrollHeight || 0) - (readingScroller?.clientHeight || 0)
    );

    if (readingScroller && maxScrollTop > 0) {
      readingScroller.scrollTop = Math.min(maxScrollTop, 360);
      readingScroller.dispatchEvent(new Event("scroll"));
    }

    const buttonsRect = buttons?.getBoundingClientRect();
    const scrollableRect = scrollable?.getBoundingClientRect();
    const paneRect = pane?.getBoundingClientRect();
    const scrollerRect = readingScroller?.getBoundingClientRect();
    const styles = buttons && window.getComputedStyle(buttons);
    return {
      hasViewport: !!reel?.querySelector(".hyperdoc-reel__viewport"),
      readingScrollerClassName: readingScroller?.className || "",
      selectedPaneIndex: selected.candidateIndex ?? null,
      readingScrollTop: readingScroller?.scrollTop || 0,
      readingMaxScrollTop: maxScrollTop,
      buttonsTop: buttonsRect?.top ?? null,
      buttonsBottom: buttonsRect?.bottom ?? null,
      buttonsLeft: buttonsRect?.left ?? null,
      buttonsRight: buttonsRect?.right ?? null,
      scrollableTop: scrollableRect?.top ?? null,
      scrollableBottom: scrollableRect?.bottom ?? null,
      scrollableLeft: scrollableRect?.left ?? null,
      scrollableRight: scrollableRect?.right ?? null,
      paneBottom: paneRect?.bottom ?? null,
      scrollerBottom: scrollerRect?.bottom ?? null,
      viewportHeight: window.innerHeight,
      position: styles?.position || null,
      insetBlockEnd: styles?.insetBlockEnd || null,
      backgroundColor: styles?.backgroundColor || null,
      paddingBlockStart: styles?.paddingBlockStart || null,
      paddingBlockEnd: styles?.paddingBlockEnd || null,
      prevDisabled: !!prev?.disabled,
      nextDisabled: !!next?.disabled,
    };
  }, paneIndex);
}

async function ensureLiveReadingOverflow(page, paneIndex = 1) {
  await page.evaluate((index) => {
    const pane =
      document.querySelectorAll(".inspector-pane")[index] ||
      document.querySelector(".inspector-pane");
    const readingScroller = pane?.querySelector(".inspector-body");
    if (!readingScroller) {
      return;
    }
    const maxScrollTop = Math.max(
      0,
      readingScroller.scrollHeight - readingScroller.clientHeight
    );
    if (maxScrollTop > 0) {
      return;
    }
    const filler = document.createElement("div");
    filler.dataset.reelReadingOverflowFixture = "true";
    filler.style.minHeight = "72rem";
    filler.style.paddingBlockStart = "1rem";
    filler.textContent = "Live reading overflow fixture for reel control reachability.";
    readingScroller.appendChild(filler);
  }, paneIndex);
}

async function readReelButtonBoundaryState(page) {
  return page.evaluate(async () => {
    const reel = document.querySelector(".hyperdoc-reel");
    const scrollable = reel?.querySelector(".hyperdoc-reel__scrollable");
    const prev = reel?.querySelector(".hyperdoc-reel__prev");
    const next = reel?.querySelector(".hyperdoc-reel__next");
    const waitForReelUpdate = () =>
      new Promise((resolve) => window.setTimeout(resolve, 120));

    if (!scrollable) {
      return null;
    }

    const originalScrollLeft = scrollable.scrollLeft;
    const maxScrollLeft = Math.max(
      0,
      scrollable.scrollWidth - scrollable.clientWidth
    );
    const capture = () => ({
      scrollLeft: scrollable.scrollLeft,
      prevDisabled: !!prev?.disabled,
      nextDisabled: !!next?.disabled,
    });

    scrollable.scrollLeft = 0;
    scrollable.dispatchEvent(new Event("scroll"));
    await waitForReelUpdate();
    const atStart = capture();

    scrollable.scrollLeft = maxScrollLeft;
    scrollable.dispatchEvent(new Event("scroll"));
    await waitForReelUpdate();
    const atEnd = capture();

    scrollable.scrollLeft = originalScrollLeft;
    scrollable.dispatchEvent(new Event("scroll"));
    await waitForReelUpdate();

    return {
      maxScrollLeft,
      originalScrollLeft,
      atStart,
      atEnd,
      restored: capture(),
    };
  });
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
  test(`Reel controls remain reachable while reading a pane fixture at ${viewport.width}x${viewport.height}`, async ({
    page,
  }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.setViewportSize(viewport);
    await mountReadingReelFixture(page);

    const buttons = page.locator(".hyperdoc-reel__buttons");
    const prev = page.locator(".hyperdoc-reel__prev");
    const next = page.locator(".hyperdoc-reel__next");
    const scrollable = page.locator(".hyperdoc-reel__scrollable");

    await expect(buttons).toBeVisible();
    await expect(prev).toHaveAttribute("aria-label", "previous");
    await expect(next).toHaveAttribute("aria-label", "next");
    await expect(prev).toBeDisabled();
    await expect(next).toBeEnabled();

    const railState = await scrollReadingPaneAndMeasureRail(page, 1);
    const scrollState = await page.evaluate(() => {
      const scrollableNode = document.querySelector(".hyperdoc-reel__scrollable");
      return {
        overflowX: window.getComputedStyle(scrollableNode).overflowX,
        scrollWidth: scrollableNode.scrollWidth,
        clientWidth: scrollableNode.clientWidth,
        children: Array.from(scrollableNode.children).map((node) => ({
          role: node.getAttribute("role"),
          isReelItem: node.classList.contains("hyperdoc-reel__item"),
          isInspectorPane: node.classList.contains("inspector-pane"),
        })),
      };
    });

    expect(railState.hasViewport).toBe(true);
    expect(railState.readingScrollerClassName).toContain("inspector-body");
    expect(railState.readingMaxScrollTop).toBeGreaterThan(0);
    expect(railState.readingScrollTop).toBeGreaterThan(0);
    expect(railState.position).toBe("absolute");
    expect(railState.insetBlockEnd).not.toBe("auto");
    expect(railState.buttonsTop).toBeGreaterThanOrEqual(railState.scrollableTop - 1);
    expect(railState.buttonsBottom).toBeLessThanOrEqual(railState.scrollableBottom + 1);
    expect(railState.buttonsBottom).toBeLessThanOrEqual(railState.viewportHeight + 1);
    expect(railState.scrollerBottom).toBeLessThanOrEqual(railState.buttonsTop + 1);
    expect(railState.backgroundColor).not.toBe("rgba(0, 0, 0, 0)");
    expect(parseFloat(railState.paddingBlockStart)).toBeGreaterThan(0);
    expect(parseFloat(railState.paddingBlockEnd)).toBeGreaterThan(0);
    expect(scrollState.overflowX).toBe("auto");
    expect(scrollState.scrollWidth).toBeGreaterThan(scrollState.clientWidth);
    expect(scrollState.children.every((child) => child.role === "listitem")).toBe(true);
    expect(scrollState.children.some((child) => child.isInspectorPane)).toBe(true);
    expect(scrollState.children.every((child) => child.isReelItem)).toBe(true);

    await page.keyboard.press("Tab");
    const focusState = await page.evaluate(() => ({
      className: document.activeElement.className,
      label: document.activeElement.getAttribute("aria-label"),
    }));
    expect(focusState.className).toContain("hyperdoc-reel__next");
    expect(focusState.label).toBe("next");

    const initialScrollLeft = await scrollable.evaluate((node) => node.scrollLeft);
    const nativeScrollLeft = await scrollable.evaluate((node) => {
      node.scrollLeft = node.scrollWidth - node.clientWidth;
      node.dispatchEvent(new Event("scroll"));
      return node.scrollLeft;
    });
    expect(nativeScrollLeft).toBeGreaterThan(initialScrollLeft);
    await expect(prev).toBeEnabled();
  });

  test(`Live HyperDoc reel controls remain reachable while reading at ${viewport.width}x${viewport.height}`, async ({
    page,
  }, testInfo) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.setViewportSize(viewport);
    await openHyperDoc(page, { timeout: 45_000 });
    await settleInspectorBindings(page, 1000);

    const buttons = page.locator(".hyperdoc-reel__buttons");
    const prev = page.locator(".hyperdoc-reel__prev");
    const next = page.locator(".hyperdoc-reel__next");

    await expect(buttons).toBeVisible();
    await expect(prev).toHaveAttribute("aria-label", "previous");
    await expect(next).toHaveAttribute("aria-label", "next");

    const boundaryState = await readReelButtonBoundaryState(page);
    await testInfo.attach(`live-boundary-state-${viewport.width}x${viewport.height}.json`, {
      body: JSON.stringify(boundaryState, null, 2),
      contentType: "application/json",
    });
    expect(boundaryState).not.toBeNull();
    expect(boundaryState.maxScrollLeft).toBeGreaterThan(0);
    expect(boundaryState.atStart.scrollLeft).toBeLessThan(
      boundaryState.maxScrollLeft / 4
    );
    expect(boundaryState.atStart.prevDisabled).toBe(true);
    expect(boundaryState.atStart.nextDisabled).toBe(false);
    expect(boundaryState.atEnd.scrollLeft).toBeGreaterThan(
      boundaryState.maxScrollLeft * 0.75
    );
    expect(boundaryState.atEnd.prevDisabled).toBe(false);
    expect(boundaryState.atEnd.nextDisabled).toBe(true);

    await ensureLiveReadingOverflow(page, 1);
    const railState = await scrollReadingPaneAndMeasureRail(page, 1);
    await testInfo.attach(`live-reading-rail-${viewport.width}x${viewport.height}.json`, {
      body: JSON.stringify(railState, null, 2),
      contentType: "application/json",
    });

    expect(railState.hasViewport).toBe(true);
    expect(railState.readingScrollerClassName).toContain("inspector-body");
    expect(railState.readingMaxScrollTop).toBeGreaterThan(0);
    expect(railState.readingScrollTop).toBeGreaterThan(0);
    expect(railState.buttonsTop).toBeGreaterThanOrEqual(railState.scrollableTop - 1);
    expect(railState.buttonsBottom).toBeLessThanOrEqual(railState.scrollableBottom + 1);
    expect(railState.buttonsBottom).toBeLessThanOrEqual(railState.viewportHeight + 1);
    expect(railState.scrollerBottom).toBeLessThanOrEqual(railState.buttonsTop + 1);
    expect(railState.prevDisabled).toBe(boundaryState.restored.prevDisabled);
    expect(railState.nextDisabled).toBe(boundaryState.restored.nextDisabled);
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
