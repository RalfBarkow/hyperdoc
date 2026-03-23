"use strict";

const { test, expect } = require("@playwright/test");
const {
  activatePaneTab,
  attachJson,
  exactTextPattern,
  openHyperDoc,
  pane,
  settleInspectorBindings,
} = require("./hyperdoc-inspector");

function staleSendErrors(messages) {
  return (messages || []).filter((message) =>
    /ws is null|cannot read (properties|property) of null.*send|can't access property "send"|readyState/i.test(
      String(message || "")
    )
  );
}

async function closeWebSocketNormally(page) {
  return page.evaluate(() => {
    return new Promise((resolve, reject) => {
      const currentWs = window.ws;
      if (!currentWs) {
        resolve({
          code: null,
          reason: null,
          wsNull: window.ws === null,
          wsReadyState: window.ws?.readyState ?? null,
          wsHasSend: !!(window.ws && typeof window.ws.send === "function"),
          connectionState: window.clog?.connection_state || null,
          disconnectedMessage: window.clog?.disconnected_message || null,
          bannerText:
            document.getElementById("clog-disconnected-banner")?.textContent?.trim() ||
            null,
        });
        return;
      }

      const timeoutId = window.setTimeout(() => {
        reject(new Error("Timed out waiting for websocket normal close"));
      }, 15_000);

      currentWs.addEventListener(
        "close",
        (event) => {
          window.setTimeout(() => {
            window.clearTimeout(timeoutId);
            resolve({
              code: event.code,
              reason: event.reason,
              wsNull: window.ws === null,
              wsReadyState: window.ws?.readyState ?? null,
              wsHasSend: !!(window.ws && typeof window.ws.send === "function"),
              connectionState: window.clog?.connection_state || null,
              disconnectedMessage: window.clog?.disconnected_message || null,
              bannerText:
                document.getElementById("clog-disconnected-banner")?.textContent?.trim() ||
                null,
              htmlState:
                document.documentElement?.getAttribute("data-clog-connection-state") ||
                null,
              bodyState:
                document.body?.getAttribute("data-clog-connection-state") || null,
            });
          }, 0);
        },
        { once: true }
      );

      currentWs.close(1000, "playwright normal close");
    });
  });
}

async function readDisconnectedState(page) {
  return page.evaluate(() => ({
    wsNull: window.ws === null,
    wsReadyState: window.ws?.readyState ?? null,
    wsHasSend: !!(window.ws && typeof window.ws.send === "function"),
    connectionState: window.clog?.connection_state || null,
    disconnectedMessage: window.clog?.disconnected_message || null,
    bannerText:
      document.getElementById("clog-disconnected-banner")?.textContent?.trim() || null,
    htmlState:
      document.documentElement?.getAttribute("data-clog-connection-state") || null,
    bodyState: document.body?.getAttribute("data-clog-connection-state") || null,
    paneCount: document.querySelectorAll(".inspector-pane").length,
  }));
}

test("Coachmark page entry degrades cleanly after websocket normal close", async ({
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

  await openHyperDoc(page);
  await activatePaneTab(page, 1, "Text pages");
  const hyperdocPane = pane(page, 1);
  const pageCell = hyperdocPane
    .locator("td")
    .filter({ hasText: exactTextPattern("Coachmark bibliography authoring plan") })
    .first();
  await expect(pageCell).toBeVisible({ timeout: 20_000 });

  const closeState = await closeWebSocketNormally(page);
  await expect(page.locator("#clog-disconnected-banner")).toBeVisible({
    timeout: 20_000,
  });
  await expect(page.locator("#clog-disconnected-banner")).toContainText(
    "Disconnected from HyperDoc"
  );
  await expect(page.locator("#clog-disconnected-banner")).toContainText(
    "Clicks will not open new panes until you reload to reconnect."
  );

  const paneCountBefore = await page.locator(".inspector-pane").count();
  await settleInspectorBindings(page);
  await pageCell.click();
  await page.waitForTimeout(500);
  const stateAfterClick = await readDisconnectedState(page);

  await attachJson(testInfo, "websocket-normal-close-state.json", closeState);
  await attachJson(testInfo, "websocket-click-after-close-state.json", stateAfterClick);
  await attachJson(testInfo, "websocket-click-after-close-console.json", {
    consoleErrors,
    consoleWarnings,
    pageErrors,
  });

  expect(closeState.code).toBe(1000);
  expect(closeState.wsNull).toBe(false);
  expect(closeState.wsReadyState).toBe(3);
  expect(closeState.wsHasSend).toBe(true);
  expect(closeState.connectionState).toBe("disconnected");
  expect(closeState.bannerText).toContain("Disconnected from HyperDoc");
  expect(closeState.bannerText).toContain(
    "Clicks will not open new panes until you reload to reconnect."
  );
  expect(closeState.htmlState).toBe("disconnected");
  expect(closeState.bodyState).toBe("disconnected");

  expect(stateAfterClick.paneCount).toBe(paneCountBefore);
  expect(stateAfterClick.wsNull).toBe(false);
  expect(stateAfterClick.wsReadyState).toBe(3);
  expect(stateAfterClick.wsHasSend).toBe(true);
  expect(stateAfterClick.connectionState).toBe("disconnected");
  expect(stateAfterClick.bannerText).toContain("Disconnected from HyperDoc");
  expect(stateAfterClick.bannerText).toContain(
    "Clicks will not open new panes until you reload to reconnect."
  );
  expect(stateAfterClick.disconnectedMessage).toContain(
    "Clicks will not open new panes until you reload to reconnect."
  );
  expect(stateAfterClick.htmlState).toBe("disconnected");
  expect(stateAfterClick.bodyState).toBe("disconnected");

  expect(staleSendErrors(consoleErrors)).toEqual([]);
  expect(staleSendErrors(pageErrors)).toEqual([]);
  expect(consoleWarnings).toEqual(
    expect.arrayContaining([expect.stringContaining("Disconnected from HyperDoc")])
  );
});
