"use strict";

const { test, expect } = require("@playwright/test");
const { attachJson, openHyperDoc } = require("./hyperdoc-inspector");

test("HyperDoc Main page renders in the pane", async ({ page }, testInfo) => {
  const consoleErrors = [];
  const pageErrors = [];
  page.on("console", (message) => {
    if (message.type() === "error") {
      consoleErrors.push(message.text());
    }
  });
  page.on("pageerror", (error) => {
    pageErrors.push(error?.message || String(error));
  });

  const hyperdocPane = await openHyperDoc(page);
  const state = await hyperdocPane.evaluate((paneNode) => {
    const activeView = paneNode.querySelector(".inspector-view:not([hidden])");
    const root =
      activeView && activeView.querySelector(".hyperdoc-connect-provider-root");
    return {
      rootText:
        root?.textContent?.replace(/\s+/g, " ").trim() || "",
      dockActions: Array.from(
        paneNode.querySelectorAll(".hyperdoc-dock-action:not([hidden])")
      ).map((node) => node.textContent?.replace(/\s+/g, " ").trim() || ""),
    };
  });

  await attachJson(testInfo, "hyperdoc-main-page-pane.json", state);
  await attachJson(testInfo, "hyperdoc-main-page-console.json", {
    consoleErrors,
    pageErrors,
  });

  await expect(hyperdocPane.locator(".hyperdoc-connect-provider-root")).toContainText(
    "HyperDoc"
  );
  expect(state.rootText.length).toBeGreaterThan(0);
  expect(state.dockActions).toEqual(
    expect.arrayContaining(["Connect", "Inspect", "Annotation"])
  );
});
