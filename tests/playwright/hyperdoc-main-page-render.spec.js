"use strict";

const { test, expect } = require("@playwright/test");
const {
  attachJson,
  exactTextPattern,
  gotoCatalog,
  pane,
  settleInspectorBindings,
} = require("./hyperdoc-inspector");

async function readMainPageBodyState(hyperdocPane) {
  return hyperdocPane.evaluate((paneNode) => {
    function rectData(node) {
      if (!node) {
        return null;
      }
      const rect = node.getBoundingClientRect();
      return {
        top: rect.top,
        left: rect.left,
        right: rect.right,
        bottom: rect.bottom,
        width: rect.width,
        height: rect.height,
      };
    }

    const activeView = paneNode.querySelector(".inspector-view:not([hidden])");
    const root =
      activeView && activeView.querySelector(".hyperdoc-connect-provider-root");
    const heading = root && root.querySelector("h1");
    const paragraph = root && root.querySelector("p");
    const firstChild = root && root.firstElementChild;
    const controls =
      activeView && activeView.querySelector(".hyperdoc-dom-connect-controls");
    const paneStyle = window.getComputedStyle(paneNode);
    const activeViewStyle = activeView ? window.getComputedStyle(activeView) : null;
    const surface =
      activeView && activeView.querySelector(".hyperdoc-connect-provider-surface");
    const surfaceStyle = surface ? window.getComputedStyle(surface) : null;
    const rootStyle = root ? window.getComputedStyle(root) : null;
    const firstChildStyle = firstChild ? window.getComputedStyle(firstChild) : null;
    const headingStyle = heading ? window.getComputedStyle(heading) : null;
    const paragraphStyle = paragraph ? window.getComputedStyle(paragraph) : null;
    const paneRect = rectData(paneNode);
    const activeViewRect = rectData(activeView);
    const surfaceRect = rectData(surface);
    const rootRect = rectData(root);
    const firstChildRect = rectData(firstChild);
    const headingRect = rectData(heading);
    const paragraphRect = rectData(paragraph);
    return {
      paneRect,
      paneOverflow: paneStyle?.overflow || null,
      paneColor: paneStyle?.color || null,
      activeViewRect,
      activeViewDisplay: activeViewStyle?.display || null,
      activeViewVisibility: activeViewStyle?.visibility || null,
      activeViewOverflow: activeViewStyle?.overflow || null,
      surfaceDisplay: surfaceStyle?.display || null,
      surfaceVisibility: surfaceStyle?.visibility || null,
      surfaceRect,
      surfaceHtml:
        surface?.outerHTML?.replace(/\s+/g, " ").trim().slice(0, 2500) || null,
      controlsHtml:
        controls?.outerHTML?.replace(/\s+/g, " ").trim().slice(0, 2500) || null,
      rootText: root?.innerText?.replace(/\s+/g, " ").trim() || "",
      rootChildCount: root?.children?.length || 0,
      rootClientHeight: root?.clientHeight || 0,
      rootDisplay: rootStyle?.display || null,
      rootVisibility: rootStyle?.visibility || null,
      rootColor: rootStyle?.color || null,
      rootRect,
      firstChildTag: firstChild?.tagName || null,
      firstChildClass: firstChild?.className || null,
      firstChildDisplay: firstChildStyle?.display || null,
      firstChildVisibility: firstChildStyle?.visibility || null,
      firstChildRect,
      firstChildHtml:
        firstChild?.outerHTML?.replace(/\s+/g, " ").trim().slice(0, 300) || null,
      headingText: heading?.innerText?.replace(/\s+/g, " ").trim() || "",
      headingDisplay: headingStyle?.display || null,
      headingVisibility: headingStyle?.visibility || null,
      headingColor: headingStyle?.color || null,
      headingRect,
      paragraphText: paragraph?.innerText?.replace(/\s+/g, " ").trim() || "",
      paragraphDisplay: paragraphStyle?.display || null,
      paragraphVisibility: paragraphStyle?.visibility || null,
      paragraphColor: paragraphStyle?.color || null,
      paragraphHeight: paragraph?.getBoundingClientRect().height || 0,
      paragraphRect,
      elementAtRootOrigin: (() => {
        if (!rootRect) {
          return null;
        }
        const element = document.elementFromPoint(rootRect.left + 16, rootRect.top + 16);
        return element
          ? {
              tag: element.tagName,
              className: element.className || "",
              text:
                element.innerText?.replace(/\s+/g, " ").trim().slice(0, 120) || "",
            }
          : null;
      })(),
      ancestorChain: root
        ? (() => {
            const chain = [];
            let current = root;
            while (current && current !== paneNode) {
              const style = window.getComputedStyle(current);
              chain.push({
                tag: current.tagName,
                className: current.className || "",
                hidden: !!current.hidden,
                display: style.display,
                visibility: style.visibility,
                position: style.position,
                rect: rectData(current),
              });
              current = current.parentElement;
            }
            return chain;
          })()
        : [],
    };
  });
}

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

  await gotoCatalog(page);
  const catalogPane = pane(page, 0);
  await catalogPane
    .locator("td")
    .filter({ hasText: exactTextPattern("HyperDoc") })
    .first()
    .click();
  await expect
    .poll(() => page.locator(".inspector-pane").count(), { timeout: 20_000 })
    .toBeGreaterThan(1);
  const hyperdocPane = pane(page, 1);
  await expect(hyperdocPane).toBeVisible({ timeout: 20_000 });
  await expect(
    hyperdocPane.locator(".inspector-tabs button.active")
  ).toHaveText(exactTextPattern("Main page"));
  await expect
    .poll(
      () =>
        hyperdocPane.evaluate((paneNode) => {
          const activeView = paneNode.querySelector(".inspector-view:not([hidden])");
          const root =
            activeView &&
            activeView.querySelector(".hyperdoc-connect-provider-root");
          return root?.textContent?.replace(/\s+/g, " ").trim().length || 0;
        }),
      { timeout: 20_000 }
    )
    .toBeGreaterThan(0);
  const initialState = await readMainPageBodyState(hyperdocPane);
  await settleInspectorBindings(page, 2000);
  const finalState = await readMainPageBodyState(hyperdocPane);
  const dockActions = await hyperdocPane.evaluate((paneNode) =>
    Array.from(
      paneNode.querySelectorAll(".hyperdoc-dock-action:not([hidden])")
    ).map((node) => node.textContent?.replace(/\s+/g, " ").trim() || "")
  );

  await attachJson(testInfo, "hyperdoc-main-page-pane.json", {
    initialState,
    finalState,
    dockActions,
  });
  await attachJson(testInfo, "hyperdoc-main-page-console.json", {
    consoleErrors,
    pageErrors,
  });

  await expect(
    hyperdocPane.locator(".hyperdoc-connect-provider-root h1")
  ).toHaveText("HyperDoc");
  await expect(
    hyperdocPane.locator(".hyperdoc-connect-provider-root .hyperbook-page")
  ).toContainText(
    "HyperDoc is a hypertext documentation component for computational systems."
  );
  expect(initialState.headingText).toBe("HyperDoc");
  expect(initialState.paragraphText).toContain(
    "HyperDoc is a hypertext documentation component for computational systems."
  );
  expect(finalState.headingText).toBe("HyperDoc");
  expect(finalState.paragraphText).toContain(
    "HyperDoc is a hypertext documentation component for computational systems."
  );
  expect(finalState.rootText).toContain(
      "HyperDoc is a hypertext documentation component for computational systems."
  );
  expect(finalState.rootChildCount).toBeGreaterThanOrEqual(1);
  expect(finalState.rootClientHeight).toBeGreaterThan(0);
  expect(finalState.rootDisplay).toBe("block");
  expect(finalState.rootVisibility).toBe("visible");
  expect(finalState.rootRect?.height || 0).toBeGreaterThan(0);
  expect(finalState.rootRect?.width || 0).toBeGreaterThan(0);
  expect(finalState.rootColor).toBe("rgb(0, 0, 0)");
  expect(finalState.firstChildTag).toBe("DIV");
  expect(finalState.firstChildClass).toContain("hyperbook-page");
  expect(finalState.firstChildDisplay).toBe("block");
  expect(finalState.firstChildVisibility).toBe("visible");
  expect(finalState.firstChildRect?.height || 0).toBeGreaterThan(0);
  expect(finalState.headingDisplay).toBe("block");
  expect(finalState.headingVisibility).toBe("visible");
  expect(finalState.headingColor).toBe("rgb(0, 0, 0)");
  expect(finalState.headingRect?.height || 0).toBeGreaterThan(0);
  expect(finalState.paragraphDisplay).toBe("block");
  expect(finalState.paragraphVisibility).toBe("visible");
  expect(finalState.paragraphColor).toBe("rgb(0, 0, 0)");
  expect(finalState.paragraphHeight).toBeGreaterThan(0);
  expect(dockActions).toEqual(
    expect.arrayContaining(["Connect", "Annotation"])
  );
  expect(dockActions).not.toContain("Inspect");
});
