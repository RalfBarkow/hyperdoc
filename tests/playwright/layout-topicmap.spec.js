"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  openHyperDoc,
  pane,
  readPaneTitles,
  settleInspectorBindings,
} = require("./hyperdoc-inspector");

async function openLayoutTopicmap(page) {
  await openHyperDoc(page, { timeout: 45_000 });
  await activatePaneTab(page, 1, "Layout topicmap");
  await settleInspectorBindings(page, 500);
  const layout = pane(page, 1).locator(".hyperdoc-layout-topicmap").first();
  await expect(layout).toBeVisible({ timeout: 20_000 });
  await expect
    .poll(() => page.evaluate(() => !!window.hyperdocLayoutTopicmap), {
      timeout: 20_000,
    })
    .toBe(true);
  await page.evaluate(() => window.hyperdocLayoutTopicmap.init(document));
  return layout;
}

async function dragButtonsTopicOntoPaneTopic(layout) {
  const buttonsTopic = layout.locator('[data-layout-topic-id="hyperdoc-reel__buttons"]');
  const paneTopic = layout.locator('[data-layout-topic-id="inspector-pane"]');
  await expect(buttonsTopic).toBeVisible();
  await expect(paneTopic).toBeVisible();
  await buttonsTopic.dragTo(paneTopic);
  const patch = layout.locator(
    '.hyperdoc-layout-patch[data-layout-patch-kind="move-topic-into-box-patch"]'
  );
  await expect(patch).toBeVisible();
  await expect(patch).toHaveAttribute("data-layout-patch-status", "created");
  return patch;
}

async function readPreviewInvariantState(page) {
  return page.evaluate(async () => {
    const wait = () => new Promise((resolve) => window.setTimeout(resolve, 140));
    const reel = document.querySelector(".hyperdoc-reel");
    const buttons = document.querySelector(".hyperdoc-reel__buttons");
    const prev = document.querySelector(".hyperdoc-reel__prev");
    const next = document.querySelector(".hyperdoc-reel__next");
    const scrollable = document.querySelector(".hyperdoc-reel__scrollable");
    const targetPane = document.querySelector(
      '.inspector-pane[data-layout-preview-target="buttons-in-pane"]'
    );

    const buttonRect = buttons?.getBoundingClientRect();
    const paneRect = targetPane?.getBoundingClientRect();
    const geometry = {
      buttonsInsidePane:
        !!buttonRect &&
        !!paneRect &&
        buttonRect.left >= paneRect.left - 1 &&
        buttonRect.right <= paneRect.right + 1 &&
        buttonRect.top >= paneRect.top - 1 &&
        buttonRect.bottom <= paneRect.bottom + 1,
      buttonsRect: buttonRect
        ? {
            top: buttonRect.top,
            right: buttonRect.right,
            bottom: buttonRect.bottom,
            left: buttonRect.left,
          }
        : null,
      paneRect: paneRect
        ? {
            top: paneRect.top,
            right: paneRect.right,
            bottom: paneRect.bottom,
            left: paneRect.left,
          }
        : null,
    };

    if (!scrollable) {
      return { geometry, missingScrollable: true };
    }

    const maxScrollLeft = Math.max(0, scrollable.scrollWidth - scrollable.clientWidth);
    scrollable.scrollLeft = 0;
    scrollable.dispatchEvent(new Event("scroll"));
    await wait();
    const atStart = {
      scrollLeft: scrollable.scrollLeft,
      prevDisabled: !!prev?.disabled,
      nextDisabled: !!next?.disabled,
    };

    scrollable.scrollLeft = maxScrollLeft;
    scrollable.dispatchEvent(new Event("scroll"));
    await wait();
    const atEnd = {
      scrollLeft: scrollable.scrollLeft,
      prevDisabled: !!prev?.disabled,
      nextDisabled: !!next?.disabled,
    };

    return {
      geometry,
      previewState: reel?.getAttribute("data-layout-preview") || null,
      previewParent: buttons?.getAttribute("data-layout-preview-parent") || null,
      buttonPosition: buttons ? window.getComputedStyle(buttons).position : null,
      overflowX: window.getComputedStyle(scrollable).overflowX,
      scrollWidth: scrollable.scrollWidth,
      clientWidth: scrollable.clientWidth,
      maxScrollLeft,
      atStart,
      atEnd,
      prevLabel: prev?.getAttribute("aria-label") || null,
      nextLabel: next?.getAttribute("aria-label") || null,
      prevType: prev?.getAttribute("type") || null,
      nextType: next?.getAttribute("type") || null,
    };
  });
}

test("Layout topicmap drag creates an inspectable move patch", async ({
  page,
}, testInfo) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  const layout = await openLayoutTopicmap(page);

  await expect(layout.locator('[data-layout-topic-id="hyperdoc-reel__buttons"]')).toContainText(
    "Reel navigation buttons"
  );
  await expect(layout.locator('[data-layout-topic-id="inspector-pane"]')).toContainText(
    "Inspector pane"
  );

  const patch = await dragButtonsTopicOntoPaneTopic(layout);
  await expect(patch).toContainText("Before topology");
  await expect(patch).toContainText("After topology");
  await expect(patch).toContainText("hyperdoc-reel__viewport");
  await expect(patch).toContainText("inspector-pane");
  await expect(patch).toContainText("Source");
  await expect(patch).toContainText("Target");
  const inspectRef = patch.locator(
    '.hyperdoc-layout-inspectable-ref [id^="inspect-"]'
  );
  await expect(inspectRef).toContainText("Inspect move-topic-into-box-patch");

  await attachJson(testInfo, "layout-topicmap-pane-titles.json", await readPaneTitles(page));
});

for (const viewport of [
  { width: 1280, height: 800 },
  { width: 1366, height: 768 },
]) {
  test(`Layout patch preview keeps reel controls and native scrolling intact at ${viewport.width}x${viewport.height}`, async ({
    page,
  }, testInfo) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.setViewportSize(viewport);
    const layout = await openLayoutTopicmap(page);
    const patch = await dragButtonsTopicOntoPaneTopic(layout);

    await patch.locator(".hyperdoc-layout-preview").click();
    await expect(patch).toHaveAttribute("data-preview-state", "previewed");

    const state = await readPreviewInvariantState(page);
    await attachJson(
      testInfo,
      `layout-preview-invariants-${viewport.width}x${viewport.height}.json`,
      state
    );

    expect(state.geometry.buttonsInsidePane).toBe(true);
    expect(state.previewState).toBe("buttons-in-pane");
    expect(state.previewParent).toContain("hyperdoc-reel__viewport");
    expect(state.buttonPosition).toBe("fixed");
    expect(state.overflowX).toBe("auto");
    expect(state.scrollWidth).toBeGreaterThan(state.clientWidth);
    expect(state.maxScrollLeft).toBeGreaterThan(0);
    expect(state.atStart.prevDisabled).toBe(true);
    expect(state.atStart.nextDisabled).toBe(false);
    expect(state.atEnd.scrollLeft).toBeGreaterThan(state.maxScrollLeft * 0.75);
    expect(state.atEnd.prevDisabled).toBe(false);
    expect(state.atEnd.nextDisabled).toBe(true);
    expect(state.prevLabel).toBe("previous");
    expect(state.nextLabel).toBe("next");
    expect(state.prevType).toBe("button");
    expect(state.nextType).toBe("button");

    await page.evaluate(async () => {
      const scrollable = document.querySelector(".hyperdoc-reel__scrollable");
      scrollable.scrollLeft = 0;
      scrollable.dispatchEvent(new Event("scroll"));
      await new Promise((resolve) => window.setTimeout(resolve, 140));
    });
    await page.locator(".hyperdoc-reel__next").focus();
    const focusState = await page.evaluate(() => ({
      className: document.activeElement.className,
      label: document.activeElement.getAttribute("aria-label"),
    }));
    expect(focusState.className).toContain("hyperdoc-reel__next");
    expect(focusState.label).toBe("next");

    await patch.locator(".hyperdoc-layout-apply").click();
    await expect(patch).toHaveAttribute(
      "data-layout-apply-state",
      "durable-override-created"
    );
  });
}
