;;;; HyperDoc Zettel slice for Adele Goldberg, "Programmer as Reader".
;;;;
;;;; Imported from the FedWiki page asset:
;;;; /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/programmer-as-reader/
;;;; Source slug: programmer-as-reader

(asdf:defsystem #:hyperdoc-goldberg-programmer-as-reader
  :description "HyperDoc Zettel rewrite of Adele Goldberg's Programmer as Reader: topics, pages, clickable reader-question examples, and operations."
  :author "Generated HyperDoc slice"
  :license "Local project documentation artifact; source-paper rights remain with original publisher/author."
  :version "0.1.0"
  :pathname "hyperdoc-goldberg-programmer-as-reader/"
  :serial t
  :components
  ((:module "src"
    :serial t
    :components
    ((:file "package")
     (:file "model")
     (:file "data")
     (:file "operations")
     (:file "topics")
     (:file "materialize")))
   (:module "pages"
    :components
    ((:static-file "Goldberg Programmer as Reader.html")
     (:static-file "Goldberg Programmer as Reader topic arrangement.html")
     (:static-file "Goldberg reading comprehension questions.html")
     (:static-file "Goldberg reader operations.html")
     (:static-file "Goldberg Smalltalk to HyperDoc crosswalk.html")))
   (:module "tests"
    :components
    ((:static-file "goldberg-reader-zettel-smoke.lisp")))))

(asdf:defsystem #:hyperdoc-goldberg-programmer-as-reader/test
  :description "Smoke tests for the Goldberg Programmer as Reader HyperDoc slice."
  :depends-on (#:hyperdoc-goldberg-programmer-as-reader)
  :pathname "hyperdoc-goldberg-programmer-as-reader/"
  :serial t
  :components ((:module "tests"
                :serial t
                :components ((:file "goldberg-reader-zettel-smoke"))))
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (funcall (read-from-string "hyperdoc-goldberg-programmer-as-reader/tests:run-goldberg-reader-zettel-smoke-tests"))))
