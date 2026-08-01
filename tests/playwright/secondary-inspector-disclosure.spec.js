"use strict";

const { test, expect } = require("@playwright/test");
const {
  exactTextPattern,
  openHyperDoc,
  openTextPageFromHyperDoc,
  pane,
  waitForPaneLoadingBoundary,
} = require("./hyperdoc-inspector");

const pageTitle = "Mobile progressive chrome in HyperDoc";

function namedTab(currentPane, title) {
  return currentPane
    .locator(".inspector-tabs button")
    .filter({ hasText: exactTextPattern(title) })
    .first();
}

async function openDisclosurePage(page) {
  await openHyperDoc(page);
  await openTextPageFromHyperDoc(page, pageTitle);
  await waitForPaneLoadingBoundary(page, 2);
  return pane(page, 2);
}

async function inspectorIdentity(currentPane) {
  return currentPane.evaluate((paneNode) => ({
    tabs: Array.from(
      paneNode.querySelectorAll(
        ".inspector-tabs button:not([data-inspector-secondary-toggle])"
      )
    ).map((tab) => ({
      id: tab.id,
      title: (tab.textContent || "").replace(/\s+/g, " ").trim(),
    })),
    views: Array.from(paneNode.querySelectorAll(".inspector-view")).map(
      (view) => view.id
    ),
  }));
}

test("secondary inspector views are disclosed without replacing existing views", async ({
  page,
}) => {
  const currentPane = await openDisclosurePage(page);
  const tabs = currentPane.locator(".inspector-tabs");
  const inspect = currentPane.locator("[data-inspector-secondary-toggle]");
  const content = namedTab(currentPane, "Content");
  const source = namedTab(currentPane, "Source");
  const links = namedTab(currentPane, "Links");
  const parseTree = namedTab(currentPane, "Parse tree");
  const before = await inspectorIdentity(currentPane);

  await expect(content).toBeVisible();
  await expect(source).toBeVisible();
  await expect(links).not.toBeVisible();
  await expect(parseTree).not.toBeVisible();
  await expect(inspect).toBeVisible();
  await expect(inspect).toHaveJSProperty("tagName", "BUTTON");
  await expect(inspect).toHaveAttribute("aria-expanded", "false");
  await expect(inspect).toHaveAttribute("aria-controls", await tabs.getAttribute("id"));
  await expect
    .poll(async () => page.evaluate(
      (id) => Boolean(document.getElementById(id)),
      await inspect.getAttribute("aria-controls")
    ))
    .toBe(true);

  await inspect.focus();
  await inspect.press("Enter");
  await expect(inspect).toHaveAttribute("aria-expanded", "true");
  await expect(inspect).toBeFocused();
  await expect(links).toBeVisible();
  await expect(parseTree).toBeVisible();

  await inspect.press("Space");
  await expect(inspect).toHaveAttribute("aria-expanded", "false");
  await expect(inspect).toBeFocused();
  await expect(links).not.toBeVisible();

  await inspect.press("Space");
  await expect(inspect).toHaveAttribute("aria-expanded", "true");
  await expect(links).toBeVisible();
  await links.focus();
  await links.press("Enter");
  await expect(links).toHaveClass(/\bactive\b/);
  await expect(inspect).toHaveAttribute("aria-expanded", "false");
  await expect(inspect).toBeFocused();
  await expect(links).not.toBeVisible();
  await expect(content).toBeVisible();
  await expect(source).toBeVisible();

  expect(await inspectorIdentity(currentPane)).toEqual(before);
});

test("a primary-only inspector tab row has no Inspect disclosure", async ({
  page,
}) => {
  await openHyperDoc(page);
  const fixture = page.locator('[data-secondary-disclosure-fixture="true"]');
  await page.evaluate(() => {
    const paneNode = document.createElement("section");
    paneNode.className = "inspector-pane";
    paneNode.dataset.secondaryDisclosureFixture = "true";
    paneNode.innerHTML = `
      <div class="inspector-tabs" id="primary-only-inspector-tabs">
        <button type="button" class="active">Content</button>
        <button type="button">Source</button>
      </div>
      <div class="inspector-view">Primary view fixture</div>
    `;
    document.body.appendChild(paneNode);
    window.hyperdocDomConnect.initCurrentView();
  });

  const content = namedTab(fixture, "Content");
  const source = namedTab(fixture, "Source");
  await expect(fixture).toBeVisible();
  await expect(content).toBeVisible();
  await expect(content).toBeEnabled();
  await expect(source).toBeVisible();
  await expect(source).toBeEnabled();
  await source.focus();
  await expect(source).toBeFocused();
  await expect(fixture.locator("[data-inspector-secondary-toggle]")).toHaveCount(0);
});
