"use strict";

const { spawnSync } = require("node:child_process");

function parseStandinReport(output) {
  const report = {};
  for (const line of String(output || "").split(/\r?\n/)) {
    const match = line.match(/^([A-Z0-9_]+)=(.*)$/);
    if (!match) {
      continue;
    }
    const [, key, value] = match;
    report[key] = value;
  }
  return report;
}

function runBibliographyAuthoringPlanStandin(options = {}) {
  const mode = options.mode || "live";
  const collection = options.collection || "coachmark";
  const entryPage = options.entryPage || "Bibliography subcollections in HyperDoc";
  const linkText = options.linkText || collection;
  const command = [
    "nix",
    "develop",
    "--command",
    "sbcl",
    "--no-userinit",
    "--script",
    "tools/bibliography-authoring-plan-standin-report.lisp",
    "--mode",
    mode,
    "--collection",
    collection,
    "--entry-page",
    entryPage,
    "--link-text",
    linkText,
  ];
  const result = spawnSync(command[0], command.slice(1), {
    cwd: process.cwd(),
    encoding: "utf8",
    env: process.env,
  });
  const report = parseStandinReport(result.stdout);
  if (result.status !== 0) {
    const error = new Error(
      `Stand-in report command failed (${result.status}): ${result.stderr || result.stdout}`
    );
    error.command = command;
    error.stdout = result.stdout;
    error.stderr = result.stderr;
    error.report = report;
    throw error;
  }
  return {
    command,
    report,
    stdout: result.stdout,
    stderr: result.stderr,
  };
}

module.exports = {
  parseStandinReport,
  runBibliographyAuthoringPlanStandin,
};
