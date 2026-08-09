;;;; Local dreyeck.ch integration and communication systems

(asdf:defsystem #:dreyeck
  :description "Local dreyeck.ch integration overlay"
  :license "BSD"
  :version "0.0.1"
  :serial t
  :components
  ((:module "dreyeck/src"
    :pathname "dreyeck/src/"
    :serial t
    :components
    ((:file "dreyeck-hyperdoc-deployment-inventory")))))

(asdf:defsystem #:dreyeck/fedwiki-navigation
  :description "Replayable Federated Wiki navigation prototype"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :components
  ((:file "fedwiki-navigation")
   (:file "make-navigation-fixture"))
  :in-order-to
  ((asdf:test-op
    (asdf:load-op "dreyeck/fedwiki-navigation")))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (uiop:symbol-call
    :dreyeck/fedwiki-navigation/prototype
    :navigation-transcript-smoke-test)))

(asdf:defsystem #:dreyeck/wiki-link
  :description "Examples of FedWiki title and slug lookup contracts"
  :license "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:hyperdoc/explorer
               #:hyperbook/fedwiki)
  :components
  ((:module "dreyeck/pages"
    :pathname "dreyeck/pages/")

   (:module "dreyeck/src"
    :pathname "dreyeck/src/"
    :serial t
    :components
    ((:file "wiki-link")))))

(asdf:defsystem #:dreyeck/git
  :description "Experimental Git-backed inspection objects incubated by Dreyeck"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:hyperdoc
               #:uiop)
  :components
  ((:file "git-package")
   (:file "git-repository-checkout")
   (:file "git-commit-inspection"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/git/tests"))))

(asdf:defsystem #:dreyeck/inspector/git
  :description "Dreyeck inspector views for experimental Git objects"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:dreyeck/git
               #:hyperdoc/inspector
               #:html-inspector-views)
  :components
  ((:file "git-inspector-package")
   (:file "git-commit-inspection-views")))

(asdf:defsystem #:dreyeck/extension-system-boundaries
  :description "Reusable ownership checks for Dreyeck extension systems"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:asdf
               #:uiop)
  :components
  ((:file "extension-system-boundaries")))

(asdf:defsystem #:dreyeck/git/tests
  :description "Stable local-fixture and ownership tests for Dreyeck Git inspection"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/inspector/git
               #:dreyeck/extension-system-boundaries)
  :components
  ((:file "git-commit-inspection-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (uiop:symbol-call
    :dreyeck/git/tests
    :run-git-commit-inspection-smoke-tests)))
