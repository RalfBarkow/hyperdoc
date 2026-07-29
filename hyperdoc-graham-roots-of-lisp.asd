;;;; Standalone HyperDoc source-station slice for Paul Graham, "The Roots of Lisp".

(asdf:defsystem #:hyperdoc-graham-roots-of-lisp
  :description "Executable HyperDoc reconstruction of Paul Graham's The Roots of Lisp."
  :author "HyperDoc project reconstruction"
  :license "BSD for reconstruction code; source-text rights remain with their authors."
  :version "0.1.0"
  :pathname "hyperdoc-graham-roots-of-lisp/"
  :serial t
  :depends-on (#:hyperdoc/topics
               #:hyperdoc/checks
               #:hyperbook/server
               #:hyperbook/fedwiki
               #:html-inspector-views
               #:cl-who
               #:shasht)
  :components
  ((:module "src"
    :serial t
    :components
    ((:file "package")
     (:file "model")
     (:file "evaluator")
     (:file "session")
     (:file "examples")
     (:file "topics")
     (:file "materialize")
     (:file "lynn-runner")))
   (:module "pages"
    :components
    ((:static-file "The Roots of Lisp.html")
     (:static-file "The Roots of Lisp reconstruction layers.html")
     (:static-file "The Surprise as an evaluation trace.html")
     (:static-file "Which bugs did Graham correct?.html")
     (:static-file "Dynamic capture in MAPLIST and DIFF.html")
     (:static-file "Stanford Lisp interpreter crosswalk.html")
     (:static-file "What Made Lisp Different crosswalk.html")
     (:static-file "Roots of Lisp runner comparison.html")))
   (:module "tests"
    :components
    ((:static-file "roots-of-lisp-smoke.lisp")))
   (:static-file "mrepl-demo.lisp")
   (:static-file "README.md")))

(asdf:defsystem #:hyperdoc-graham-roots-of-lisp/development-server
  :description "Development catalogue composition including the standalone Roots of Lisp HyperDoc."
  :depends-on (#:hyperdoc/server
               #:hyperdoc-graham-roots-of-lisp))

(asdf:defsystem #:hyperdoc-graham-roots-of-lisp/test
  :description "Smoke tests for the executable Roots of Lisp source station."
  :depends-on (#:hyperdoc-graham-roots-of-lisp)
  :pathname "hyperdoc-graham-roots-of-lisp/"
  :serial t
  :components
  ((:module "tests"
    :serial t
    :components ((:file "roots-of-lisp-smoke"))))
  :perform
  (asdf:test-op (operation system)
    (declare (ignore operation system))
    (uiop:symbol-call
     :hyperdoc-graham-roots-of-lisp/tests
     :run-roots-of-lisp-smoke-tests)))
