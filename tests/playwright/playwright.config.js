const path = require("path");
const { defineConfig, devices } = require("@playwright/test");

const defaultPort = process.env.HYPERDOC_PORT || "18080";
const explicitBootUrl = process.env.HYPERDOC_BASE_URL || null;
const bootUrl = explicitBootUrl || `http://127.0.0.1:${defaultPort}/boot.html`;

module.exports = defineConfig({
  testDir: __dirname,
  testMatch: /.*\.spec\.js/,
  fullyParallel: false,
  workers: 1,
  timeout: 90_000,
  expect: {
    timeout: 15_000,
  },
  reporter: process.env.CI
    ? [
        ["dot"],
        [
          "html",
          {
            open: "never",
            outputFolder: path.join(
              __dirname,
              "..",
              "..",
              "test-results",
              "playwright-report"
            ),
          },
        ],
      ]
    : [["list"]],
  outputDir: path.join(
    __dirname,
    "..",
    "..",
    "test-results",
    "playwright-artifacts"
  ),
  use: {
    headless: true,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
    ignoreHTTPSErrors: true,
  },
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        browserName: "chromium",
      },
    },
    {
      name: "webkit",
      use: {
        ...devices["Desktop Safari"],
        browserName: "webkit",
      },
    },
  ],
  webServer: explicitBootUrl
    ? undefined
    : {
        command: `env HYPERDOC_PORT=${defaultPort} HYPERDOC_BIND_ADDRESS=127.0.0.1 nix run .`,
        url: bootUrl,
        reuseExistingServer: true,
        timeout: 120_000,
        stdout: "pipe",
        stderr: "pipe",
      },
});
