# Issue #7: local journal restart repair

Integrated repair base: PR #6, `4ef218a6d273e17091f4ee541965a01ae53d39fc`.
This is a separately authorized journal repair, not a deployment or production
acceptance record. The public Common Workspace tools, schemas, enabled-write
contract and authentication rules are unchanged.

## Implementation

- `restore-hyperdoc-local-workspace-journal-streams` validates discovered local
  JSON files before publishing restored streams. The launcher calls it after
  choosing the operator-supplied state directory and before starting the server.
- Subject reads, revision reads and the transition writer restore a subject on
  a cache miss. Workspace reads discover all persisted subjects. Existing files
  are validated even if the subject is already cached.
- The validator checks ownership, schema/storage metadata, filename/subject
  identity, event state identities and contiguous revisions. Parsing, trailing
  data and file-access failures signal
  `hyperdoc-local-workspace-journal-file-error`, without substituting a new base
  history. Restoration does not rewrite or migrate files.
- Writes append to a copy of the recovered stream. The cache is published only
  after the write succeeds. No-event transitions do not call the file writer;
  an existing local pathname remains available in the transition diagnostic.
- The source manifest retains historical extraction spans and explicitly records
  five adapted spans plus the complete repaired journal file hash. The source
  checker verifies unchanged spans and the separately identified replacement.

## Regression replay

With the repository's Nix Lisp dependencies available, run as an unprivileged
user (the unreadable-file case relies on real filesystem permissions):

```sh
nix develop --command python3 scripts/test-dmx-journal-restart.py \
  --artifacts /absolute/path/to/a/new/disposable/journal-test-run
```

The five regression groups cover restart reads/replay; same-subject append;
unchanged-write byte/mtime/inode preservation; multiple subjects; and damaged or
unreadable files. The last group covers malformed JSON, trailing data, unsupported
schema, subject mismatch, inconsistent revisions and mode-000 files. Every case
uses fresh Lisp processes, actual JSON files and the ordinary local transition
sink. Writes are deliberately tested before any explicit restoration or read.

The suite is also included in `checks.<system>.dmx-mcp`. The earlier isolated repair run did not rebuild the full package. The final
integration validation builds the package and focused Nix check; exact commit,
store identities and results are recorded in the PR #6 integration review.

The recorded local run used the existing Nix-packaged SBCL/dependency closure
with this patched source archive, 29 separate unprivileged Lisp processes,
read-only source mounts and Docker `--network=none`. The companion results JSON
and process logs identify the exact steps. All five groups passed.

## Limits

The fixture proves orderly process-exit/restart recovery in a single-writer
sequence. The retained superseding file writer does not establish crash/power-loss
atomicity, fsync durability, simultaneous writer synchronization or safe external
file replacement while an application is running. Those are not claimed fixed.
No production journal, backend endpoint or running service was accessed. No state
migration or cleanup was attempted. Compatibility with unexamined historical
file variants and the production operator's actual directory/permissions remains
a separate acceptance question.

Reconstruction: this document records the implementation and replay path; Lisp
changes are confined to the local journal and launcher. No HyperDoc/FedWiki
publication or live-image inspection is claimed.
