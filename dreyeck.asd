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
  :description "Dreyeck FedWiki lookup and story-item operation examples"
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
     (:file "fedwiki-journal-context-debugger")
     (:file "fedwiki-story-item-transfer")))))

(asdf:defsystem #:dreyeck/wiki-link/tests
  :description "Deterministic tests for Dreyeck FedWiki diagnostic operations"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/wiki-link)
  :components
  ((:file "wiki-link-slug-contract")
   (:file "fedwiki-journal-context-debugger-smoke")
   (:file "fedwiki-story-item-transfer-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (uiop:symbol-call
    :dreyeck/wiki-link/contract-tests
    :run-wiki-link-slug-contract-tests)
   (uiop:symbol-call
    :dreyeck/fedwiki-journal-context-debugger/tests
    :run-fedwiki-journal-context-debugger-tests)
   (uiop:symbol-call
    :dreyeck/fedwiki-story-item-transfer/tests
    :run-fedwiki-story-item-transfer-tests)))

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

(asdf:defsystem #:dreyeck/upstream-intake
  :description "Read-only observations of upstream commits and components"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:dreyeck/git
               #:hyperdoc
               #:closer-mop)
  :components
  ((:module "dreyeck/pages/upstream-intake"
    :pathname "../pages/upstream-intake/")
   (:file "upstream-intake-package")
   (:file "upstream-intake")
   (:file "upstream-intake-hyperdoc"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/upstream-intake/tests"))))

(asdf:defsystem #:dreyeck/inspector/upstream-intake
  :description "Inspector views for read-only upstream intake observations"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:dreyeck/upstream-intake
               #:dreyeck/inspector/git
               #:hyperdoc/inspector
               #:html-inspector-views)
  :components
  ((:file "upstream-intake-inspector-package")
   (:file "upstream-intake-views")))

(asdf:defsystem #:dreyeck/catalog
  :description "Explicit membership and runtime support for the Dreyeck HyperBook catalog"
  :license "BSD"
  :version "0.0.1"
  ;; The HyperDoc systems declare membership. The inspector system supplies
  ;; the executable Upstream Intake views reached from those pages.
  :depends-on (#:dreyeck/wiki-link
               #:dreyeck/upstream-intake
               #:dreyeck/inspector/upstream-intake)
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/catalog/tests"))))

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

(asdf:defsystem #:dreyeck/upstream-intake/tests
  :description "Deterministic read-only Upstream Intake contract tests"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/inspector/upstream-intake
               #:hyperdoc/explorer
               #:hyperbook/fedwiki
               #:dreyeck/extension-system-boundaries)
  :components
  ((:file "upstream-intake-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (uiop:symbol-call
    :dreyeck/upstream-intake/tests
    :run-upstream-intake-tests)))

(asdf:defsystem #:dreyeck/catalog/tests
  :description "Fresh-image contract tests for the Dreyeck HyperBook catalog"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:uiop)
  :components
  ((:file "catalog-startup-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (uiop:symbol-call
    :dreyeck/catalog/tests
    :run-catalog-startup-smoke-tests)))
