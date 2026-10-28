;;;; The HyperDoc reading of the integration of Topic Maps 6162ed68 (Task 1C) into HyperDoc.
;;;; Local review only: it loads the Project Workspace, which needs Topic Maps in the ASDF registry, and the Catalog's startup guard,
;;;; which refuses that Workspace in the served runtime. It has its own .asd so that reading the integration changes no system of dreyeck.asd.

(asdf:defsystem "topic-maps-integration-review"
  :description "Integrating Topic Maps 6162ed68: the reviewed change, the independent evidence, the performance difference, the source revision, the Project Workspace and what remains"
  :license "BSD"
  :depends-on ("dreyeck/work/project" "dreyeck/work/topic-maps-project-example" "dreyeck/source-snapshot" "dreyeck/catalog-topic-maps" "dreyeck/topicmap" "dreyeck/inspector/topicmap"
               "dreyeck/git" "html-inspector-views" "ironclad" "shasht"
               ;; The earlier review: its page of proposed Work Packages and its version-bound contract are objects of this reading.
               "topic-maps-deployment-review")
  :serial t
  :components ((:module "code"
                :serial t
                :components ((:file "package") (:file "evidence") (:file "boundaries") (:file "subjects") (:file "reading")))
               (:module "evidence"
                :components ((:static-file "SHA256SUMS")))
               (:module "pages"
                :components ((:static-file "Integrating Topic Maps 6162ed68.html")
                             (:static-file "The Reviewed Change.html")
                             (:static-file "The Independent Evidence.html")
                             (:static-file "The Performance Difference.html")
                             (:static-file "The Topic Maps Source Revision.html")
                             (:static-file "Project Workspace Compatibility.html")
                             (:static-file "The Four Commits.html")
                             (:static-file "The Earlier Review's Contract.html")
                             (:static-file "The Project Workspace in a Browser.html")
                             (:static-file "From Work Item to Implementation.html")
                             (:static-file "Remaining Work and Acceptance.html"))))
  :in-order-to ((asdf:test-op (asdf:test-op "topic-maps-integration-review/tests"))))

(asdf:defsystem "topic-maps-integration-review/tests"
  :depends-on ("topic-maps-integration-review")
  :components ((:module "tests" :serial t :components ((:file "review"))))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :topic-maps-integration-review/tests :run-tests)))
