# DMX MCP launcher state boundary


> Superseded operational decision (2026-10-30): the current candidate includes
> the Issue #7 restart repair and may use an explicitly new empty journal epoch.
> Preserve old state untouched; no import is required. See the
> [current operator runbook](dmx-mcp-operator-runbook.md) and
> [repair notes](dmx-journal-restart-repair.md). The earlier findings/results below
> describe their named historical revisions, not the repaired integration head.

Source review, 2026-10-30, of verified PR #6 runtime revision
`e15e36f34fe3d314d162fee244212d7a7fec3dc2`. No Lisp process was started; no production endpoint,
persisted service state or DMX data was accessed for this assessment. This documents
the migration boundary; it does not implement or validate the Journal feature.

The separate investigation Topic **DMX Workspace Journal persistence and legacy
Topics** is tracked in [work item #7](https://github.com/RalfBarkow/hyperdoc/issues/7).
That is a proposed follow-up, not an Acceptance Record or authorization to change
data. No DMX Topic, ISO Topic or accepted Work declaration is created here.

## Distinct state authorities

| State | Evidence in the retained application | What is not established |
| --- | --- | --- |
| Service state tree | Operator-owned root; not a definition of the Journal store | Aggregate directory size does not identify Journal files or free capacity |
| Volatile local Journal streams | Fresh hash table; reads and revisions consult that table | Prior persisted history is not restored by setting a pathname |
| Local JSON files | Deterministic per-subject output path; replace-on-write behavior | File presence does not demonstrate recoverability or merge with new history |
| Journal-related DMX Topics | Existing contract includes legacy inventory/planning and other Journal dependencies | Candidate naming does not justify cleanup; actual data and correctness require separate evidence |

## Bounded source trace

1. [The application entrypoint](../scripts/dmx-mcp-main.lisp), lines 22–28,
   requires `HYPERDOC_MCP_STATE_DIRECTORY` to be absolute and already a directory,
   then assigns it directly to `*hyperdoc-local-workspace-journal-directory*`.
   There is no comparison with the former release's path, state manifest,
   writability check or persisted-stream hydration. It performs no data move,
   copy, deletion or Journal write at this startup assignment.
2. [The retained Journal source](../dmx-mcp/dmx-workspace-journal.lisp), lines
   37–46, initializes `*hyperdoc-local-workspace-journal-streams*` as an empty
   hash in a fresh application process and enables local file writes. Its
   historical directory default is `var/hyperdoc-local-journal/` relative to
   ASDF's `hyperdoc` source directory. The new entrypoint replaces that default;
   neither path is derived from the service WorkingDirectory.
3. `hyperdoc-local-workspace-journal-pathname` and
   `write-hyperdoc-local-workspace-journal-stream` (lines 1946–1964) construct
   a filename from the subject key under the selected directory, ensure parents
   exist and open with `:if-exists :supersede` / `:if-does-not-exist :create`.
4. `hyperdoc-local-workspace-journal-record-transition` (lines 1968–2044)
   takes an existing stream from memory or constructs a new base stream. It
   writes that stream without first reading/merging an existing disk file.
   The write call is not guarded by the presence of new events.
5. `hyperdoc-local-workspace-journal-streams`, `read-hyperdoc-workspace-journal`,
   `read-hyperdoc-topic-journal` and `list-hyperdoc-topic-revisions` (lines
   2288–2390) enumerate/look up memory. There is no persisted-file loader in
   this application closure. A fresh local read can therefore report an empty
   workspace journal or no matching subject despite files being present.
6. [The import boundary](../dmx-mcp/dmx-import.lisp), lines 25–28, retains
   `*workspace-journal-sink* = :hyperdoc-local` and the separate
   `*allow-dmx-workspace-journal-writes* = nil` default. Ordinary
   [workspace-note write hooks](../dmx-mcp/dmx-workspace-notes.lisp) also call
   `record-workspace-transition`; avoiding explicit Journal tool calls is not
   sufficient to exclude local file writes. These defaults and hooks are not
   changed by this scope correction.

The public historical source at
[`591f275...`](https://github.com/RalfBarkow/hyperdoc/blob/591f275fc26ebef7967cc8d3e3fb5a0efc19cc85/hyperdoc/dmx-workspace-journal.lisp)
already contains the source-relative default and superseding writer. The port's
source evidence is repair `f512aa8...`. This is not proof that the installed
release is either revision or that its image lacks extra initialization. Its
actual package, directory mapping and data must not be inferred from Git alone.

## What the launcher can silently do

- **Redirect future output:** a different existing directory passes the startup
  check without a mismatch warning. This is an effective change of storage
  location; the launcher does not relocate old files into it.
- **Ignore old persisted streams:** cold-process reads use memory, even if the
  intended directory and files still exist. Matching old/new pathnames alone
  is not evidence of recovery or Journal correctness.
- **Replace a subject file later:** a retained write can supersede a same-named
  file using a new memory stream, without carrying its prior disk history.
  This is conditional on reaching that write path, not a claim that startup
  overwrites an entire state tree or that production loss has been observed.

The confirmed public Common Workspace contract, including enabled writes, must
be preserved. PR #6 does not fix these Journal behaviors, disable their hooks,
change sinks, invent a loader, copy/migrate state or clean up DMX Topics. Preserve
the original state and permissions; if the operator cannot establish preservation
for a later replacement, leave the candidate unactivated and record that gap in
#7. Turning writes off or starting with an empty store is not an equivalent
migration. The [operator runbook](dmx-mcp-operator-runbook.md) keeps that hold
separate from accepting this source-port scope.

## Evidence limits and next work

This assessment is static source evidence, not a live SLY observation, a new
runtime test or a production Journal inventory. The 8 historical controls,
72 discovery checks, 16 application checks, 11 regression groups and 20 ISO
coexistence checks remain earlier results at `e15e36f...`; they were not repeated
for this documentation-only update. The retained local-Journal fixtures seed
memory and disable file writes. They prove neither restart recovery nor safety
of the running service's persisted state, nor end-to-end Common Workspace writes
after a production replacement.

Follow-up #7 owns private operator evidence, separately authorized read-only
inventory and disposable cold-start/collision/recovery fixtures. Only that later
evidence can justify a separate bounded repair or a proposed disposition of
identified Topics. Cleanup would need a further work item and explicit mutation
authorization. No such work is performed or presumed accepted in PR #6.
