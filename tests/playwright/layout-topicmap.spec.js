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

const LAYOUT_OVERRIDE_STORE_KEY = "hyperdoc.layout.overrides.v1";

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
    const patch = document.querySelector(".hyperdoc-layout-patch");
    const reel = document.querySelector(".hyperdoc-reel");
    const buttons = document.querySelector(".hyperdoc-reel__buttons");
    const prev = document.querySelector(".hyperdoc-reel__prev");
    const next = document.querySelector(".hyperdoc-reel__next");
    const scrollable = document.querySelector(".hyperdoc-reel__scrollable");
    const targetPane = document.querySelector(
      '.inspector-pane[data-layout-preview-target="buttons-in-pane"], .inspector-pane[data-layout-replay-target="buttons-in-pane"]'
    );
    const targetPaneBody = targetPane?.querySelector(".inspector-body") || null;

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
      repairPlanStatus: patch?.getAttribute("data-layout-repair-plan-status") || null,
      renderedEffectCount: patch
        ? patch.querySelectorAll(".hyperdoc-layout-renderer-effect").length
        : 0,
      previewSource: patch?.getAttribute("data-preview-source") || null,
      previewEffectCount: patch?.getAttribute("data-preview-effect-count") || null,
      previewState:
        reel?.getAttribute("data-layout-preview") ||
        reel?.getAttribute("data-layout-replay") ||
        null,
      previewParent: buttons?.getAttribute("data-layout-preview-parent") || null,
      previewEffect:
        buttons?.getAttribute("data-layout-preview-effect") ||
        buttons?.getAttribute("data-layout-replay-effect") ||
        null,
      buttonPosition: buttons ? window.getComputedStyle(buttons).position : null,
      paneClearance:
        targetPaneBody?.getAttribute("data-layout-preview-clearance") ||
        targetPaneBody?.getAttribute("data-layout-replay-clearance") ||
        null,
      paneClearanceEffect:
        targetPaneBody?.getAttribute("data-layout-preview-clearance-effect") ||
        targetPaneBody?.getAttribute("data-layout-replay-clearance-effect") ||
        null,
      panePaddingBottom: targetPaneBody?.style.paddingBottom || null,
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
  await expect(patch).toContainText("Derived repair plan");
  await expect(patch).toContainText("Rule results");
  await expect(patch).toContainText("Renderer effects");
  await expect(patch).toHaveAttribute("data-layout-repair-plan-status", "previewable");
  await expect(
    patch.locator('[data-layout-rule-result-status="pass"]')
  ).toHaveCount(4);
  await expect(
    patch.locator('[data-layout-rule-result-status="repair"]')
  ).toHaveCount(3);
  await expect(
    patch.locator('[data-layout-rule-result-status="fail"]')
  ).toHaveCount(0);
  await expect(
    patch.locator(
      '[data-layout-effect-phase="preview"][data-layout-effect-kind="position-control-rail"]'
    )
  ).toBeVisible();
  await expect(
    patch.locator(
      '[data-layout-effect-phase="preview"][data-layout-effect-kind="set-style"]'
    )
  ).toBeVisible();
  await expect(
    patch.locator(
      '[data-layout-effect-phase="apply"][data-layout-effect-kind="durable-override"]'
    )
  ).toBeVisible();
  await expect(patch).toContainText("hyperdoc-reel__viewport");
  await expect(patch).toContainText("inspector-pane");
  await expect(patch).toContainText("Source");
  await expect(patch).toContainText("Target");
  const inspectRef = patch.locator('.hyperdoc-layout-inspectable-ref:has-text("Inspect move-topic-into-box-patch") [id^="inspect-"]');
  await expect(inspectRef).toContainText("Inspect move-topic-into-box-patch");
  const planInspectRef = patch.locator('.hyperdoc-layout-inspectable-ref:has-text("Inspect layout-repair-plan") [id^="inspect-"]');
  await expect(planInspectRef).toContainText("Inspect layout-repair-plan");

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
    expect(state.repairPlanStatus).toBe("previewable");
    expect(state.renderedEffectCount).toBe(3);
    expect(state.previewSource).toBe("renderer-effects");
    expect(state.previewEffectCount).toBe("2");
    expect(state.previewState).toBe("buttons-in-pane");
    expect(state.previewParent).toContain("hyperdoc-reel__viewport");
    expect(state.previewEffect).toBe("position-control-rail-in-pane");
    expect(state.buttonPosition).toBe("fixed");
    expect(state.paneClearance).toBe("reserved");
    expect(state.paneClearanceEffect).toBe("reserve-pane-bottom-clearance");
    expect(state.panePaddingBottom).toBe("4.5rem");
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
    await expect(patch).toHaveAttribute(
      "data-layout-apply-source",
      "renderer-effects"
    );
    await expect(patch).toHaveAttribute(
      "data-layout-apply-effect",
      "create-durable-layout-override"
    );
    await expect(patch).toHaveAttribute("data-layout-override-state", "persisted");
    await expect(patch).toHaveAttribute(
      "data-layout-override-store-key",
      LAYOUT_OVERRIDE_STORE_KEY
    );
    const durableOverride = await patch.getAttribute("data-layout-durable-override");
    expect(durableOverride.toLowerCase()).toContain("layout-renderer-override");
  });
}

test("Layout patch apply persists and replays override after reload", async ({
  page,
}, testInfo) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.setViewportSize({ width: 1280, height: 800 });
  const layout = await openLayoutTopicmap(page);
  await page.evaluate((key) => window.localStorage.removeItem(key), LAYOUT_OVERRIDE_STORE_KEY);
  const patch = await dragButtonsTopicOntoPaneTopic(layout);

  await patch.locator(".hyperdoc-layout-apply").click();
  await expect(patch).toHaveAttribute("data-layout-override-state", "persisted");
  const persistedOverrideId = await patch.getAttribute("data-layout-override-id");
  expect(persistedOverrideId).toBeTruthy();

  const persistedStore = await page.evaluate((key) => {
    return JSON.parse(window.localStorage.getItem(key));
  }, LAYOUT_OVERRIDE_STORE_KEY);
  await attachJson(testInfo, "layout-override-store-after-apply.json", persistedStore);
  expect(persistedStore.storageKey).toBe(LAYOUT_OVERRIDE_STORE_KEY);
  expect(persistedStore.overrides).toHaveLength(1);
  const [override] = persistedStore.overrides;
  expect(override.id).toBe(persistedOverrideId);
  expect(override.sourcePatchId).toBe("move-hyperdoc-reel__buttons-into-inspector-pane");
  expect(override.beforeTopology).toContainEqual({
    parentId: "hyperdoc-reel__viewport",
    childId: "hyperdoc-reel__buttons",
  });
  expect(override.afterTopology).toContainEqual({
    parentId: "inspector-pane",
    childId: "hyperdoc-reel__buttons",
  });
  expect(override.rendererEffects.map((effect) => effect.kind)).toEqual(
    expect.arrayContaining(["position-control-rail", "set-style", "durable-override"])
  );

  const reloadedLayout = await openLayoutTopicmap(page);
  const replayedPatch = reloadedLayout.locator(
    '.hyperdoc-layout-patch[data-layout-patch-kind="move-topic-into-box-patch"]'
  );
  await expect(replayedPatch).toBeVisible();
  await expect(replayedPatch).toHaveAttribute("data-layout-patch-status", "replayed");
  await expect(replayedPatch).toHaveAttribute("data-layout-override-state", "replayed");
  await expect(replayedPatch).toHaveAttribute(
    "data-layout-replayed-override-id",
    persistedOverrideId
  );
  await expect(
    reloadedLayout.locator(
      '[data-layout-topic-id="hyperdoc-reel__buttons"][data-layout-replayed-parent-id="inspector-pane"]'
    )
  ).toBeVisible();
  await expect(
    replayedPatch.locator(
      '[data-layout-topology-title="After topology"] [data-layout-parent-id="inspector-pane"][data-layout-child-id="hyperdoc-reel__buttons"]'
    )
  ).toBeVisible();

  const replayState = await readPreviewInvariantState(page);
  await attachJson(testInfo, "layout-override-replay-invariants.json", replayState);
  expect(replayState.geometry.buttonsInsidePane).toBe(true);
  expect(replayState.repairPlanStatus).toBe("previewable");
  expect(replayState.renderedEffectCount).toBe(3);
  expect(replayState.previewState).toBe("buttons-in-pane");
  expect(replayState.previewEffect).toBe("position-control-rail-in-pane");
  expect(replayState.buttonPosition).toBe("fixed");
  expect(replayState.paneClearance).toBe("reserved");
  expect(replayState.paneClearanceEffect).toBe("reserve-pane-bottom-clearance");
  expect(replayState.overflowX).toBe("auto");
  expect(replayState.scrollWidth).toBeGreaterThan(replayState.clientWidth);
  expect(replayState.maxScrollLeft).toBeGreaterThan(0);
  expect(replayState.atStart.prevDisabled).toBe(true);
  expect(replayState.atStart.nextDisabled).toBe(false);
  expect(replayState.atEnd.prevDisabled).toBe(false);
  expect(replayState.atEnd.nextDisabled).toBe(true);
  expect(replayState.prevLabel).toBe("previous");
  expect(replayState.nextLabel).toBe("next");
  expect(replayState.prevType).toBe("button");
  expect(replayState.nextType).toBe("button");

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
});
