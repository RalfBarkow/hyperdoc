"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  exactTextPattern,
  openHyperDoc,
  openTextPageFromHyperDoc,
  pane,
  readInspectorPaneState,
} = require("./hyperdoc-inspector");
const {
  openObjectFromTextPageLink,
} = require("./bibliography-authoring-plan-live-helper");

test.describe.configure({ mode: "serial" });

const LIVE_CASES = {
  htmlRewriting: {
    id: "html-rewriting",
    linkText: "HTML Rewriting live plan",
    paneOpenTimeoutMs: 60_000,
    timeoutNote: "explicit cold first-plan pane-open budget",
    heavyFactors: [
      "import cost stays near the baseline for this live suite",
      "candidate extraction remains sparse",
      "inspector rendering stays small because the decision list is thin",
      "pane-open/UI polling on the first live plan also absorbs the cold first-plan path in the browser run",
    ],
  },
  topologicalIntelligence: {
    id: "topological-intelligence",
    linkText: "Topological Intelligence live plan",
    paneOpenTimeoutMs: 45_000,
    timeoutNote: "explicit moderate-plan pane-open budget",
    heavyFactors: [
      "import cost stays near the baseline for this live suite",
      "candidate extraction is moderate because multiple overlay variants remain in play",
      "inspector rendering stays moderate because the plan keeps multiple competing overlay decisions visible",
      "pane-open/UI polling can exceed the default budget while the full ambiguity surface becomes visible",
    ],
  },
  plasticsPackaging: {
    id: "plastics-packaging",
    linkText: "Plastics Packaging live plan",
    paneOpenTimeoutMs: 60_000,
    timeoutNote: "explicit heavy-plan pane-open budget",
    heavyFactors: [
      "import cost is heavier because the live subcollection yields a broader entry set",
      "candidate extraction cost is heavier because thin note, keyword, and title cues still produce many proposals",
      "inspector rendering cost is heavier because the plan surfaces a larger decision and repo-touch preview set",
      "pane-open/UI polling cost is heavier because the browser waits for the full plan pane to become visible and populated",
    ],
  },
};

function liveZoteroEnabled() {
  return process.env.HYPERDOC_RUN_ZOTERO_LIVE_TESTS === "1";
}

const RELATED_PAGE_LINKS = [
  "Bibliography subcollections in HyperDoc",
  "Bibliography authoring-plan stand-in inspection",
  "Coachmark bibliography authoring plan",
];

function tableRowsToMap(rows) {
  return Object.fromEntries(
    (rows || [])
      .filter((row) => row.length >= 2 && row[0])
      .map((row) => [row[0], row.slice(1).join(" ").trim()])
  );
}

async function openLiveEvaluationPage(page) {
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, "Bibliography subcollections in HyperDoc");
  await activatePaneTab(page, 2, "Content");
}

async function openBibliographyAuthoringPlanLiveEvaluationPage(page) {
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, "Bibliography authoring plan live evaluation");
  await activatePaneTab(page, 2, "Content");
}

async function openLivePlan(page, liveCase) {
  await openLiveEvaluationPage(page);
  return openObjectFromTextPageLink(page, 2, liveCase.linkText, liveCase.paneOpenTimeoutMs);
}

async function readPaneUrl(page, paneIndex) {
  await activatePaneTab(page, paneIndex, "URL");
  const urlPane = pane(page, paneIndex);
  const link = urlPane.locator("a[href]").first();
  await expect(link).toBeVisible({ timeout: 20_000 });
  return link.getAttribute("href");
}

async function assertDirectRouteLoads(page, url, targetTitle) {
  const routePage = await page.context().newPage();
  try {
    await routePage.goto(url, { waitUntil: "domcontentloaded", timeout: 30_000 });
    await expect(routePage.locator("body")).not.toContainText("502 Bad Gateway", {
      timeout: 20_000,
    });
    await expect(routePage.locator(".inspector-pane")).toBeVisible({ timeout: 20_000 });
    await expect(
      routePage
        .locator(".inspector-title-bar-object, .inspector-title-bar-class")
        .filter({ hasText: exactTextPattern(targetTitle) })
        .first()
    ).toBeVisible({ timeout: 20_000 });
    await expect(routePage.locator("#clog-disconnected-banner")).toHaveCount(0);
  } finally {
    await routePage.close();
  }
}

function asInteger(value) {
  const parsed = Number.parseInt(String(value || ""), 10);
  return Number.isFinite(parsed) ? parsed : null;
}

async function attachPaneOpenTiming(testInfo, liveCase, summaryRows, paneOpen) {
  await attachJson(testInfo, `${liveCase.id}-pane-open-timing.json`, {
    caseId: liveCase.id,
    linkText: liveCase.linkText,
    classification: paneOpen.paneOpenDiagnostic?.classification || null,
    currentUrl: paneOpen.paneOpenDiagnostic?.currentUrl || null,
    paneOpenMs: paneOpen.paneOpenMs,
    paneOpenTimeoutMs: paneOpen.paneOpenTimeoutMs,
    timeoutNote: liveCase.timeoutNote,
    collectionPath: summaryRows["Collection path"] || null,
    importedEntries: asInteger(summaryRows["Imported entries"]),
    heavyFactors: liveCase.heavyFactors,
  });
}

async function openLivePlanWithDiagnostics(page, liveCase, testInfo) {
  try {
    const paneOpen = await openLivePlan(page, liveCase);
    await attachJson(
      testInfo,
      `${liveCase.id}-pane-open-diagnostic.json`,
      paneOpen.paneOpenDiagnostic
    );
    return paneOpen;
  } catch (error) {
    if (error.paneOpenDiagnostic) {
      await attachJson(
        testInfo,
        `${liveCase.id}-pane-open-diagnostic.json`,
        error.paneOpenDiagnostic
      );
    }
    throw error;
  }
}

test.describe("bibliography related page navigation", () => {
  for (const targetTitle of RELATED_PAGE_LINKS) {
    test(`opens ${targetTitle} without disconnecting`, async ({
      page,
    }, testInfo) => {
      await openBibliographyAuthoringPlanLiveEvaluationPage(page);

      let paneOpen;
      try {
        paneOpen = await openObjectFromTextPageLink(page, 2, targetTitle, 20_000);
      } catch (error) {
        if (error.paneOpenDiagnostic) {
          await attachJson(
            testInfo,
            `${targetTitle.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}-related-page-diagnostic.json`,
            error.paneOpenDiagnostic
          );
        }
        throw error;
      }

      await attachJson(
        testInfo,
        `${targetTitle.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}-related-page-diagnostic.json`,
        paneOpen.paneOpenDiagnostic
      );

      const targetTitleButton = pane(page, paneOpen.paneIndex)
        .locator(".inspector-title-bar-object, .inspector-title-bar-class")
        .filter({ hasText: exactTextPattern(targetTitle) })
        .first();

      await expect(page.locator("#clog-disconnected-banner")).toHaveCount(0);
      await expect(targetTitleButton).toBeVisible({ timeout: 15_000 });

      const directUrl = await readPaneUrl(page, paneOpen.paneIndex);
      await attachJson(
        testInfo,
        `${targetTitle.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}-related-page-url.json`,
        {
          targetTitle,
          directUrl,
        }
      );

      await assertDirectRouteLoads(page, directUrl, targetTitle);
    });
  }
});

test.describe("live bibliography authoring-plan evaluation", () => {
  test.skip(
    !liveZoteroEnabled(),
    "Set HYPERDOC_RUN_ZOTERO_LIVE_TESTS=1 to enable live bibliography evaluation tests."
  );

  test("HTML Rewriting shows the sparse continuity-shell case without a repo write", async ({
    page,
  }, testInfo) => {
    const liveCase = LIVE_CASES.htmlRewriting;
    const paneOpen = await openLivePlanWithDiagnostics(page, liveCase, testInfo);

    const summary = await readInspectorPaneState(page, paneOpen.paneIndex);
    const summaryRows = tableRowsToMap(summary.tables[0]);

    await activatePaneTab(page, paneOpen.paneIndex, "Page write/update plan");
    const decisionPlan = await readInspectorPaneState(page, paneOpen.paneIndex);

    await activatePaneTab(page, paneOpen.paneIndex, "Materialization preview");
    const preview = await readInspectorPaneState(page, paneOpen.paneIndex);

    await attachJson(testInfo, "html-rewriting-collection-summary.json", summary);
    await attachJson(testInfo, "html-rewriting-page-plan.json", decisionPlan);
    await attachJson(testInfo, "html-rewriting-materialization-preview.json", preview);
    await attachPaneOpenTiming(testInfo, liveCase, summaryRows, paneOpen);

    expect(summaryRows["Collection path"]).toContain("HTML Rewriting");
    expect(Number(summaryRows["Imported entries"])).toBeGreaterThan(0);
    expect(paneOpen.paneOpenMs).toBeLessThanOrEqual(liveCase.paneOpenTimeoutMs);
    expect(decisionPlan.bodyText).toContain("HTML Rewriting");
    expect(decisionPlan.bodyText).toContain("continuity shell");
    expect(decisionPlan.bodyText).toContain("no write yet");
    expect(preview.bodyText).toContain("= bundle-only preview");
    expect(preview.bodyText).toContain("plan-summary.txt");
  });

  test("Topological Intelligence keeps the overlay ambiguity inspectable", async ({
    page,
  }, testInfo) => {
    const liveCase = LIVE_CASES.topologicalIntelligence;
    const paneOpen = await openLivePlanWithDiagnostics(page, liveCase, testInfo);

    const summary = await readInspectorPaneState(page, paneOpen.paneIndex);
    const summaryRows = tableRowsToMap(summary.tables[0]);

    await activatePaneTab(page, paneOpen.paneIndex, "Page write/update plan");
    const decisionPlan = await readInspectorPaneState(page, paneOpen.paneIndex);

    await activatePaneTab(page, paneOpen.paneIndex, "Materialization preview");
    const preview = await readInspectorPaneState(page, paneOpen.paneIndex);

    await attachJson(testInfo, "topological-intelligence-collection-summary.json", summary);
    await attachJson(testInfo, "topological-intelligence-page-plan.json", decisionPlan);
    await attachJson(testInfo, "topological-intelligence-materialization-preview.json", preview);
    await attachPaneOpenTiming(testInfo, liveCase, summaryRows, paneOpen);

    expect(summaryRows["Collection path"]).toContain("Topological Intelligence");
    expect(Number(summaryRows["Imported entries"])).toBeGreaterThan(0);
    expect(paneOpen.paneOpenMs).toBeLessThanOrEqual(liveCase.paneOpenTimeoutMs);
    expect(decisionPlan.bodyText).toContain("Overlay");
    expect(decisionPlan.bodyText).toContain("Manipulation topological overlay");
    expect(decisionPlan.bodyText).toContain("Topological overlay");
    expect(decisionPlan.bodyText).toContain("new topic proposal");
    expect(decisionPlan.bodyText).toContain("arrangement only");
    expect(decisionPlan.bodyText).toContain("Broader-neighborhood/editorial evidence");
    expect(preview.bodyText).toContain("overlay-topic");
    expect(preview.bodyText).toContain("hyperdoc/Overlay.html");
  });

  test("Plastics Packaging makes thin generic proposals visible before any write", async ({
    page,
  }, testInfo) => {
    const liveCase = LIVE_CASES.plasticsPackaging;
    const paneOpen = await openLivePlanWithDiagnostics(page, liveCase, testInfo);

    const summary = await readInspectorPaneState(page, paneOpen.paneIndex);
    const summaryRows = tableRowsToMap(summary.tables[0]);

    await activatePaneTab(page, paneOpen.paneIndex, "Page write/update plan");
    const decisionPlan = await readInspectorPaneState(page, paneOpen.paneIndex);

    await activatePaneTab(page, paneOpen.paneIndex, "Materialization preview");
    const preview = await readInspectorPaneState(page, paneOpen.paneIndex);

    await attachJson(testInfo, "plastics-packaging-collection-summary.json", summary);
    await attachJson(testInfo, "plastics-packaging-page-plan.json", decisionPlan);
    await attachJson(testInfo, "plastics-packaging-materialization-preview.json", preview);
    await attachPaneOpenTiming(testInfo, liveCase, summaryRows, paneOpen);

    expect(summaryRows["Collection path"]).toContain("Plastics Packaging");
    expect(Number(summaryRows["Imported entries"])).toBeGreaterThan(0);
    expect(paneOpen.paneOpenMs).toBeLessThanOrEqual(liveCase.paneOpenTimeoutMs);
    expect(decisionPlan.bodyText).toContain("Research");
    expect(decisionPlan.bodyText).toContain("Environmental justice");
    expect(decisionPlan.bodyText).toContain("Traditional ecological knowledge");
    expect(decisionPlan.bodyText).toContain("Notes/keywords/tag evidence");
    expect(decisionPlan.bodyText).toContain("new topic proposal");
    expect(preview.bodyText).toContain("research-topic");
    expect(preview.bodyText).toContain("Traditional ecological knowledge.html");
    expect(preview.bodyText).toContain("hyperdoc/topics.lisp");
  });
});
