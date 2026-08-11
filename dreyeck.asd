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

(asdf:defsystem #:dreyeck/wiki-link
  :description "Examples of FedWiki title and slug lookup contracts"
  :license "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:hyperdoc/explorer
               #:hyperbook/fedwiki)
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/wiki-link/tests")))
  :components
  ((:module "dreyeck/pages"
    :pathname "dreyeck/pages/")

   (:module "dreyeck/src"
    :pathname "dreyeck/src/"
    :serial t
    :components
    ((:file "wiki-link")
     (:file "fedwiki-journal-context-debugger")))))

(asdf:defsystem #:dreyeck/wiki-link/tests
  :description "Deterministic tests for the executable FedWiki failure trace"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/wiki-link)
  :components
  ((:file "fedwiki-journal-context-debugger-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (uiop:symbol-call
    :dreyeck/fedwiki-journal-context-debugger/tests
    :run-fedwiki-journal-context-debugger-tests)))

(asdf:defsystem #:dreyeck/fedwiki-navigation
  :description "Replayable Federated Wiki navigation prototype"
  :license "BSD"
  :version "0.0.1"
  :depends-on (#:asdf
	       #:uiop
	       #:hyperdoc)
  :pathname "dreyeck/src/"
  :serial t
  :components
  ((:file "fedwiki-navigation")
   (:file "make-navigation-fixture")
   (:file "navigation-trace"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/fedwiki-navigation/tests"))))

(asdf:defsystem #:dreyeck/inspector/fedwiki-navigation
  :description "Inspector views for source-backed FedWiki navigation traces"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:dreyeck/fedwiki-navigation
               #:hyperdoc/inspector
               #:html-inspector-views)
  :components
  ((:file "navigation-trace-views")))

(asdf:defsystem #:dreyeck/fedwiki-navigation/tests
  :description "Deterministic tests for source-backed FedWiki navigation traces"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/inspector/fedwiki-navigation
               #:dreyeck/extension-system-boundaries)
  :components
  ((:file "fedwiki-navigation-trace-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (uiop:symbol-call
    :dreyeck/fedwiki-navigation/tests
    :run-fedwiki-navigation-trace-tests)))

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
