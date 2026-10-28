;;;; The HyperDoc reading of the re-pin of Topic Maps from 6162ed68 (Task 1C) to 88994c1b (Task 1E).
;;;; Local review only. Its own .asd, so that reading the re-pin changes no system of dreyeck.asd. It loads the Project Workspace,
;;;; which the served Catalog's startup guard refuses; serve it with the trusted review runtime, on loopback.

(asdf:defsystem "topic-maps-task-1e-review"
  :description "Re-pinning Topic Maps to 88994c1b: the two reviewed changes, the snapshot, the Project Workspace results, the Stage 1 CTM and what remains"
  :license "BSD"
  :depends-on ("dreyeck/work/project" "dreyeck/work/topic-maps-project-example" "dreyeck/source-snapshot" "dreyeck/catalog-topic-maps" "html-inspector-views" "ironclad" "alexandria" "plump")
  :serial t
  :components ((:module "code" :serial t :components ((:file "package") (:file "review")))
               (:module "evidence" :components ((:static-file "SHA256SUMS")))
               (:module "pages"
                :components ((:static-file "Re-pinning Topic Maps to 88994c1b.html")
                             (:static-file "Task 1C and Task 1E.html")
                             (:static-file "The 88994c1b Snapshot.html")
                             (:static-file "Project Workspace on 88994c1b.html")
                             (:static-file "The Stage 1 CTM and the Proposed Work Packages.html")
                             (:static-file "Remaining Requirements.html"))))
  :in-order-to ((asdf:test-op (asdf:test-op "topic-maps-task-1e-review/tests"))))

(asdf:defsystem "topic-maps-task-1e-review/tests"
  :depends-on ("topic-maps-task-1e-review")
  :components ((:module "tests" :serial t :components ((:file "review"))))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :topic-maps-task-1e-review/tests :run-tests)))
