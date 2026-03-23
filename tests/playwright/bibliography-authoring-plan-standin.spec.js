"use strict";

const { test, expect } = require("@playwright/test");
const { attachJson } = require("./hyperdoc-inspector");
const { runBibliographyAuthoringPlanStandin } = require("./bibliography-authoring-plan-standin");

function reportInteger(report, key) {
  return Number.parseInt(report[key] || "0", 10);
}

function liveZoteroEnabled() {
  return process.env.HYPERDOC_RUN_ZOTERO_LIVE_TESTS === "1";
}

test("fixture coachmark stand-in proves bibliography readiness before pane opening", async ({}, testInfo) => {
  const result = runBibliographyAuthoringPlanStandin({
    mode: "fixture",
    collection: "coachmark",
    linkText: "coachmark",
  });
  const { report } = result;

  await attachJson(testInfo, "coachmark-standin-report.json", {
    command: result.command,
    report,
  });

  expect(report.ENTRY_PAGE_SELECTION_CLASSIFICATION).toBe("tracked-entry-page-selected");
  expect(report.RUNTIME_SURFACE_INVENTORY_CLASSIFICATION).toBe(
    "runtime-entry-page-with-live-link"
  );
  expect(report.WORKSPACE_VS_FLAKE_MISMATCH_CLASSIFICATION).toBe(
    "tracked-page-no-mismatch-risk"
  );
  expect(report.PLAN_READY).toBe("T");
  expect(report.ARTIFACT_BUNDLE_READY).toBe("T");
  expect(report.FAILURE_CLASSIFICATION_BEFORE_BROWSER).toBe("ready-before-pane-open");
  expect(report.LAST_PROTOCOL_BOUNDARY).toBe("artifact-bundle-written");
  expect(reportInteger(report, "MATERIALIZATION_ENTRY_COUNT")).toBeGreaterThan(0);
  expect(report.PLAN_SUMMARY_PATH).toContain("plan-summary.txt");
});

test.describe("live bibliography authoring-plan stand-in evaluation", () => {
  test.skip(
    !liveZoteroEnabled(),
    "Set HYPERDOC_RUN_ZOTERO_LIVE_TESTS=1 to enable live bibliography stand-in tests."
  );

  test("Plastics Packaging is ready before the pane-open seam", async ({}, testInfo) => {
    const result = runBibliographyAuthoringPlanStandin({
      mode: "live",
      collection: "Plastics Packaging",
      linkText: "Plastics Packaging live plan",
    });
    const { report } = result;

    await attachJson(testInfo, "plastics-packaging-standin-report.json", {
      command: result.command,
      report,
    });

    expect(report.ENTRY_PAGE_SELECTION_CLASSIFICATION).toBe("tracked-entry-page-selected");
    expect(report.RUNTIME_SURFACE_INVENTORY_CLASSIFICATION).toBe(
      "runtime-entry-page-with-live-link"
    );
    expect(report.WORKSPACE_VS_FLAKE_MISMATCH_CLASSIFICATION).toBe(
      "tracked-page-no-mismatch-risk"
    );
    expect(report.PLAN_READY).toBe("T");
    expect(report.ARTIFACT_BUNDLE_READY).toBe("T");
    expect(report.FAILURE_CLASSIFICATION_BEFORE_BROWSER).toBe("ready-before-pane-open");
    expect(report.LAST_PROTOCOL_BOUNDARY).toBe("artifact-bundle-written");
    expect(reportInteger(report, "IMPORTED_ENTRY_COUNT")).toBeGreaterThan(0);
    expect(reportInteger(report, "MATERIALIZATION_ENTRY_COUNT")).toBeGreaterThan(0);
    expect(reportInteger(report, "PLAN_BUILD_MS")).toBeLessThan(60_000);
  });
});
