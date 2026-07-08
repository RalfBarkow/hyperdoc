(:artifact zkn3-import-report-projection-adapter-record
 :kind implementation-record
 :created-from-task
 (!create-hyperdoc-clog-zkn3-import-report-adapter
  :mode :adapter-model-and-views
  :target :hyperdoc
  :input :sexp-fixture-from-Zkn3ImportReport
  :must-not-touch-javafx true
  :must-not-create-resolved-edge true)

 :implementation
 (:repo "/Users/rgb/workspace/hyperdoc"
  :branch "hauptsache"
  :commit "83d324cb"
  :message "feat(inspector): add zkn3 import report projection adapter"
  :paths
  ("hyperdoc.asd"
   "hyperdoc-inspector/zkn3-import-report-projection.lisp"
   "tests/zkn3-import-report-projection-smoke.lisp"))

 :adapter-model
 (:classes
  (zkn3-import-report-projection
   zkn3-unresolved-reference-projection)
  :constructors
  (make-zkn3-import-report-projection
   make-zkn3-unresolved-reference-projection
   make-example-zkn3-import-report-projection)
  :role
  "Mirror Java Zkn3ImportReport facts for HyperDoc/CLOG inspection without owning
   import semantics or resolving references.")

 :views
 ((:subject zkn3-import-report-projection
   :view "Summary"
   :shows (:source :observed-counts :unresolved-reference-count :by-kind :by-reason))

  (:subject zkn3-import-report-projection
   :view "Unresolved references"
   :shows (:sourceNoteId :sourceField :rawReference :referenceKind :reason :order))

  (:subject zkn3-unresolved-reference-projection
   :view "Edge boundary"
   :shows (:rawReference :referenceKind :reason :created-Zkn3LinkRecord false :created-resolved-edge false))

  (:subject zkn3-import-report-projection
   :view "Evidence"
   :shows (:implementation-commit :verification-commits :design-artifacts)))

 :real-source-example
 (:source "rgb.zkn3"
  :observed
  (:notes 9023
   :keywords 13602
   :links 2436
   :sequences 7115
   :attachments 716
   :diagnostics 3520
   :unresolvedReferenceCount 1)
  :unresolved-reference
  (:sourceNoteId "240611105406688rgb50919"
   :sourceField "manlinks"
   :rawReference "64444"
   :referenceKind "MANUAL_LINK"
   :reason "OUT_OF_RANGE"
   :order 15)
  :edge-boundary
  (:created-Zkn3LinkRecord false
   :created-resolved-edge false))

 :validation
 (:system :hyperdoc/zkn3-import-report-projection/tests
  :sbcl "2.4.10"
  :nix-dev-shell true
  :smoke-test :passed
  :pre-commit-full-load-gate :passed
  :load-gate "LOAD_GATE_OK")

 :relation-to-zettelkastenfx
 (:java-report-implementation-commit "deff040"
  :java-report-implementation-record-commit "cf85959"
  :real-source-verification-record-commit "c2a9e34"
  :inspector-contract-design-commit "21c9aa7"
  :hyperdoc-adapter-design-commit "d841883")

 :boundary
 (:does-not-touch-zettelkastenfx true
  :does-not-touch-javafx true
  :does-not-touch-swing true
  :does-not-create-resolved-edge true
  :does-not-write-sqlite true
  :does-not-repair-source true)

 :preserved-unowned-state
 ("hyperdoc/task-location-problem-determined-htn.sexp")

 :next
 (!inspect-example-zkn3-import-report-projection-in-running-hyperdoc
  :object make-example-zkn3-import-report-projection
  :must-not-touch-javafx true
  :must-not-create-resolved-edge true))
