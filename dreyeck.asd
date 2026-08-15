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
  :depends-on (#:dreyeck/inspector/fedwiki-navigation)
  :components
  ((:file "fedwiki-navigation-trace-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (uiop:symbol-call
    :dreyeck/fedwiki-navigation/tests
    :run-fedwiki-navigation-trace-tests)))

(asdf:defsystem #:dreyeck/topicmap
  :description "Renderer-independent Topicmap projection protocol owned by Dreyeck"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :components
  ((:file "topicmap-package")
   (:file "topicmap"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/topicmap/tests"))))

(asdf:defsystem #:dreyeck/inspector/topicmap
  :description "Generic Dreyeck Topicmap view and native CLOG/SVG renderer"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:dreyeck/topicmap
               #:hyperdoc/inspector
               #:html-inspector-views
               #:trivial-package-local-nicknames)
  :components
  ((:file "topicmap-inspector-package")
   (:file "topicmap-inspector")))

(asdf:defsystem #:dreyeck/topicmap/tests
  :description "Behavior tests for the Dreyeck Topicmap extension"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/inspector/topicmap
               #:asdf
               #:uiop)
  :components
  ((:file "topicmap-view-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (uiop:symbol-call
    :dreyeck/topicmap/tests
    :run-topicmap-view-smoke-tests)))

(asdf:defsystem #:dreyeck/fedwiki-source-relations
  :description "Source-backed observation of FedWiki component relations"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:dreyeck/git
               #:dreyeck/topicmap
               #:hyperdoc)
  :components
  ((:module "dreyeck/pages/fedwiki-source-relations"
    :pathname "../pages/fedwiki-source-relations/")
   (:file "fedwiki-source-relations-package")
   (:file "fedwiki-source-relations")
   (:file "fedwiki-source-relations-hyperdoc"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/fedwiki-source-relations/tests"))))

(asdf:defsystem #:dreyeck/inspector/fedwiki-source-relations
  :description "Inspector views for Dreyeck FedWiki source relations"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:dreyeck/fedwiki-source-relations
               #:dreyeck/inspector/git
               #:dreyeck/inspector/topicmap
               #:hyperdoc/inspector
               #:html-inspector-views)
  :components
  ((:file "fedwiki-source-relations-inspector-package")
   (:file "fedwiki-source-relations-views")))

(asdf:defsystem #:dreyeck/fedwiki-source-relations/tests
  :description "Source-backed tests for FedWiki source relations"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/inspector/fedwiki-source-relations
               #:hyperdoc/explorer)
  :components
  ((:file "fedwiki-source-relations-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (uiop:symbol-call
    :dreyeck/fedwiki-source-relations/tests
    :run-fedwiki-source-relations-tests)))

(asdf:defsystem #:dreyeck/git
  :description "Experimental Git-backed inspection objects incubated by Dreyeck"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:dreyeck/topicmap
               #:asdf
               #:uiop)
  :components
  ((:file "git-package")
   (:file "git-repository-checkout")
   (:file "git-commit-inspection")
   (:file "git-asdf-references")
   (:file "git-asdf-reference-topicmap"))
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
               #:dreyeck/inspector/topicmap
               #:hyperdoc/inspector
               #:html-inspector-views)
  :components
  ((:file "git-inspector-package")
   (:file "git-commit-inspection-views")
   (:file "git-asdf-reference-views")))

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
  :description "Explicit membership and runtime support for the dreyeck.ch HyperBook catalog"
  :license "BSD"
  :version "0.0.1"
  ;; The HyperDoc systems declare membership. Their inspector systems supply
  ;; the executable views reached from the catalog pages.
  :depends-on (#:dreyeck/wiki-link
               #:dreyeck/upstream-intake
               #:dreyeck/inspector/upstream-intake
               #:dreyeck/inspector/fedwiki-source-relations
	       #:dreyeck/lisp-image)
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/catalog/tests"))))

(asdf:defsystem #:dreyeck/git/tests
  :description "Stable local-fixture tests for Dreyeck Git inspection"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/inspector/git
               #:closer-mop)
  :components
  ((:file "git-commit-inspection-smoke")
   (:file "git-asdf-reference-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (uiop:symbol-call
    :dreyeck/git/tests
    :run-git-commit-inspection-smoke-tests)
   (uiop:symbol-call
    :dreyeck/git/asdf-reference-tests
    :run-git-asdf-reference-smoke-tests)))

(asdf:defsystem #:dreyeck/upstream-intake/tests
  :description "Deterministic read-only Upstream Intake contract tests"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/inspector/upstream-intake
               #:hyperdoc/explorer
               #:hyperbook/fedwiki)
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

(asdf:defsystem #:dreyeck/lisp-image
  :description "dreyeck.ch-owned Lisp image inventory and executable HyperDoc reading path."
  :license "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:hyperdoc/explorer)
  :components
  ((:module "dreyeck/src"
    :pathname "dreyeck/src/"
    :serial t
    :components
    ((:file "lisp-image-package")
     (:file "lisp-image-inventory")
     (:file "lisp-image-observations")
     (:file "lisp-image-views")
     (:file "lisp-image-hyperdoc")))
   (:module "dreyeck/pages/lisp-image"
    :pathname "dreyeck/pages/lisp-image/"
    :components
    ((:static-file "Lisp image HyperBook refactor.html")))))


(asdf:defsystem #:dreyeck/fedwiki-assets
  :description "Read-only discovery of local assets referenced by Federated Wiki pages"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:uiop
               #:shasht)
  :components
  ((:file "fedwiki-assets-package")
   (:file "fedwiki-assets"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/fedwiki-assets/tests"))))

(asdf:defsystem #:dreyeck/fedwiki-assets/tests
  :description "Deterministic tests for local FedWiki asset discovery"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/fedwiki-assets)
  :components
  ((:file "fedwiki-assets-test-package")
   (:file "fedwiki-assets-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (unless
       (uiop:symbol-call
        :dreyeck/fedwiki-assets/tests
        :run-fedwiki-assets-tests)
     (error "Dreyeck FedWiki assets tests failed."))))


(asdf:defsystem #:dreyeck/page-attached-asdf
  :description "Observable registration of trusted page-attached ASDF definitions"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:asdf
               #:uiop)
  :components
  ((:file "page-attached-asdf-package")
   (:file "page-attached-asdf"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/page-attached-asdf/tests"))))

(asdf:defsystem #:dreyeck/page-attached-asdf/tests
  :description "Deterministic tests for page-attached ASDF registration"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/page-attached-asdf)
  :components
  ((:file "page-attached-asdf-test-package")
   (:file "page-attached-asdf-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (unless
       (uiop:symbol-call
        :dreyeck/page-attached-asdf/tests
        :run-page-attached-asdf-tests)
     (error
      "Dreyeck page-attached ASDF tests failed."))))


(asdf:defsystem #:dreyeck/page-attached-hyperdoc
  :description "Observe HyperDocs registered by explicitly loaded ASDF systems"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:asdf
               #:hyperbook
               #:hyperdoc)
  :components
  ((:file "page-attached-hyperdoc-package")
   (:file "page-attached-hyperdoc"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/page-attached-hyperdoc/tests"))))

(asdf:defsystem #:dreyeck/page-attached-hyperdoc/tests
  :description "Deterministic tests for page-attached HyperDoc activation"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/page-attached-hyperdoc)
  :components
  ((:file "page-attached-hyperdoc-test-package")
   (:file "page-attached-hyperdoc-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (unless
       (uiop:symbol-call
        :dreyeck/page-attached-hyperdoc/tests
        :run-page-attached-hyperdoc-tests-in-fresh-process)
     (error
      "Dreyeck page-attached HyperDoc tests failed."))))


(asdf:defsystem #:dreyeck/fedwiki-hyperdoc
  :description "Activate local page-attached HyperDocs from FedWiki assets"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:asdf
               #:uiop
               #:hyperbook
               #:hyperdoc
               #:dreyeck/fedwiki-assets
               #:dreyeck/page-attached-asdf
               #:dreyeck/page-attached-hyperdoc)
  :components
  ((:file "fedwiki-hyperdoc-package")
   (:file "fedwiki-hyperdoc"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/fedwiki-hyperdoc/tests"))))

(asdf:defsystem #:dreyeck/fedwiki-hyperdoc-demo
  :description "Executable demonstration of local FedWiki page-attached HyperDoc activation"
  :license "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:dreyeck/fedwiki-hyperdoc
               #:hyperdoc/explorer)
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/fedwiki-hyperdoc-demo/tests")))
  :components
  ((:module "dreyeck/pages/fedwiki-hyperdoc-demo"
    :pathname "dreyeck/pages/fedwiki-hyperdoc-demo/")
   (:module "dreyeck/src"
    :pathname "dreyeck/src/"
    :components
    ((:file "fedwiki-hyperdoc-demo")))))

(asdf:defsystem #:dreyeck/fedwiki-hyperdoc-demo/tests
  :description "Smoke tests for the executable FedWiki HyperDoc demonstration"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/fedwiki-hyperdoc-demo)
  :components
  ((:file "fedwiki-hyperdoc-demo-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (unless
       (uiop:symbol-call
        :dreyeck/fedwiki-hyperdoc-demo/tests
        :run-fedwiki-hyperdoc-demo-tests)
     (error
      "Dreyeck FedWiki HyperDoc demo tests failed."))))

(asdf:defsystem #:dreyeck/fedwiki-hyperdoc/tests
  :description "End-to-end tests for local FedWiki page-attached HyperDoc activation"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/fedwiki-hyperdoc)
  :components
  ((:file "fedwiki-hyperdoc-test-package")
   (:file "fedwiki-hyperdoc-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (unless
       (uiop:symbol-call
        :dreyeck/fedwiki-hyperdoc/tests
        :run-fedwiki-hyperdoc-tests-in-fresh-process)
     (error
      "Dreyeck FedWiki HyperDoc tests failed."))))


(asdf:defsystem #:dreyeck/local-fedwiki-page
  :description "Local Federated Wiki pages with explicit local provenance"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:uiop
               #:hyperbook/fedwiki
               #:dreyeck/fedwiki-assets)
  :components
  ((:file "local-fedwiki-page-package")
   (:file "local-fedwiki-page"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/local-fedwiki-page/tests"))))


(asdf:defsystem #:dreyeck/local-fedwiki-page/inspector
  :description "Inspector integration for local Federated Wiki page provenance"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:dreyeck/local-fedwiki-page
               #:hyperbook/fedwiki
               #:html-inspector-views)
  :components
  ((:file "local-fedwiki-page-inspector-package")
   (:file "local-fedwiki-page-inspector")))

(asdf:defsystem #:dreyeck/local-fedwiki-page/tests
  :description "Fresh-process tests for local FedWiki provenance and inspector discovery"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/local-fedwiki-page/inspector)
  :components
  ((:file "local-fedwiki-page-test-package")
   (:file "local-fedwiki-page-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (unless
       (uiop:symbol-call
        :dreyeck/local-fedwiki-page/tests
        :run-local-fedwiki-page-tests-in-fresh-process)
     (error
      "Dreyeck local FedWiki page tests failed."))))


(asdf:defsystem #:dreyeck/local-fedwiki-page/activation-inspector
  :description "Explicit HyperDoc activation from local Federated Wiki page inspection"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:dreyeck/local-fedwiki-page/inspector
               #:dreyeck/fedwiki-hyperdoc)
  :components
  ((:file "local-fedwiki-page-activation-inspector"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op
     "dreyeck/local-fedwiki-page/activation-inspector/tests"))))

(asdf:defsystem #:dreyeck/local-fedwiki-page/activation-inspector/tests
  :description "Fresh-process tests for explicit local FedWiki HyperDoc activation"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/local-fedwiki-page/activation-inspector)
  :components
  ((:file "local-fedwiki-page-activation-inspector-test-package")
   (:file "local-fedwiki-page-activation-inspector-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (unless
       (uiop:symbol-call
        :dreyeck/local-fedwiki-page/activation-inspector/tests
        :run-local-fedwiki-page-activation-inspector-tests-in-fresh-process)
     (error
      "Dreyeck local FedWiki page activation-inspector tests failed."))))


(asdf:defsystem #:dreyeck/wiki-assets-acceptance/tests
  :description "Fresh-process acceptance of tracked page-attached Wiki asset ASDF systems"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:asdf
               #:uiop)
  :components
  ((:file "wiki-assets-acceptance-test-package")
   (:file "wiki-assets-acceptance-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (unless
       (uiop:symbol-call
        :dreyeck/wiki-assets-acceptance/tests
        :run-wiki-assets-acceptance-tests-in-fresh-process)
     (error
      "Dreyeck Wiki-assets acceptance failed."))))
