# Code ownership of the library paths, per definition

`dreyeck.ch` carries Konrad Hinsen's HyperDoc as library paths (`hyperdoc`, `hyperbook`, `hyperdoc-explorer`, `hyperbook-explorer`, `inspector-hyperdoc`, `hyperbook-fedwiki`,
`hyperbook-wikipedia`, `hyperbook-server`, `hyperdoc.asd`, `hyperbook.asd`). The existing contract (`dreyeck/hyperdoc/library-tests`, RalfBarkow/hyperdoc#17) compares those
paths with upstream's `8a1149197` and with a retained earlier state `401953522` (`+PREVIOUS+`), by Git history. This directory adds what that contract cannot say: **for each
definition in which the fork differs from upstream, why, who should own it, and what the way out is.**

It is a record, not a decision procedure: **no difference is accepted here as permanent, and none is classified as dreyeck-specific by a rule.** Every open entry is `:pending` with a plan,
because which definitions belong to the library, to a reusable extension or to dreyeck is for the maintainers.

| File | What it is | Who changes it |
|---|---|---|
| `manifest.lisp-data` | the definitions of upstream's library at `8a1149197` (key, kind, digest of the canonical source tree, per file) | `scripts/code-ownership.lisp --manifest REF`, once, from Git objects |
| `decisions.lisp-data` | the ownership rules: nature, proposed owner class, target system, plan, priority, basis | a person |
| `inventory.lisp-data` | one entry per measured difference, joined from the two above, the ASDF owner and the commit where the form first stood | `scripts/code-ownership.lisp --inventory` |

The check (`--check`, and `check-library-inventory`) **uses no Git**: it scans the fork's files as syntax (nothing is loaded) and compares them with the manifest and the inventory.
A difference with no entry fails; so does an entry whose difference is gone, an entry for a form that has changed since it was recorded, an entry without the fields its status needs,
a migrated definition that is not found at its new place (or that still differs in the library), and an inventory made against another upstream reference.
`:pending` entries are listed and counted as *not accepted*. The identity of a definition is that of `dreyeck/upstream-assessment` (PR A, RalfBarkow/hyperdoc#20): package qualifiers
are not normalized, which is why a difference that is only printing (`hyperdoc::hd` for `hd`, `(quote x)` for `'x`) shows up as a difference to repair.

## Vocabulary

* **status**: `:pending` (open, with a plan), `:accepted` (documented, with justification, origin and target; none yet), `:migrated` (moved out of the library path, verified at its new place by digest).
* **nature**: `:serialization-only` (same symbols and structure, differently printed), `:behaviour`.
* **category** (the owner class that should own it): `:upstream-owned`, `:dreyeck-owned`, `:reusable-extension`. PR A's assessment reads it as *should own* when it assesses an upstream commit.

## What the inventory finds (34 differences, 55 library files in the manifest)

| Priority | Nature | Entries | What to do |
|---|---|---|---|
| 1 | serialization-only | 5: `hyperbook-explorer/package.lisp` export form (removed and added printing), the two `PAGE-CLASS` methods of `hyperdoc-explorer`, `defgeneric page-class` | Restore upstream's text. Mechanical, no behaviour: library-tests keeps passing for them. |
| 2 | Mech integration (`dreyeck-owned`) | 4: `*mech-plugin-host-url*`, `mech-neighborhood-snapshot`, `mech-json-base64`, the `:mech` method of `render-story-item` | Move to a new `dreyeck/fedwiki-mech` after the two retention seams below. The `:mech` method is an *added* method, so it can be defined from any system. |
| 2 | retention seams (`reusable-extension`) | 8: retained sitemap (`fedwiki`, `fetch-sitemap`, `sitemap-snapshot`), retained page JSON (`fedwiki-page`, `copy-page-json`, `set-page-data`), `make-remote`, and the `hyperbook/fedwiki` dependencies in `hyperbook.asd` | An upstream seam (slot and accessor) or an extension hook; `cl-base64` moves with the Mech definitions, `clog` and `flexi-streams` stay (upstream files use them). `make-remote` is not yet understood beyond its origin. |
| 3 | reusable fixes and options (`reusable-extension`) | 17: code-subdirectory (3), FedWiki initialization (4), context extraction (3), image rendering (3), slug navigation (2), server HOST (2) | Prepare upstream contributions, one coherent change each. Stay as they are until accepted. The initialization group travels with the DNS handler question of RalfBarkow/hyperdoc#13 / #15. |

## The first migration slice: `hyperbook/fedwiki/tests`

`hyperbook.asd` defined `hyperbook/fedwiki/tests`, a *dreyeck* test system of dreyeck's Mech story-item integration, inside the upstream-owned system file. It is now
`dreyeck/fedwiki-mech/tests` in `dreyeck.asd`: same dependencies (`hyperbook/fedwiki`, `clog-moldable-inspector`), same four files in the same order, same entry point
(`run-tests` in the renamed package); the files moved from `tests/` to `dreyeck/tests/` (the browser fixtures they read stay where they are), the browser scripts and `docs/fedwiki-mech-story.md`
point to the new paths, and `dreyeck/catalog-application/tests` depends on the new name. The old system name is retired (nothing else referred to it; the evidence logs of earlier
runs still mention it as history). Verified: the five `FEDWIKI-MECH-*-PASS` lines, `dreyeck/code-ownership/tests`, the unchanged Nix `catalog` check.

Effect on the contract: `hyperbook.asd` loses one difference from upstream (a defsystem that upstream does not have); the historical states `401953522` and `8a1149197` are untouched.

What is **not** migrated yet and why: the Mech *definitions* in `hyperbook-fedwiki/` (above) read retained sitemap and page JSON through slots that only the library files can add; a
move before the seam exists would break them. That is the documented blocker of the fallback slice, and the next slice after the seams.

## Why the strict contract still needs Git, and what runs without it

`dreyeck/hyperdoc/library-tests` reads `8a1149197` and `+PREVIOUS+` from Git objects. The Nix `catalog` check builds from `cleanSource self.outPath`: a source snapshot with **no `.git`**, in a sandbox
without network, so that comparison cannot run there. The manifest and inventory are that comparison's content, stored: `nix build .#checks.<system>.library-inventory` runs `--check` on a
snapshot (and asserts that it has no `.git`). `catalog` itself is unchanged. Neither `+PREVIOUS+` nor the upstream reference is moved, and `library-tests` is not weakened by this PR.

## What the `library-inventory` check is, and is not

It checks that the inventory is **consistent with the files**: every difference from upstream is recorded, no entry is stale or incomplete, a migrated definition stands at its new place.
It is **not an ownership approval**: a `:pending` entry passes it, and that means "documented", not "accepted" (the report counts them as not accepted; 34 of 34 are pending). And it does **not
fix RalfBarkow/hyperdoc#17**: `dreyeck/hyperdoc/library-tests` still compares with `+PREVIOUS+` and `8a1149197` by Git history and stays as it is, failing at the base and here.

## How the check is meant to be run every time (no scheduler, no CI is introduced)

The check is a flake check: `checks.<system>.library-inventory`. It is a pure derivation of the source snapshot. Two things are therefore different and are kept apart here: its **reproducibility** (a property of the check, below) and its **execution** (not yet technically enforced, below):

1. **A result belongs to exactly one state of the sources.** Its inputs are the library paths, the manifest and the inventory themselves. Any change to them is a new derivation, so a cached "pass"
   is never the result for changed sources: the check is reproducible and depends only on those inputs. This is a property of the check, **not a guarantee that it is run**: if nobody builds it after a change,
   nothing re-runs it, and an earlier result can still be quoted as if it were current. Whether a stated result belongs to the head under review has to be checked by the reviewer (the PR description names the commit it was run on).
2. **It is part of the existing acceptance command, if that command is run.** `nix flake check` builds every `checks` attribute, so whoever runs the flake check that already accepts a change to this repository
   also gets `library-inventory` (and `catalog`); running it remains a person's act, not a technical requirement. It can be called alone: `nix build .#checks.x86_64-linux.library-inventory`.

What this does **not** do: the execution is **not yet technically enforced**; nothing forces anybody to run it. There is no required status, no pre-merge hook, no timer. The proposed rule is a review rule, to be adopted or not by the maintainers:
*a change that touches a library path, `docs/code-ownership/` or `scripts/code-ownership.lisp` states the result of `library-inventory` (and of the unchanged `catalog` check) in its PR description,
as this PR does; a reviewer may ask for it.* Making the run mandatory by machine (a required CI job, a branch protection rule) needs infrastructure and is a separate decision that is **not made here**.
When a difference is added on purpose, the same change regenerates the inventory (`scripts/code-ownership.lisp --inventory`) and adds a rule to `decisions.lisp-data`, so the new difference is
visible in review as a new pending entry.

## Limits

* The inventory is a *measurement plus a plan*: it records which definitions differ; it does not prove that a differing definition behaves differently or the same.
* The origin commit is the oldest commit of the file that contains the form's current digest, not necessarily the author of the idea.
* Priorities are proposals. The `make-remote` entry in particular is open.
* The manifest is a stored copy of upstream at one reference; moving the reference is a separate, explicit step that regenerates it.
