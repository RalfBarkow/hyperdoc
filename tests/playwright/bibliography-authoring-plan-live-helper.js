"use strict";

const { expect } = require("@playwright/test");
const {
  exactTextPattern,
  pane,
  settleInspectorBindings,
} = require("./hyperdoc-inspector");

function trimText(value, maxLength = 240) {
  const text = String(value || "").replace(/\s+/g, " ").trim();
  if (text.length <= maxLength) {
    return text;
  }
  return `${text.slice(0, Math.max(0, maxLength - 1))}\u2026`;
}

async function installPaneOpenDiagnostics(page, sourcePaneIndex, linkText) {
  const beforePanes = await page.evaluate(({ sourcePaneIndex: paneIndex, targetLinkText }) => {
    function readPanes() {
      return Array.from(document.querySelectorAll(".inspector-pane")).map((paneNode, index) => {
        const activeTab = paneNode.querySelector(".inspector-tabs button.active");
        const titleNode =
          paneNode.querySelector(".inspector-title-bar-object") ||
          paneNode.querySelector(".inspector-title-bar-class");
        const activeView = paneNode.querySelector(".inspector-view:not([hidden])");
        return {
          index,
          title: titleNode?.textContent?.trim() || null,
          activeTab: activeTab?.textContent?.trim() || null,
          bodyPreview:
            activeView?.innerText?.replace(/\s+/g, " ").trim().slice(0, 240) || "",
        };
      });
    }

    const observerState = {
      linkText: targetLinkText,
      sourcePaneIndex: paneIndex,
      currentUrl: window.location.href,
      startedAtMs: null,
      beforePanes: readPanes(),
      samples: [],
    };
    const startedAt = performance.now();
    observerState.startedAtMs = startedAt;

    function sample(label) {
      const panes = readPanes();
      observerState.samples.push({
        label,
        atMs: Math.round(performance.now() - startedAt),
        paneCount: panes.length,
        paneTitles: panes.map((currentPane) => ({
          index: currentPane.index,
          title: currentPane.title,
          activeTab: currentPane.activeTab,
        })),
      });
    }

    if (window.__hyperdocPaneOpenObserver) {
      window.__hyperdocPaneOpenObserver.disconnect();
    }
    window.__hyperdocPaneOpenDiagnostics = observerState;
    sample("observer-installed");
    const observer = new MutationObserver(() => {
      const panes = readPanes();
      const paneTitles = panes.map((currentPane) => ({
        index: currentPane.index,
        title: currentPane.title,
        activeTab: currentPane.activeTab,
      }));
      const lastSample = observerState.samples[observerState.samples.length - 1];
      const changed =
        !lastSample ||
        lastSample.paneCount !== panes.length ||
        JSON.stringify(lastSample.paneTitles) !== JSON.stringify(paneTitles);
      if (changed) {
        sample("mutation");
      }
    });
    observer.observe(document.body, {
      subtree: true,
      childList: true,
      attributes: true,
      attributeFilter: ["hidden", "class", "style", "data-view-title"],
    });
    window.__hyperdocPaneOpenObserver = observer;
    return observerState.beforePanes;
  }, { sourcePaneIndex, targetLinkText: linkText });

  return beforePanes;
}

function classifyPaneOpenDiagnostic(diagnostic) {
  const maxObservedPaneCount = Math.max(
    diagnostic.paneCountAfter,
    ...diagnostic.mutationSamples.map((sample) => sample.paneCount || 0)
  );

  if (maxObservedPaneCount > diagnostic.paneCountBefore) {
    return "rendered-but-not-detected-or-closed";
  }
  if ((diagnostic.pageErrors || []).length > 0) {
    return "crashed-during-render-open";
  }
  if ((diagnostic.consoleErrors || []).length > 0) {
    return "client-error-during-render-open";
  }
  const beforeTitles = JSON.stringify(
    (diagnostic.beforePanes || []).map((currentPane) => [
      currentPane.title,
      currentPane.activeTab,
    ])
  );
  const afterTitles = JSON.stringify(
    (diagnostic.afterPanes || []).map((currentPane) => [
      currentPane.title,
      currentPane.activeTab,
    ])
  );
  if (beforeTitles !== afterTitles) {
    return "rendered-into-existing-pane-or-mutated-without-new-pane";
  }
  return "blocked-or-hung-before-pane-create";
}

async function finalizePaneOpenDiagnostic(
  page,
  {
    linkText,
    sourcePaneIndex,
    paneCountBefore,
    paneOpenTimeoutMs,
    startedAt,
    lastSuccessfulUiStep,
    beforePanes,
    consoleErrors,
    pageErrors,
  }
) {
  return page.evaluate(
    ({
      linkText: targetLinkText,
      sourcePaneIndex: paneIndex,
      paneCountBefore: beforeCount,
      paneOpenTimeoutMs: timeoutMs,
      startedAt: startedAtEpochMs,
      lastSuccessfulUiStep: lastStep,
      beforePanes: panesBefore,
      consoleErrors: loggedConsoleErrors,
      pageErrors: loggedPageErrors,
    }) => {
      function readPanes() {
        return Array.from(document.querySelectorAll(".inspector-pane")).map((paneNode, index) => {
          const activeTab = paneNode.querySelector(".inspector-tabs button.active");
          const titleNode =
            paneNode.querySelector(".inspector-title-bar-object") ||
            paneNode.querySelector(".inspector-title-bar-class");
          const activeView = paneNode.querySelector(".inspector-view:not([hidden])");
          return {
            index,
            title: titleNode?.textContent?.trim() || null,
            activeTab: activeTab?.textContent?.trim() || null,
            bodyPreview:
              activeView?.innerText?.replace(/\s+/g, " ").trim().slice(0, 240) || "",
          };
        });
      }

      const state = window.__hyperdocPaneOpenDiagnostics || { samples: [] };
      if (window.__hyperdocPaneOpenObserver) {
        window.__hyperdocPaneOpenObserver.disconnect();
        window.__hyperdocPaneOpenObserver = null;
      }
      const afterPanes = readPanes();
      return {
        linkText: targetLinkText,
        currentUrl: window.location.href,
        sourcePaneIndex: paneIndex,
        paneCountBefore: beforeCount,
        paneCountAfter: afterPanes.length,
        paneOpenTimeoutMs: timeoutMs,
        elapsedMs: Date.now() - startedAtEpochMs,
        lastSuccessfulUiStep: lastStep,
        beforePanes: panesBefore,
        afterPanes,
        mutationSamples: state.samples || [],
        sourcePaneAfter: afterPanes[paneIndex] || null,
        consoleErrors: loggedConsoleErrors,
        pageErrors: loggedPageErrors,
      };
    },
    {
      linkText,
      sourcePaneIndex,
      paneCountBefore,
      paneOpenTimeoutMs,
      startedAt,
      lastSuccessfulUiStep,
      beforePanes,
      consoleErrors,
      pageErrors,
    }
  );
}

async function openObjectFromTextPageLink(page, paneIndex, linkText, paneOpenTimeoutMs = 30_000) {
  const paneCountBefore = await page.locator(".inspector-pane").count();
  const sourcePane = pane(page, paneIndex);
  const reference = sourcePane
    .locator(".hyperbook-reference")
    .filter({ hasText: exactTextPattern(linkText) })
    .first();
  const startedAt = Date.now();
  let lastSuccessfulUiStep = "start";
  const consoleErrors = [];
  const pageErrors = [];
  const handleConsole = (message) => {
    if (message.type() === "error") {
      consoleErrors.push(trimText(message.text(), 400));
    }
  };
  const handlePageError = (error) => {
    pageErrors.push(trimText(error?.message || error, 400));
  };
  page.on("console", handleConsole);
  page.on("pageerror", handlePageError);
  try {
    const beforePanes = await installPaneOpenDiagnostics(page, paneIndex, linkText);
    await expect(reference).toBeVisible({ timeout: 20_000 });
    lastSuccessfulUiStep = "reference-visible";
    await settleInspectorBindings(page);
    lastSuccessfulUiStep = "bindings-settled";
    await reference.click();
    lastSuccessfulUiStep = "reference-clicked";
    try {
      await expect
        .poll(() => page.locator(".inspector-pane").count(), { timeout: paneOpenTimeoutMs })
        .toBe(paneCountBefore + 1);
      lastSuccessfulUiStep = "pane-count-increased";
      const objectPane = pane(page, paneCountBefore);
      await expect(objectPane).toBeVisible({ timeout: 20_000 });
      lastSuccessfulUiStep = "object-pane-visible";
      await settleInspectorBindings(page);
      lastSuccessfulUiStep = "object-pane-settled";
      const paneOpenDiagnostic = await finalizePaneOpenDiagnostic(page, {
        linkText,
        sourcePaneIndex: paneIndex,
        paneCountBefore,
        paneOpenTimeoutMs,
        startedAt,
        lastSuccessfulUiStep,
        beforePanes,
        consoleErrors,
        pageErrors,
      });
      paneOpenDiagnostic.classification = "opened";
      return {
        pane: objectPane,
        paneIndex: paneCountBefore,
        paneOpenMs: Date.now() - startedAt,
        paneOpenTimeoutMs,
        paneOpenDiagnostic,
      };
    } catch (error) {
      const paneOpenDiagnostic = await finalizePaneOpenDiagnostic(page, {
        linkText,
        sourcePaneIndex: paneIndex,
        paneCountBefore,
        paneOpenTimeoutMs,
        startedAt,
        lastSuccessfulUiStep,
        beforePanes,
        consoleErrors,
        pageErrors,
      });
      paneOpenDiagnostic.classification = classifyPaneOpenDiagnostic(paneOpenDiagnostic);
      error.paneOpenDiagnostic = paneOpenDiagnostic;
      error.message = `${error.message}\n\nPane-open diagnostic:\n${JSON.stringify(
        paneOpenDiagnostic,
        null,
        2
      )}`;
      throw error;
    }
  } finally {
    page.off("console", handleConsole);
    page.off("pageerror", handlePageError);
  }
}

module.exports = {
  openObjectFromTextPageLink,
};
