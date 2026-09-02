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

(asdf/parse-defsystem:defsystem #:dreyeck/git
  :description
  "Experimental Git-backed inspection objects incubated by Dreyeck"
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/src/"
  :serial
  t
  :depends-on
  (#:dreyeck/topicmap #:asdf #:uiop)
  :components
  ((:file "git-package") (:file "git-repository-checkout")
   (:file "git-commit-inspection") (:file "git-source-slice")
   (:file "git-repository-topicmap") (:file "git-asdf-references")
   (:file "git-asdf-reference-topicmap"))
  :in-order-to
  ((asdf/lisp-action:test-op (asdf/lisp-action:test-op "dreyeck/git/tests"))))

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


(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/CATALOG
  :DESCRIPTION
  "Explicit membership and runtime support for the dreyeck.ch HyperBook catalog"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :DEPENDS-ON
  (#:DREYECK/WIKI-LINK #:DREYECK/UPSTREAM-INTAKE
   #:DREYECK/INSPECTOR/UPSTREAM-INTAKE
   #:DREYECK/INSPECTOR/FEDWIKI-SOURCE-RELATIONS #:DREYECK/LISP-IMAGE
   #:DREYECK/PAGE-ATTACHED-WORKSPACE-OFFER)
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/catalog/tests")))
  :COMPONENTS
  ((:FILE "dreyeck/src/catalog")))

(asdf/parse-defsystem:defsystem #:dreyeck/git/tests
  :description
  "Stable local-fixture tests for Dreyeck Git inspection"
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/tests/"
  :serial
  t
  :depends-on
  (#:dreyeck/inspector/git #:closer-mop)
  :components
  ((:file "git-commit-inspection-smoke") (:file "git-source-slice-smoke")
   (:file "git-repository-topicmap-smoke") (:file "git-asdf-reference-smoke"))
  :perform
  (asdf/lisp-action:test-op (operation component)
   (declare (ignore operation component))
   (uiop/package:symbol-call :dreyeck/git/tests
                             :run-git-commit-inspection-smoke-tests)
   (uiop/package:symbol-call :dreyeck/git/tests
                             :run-git-source-slice-smoke-tests)
   (uiop/package:symbol-call :dreyeck/git/tests
                             :run-git-repository-topicmap-smoke-tests)
   (uiop/package:symbol-call :dreyeck/git/asdf-reference-tests
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


(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/CATALOG/TESTS
  :DESCRIPTION
  "Fresh-image contract tests for the Dreyeck HyperBook catalog"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:UIOP #:DREYECK/CATALOG)
  :COMPONENTS
  ((:FILE "catalog-startup-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/CATALOG/TESTS
                             :RUN-CATALOG-STARTUP-SMOKE-TESTS)))

(asdf/parse-defsystem:defsystem #:dreyeck/lisp-image
  :description
  "dreyeck.ch-owned Lisp image inventory and executable HyperDoc reading path."
  :license
  "BSD"
  :version
  "0.0.1"
  :serial
  t
  :depends-on
  (#:hyperdoc/explorer)
  :components
  ((:module "dreyeck/src" :pathname "dreyeck/src/" :serial t :components
    ((:file "lisp-image-package") (:file "lisp-image-inventory")
     (:file "lisp-image-definition-sources") (:file "lisp-image-observations")
     (:file "lisp-image-views") (:file "lisp-image-hyperdoc")))
   (:module "dreyeck/pages/lisp-image" :pathname "dreyeck/pages/lisp-image/"
    :components ((:static-file "Lisp image HyperBook refactor.html")))))

(asdf/parse-defsystem:defsystem #:dreyeck/lisp-image/topicmap
  :depends-on
  (#:dreyeck/lisp-image #:dreyeck/topicmap)
  :description
  "Topicmap projection adapter for live Lisp image subjects."
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/src/"
  :serial
  t
  :components
  ((:file "lisp-image-topicmap"))
  :in-order-to
  ((asdf/lisp-action:test-op
    (asdf/lisp-action:test-op "dreyeck/lisp-image/topicmap/tests"))))

(asdf/parse-defsystem:defsystem #:dreyeck/lisp-image/topicmap/tests
  :description
  "Behavior tests for live Lisp image Topicmap projections."
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/tests/"
  :serial
  t
  :depends-on
  (#:dreyeck/lisp-image/topicmap #:asdf #:uiop)
  :components
  ((:file "lisp-image-topicmap-smoke"))
  :perform
  (asdf/lisp-action:test-op (operation component)
   (declare (ignore operation component))
   (uiop/package:symbol-call :dreyeck/lisp-image/topicmap/tests
                             :run-lisp-image-topicmap-smoke-tests)))



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


(asdf/parse-defsystem:defsystem #:dreyeck/fedwiki-journal
  :description
  "Generic invariant checks and inspectable findings for Federated Wiki journals"
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/src/"
  :serial
  t
  :depends-on
  (#:hyperbook/fedwiki #:local-time)
  :components
  ((:file "fedwiki-journal-package") (:file "fedwiki-journal"))
  :in-order-to
  ((asdf/lisp-action:test-op
    (asdf/lisp-action:test-op "dreyeck/fedwiki-journal/tests"))))

(asdf/parse-defsystem:defsystem #:dreyeck/fedwiki-journal/tests
  :description
  "Deterministic tests for generic Federated Wiki journal checks"
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/tests/"
  :serial
  t
  :depends-on
  (#:dreyeck/fedwiki-journal)
  :components
  ((:file "fedwiki-journal-test-package") (:file "fedwiki-journal-smoke"))
  :perform
  (asdf/lisp-action:test-op (operation component)
   (declare (ignore operation component))
   (unless
       (uiop/package:symbol-call :dreyeck/fedwiki-journal/tests
                                 :run-fedwiki-journal-tests)
     (error "Dreyeck FedWiki journal tests failed."))))

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
        :run-page-attached-asdf-tests-in-fresh-process)
     (error
      "Dreyeck page-attached ASDF tests failed."))))


(asdf/parse-defsystem:defsystem "dreyeck/page-attached-system-projection"
                                :pathname "dreyeck/src/" :serial t :depends-on
                                ("asdf"
                                 "dreyeck/page-attached-asdf"
                                 "dreyeck/topicmap")
                                :components
                                ((:file
                                        "page-attached-system-projection-package")
                                 (:file "page-attached-system-projection"))
                                :in-order-to
                                ((asdf/lisp-action:test-op
                                                           (asdf/lisp-action:test-op
                                                                                     "dreyeck/page-attached-system-projection/tests"))))

(asdf/parse-defsystem:defsystem "dreyeck/page-attached-system-projection/tests"
  :pathname
  "dreyeck/tests/"
  :serial
  t
  :depends-on
  ("asdf" "dreyeck/page-attached-system-projection" "dreyeck/topicmap")
  :components
  ((:file "page-attached-system-projection-package")
   (:file "page-attached-system-projection"))
  :perform
  (asdf/lisp-action:test-op (operation component)
   (declare (ignore operation component))
   (uiop/package:symbol-call :dreyeck/page-attached-system-projection/tests
                             :run-page-attached-system-projection-tests)))

(asdf/parse-defsystem:defsystem "dreyeck/page-attached-workspace-reconstruction"
  :pathname
  "dreyeck/src/"
  :serial
  t
  :depends-on
  ("asdf" "dreyeck/page-attached-system-projection" "dreyeck/topicmap")
  :components
  ((:file "page-attached-workspace-reconstruction")))

(asdf/parse-defsystem:defsystem "dreyeck/page-attached-workspace-reconstruction-runner"
  :pathname
  "dreyeck/src/"
  :serial
  t
  :depends-on
  ("asdf" "uiop" "dreyeck/page-attached-workspace-reconstruction")
  :components
  ((:file "page-attached-workspace-reconstruction-runner")))

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


(asdf:defsystem #:dreyeck/local-fedwiki-view
  :description "Serve locally persisted Federated Wiki JSON through /view/<slug>"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:dreyeck/local-fedwiki-page
               #:hyperbook/server)
  :components
  ((:file "local-fedwiki-view-package")
   (:file "local-fedwiki-view"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/local-fedwiki-view/tests"))))

(asdf:defsystem #:dreyeck/local-fedwiki-view/tests
  :description "Server-independence tests for local FedWiki JSON rendering"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/local-fedwiki-view)
  :components
  ((:file "local-fedwiki-view-test-package")
   (:file "local-fedwiki-view-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare
    (ignore operation component))
   (unless
       (uiop:symbol-call
        :dreyeck/local-fedwiki-view/tests
        :run-local-fedwiki-view-tests)
     (error
      "Local FedWiki /view tests failed."))))

(asdf:defsystem #:dreyeck/fedwiki-page-materialization
  :description "Persist raw Federated Wiki Page JSON; fork provenance is an explicit operation"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/src/"
  :serial t
  :depends-on (#:dreyeck/fedwiki-assets
               #:shasht
               #:uiop)
  :components
  ((:file "fedwiki-page-materialization-package")
   (:file "fedwiki-page-materialization"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "dreyeck/fedwiki-page-materialization/tests"))))

(asdf:defsystem #:dreyeck/fedwiki-page-materialization/tests
  :description "Deterministic tests for local FedWiki page materialization"
  :license "BSD"
  :version "0.0.1"
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on (#:dreyeck/fedwiki-page-materialization)
  :components
  ((:file "fedwiki-page-materialization-test-package")
   (:file "fedwiki-page-materialization-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare
    (ignore operation component))
   (unless
       (uiop:symbol-call
        :dreyeck/fedwiki-page-materialization/tests
        :run-fedwiki-page-materialization-tests)
     (error
      "FedWiki page materialization tests failed."))))

(asdf:defsystem #:dreyeck/shop3
  :description
  "SHOP3-backed HTN planning layer owned by Dreyeck"
  :author
  "Ralf Barkow <ralf.barkow@me.com>"
  :license
  "BSD"
  :version
  "0.0.1"
  :serial
  t
  :depends-on
  (#:hyperdoc #:shop3)
  :components
  ((:module "dreyeck/shop3" :serial t :components
    ((:file "package") (:file "manual-topics") (:file "plan-objects")
     (:file "examples") (:file "views")))))

(asdf:defsystem #:DREYECK/STATE-MACHINE :description
                "Generic evidence-bearing state-machine runtime" :license "BSD"
                :version "0.0.1" :pathname "dreyeck/src/" :serial t :components
                ((:file "state-machine-package") (:file "state-machine"))
                :in-order-to
                ((asdf:test-op (asdf:test-op "dreyeck/state-machine/tests"))))

(asdf:defsystem #:DREYECK/STATE-MACHINE/TESTS :description
                "Deterministic tests for the generic state-machine runtime"
                :license "BSD" :version "0.0.1" :pathname "dreyeck/tests/"
                :serial t :depends-on (#:DREYECK/STATE-MACHINE) :components
                ((:file "state-machine-test-package")
                 (:file "state-machine-smoke"))
                :perform
                (asdf:test-op (operation component)
                              (declare (ignore operation component))
                              (unless
                                      (uiop:symbol-call
                                                        :DREYECK/STATE-MACHINE/TESTS
                                                        :RUN-STATE-MACHINE-TESTS)
                                      (error
                                             "Dreyeck state-machine tests failed."))))

(asdf:defsystem #:DREYECK/LISP-CRITIC :description
                "Generic LISP-CRITIC execution contracts and run records"
                :license "BSD" :version "0.0.1" :pathname "dreyeck/src/"
                :serial t :depends-on (#:ASDF #:UIOP) :components
                ((:file "lisp-critic-package") (:file "lisp-critic"))
                :in-order-to
                ((asdf:test-op (asdf:test-op "dreyeck/lisp-critic/tests"))))

(asdf:defsystem #:DREYECK/LISP-CRITIC/TESTS :description
                "Deterministic tests for generic LISP-CRITIC execution contracts"
                :license "BSD" :version "0.0.1" :pathname "dreyeck/tests/"
                :serial t :depends-on (#:DREYECK/LISP-CRITIC) :components
                ((:file "lisp-critic-test-package")
                 (:file "lisp-critic-smoke"))
                :perform
                (asdf:test-op (operation component)
                              (declare (ignore operation component))
                              (unless
                                      (uiop:symbol-call
                                                        :DREYECK/LISP-CRITIC/TESTS
                                                        :RUN-LISP-CRITIC-TESTS)
                                      (error
                                             "Dreyeck LISP-CRITIC tests failed."))))

(asdf:defsystem #:DREYECK/EVALUATION-RECORD :description
                "Generic protocol for projecting execution objects as evaluation records"
                :license "BSD" :version "0.0.1" :pathname "dreyeck/src/"
                :serial t :components
                ((:file "evaluation-record-package")
                 (:file "evaluation-record"))
                :in-order-to
                ((asdf:test-op
                               (asdf:test-op
                                             "dreyeck/evaluation-record/tests"))))

(asdf:defsystem #:DREYECK/EVALUATION-RECORD/STATE-MACHINE :description
                "Evaluation-record projection for state-machine runs" :license
                "BSD" :version "0.0.1" :pathname "dreyeck/src/" :depends-on
                (#:DREYECK/EVALUATION-RECORD #:DREYECK/STATE-MACHINE)
                :components ((:file "evaluation-record-state-machine")))

(asdf:defsystem #:DREYECK/EVALUATION-RECORD/LISP-CRITIC :description
                "Evaluation-record projection for LISP-CRITIC run records"
                :license "BSD" :version "0.0.1" :pathname "dreyeck/src/"
                :depends-on (#:DREYECK/EVALUATION-RECORD #:DREYECK/LISP-CRITIC)
                :components ((:file "evaluation-record-lisp-critic")))

(asdf:defsystem #:DREYECK/EVALUATION-RECORD/TESTS :description
                "Tests for generic evaluation-record projections" :license
                "BSD" :version "0.0.1" :pathname "dreyeck/tests/" :serial t
                :depends-on
                (#:DREYECK/EVALUATION-RECORD/STATE-MACHINE
                                                           #:DREYECK/EVALUATION-RECORD/LISP-CRITIC
                                                           #:DREYECK/STATE-MACHINE/TESTS)
                :components
                ((:file "evaluation-record-test-package")
                 (:file "evaluation-record-smoke"))
                :perform
                (asdf:test-op (operation component)
                              (declare (ignore operation component))
                              (unless
                                      (uiop:symbol-call
                                                        :DREYECK/EVALUATION-RECORD/TESTS
                                                        :RUN-EVALUATION-RECORD-TESTS)
                                      (error
                                             "Dreyeck evaluation-record tests failed."))))

(asdf:defsystem #:DREYECK/WORKSPACE-OPERATION :description
                "Generic workspace operation and invocation records" :license
                "BSD" :version "0.0.1" :pathname "dreyeck/src/" :serial t
                :components
                ((:file "workspace-operation-package")
                 (:file "workspace-operation"))
                :in-order-to
                ((asdf:test-op
                               (asdf:test-op
                                             "dreyeck/workspace-operation/tests"))))

(asdf:defsystem #:DREYECK/WORKSPACE-OPERATION/TESTS :description
                "Deterministic tests for workspace operation invocation"
                :license "BSD" :version "0.0.1" :pathname "dreyeck/tests/"
                :serial t :depends-on (#:DREYECK/WORKSPACE-OPERATION)
                :components
                ((:file "workspace-operation-test-package")
                 (:file "workspace-operation-smoke"))
                :perform
                (asdf:test-op (operation component)
                              (declare (ignore operation component))
                              (unless
                                      (uiop:symbol-call
                                                        :DREYECK/WORKSPACE-OPERATION/TESTS
                                                        :RUN-WORKSPACE-OPERATION-TESTS)
                                      (error
                                             "Dreyeck workspace-operation tests failed."))))

(asdf:defsystem #:DREYECK/EVALUATION-RECORD/WORKSPACE-OPERATION :description
                "Evaluation-record projection for workspace operation invocations"
                :license "BSD" :version "0.0.1" :pathname "dreyeck/src/"
                :serial t :depends-on
                (#:DREYECK/EVALUATION-RECORD #:DREYECK/WORKSPACE-OPERATION)
                :components ((:file "evaluation-record-workspace-operation"))
                :in-order-to
                ((asdf:test-op
                               (asdf:test-op
                                             "dreyeck/evaluation-record/workspace-operation/tests"))))

(asdf:defsystem #:DREYECK/EVALUATION-RECORD/WORKSPACE-OPERATION/TESTS
                :description
                "Tests for workspace operation evaluation-record projection"
                :license "BSD" :version "0.0.1" :pathname "dreyeck/tests/"
                :serial t :depends-on
                (#:DREYECK/EVALUATION-RECORD/WORKSPACE-OPERATION) :components
                ((:file "evaluation-record-workspace-operation-test-package")
                 (:file "evaluation-record-workspace-operation-smoke"))
                :perform
                (asdf:test-op (operation component)
                              (declare (ignore operation component))
                              (unless
                                      (uiop:symbol-call
                                                        :DREYECK/EVALUATION-RECORD/WORKSPACE-OPERATION/TESTS
                                                        :RUN-WORKSPACE-OPERATION-EVALUATION-RECORD-TESTS)
                                      (error
                                             "Workspace-operation evaluation-record tests failed."))))

(asdf:defsystem #:DREYECK/SLICE-SUMMARY :description
                "Summary projections over ordered evaluation records" :license
                "BSD" :version "0.0.1" :pathname "dreyeck/src/" :serial t
                :depends-on (#:DREYECK/EVALUATION-RECORD) :components
                ((:file "slice-summary-package") (:file "slice-summary"))
                :in-order-to
                ((asdf:test-op (asdf:test-op "dreyeck/slice-summary/tests"))))

(asdf:defsystem #:DREYECK/SLICE-SUMMARY/TESTS :description
                "Tests for heterogeneous evaluation-record summaries" :license
                "BSD" :version "0.0.1" :pathname "dreyeck/tests/" :serial t
                :depends-on
                (#:DREYECK/SLICE-SUMMARY
                                         #:DREYECK/EVALUATION-RECORD/STATE-MACHINE
                                         #:DREYECK/EVALUATION-RECORD/LISP-CRITIC
                                         #:DREYECK/EVALUATION-RECORD/WORKSPACE-OPERATION
                                         #:DREYECK/STATE-MACHINE/TESTS)
                :components
                ((:file "slice-summary-test-package")
                 (:file "slice-summary-smoke"))
                :perform
                (asdf:test-op (operation component)
                              (declare (ignore operation component))
                              (unless
                                      (uiop:symbol-call
                                                        :DREYECK/SLICE-SUMMARY/TESTS
                                                        :RUN-SLICE-SUMMARY-TESTS)
                                      (error
                                             "Dreyeck slice-summary tests failed."))))

(asdf:defsystem #:DREYECK/SLY-MREPL :description
                "Model observed SLY mREPL evaluation records" :license "BSD"
                :version "0.0.1" :pathname "dreyeck/src/" :serial t :components
                ((:file "sly-mrepl-package") (:file "sly-mrepl")))

(asdf:defsystem #:DREYECK/EVALUATION-RECORD/SLY-MREPL :description
                "Evaluation-record adapter for SLY mREPL evaluations" :license
                "BSD" :version "0.0.1" :pathname "dreyeck/src/" :serial t
                :depends-on (#:DREYECK/EVALUATION-RECORD #:DREYECK/SLY-MREPL)
                :components ((:file "evaluation-record-sly-mrepl"))
                :in-order-to
                ((asdf:test-op
                               (asdf:test-op
                                             "dreyeck/evaluation-record/sly-mrepl/tests"))))

(asdf:defsystem #:DREYECK/EVALUATION-RECORD/SLY-MREPL/TESTS :description
                "Tests for SLY mREPL evaluation-record integration" :license
                "BSD" :version "0.0.1" :pathname "dreyeck/tests/" :serial t
                :depends-on
                (#:DREYECK/EVALUATION-RECORD/SLY-MREPL #:DREYECK/SLICE-SUMMARY)
                :components
                ((:file "evaluation-record-sly-mrepl-test-package")
                 (:file "evaluation-record-sly-mrepl-smoke"))
                :perform
                (asdf:test-op (operation component)
                              (declare (ignore operation component))
                              (unless
                                      (uiop:symbol-call
                                                        :DREYECK/EVALUATION-RECORD/SLY-MREPL/TESTS
                                                        :RUN-SLY-MREPL-EVALUATION-RECORD-TESTS)
                                      (error
                                             "Dreyeck SLY mREPL evaluation-record tests failed."))))

(asdf:defsystem #:DREYECK/SLY-MREPL/RECORDING :description
                "Capture SLY mREPL evaluations as Dreyeck records" :license
                "BSD" :version "0.0.1" :pathname "dreyeck/src/" :serial t
                :depends-on (#:SLYNK/MREPL #:DREYECK/SLY-MREPL) :components
                ((:file "sly-mrepl-recording-package")
                 (:file "sly-mrepl-recording"))
                :in-order-to
                ((asdf:test-op
                               (asdf:test-op
                                             "dreyeck/sly-mrepl/recording/tests"))))

(asdf:defsystem #:DREYECK/SLY-MREPL/RECORDING/TESTS :description
                "Tests for SLY mREPL evaluation capture" :license "BSD"
                :version "0.0.1" :pathname "dreyeck/tests/" :serial t
                :depends-on
                (#:DREYECK/SLY-MREPL/RECORDING
                                               #:DREYECK/EVALUATION-RECORD/SLY-MREPL)
                :components
                ((:file "sly-mrepl-recording-test-package")
                 (:file "sly-mrepl-recording-smoke"))
                :perform
                (asdf:test-op (operation component)
                              (declare (ignore operation component))
                              (unless
                                      (uiop:symbol-call
                                                        :DREYECK/SLY-MREPL/RECORDING/TESTS
                                                        :RUN-SLY-MREPL-RECORDING-TESTS)
                                      (error
                                             "Dreyeck SLY mREPL recording tests failed."))))

(asdf/parse-defsystem:defsystem #:dreyeck/image-audit
  :description
  "Function reconstruction audits for Dreyeck"
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/src/"
  :serial
  t
  :depends-on
  nil
  :components
  ((:file "image-audit-package") (:file "image-function-audit"))
  :in-order-to
  ((asdf/lisp-action:test-op
    (asdf/lisp-action:test-op "dreyeck/image-audit/tests"))))

(asdf/parse-defsystem:defsystem #:dreyeck/image-audit/tests
  :description
  "Fresh-image smoke tests for Dreyeck image function audits"
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/tests/"
  :serial
  t
  :depends-on
  (#:dreyeck/image-audit)
  :components
  ((:file "image-audit-test-package") (:file "image-function-audit-smoke"))
  :perform
  (asdf/lisp-action:test-op (operation component)
   (declare (ignore operation component))
   (unless
       (uiop/package:symbol-call :dreyeck/image-audit/tests
                                 :run-image-function-audit-tests-in-fresh-process)
     (error "Dreyeck image function audit tests failed."))))

(asdf/parse-defsystem:defsystem #:dreyeck/inspector/image
  :description
  "Dreyeck Inspector views for Lisp image reconstruction audits"
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/src/"
  :serial
  t
  :depends-on
  (#:dreyeck/image-audit #:hyperdoc/inspector #:html-inspector-views/standard)
  :components
  ((:file "image-inspector-package") (:file "image-only-functions-view")))

(asdf/parse-defsystem:defsystem #:dreyeck/issue
  :description
  "Issue references and repository work contexts for Dreyeck"
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/src/"
  :serial
  t
  :depends-on
  (#:dreyeck/git #:dreyeck/topicmap)
  :components
  ((:file "issue-package") (:file "issue-reference")
   (:file "issue-work-context") (:file "issue-work-context-topicmap"))
  :in-order-to
  ((asdf/lisp-action:test-op (asdf/lisp-action:test-op "dreyeck/issue/tests"))))

(asdf/parse-defsystem:defsystem #:dreyeck/issue/tests
  :description
  "Smoke tests for Dreyeck issue work contexts and Topicmap projection"
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/tests/"
  :serial
  t
  :depends-on
  (#:dreyeck/issue #:dreyeck/git/tests #:dreyeck/inspector/topicmap)
  :components
  ((:file "issue-work-context-topicmap-smoke"))
  :perform
  (asdf/lisp-action:test-op (operation component)
   (declare (ignore operation component))
   (uiop/package:symbol-call :dreyeck/issue/tests
                             :run-issue-work-context-topicmap-smoke-tests)))


(defsystem #:dreyeck/fedwiki-publication
  :description
  "Reconstruct publication inputs for a local Federated Wiki context"
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/src/"
  :serial
  t
  :depends-on
  (#:dreyeck/git
   #:dreyeck/fedwiki-assets
   #:dreyeck/local-fedwiki-page)
  :components
  ((:file "fedwiki-publication-package")
   (:file "fedwiki-publication"))
  :in-order-to
  ((test-op
    (test-op "dreyeck/fedwiki-publication/tests"))))

(defsystem #:dreyeck/fedwiki-publication/tests
  :description
  "Tests for FedWiki publication reconstruction"
  :license
  "BSD"
  :version
  "0.0.1"
  :pathname
  "dreyeck/tests/"
  :serial
  t
  :depends-on
  (#:dreyeck/fedwiki-publication)
  :components
  ((:file "fedwiki-publication-test-package")
   (:file "fedwiki-publication-smoke"))
  :perform
  (test-op
   (operation component)
   (declare
    (ignore operation component))
   (uiop:symbol-call
    :dreyeck/fedwiki-publication/tests
    :run-fedwiki-publication-smoke-tests)))


(asdf:defsystem #:dreyeck/fedwiki-journal/topicmap
  :pathname "dreyeck/src/"
  :depends-on
  ("dreyeck/fedwiki-journal"
   "dreyeck/topicmap")
  :components
  ((:file "fedwiki-journal-topicmap"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op
     "dreyeck/fedwiki-journal/topicmap/tests"))))

(asdf:defsystem #:dreyeck/fedwiki-journal/topicmap/tests
  :pathname "dreyeck/tests/"
  :serial t
  :depends-on
  ("dreyeck/fedwiki-journal/topicmap")
  :components
  ((:file "fedwiki-journal-topicmap-test-package")
   (:file "fedwiki-journal-topicmap-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare
    (ignore operation component))
   (unless
       (uiop:symbol-call
        "DREYECK/FEDWIKI-JOURNAL/TOPICMAP/TESTS"
        "RUN-FEDWIKI-JOURNAL-TOPICMAP-TESTS")
     (error
      "FedWiki journal Topicmap tests failed."))))


(asdf:defsystem "dreyeck/page-attached-workspace-offer"
  :depends-on ("hyperbook" "dreyeck/page-attached-workspace-reconstruction")
  :components ((:file "dreyeck/src/page-attached-workspace-offer")))


(asdf:defsystem "dreyeck/page-attached-workspace-offer/tests"
  :depends-on ("dreyeck/page-attached-workspace-offer")
  :components ((:file "dreyeck/src/page-attached-workspace-offer-tests")))


(asdf:defsystem "dreyeck/fresh-image-runner"
  :depends-on ("asdf")
  :components ((:file "dreyeck/src/fresh-image-runner")))
