"use strict";

const { test, expect } = require("@playwright/test");
const { attachJson, openHyperDoc } = require("./hyperdoc-inspector");

function emptyIdPayloadMessages(messages) {
  return (messages || []).filter((message) =>
    /clog\[''\]=\$\('#'\)\.get\(0\)|Ignoring empty jQuery selector "#"/.test(
      String(message || "")
    )
  );
}

function carriesEmptyIdPayload(payload) {
  return typeof payload === "string" && payload.includes("clog['']=$('#').get(0)");
}

async function readClogEvalState(page) {
  return page.evaluate(() => ({
    evalSeq: window.__clog_eval_seq || 0,
    lastEvalPayload: window.__clog_last_eval_payload || null,
    connectionState: window.clog?.connection_state || null,
    paneCount: document.querySelectorAll(".inspector-pane").length,
  }));
}

async function exerciseHyperDocBoot(page) {
  await openHyperDoc(page);
  await page.waitForTimeout(1000);
  return readClogEvalState(page);
}

test("HyperDoc boot and reload emit no empty-id CLOG websocket payloads", async ({
  page,
}, testInfo) => {
  const consoleErrors = [];
  const consoleWarnings = [];
  const pageErrors = [];

  page.on("console", (message) => {
    if (message.type() === "error") {
      consoleErrors.push(message.text());
    }
    if (message.type() === "warning") {
      consoleWarnings.push(message.text());
    }
  });
  page.on("pageerror", (error) => {
    pageErrors.push(error?.message || String(error));
  });

  const initialState = await exerciseHyperDocBoot(page);
  await page.reload({ waitUntil: "domcontentloaded" });
  const reloadState = await exerciseHyperDocBoot(page);

  await attachJson(testInfo, "clog-empty-id-runtime.json", {
    initialState,
    reloadState,
    consoleErrors,
    consoleWarnings,
    pageErrors,
  });

  expect(emptyIdPayloadMessages(consoleErrors)).toEqual([]);
  expect(emptyIdPayloadMessages(consoleWarnings)).toEqual([]);
  expect(emptyIdPayloadMessages(pageErrors)).toEqual([]);
  expect(carriesEmptyIdPayload(initialState.lastEvalPayload)).toBe(false);
  expect(carriesEmptyIdPayload(reloadState.lastEvalPayload)).toBe(false);
  expect(initialState.connectionState).toBe("connected");
  expect(reloadState.connectionState).toBe("connected");
  expect(initialState.paneCount).toBeGreaterThan(1);
  expect(reloadState.paneCount).toBeGreaterThan(1);
});
