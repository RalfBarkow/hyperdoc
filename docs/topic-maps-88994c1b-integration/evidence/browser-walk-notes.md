# Browser walk of the served reading (hand-recorded observations, 2026-10-28)

Not an automated test: these are what I observed in the in-app browser. Server: `dreyeck/work/topic-maps-task-1e-review/serve.sh 18779`
on 127.0.0.1 only, started for this walk and stopped afterwards (log: served-reading-server.log). Its ASDF origins, from the
server's own startup line: Topic Maps from /nix/store/kna6395gl32f2hl4n3ha4776zm9r0sgb-source/ (the verified 88994c1b snapshot);
HyperDoc from /Users/rgb/workspace/hyperdoc-topic-maps-88994c1b/ (this candidate).

Walked, in the Catalog's Inspector: Catalog -> book "Re-pinning Topic Maps to 88994c1b" -> Main page; the Pins view (four rows, each "yes",
all 88994c1b9e1edbf13e665e984a5c9c3b2cdf7575); Task 1C and Task 1E (links to the independent review record and the commit record, both render
with their file's text); The 88994c1b Snapshot; Project Workspace on 88994c1b (five timing rows, model counts); The Stage 1 CTM and the Proposed
Work Packages (says proposed, not accepted; says the 107-113 s readings were of an earlier CTM state); Remaining Requirements (names Linux, memory,
Stage 2, high-arity, NFC, Catalog suite, the older reading's failing check, deployment, uncommitted); Code pages tab (two code pages; source rendered);
the function link next-association-merge opened the Inspector function view with "Source code" (the indexed search) and "Callers"
(topic-maps.tmdm::normalize-associations).

Not observed: Print/Operations/Playground tabs were not used. The first server (before two page edits) was restarted so the walk of the
function links ran against the final pages. The reading defines no button, so no run was possible from it; the server log has no test,
suite or Git line.
