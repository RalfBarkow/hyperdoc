;;; Written by emitter-crosscheck.lisp in its own process with Topic Maps 5a4a66850403cdfe2755c6c88083a8e31af89628.

(:PURPOSE
 "The project CTM emitter on the page Implementation Assignments followed by the addition, with the draft dictionary as a proposed dictionary; nothing written but this record."
 :STARTED-AT "2026-10-27T13:15:13Z" :FINISHED-AT "2026-10-27T13:15:13Z" :LISP "SBCL 2.4.10" :ASDF "3.3.1" :TOPIC-MAPS
 (:DIRECTORY "/Users/rgb/workspace/topic-maps-hyperdoc-5a4a668/" :COMMIT "5a4a66850403cdfe2755c6c88083a8e31af89628" :CLEAN COMMON-LISP:T
  :PINNED COMMON-LISP:T)
 :HYPERDOC-ROOT "/Users/rgb/workspace/hyperdoc-dreyeck-ch/" :INPUTS
 (:ADDITION-SHA256 "274ef8953a8bbff3ac04f015b7bf744b1c52889b3dcb5b26fbc03afab960e184" :DICTIONARY-SHA256
  "2421297f290004db02d8a07260f91f5e1e2a19e4a0405b0cfd614be06a9876a6" :PAGE-SHA256
  "643bccccf0cffa0aee20423a9ae2c939246fb4c95316c541a358297363ea38f8" :RETAINED-CTM-SHA256
  "f4f04bb49ce3b762b3e1c0bccf9e177e11785d33db87e8c0d043b04820b540d3")
 :BASELINE (:CTM-EQUALS-RETAINED COMMON-LISP:T :CTM-SHA256 "f4f04bb49ce3b762b3e1c0bccf9e177e11785d33db87e8c0d043b04820b540d3")
 :WITH-PROPOSALS
 (:REFUSED COMMON-LISP:NIL :PROPOSALS
  (("tmd" "work item" "Deploying Topic Maps with HyperDoc on dreyeck.ch")
   ("tmd-deployment" "deliverable" "Topic Maps operating with HyperDoc on dreyeck.ch")
   ("tmd-wp-1" "work package" "1 Verified Topic Maps Source Distribution") ("tmd-2" "deliverable" "2 Integrated HyperDoc Catalog Package")
   ("tmd-wp-2-1" "work package" "2.1 Catalog package definition")
   ("tmd-wp-2-2" "work package" "2.2 Provenance dispatch of the Topic Maps readings")
   ("tmd-wp-2-3" "work package" "2.3 Catalog startup policy") ("tmd-wp-3" "work package" "3 Inspectable Project Documentation")
   ("tmd-wp-4" "work package" "4 Validated Linux Deployment Candidate") ("tmd-wp-5" "work package" "5 Operational HyperDoc Deployment")
   ("tmd-p1" "plan step" "Export, pin and verify the snapshot") ("tmd-p2" "plan step" "Define the Catalog package")
   ("tmd-p3" "plan step" "Dispatch the Topic Maps readings by provenance") ("tmd-p4" "plan step" "Enforce the startup policy")
   ("tmd-p5" "plan step" "Correct the guard's method identities") ("tmd-p6" "plan step" "Build the HyperDoc review reading")
   ("tmd-p7" "plan step" "Keep the snapshot alive for a reading session") ("tmd-p8" "plan step" "Build, check and stage on x86_64-linux")
   ("tmd-p9" "plan step" "Activate and verify the deployment") ("tmd-pre-change" "precondition" "Authorization to change tested files")
   ("tmd-pre-commit" "precondition" "Candidate committed on approval") ("tmd-pre-push" "precondition" "Approval to push dreyeck.ch")
   ("tmd-pre-archive" "precondition" "Archive obtainable by the builder")
   ("tmd-pre-builder" "precondition" "Independent x86_64-linux builder") ("tmd-pre-server" "precondition" "Server state from the operator")
   ("tmd-pre-exposure" "precondition" "Exposure decision") ("tmd-pre-activation" "precondition" "Approval to activate"))
  :DECLARED-TMD COMMON-LISP:NIL :PROPOSED-STATEMENTS
  (("tmd-deployment" "work:relation/decomposes-into" "tmd-wp-1") ("tmd-deployment" "work:relation/decomposes-into" "tmd-2")
   ("tmd-deployment" "work:relation/decomposes-into" "tmd-wp-3") ("tmd-deployment" "work:relation/decomposes-into" "tmd-wp-4")
   ("tmd-deployment" "work:relation/decomposes-into" "tmd-wp-5") ("tmd-2" "work:relation/decomposes-into" "tmd-wp-2-1")
   ("tmd-2" "work:relation/decomposes-into" "tmd-wp-2-2") ("tmd-2" "work:relation/decomposes-into" "tmd-wp-2-3")
   ("tmd-p1" "work:relation/produces" "tmd-wp-1") ("tmd-p2" "work:relation/produces" "tmd-wp-2-1")
   ("tmd-p3" "work:relation/produces" "tmd-wp-2-2") ("tmd-p4" "work:relation/produces" "tmd-wp-2-3")
   ("tmd-p5" "work:relation/produces" "tmd-wp-2-3") ("tmd-p6" "work:relation/produces" "tmd-wp-3")
   ("tmd-p7" "work:relation/produces" "tmd-wp-3") ("tmd-p8" "work:relation/produces" "tmd-wp-4")
   ("tmd-p9" "work:relation/produces" "tmd-wp-5") ("tmd-p2" "work:relation/depends-on" "tmd-p1")
   ("tmd-p3" "work:relation/depends-on" "tmd-p1") ("tmd-p4" "work:relation/depends-on" "tmd-p2")
   ("tmd-p5" "work:relation/depends-on" "tmd-p4") ("tmd-p5" "work:relation/depends-on" "tmd-pre-change")
   ("tmd-p6" "work:relation/depends-on" "tmd-p3") ("tmd-p6" "work:relation/depends-on" "tmd-p4")
   ("tmd-p7" "work:relation/depends-on" "tmd-p6") ("tmd-p8" "work:relation/depends-on" "tmd-p5")
   ("tmd-p8" "work:relation/depends-on" "tmd-pre-commit") ("tmd-p8" "work:relation/depends-on" "tmd-pre-push")
   ("tmd-p8" "work:relation/depends-on" "tmd-pre-archive") ("tmd-p8" "work:relation/depends-on" "tmd-pre-builder")
   ("tmd-p8" "work:relation/depends-on" "tmd-pre-server") ("tmd-p9" "work:relation/depends-on" "tmd-p8")
   ("tmd-p9" "work:relation/depends-on" "tmd-pre-exposure") ("tmd-p9" "work:relation/depends-on" "tmd-pre-activation"))
  :ASSIGNMENTS
  (("cc-2026-10-26-topic-maps-deployment-design" "Claude Code: Design the deployment of Topic Maps with HyperDoc on dreyeck.ch"
    (("work-item" "tmd")))
   ("cc-2026-10-26-topic-maps-local-packaging" "Claude Code: Package Topic Maps b2eecffa locally as hyperdoc-catalog-topic-maps"
    (("work-item" "tmd")))
   ("cc-2026-10-27-topic-maps-deployment-review" "Claude Code: Review the Topic Maps deployment candidate in HyperDoc"
    (("work-item" "tmd") ("delivers" "tmd-wp-3")))
   ("cc-2026-10-27-topic-maps-deployment-wbs-proposal" "Claude Code: Propose the deployment's WBS, WBS Dictionary and plan"
    (("work-item" "tmd"))))
  :EVIDENCE-ENTRIES
  (("cc-2026-10-26-topic-maps-deployment-design/tmd-design-document" :EVIDENCE-NOTE)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-run-archive-verification" :EXECUTION-REPORT)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-note-archive-controls" :EVIDENCE-NOTE)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-run-package-contract" :EXECUTION-REPORT)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-run-executable-contract" :EXECUTION-REPORT)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-run-production-check" :EXECUTION-REPORT)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-run-unchanged-linux" :EXECUTION-REPORT)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-run-unchanged-darwin" :EXECUTION-REPORT)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-note-changed-wrapper" :EVIDENCE-NOTE)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-run-checkout-ctm-review" :EXECUTION-REPORT)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-run-checkout-22u" :EXECUTION-REPORT)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-run-checkout-snapshot-verifier" :EXECUTION-REPORT)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-run-browser-review-checkout" :EXECUTION-REPORT)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-run-browser-review-snapshot" :EXECUTION-REPORT)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-run-browser-22u" :EXECUTION-REPORT)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-note-mutants" :EVIDENCE-NOTE)
   ("cc-2026-10-26-topic-maps-local-packaging/tmd-note-tested-files" :EVIDENCE-NOTE)
   ("cc-2026-10-27-topic-maps-deployment-review/tmd-run-asdf-collision-probe" :EXECUTION-REPORT)
   ("cc-2026-10-27-topic-maps-deployment-review/tmd-note-snapshot-collected" :EVIDENCE-NOTE)
   ("cc-2026-10-27-topic-maps-deployment-wbs-proposal/tmd-note-emitter-crosscheck" :EVIDENCE-NOTE))
  :PROPOSED-ENTRIES
  (("tmd-wp-1" ("tmd-archive-equals-commit" "tmd-snapshot-verifies-without-git" "tmd-builder-obtains-archive"))
   ("tmd-wp-2-1" ("tmd-package-contract" "tmd-production-unchanged")) ("tmd-wp-2-2" ("tmd-ctm-review" "tmd-22u-inspector"))
   ("tmd-wp-2-3" ("tmd-startup-suite" "tmd-executable-contract" "tmd-asdf-methods-preserved"))
   ("tmd-wp-3" ("tmd-reading-suite" "tmd-session-root")) ("tmd-wp-4" ("tmd-linux-build" "tmd-host-staging"))
   ("tmd-wp-5" ("tmd-process-identity" "tmd-reachability" "tmd-rollback")))
  :EVIDENCE-INPUTS
  (("tmd-archive-equals-commit" "tests/test_topic_maps_snapshot.py" "ac2cbfeb5913e9153ff06489e4a0aed12b7eb97deb5f7484e0baa1ae63bd4598")
   ("tmd-snapshot-verifies-without-git" "dreyeck/tests/source-snapshot.lisp"
    "9e6c1923d11795961e06fdc378332d942634c25bb37d6e2880c60419e519965e")
   ("tmd-package-contract" "scripts/test-catalog-topic-maps.lisp" "e140f272f27b8ecb5213b6330c1a7f4685afccad3c974419aff089099540464f")
   ("tmd-production-unchanged" "scripts/compare-catalog-derivation.py" "ad01af7782c828a3b13e5c2a819aec4a2676a6e8ad52293218b67e27ebb10db4")
   ("tmd-ctm-review" "dreyeck/tests/topic-maps-ctm-review.lisp" "a8ffae4948110ed4c328dbf3cd0d4dc441e0948e26fc64dc01e8a65790c17e3c")
   ("tmd-22u-inspector" "dreyeck/tests/topic-maps-project-example.lisp" "8c830d0b37e8ffa2431b84fc9ac68eca0a0f7ab80a83e8d7ab5072687c136e1b")
   ("tmd-startup-suite" "dreyeck/tests/catalog-topic-maps.lisp" "a9a3a913fa5fba099785d1cc99b7433e009c6987e2c8b7257fa3c2fd06f6c9c1")
   ("tmd-executable-contract" "tests/test_catalog_topic_maps_executable.py"
    "0d0cba1ae1c7f69226691d31106241bb6e95d3126de69552c406e93b57dc01f4")
   ("tmd-reading-suite" "dreyeck/work/topic-maps-deployment-review/tests/review.lisp"
    "feb8f5694ddffeae84d29014741093bbe9fff64ec1ff771a99b368c8aad6f725"))
  :GAPS
  (("work-item-deliverable-unlinked" "tmd/tmd-deployment") ("work-item-deliverable-unlinked" "tmd/tmd-2")
   ("assignment-without-plan-step" "cc-2026-10-26-topic-maps-deployment-design")
   ("assignment-without-plan-step" "cc-2026-10-26-topic-maps-local-packaging")
   ("assignment-without-plan-step" "cc-2026-10-27-topic-maps-deployment-review")
   ("assignment-without-plan-step" "cc-2026-10-27-topic-maps-deployment-wbs-proposal") ("acceptance-requires-declaration" "tmd-wp-1")
   ("acceptance-requires-declaration" "tmd-wp-2-1") ("acceptance-requires-declaration" "tmd-wp-2-2")
   ("acceptance-requires-declaration" "tmd-wp-2-3") ("acceptance-requires-declaration" "tmd-wp-3")
   ("acceptance-requires-declaration" "tmd-wp-4") ("acceptance-requires-declaration" "tmd-wp-5"))
  :CTM-SHA256 "a9f32a4b8281786e7a8e2c4c2603420ab8a532c960c8d7efa3c2f0460b396fc3" :CTM-CHARACTERS 290414 :CTM-LINES-NAMING-TMD 239
  :CTM-EQUALS-RETAINED COMMON-LISP:NIL)
 :UNCHANGED (:TREE COMMON-LISP:T :RETAINED-CTM COMMON-LISP:T :SOURCE-PAGES COMMON-LISP:T) :TREE-DIFF-SHA256
 "9b45a8ce892b92a4d5dd1918ef59e17cdf1e23db2efc6d572cf1c8c19635cf78")
