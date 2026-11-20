;;;; Code paths into page-attached code, observed in this image: a reading with a Topicmap of the call paths.
;;;; Its own .asd, so that a running HyperDoc image can load it from a separate checkout or a page copy.

(asdf:defsystem "codepath-review"
  :description "Where this image could make ASDF see or evaluate code that arrived with a wiki page, and whether each place passes the execution guard"
  :license "BSD"
  :depends-on ("dreyeck/catalog" "dreyeck/authority-policy" "dreyeck/dita-story-item" "dreyeck/topicmap"
               "dreyeck/inspector/topicmap" "html-inspector-views" "hyperbook/server" "clog" "clog-moldable-inspector"
               "plump" "sb-introspect")
  :serial t
  :components ((:file "analysis") (:file "pages")
               (:static-file "trust-boundary.dita") (:static-file "method.dita") (:static-file "analyze-codepaths.dita")
               (:module "evidence" :components ((:static-file "production-catalog-6057938a.sexp"))))
  :in-order-to ((asdf:test-op (asdf:test-op "codepath-review/tests"))))

(asdf:defsystem "codepath-review/tests"
  :depends-on ("codepath-review")
  :components ((:module "tests" :serial t :components ((:file "fixture") (:file "codepath-review"))))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :codepath-review :run-tests)))
