# Human Work-editor demo

From the checkout containing the human-demo acceptance corrections:

```sh
nix develop path:.#workflow-authoring -c sbcl \
  --noinform --no-userinit --script scripts/work-editor-human-demo.lisp
```

Open http://127.0.0.1:18091/ after the terminal prints `Demo:`. This is a
loopback-only authoring image with an isolated, registered temporary HyperBook.
The terminal prints the exact temporary `Work Breakdown.html` source path.
Enter stops the server and removes the fixture. Copied code pages are available
for inspection; their code is not loaded again. All Work effects go to the
temporary declaring page, never the original carrier page or repository pages.

`workflow-authoring` alone is the complete environment for this demo's Work
operations. TALA/D2 is optional. Loading its Inspector/reading extension does
not install its CLI. Without the pinned executable, layout examples show
`TALA unavailable (inspect capability)` instead of a play button. That link
inspects the existing `tala-dependency-status` evidence and its remedy. Source,
native Topicmaps and non-layout examples remain usable. `.#tala` supplies the
optional pinned D2 renderer; it is not required for Work authoring.

## Acceptance paths

- **Point:** initially the exact Work Topic label appears once, followed by
  `Open Work Topic` and `Carrier page: Operations and Change`. The label opens
  the exact Topic; the editor reference keeps the concrete Workspace context;
  the carrier opens the existing, distinct page.
- **Fixture navigation:** Point → Open Work Topic → Work Operations → Change
  work status → Declaring page: Work Breakdown → Content → Structural HyperDoc
  Page Authoring. The authored relative link opens the fixture's Operations and
  Change copy, without a HyperBook lookup error.
- **Status:** Point → Open Work Topic → Work Operations → Change work status →
  Change work status to `"in progress"` → Work request tab → Preview plan →
  Work plan tab → Execute request after revalidation → fresh Workspace →
  Work Breakdown tab → Applied.
- **Relationship:** fresh Workspace → Topicmap → primary-click Structural Lisp
  Source Authoring → Point → Open Work Topic → Work Operations → Create
  relationship → Target: Running Lisp Image Authoring → View tab if necessary
  → Use relation: informs → Work request → Preview plan → Work plan → Execute
  request after revalidation → fresh Workspace → Work Breakdown → Applied.
- **Stale selection:** retain the original Change work status selection pane
  during execution to its right. Return to that original pane and choose
  `"in progress"` again. It refuses as stale without writing or relocating by
  Topic ID. Returning to an ancestor closes panes to its right; do this last.
- **Optional TALA:** initial Workspace → Topicmap → primary-click Topicmap →
  Point → Carrier page: Reading TALA as a Layout Layer → Content → the
  capability reference beside READING-INVARIANT-REPORT (also beside
  READING-LAYOUT-RESULT, READING-GEOMETRY and READING-COMPARISON). Inspect
  `:status :unavailable`, the failed `d2` probe and the optional-shell remedy.
  The `►` beside READING-WORKSPACE still opens a native Git repository/HEAD
  Workspace. These are TALA reading examples, not Work editor operations.

The ordinary `HYPERDOC_CATALOG_HOST=127.0.0.1 nix run .#catalog -- 8080`
starts reading/navigation and unexecuted request inspection. It does not load
the Work authoring executor or the authoring environment and cannot persist
Work edits. This demo explicitly loads the separate authoring-side test system.

The durable live browser witness follows these paths with synthetic DOM input:

```sh
nix develop path:.#workflow-authoring -c sbcl --noinform --no-userinit \
  --non-interactive --eval '(require :asdf)' \
  --eval '(asdf:load-system "dreyeck/work/authoring/tests")' \
  --eval '(dreyeck/work/editor/tests:run-live-editor-witness :port 18091 :linger 0)'
```

Connect a browser after LISTENING. The witness checks missing-TALA evidence and
continued navigation, then complete status, relationship and stale paths on the
same live connection. Repository Work page contents are compared before/after.
