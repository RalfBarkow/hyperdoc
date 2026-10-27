;;;; The HyperDoc reading that reviews the uncommitted Topic Maps packaging candidate.
;;;; It has its own .asd so that reviewing the candidate changes none of the candidate's files, dreyeck.asd included.

(asdf:defsystem "topic-maps-deployment-review"
  :description "Deploying Topic Maps with HyperDoc: a reading of the hyperdoc-catalog-topic-maps candidate, its sources and evidence"
  :license "BSD"
  :depends-on ("dreyeck/catalog-topic-maps" "dreyeck/source-snapshot" "dreyeck/work/topic-maps-ctm-review"
               "dreyeck/topicmap" "dreyeck/inspector/topicmap" "dreyeck/git" "dreyeck/authority-policy"
               ;; Loaded for their test procedures as objects; loading runs no test.
               "dreyeck/source-snapshot/tests" "dreyeck/catalog-topic-maps/tests"
               "dreyeck/work/topic-maps-ctm-review/tests" "dreyeck/work/topic-maps-project-example/tests"
               ;; The Work reader and the CTM plan page's WBS Dictionary reader, for the proposed project work; Topic Maps-free.
               "dreyeck/work/reading" "plump"
               "ironclad" "shasht" "sb-introspect")
  :serial t
  :components ((:module "code"
                :serial t
                :components ((:file "package") (:file "candidate") (:file "evidence") (:file "claims")
                             (:file "subjects") (:file "reading") (:file "proposals")))
               ;; The proposed project work: an addition to Implementation Assignments and a draft WBS Dictionary, in the
               ;; project's own forms; the emitter's reading of them, run in a process of its own with Topic Maps 5a4a668.
               (:module "proposals"
                :components ((:static-file "implementation-assignments-addition.html")
                             (:static-file "topic-maps-deployment-wbs-dictionary.html")
                             (:static-file "emitter-crosscheck.lisp") (:static-file "run-emitter-crosscheck.sh")
                             (:module "evidence" :components ((:static-file "emitter-crosscheck.sexp")))))
               (:module "pages"
                :components ((:static-file "Deploying Topic Maps with HyperDoc.html")
                             (:static-file "Why a Separate Nix Package.html")
                             (:static-file "From Git Commit to Verified Snapshot.html")
                             (:static-file "What the Snapshot Verifier Establishes.html")
                             (:static-file "Where ASDF Finds the Sources.html")
                             (:static-file "Keeping the Project Workspace Out.html")
                             (:static-file "Execution Authority.html")
                             (:static-file "Tested and Unverified.html"))))
  :in-order-to ((asdf:test-op (asdf:test-op "topic-maps-deployment-review/tests"))))

(asdf:defsystem "topic-maps-deployment-review/tests"
  :depends-on ("topic-maps-deployment-review")
  :components ((:module "tests" :serial t :components ((:file "review") (:file "proposals"))))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :topic-maps-deployment-review/tests :run-tests)
             (uiop:symbol-call :topic-maps-deployment-review/tests :run-proposal-tests)))
