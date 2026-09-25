
(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK
  :DESCRIPTION
  "Local dreyeck.ch integration overlay"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T)

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/hyperspec"
  :DESCRIPTION
  "Same-origin HyperSpec policy for the Dreyeck inspector"
  :DEPENDS-ON
  ("hyperdoc/inspector" "uiop")
  :COMPONENTS
  ((:FILE "dreyeck/src/hyperspec")))

(DEFSYSTEM "dreyeck/hyperspec/tests" :DESCRIPTION
 "Tests for HyperDoc inspector adaptations" :AUTHOR
 "Konrad Hinsen <konrad.hinsen@fastmail.net>" :LICENSE "BSD" :VERSION "0.0.1"
 :PATHNAME "tests/" :SERIAL T :DEPENDS-ON
 ("dreyeck/hyperspec" "hyperbook/server" "clack-handler-hunchentoot" "usocket")
 :COMPONENTS ((:FILE "local-hyperspec")) :PERFORM
 (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
  (DECLARE (IGNORE OPERATION COMPONENT))
  (UIOP/PACKAGE:SYMBOL-CALL :HYPERDOC/INSPECTOR/TESTS
                            :RUN-LOCAL-HYPERSPEC-TESTS)))

(DEFSYSTEM "dreyeck/hyperdoc/compatibility-tests" :DESCRIPTION
 "Tests for the HyperDoc core" :AUTHOR "Ralf Barkow" :LICENSE "BSD" :VERSION
 "0.0.1" :PATHNAME "tests/hyperdoc/" :SERIAL T :DEPENDS-ON (#:HYPERDOC)
 :COMPONENTS ((:FILE "package") (:FILE "code-subdirectory")) :PERFORM
 (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
  (DECLARE (IGNORE OPERATION COMPONENT))
  (UNLESS (UIOP/PACKAGE:SYMBOL-CALL :HYPERDOC/TESTS :RUN-TESTS)
    (ERROR "HyperDoc core tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/hyperdoc/boundary-tests"
  :DESCRIPTION
  "Fresh upstream-first page policy boundary"
  :DEPENDS-ON
  ("hyperdoc/explorer" "uiop")
  :COMPONENTS
  ((:FILE "dreyeck/tests/hyperdoc-boundary"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OP COMPONENT) (DECLARE (IGNORE OP COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/HYPERDOC/BOUNDARY-TESTS :RUN-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/hyperdoc/library-tests"
  :DESCRIPTION
  "CST comparison against the verified upstream and retained compatibility inventory"
  :DEPENDS-ON
  ("hyperdoc/explorer" "hyperbook/fedwiki" "hyperbook/server"
   "dreyeck/workflow" "dreyeck/git")
  :COMPONENTS
  ((:FILE "dreyeck/tests/hyperdoc-library-delta"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OP COMPONENT) (DECLARE (IGNORE OP COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/HYPERDOC/LIBRARY-TESTS :RUN-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/hyperdoc"
  :DESCRIPTION
  "Dreyeck page policy using the upstream LOAD-PAGE extension"
  :DEPENDS-ON
  ("hyperdoc/explorer" "plump")
  :COMPONENTS
  ((:FILE "dreyeck/src/hyperdoc-pages")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/WIKI-LINK :DESCRIPTION
                                "Dreyeck FedWiki lookup and story-item operation examples"
                                :LICENSE "BSD" :VERSION "0.0.1" :SERIAL T
                                :DEPENDS-ON
                                ("dreyeck/hyperdoc"
                                 #:HYPERDOC/EXPLORER
                                 #:HYPERBOOK/FEDWIKI)
                                :IN-ORDER-TO
                                ((ASDF/LISP-ACTION:TEST-OP
                                                           (ASDF/LISP-ACTION:TEST-OP
                                                                                     "dreyeck/wiki-link/tests")))
                                :COMPONENTS
                                ((:MODULE "dreyeck/pages" :PATHNAME
                                          "dreyeck/pages/")
                                 (:MODULE "dreyeck/src" :PATHNAME
                                          "dreyeck/src/" :SERIAL T :COMPONENTS
                                          ((:FILE "wiki-link")
                                           (:FILE
                                                  "fedwiki-journal-context-debugger")
                                           (:FILE
                                                  "fedwiki-story-item-transfer")))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/WIKI-LINK/TESTS
  :DESCRIPTION
  "Deterministic tests for Dreyeck FedWiki diagnostic operations"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/WIKI-LINK)
  :COMPONENTS
  ((:FILE "wiki-link-slug-contract")
   (:FILE "fedwiki-journal-context-debugger-smoke")
   (:FILE "fedwiki-story-item-transfer-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/WIKI-LINK/CONTRACT-TESTS
                             :RUN-WIKI-LINK-SLUG-CONTRACT-TESTS)
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/FEDWIKI-JOURNAL-CONTEXT-DEBUGGER/TESTS
                             :RUN-FEDWIKI-JOURNAL-CONTEXT-DEBUGGER-TESTS)
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/FEDWIKI-STORY-ITEM-TRANSFER/TESTS
                             :RUN-FEDWIKI-STORY-ITEM-TRANSFER-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-NAVIGATION
  :DESCRIPTION
  "Replayable Federated Wiki navigation prototype"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :DEPENDS-ON
  (#:ASDF #:UIOP #:HYPERDOC)
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :COMPONENTS
  ((:FILE "fedwiki-navigation") (:FILE "make-navigation-fixture")
   (:FILE "navigation-trace"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/fedwiki-navigation/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/INSPECTOR/FEDWIKI-NAVIGATION
  :DESCRIPTION
  "Inspector views for source-backed FedWiki navigation traces"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/FEDWIKI-NAVIGATION #:HYPERDOC/INSPECTOR #:HTML-INSPECTOR-VIEWS)
  :COMPONENTS
  ((:FILE "navigation-trace-views")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-NAVIGATION/TESTS
  :DESCRIPTION
  "Deterministic tests for source-backed FedWiki navigation traces"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/INSPECTOR/FEDWIKI-NAVIGATION)
  :COMPONENTS
  ((:FILE "fedwiki-navigation-trace-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/FEDWIKI-NAVIGATION/TESTS
                             :RUN-FEDWIKI-NAVIGATION-TRACE-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/TOPICMAP
  :DESCRIPTION
  "Renderer-independent Topicmap projection protocol owned by Dreyeck"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :COMPONENTS
  ((:FILE "topicmap-package") (:FILE "topicmap"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/topicmap/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/topicmap/curation"
  :DESCRIPTION
  "Policy-driven hypothetical impact projections without domain dependencies"
  :DEPENDS-ON
  ("dreyeck/topicmap")
  :SERIAL
  T
  :PATHNAME
  "dreyeck/src/"
  :COMPONENTS
  ((:FILE "topicmap-curation-package") (:FILE "topicmap-curation"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/topicmap/curation/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/topicmap/curation/tests"
  :DEPENDS-ON
  ("dreyeck/topicmap/curation")
  :PATHNAME
  "dreyeck/tests/"
  :COMPONENTS
  ((:FILE "topicmap-curation-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OP COMPONENT) (DECLARE (IGNORE OP COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/TOPICMAP/CURATION/TESTS :RUN-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/hyperdoc/curation"
  :DESCRIPTION
  "Bounded HyperDoc DOM/CST reference evidence and page removal policy"
  :DEPENDS-ON
  ("dreyeck/topicmap/curation" "hyperdoc/explorer" "html-inspector-views"
   "concrete-syntax-tree" "plump" "uiop")
  :SERIAL
  T
  :PATHNAME
  "dreyeck/src/"
  :COMPONENTS
  ((:FILE "hyperdoc-curation-package") (:FILE "hyperdoc-curation"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/hyperdoc/curation/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/hyperdoc/curation/tests"
  :DEPENDS-ON
  ("dreyeck/hyperdoc/curation" "dreyeck/upstream-intake")
  :PATHNAME
  "dreyeck/tests/"
  :COMPONENTS
  ((:FILE "hyperdoc-curation-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OP COMPONENT) (DECLARE (IGNORE OP COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/HYPERDOC/CURATION/TESTS :RUN-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/INSPECTOR/TOPICMAP
  :DESCRIPTION
  "Generic Dreyeck Topicmap view and native CLOG/SVG renderer"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/TOPICMAP #:HYPERDOC/INSPECTOR #:HTML-INSPECTOR-VIEWS
   #:TRIVIAL-PACKAGE-LOCAL-NICKNAMES "clog-moldable-inspector" "dreyeck/gesture/clog")
  :COMPONENTS
  ((:FILE "topicmap-inspector-package") (:FILE "topicmap-gesture")
   (:FILE "topicmap-inspector")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/TOPICMAP/TESTS
  :DESCRIPTION
  "Behavior tests for the Dreyeck Topicmap extension"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/INSPECTOR/TOPICMAP #:ASDF #:UIOP "dreyeck/inspector/topicmap/tala")
  :COMPONENTS
  ((:FILE "topicmap-view-smoke") (:FILE "topicmap-tala-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/TOPICMAP/TESTS
                             :RUN-TOPICMAP-VIEW-SMOKE-TESTS)
   (UIOP:SYMBOL-CALL :DREYECK/TOPICMAP/TESTS :RUN-TALA-INPUT-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-SOURCE-RELATIONS
  :DESCRIPTION
  "Source-backed observation of FedWiki component relations"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/GIT #:DREYECK/TOPICMAP #:HYPERDOC)
  :COMPONENTS
  ((:MODULE "dreyeck/pages/fedwiki-source-relations" :PATHNAME
    "../pages/fedwiki-source-relations/")
   (:FILE "fedwiki-source-relations-package")
   (:FILE "fedwiki-source-relations")
   (:FILE "fedwiki-source-relations-hyperdoc"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/fedwiki-source-relations/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/INSPECTOR/FEDWIKI-SOURCE-RELATIONS
  :DESCRIPTION
  "Inspector views for Dreyeck FedWiki source relations"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/FEDWIKI-SOURCE-RELATIONS #:DREYECK/INSPECTOR/GIT
   #:DREYECK/INSPECTOR/TOPICMAP #:HYPERDOC/INSPECTOR #:HTML-INSPECTOR-VIEWS)
  :COMPONENTS
  ((:FILE "fedwiki-source-relations-inspector-package")
   (:FILE "fedwiki-source-relations-views")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-SOURCE-RELATIONS/TESTS
  :DESCRIPTION
  "Source-backed tests for FedWiki source relations"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/INSPECTOR/FEDWIKI-SOURCE-RELATIONS #:HYPERDOC/EXPLORER)
  :COMPONENTS
  ((:FILE "fedwiki-source-relations-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/FEDWIKI-SOURCE-RELATIONS/TESTS
                             :RUN-FEDWIKI-SOURCE-RELATIONS-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/asdf-source"
  :DESCRIPTION
  "ASDF definition source read as syntax, without READ, ASDF or a repository"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  ("uiop")
  :COMPONENTS
  ((:FILE "asdf-source-package") (:FILE "asdf-source"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP (ASDF/LISP-ACTION:TEST-OP "dreyeck/asdf-source/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/asdf-source/tests"
  :DESCRIPTION
  "Contracts for reading ASDF definition source as syntax"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  ("dreyeck/asdf-source")
  :COMPONENTS
  ((:FILE "asdf-source-tests"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/ASDF-SOURCE/TESTS :RUN-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/GIT
  :DESCRIPTION
  "Experimental Git-backed inspection objects incubated by Dreyeck"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/TOPICMAP #:ASDF #:UIOP "dreyeck/asdf-source")
  :COMPONENTS
  ((:FILE "git-package") (:FILE "git-repository-checkout")
   (:FILE "git-commit-inspection") (:FILE "git-source-slice")
   (:FILE "git-repository-topicmap") (:FILE "git-asdf-references")
   (:FILE "git-asdf-reference-topicmap"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP (ASDF/LISP-ACTION:TEST-OP "dreyeck/git/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/INSPECTOR/GIT
  :DESCRIPTION
  "Dreyeck inspector views for experimental Git objects"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/GIT #:DREYECK/INSPECTOR/TOPICMAP #:HYPERDOC/INSPECTOR
   #:HTML-INSPECTOR-VIEWS)
  :COMPONENTS
  ((:FILE "git-inspector-package") (:FILE "git-commit-inspection-views")
   (:FILE "git-asdf-reference-views")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/workflow/upstream-intake"
  :DESCRIPTION
  "Optional read-only workflow intake; observation grants no authoring capability"
  :DEPENDS-ON
  ("dreyeck/git" "closer-mop")
  :SERIAL
  T
  :PATHNAME
  "dreyeck/src/"
  :COMPONENTS
  ((:FILE "upstream-intake-package") (:FILE "upstream-intake")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/UPSTREAM-INTAKE :DESCRIPTION
                                "Read-only observations of upstream commits and components"
                                :LICENSE "BSD" :VERSION "0.0.1" :PATHNAME
                                "dreyeck/src/" :SERIAL T :DEPENDS-ON
                                ("dreyeck/hyperdoc/curation"
                                 "dreyeck/workflow"
                                 "dreyeck/workflow/upstream-intake"
                                 "dreyeck/hyperdoc")
                                :COMPONENTS
                                ((:MODULE "dreyeck/pages/upstream-intake"
                                          :PATHNAME
                                          "../pages/upstream-intake/")
                                 (:FILE "upstream-intake-hyperdoc")
                                 (:FILE "upstream-page-loading-history"))
                                :IN-ORDER-TO
                                ((ASDF/LISP-ACTION:TEST-OP
                                                           (ASDF/LISP-ACTION:TEST-OP
                                                                                     "dreyeck/upstream-intake/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/INSPECTOR/UPSTREAM-INTAKE
                                :DESCRIPTION
                                "Inspector views for read-only upstream intake observations"
                                :LICENSE "BSD" :VERSION "0.0.1" :PATHNAME
                                "dreyeck/src/" :SERIAL T :DEPENDS-ON
                                ("dreyeck/hyperspec"
                                 #:DREYECK/UPSTREAM-INTAKE
                                 #:DREYECK/INSPECTOR/GIT
                                 #:HYPERDOC/INSPECTOR
                                 #:HTML-INSPECTOR-VIEWS)
                                :COMPONENTS
                                ((:FILE "upstream-intake-inspector-package")
                                 (:FILE "upstream-intake-views")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/CATALOG :DESCRIPTION
                                "Explicit membership and runtime support for the dreyeck.ch HyperBook catalog"
                                :LICENSE "BSD" :VERSION "0.0.1" :DEPENDS-ON
                                ("dreyeck/hyperspec"
                                 #:DREYECK/WIKI-LINK
                                 #:DREYECK/UPSTREAM-INTAKE
                                 #:DREYECK/INSPECTOR/UPSTREAM-INTAKE
                                 #:DREYECK/INSPECTOR/FEDWIKI-SOURCE-RELATIONS
                                 #:DREYECK/LISP-IMAGE
                                 #:DREYECK/PAGE-ATTACHED-WORKSPACE-OFFER
                                 "dreyeck/topicmap/tala/reading"
                                 "dreyeck/upstream-intake/temporal"
                                 "dreyeck/workflow/reading"
                                 "dreyeck/lisp-critic/reading"
                                 "dreyeck/gesture/reading"
                                 "dreyeck/work/reading")
                                :IN-ORDER-TO
                                ((ASDF/LISP-ACTION:TEST-OP
                                                           (ASDF/LISP-ACTION:TEST-OP
                                                                                     "dreyeck/catalog/tests")))
                                :COMPONENTS ((:FILE "dreyeck/src/catalog")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/GIT/TESTS
  :DESCRIPTION
  "Stable local-fixture tests for Dreyeck Git inspection"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/INSPECTOR/GIT #:CLOSER-MOP)
  :COMPONENTS
  ((:FILE "git-commit-inspection-smoke") (:FILE "git-source-slice-smoke")
   (:FILE "git-repository-topicmap-smoke") (:FILE "git-asdf-reference-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/GIT/TESTS
                             :RUN-GIT-COMMIT-INSPECTION-SMOKE-TESTS)
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/GIT/TESTS
                             :RUN-GIT-SOURCE-SLICE-SMOKE-TESTS)
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/GIT/TESTS
                             :RUN-GIT-REPOSITORY-TOPICMAP-SMOKE-TESTS)
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/GIT/ASDF-REFERENCE-TESTS
                             :RUN-GIT-ASDF-REFERENCE-SMOKE-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/UPSTREAM-INTAKE/TESTS :DESCRIPTION
                                "Deterministic read-only Upstream Intake contract tests"
                                :LICENSE "BSD" :VERSION "0.0.1" :PATHNAME
                                "dreyeck/tests/" :SERIAL T :DEPENDS-ON
                                ("dreyeck/workflow"
                                 #:DREYECK/INSPECTOR/UPSTREAM-INTAKE
                                 #:HYPERDOC/EXPLORER
                                 #:HYPERBOOK/FEDWIKI)
                                :COMPONENTS ((:FILE "upstream-intake-smoke"))
                                :PERFORM
                                (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
                                                          (DECLARE
                                                                   (IGNORE
                                                                           OPERATION
                                                                           COMPONENT))
                                                          (UIOP/PACKAGE:SYMBOL-CALL
                                                                                    :DREYECK/UPSTREAM-INTAKE/TESTS
                                                                                    :RUN-UPSTREAM-INTAKE-TESTS)))

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

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/LISP-IMAGE
  :DESCRIPTION
  "dreyeck.ch-owned Lisp image inventory and executable HyperDoc reading path."
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T
  :DEPENDS-ON
  (#:HYPERDOC/EXPLORER)
  :COMPONENTS
  ((:MODULE "dreyeck/src" :PATHNAME "dreyeck/src/" :SERIAL T :COMPONENTS
    ((:FILE "lisp-image-package") (:FILE "lisp-image-inventory")
     (:FILE "lisp-image-definition-sources") (:FILE "lisp-image-observations")
     (:FILE "lisp-image-views") (:FILE "lisp-image-hyperdoc")))
   (:MODULE "dreyeck/pages/lisp-image" :PATHNAME "dreyeck/pages/lisp-image/"
    :COMPONENTS ((:STATIC-FILE "Lisp image HyperBook refactor.html")))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/LISP-IMAGE/TOPICMAP
  :DEPENDS-ON
  (#:DREYECK/LISP-IMAGE #:DREYECK/TOPICMAP)
  :DESCRIPTION
  "Topicmap projection adapter for live Lisp image subjects."
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :COMPONENTS
  ((:FILE "lisp-image-topicmap"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/lisp-image/topicmap/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/LISP-IMAGE/TOPICMAP/TESTS
  :DESCRIPTION
  "Behavior tests for live Lisp image Topicmap projections."
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/LISP-IMAGE/TOPICMAP #:ASDF #:UIOP)
  :COMPONENTS
  ((:FILE "lisp-image-topicmap-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/LISP-IMAGE/TOPICMAP/TESTS
                             :RUN-LISP-IMAGE-TOPICMAP-SMOKE-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-ASSETS
  :DESCRIPTION
  "Read-only discovery of local assets referenced by Federated Wiki pages"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:UIOP #:SHASHT)
  :COMPONENTS
  ((:FILE "fedwiki-assets-package") (:FILE "fedwiki-assets"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/fedwiki-assets/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-ASSETS/TESTS
  :DESCRIPTION
  "Deterministic tests for local FedWiki asset discovery"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/FEDWIKI-ASSETS)
  :COMPONENTS
  ((:FILE "fedwiki-assets-test-package") (:FILE "fedwiki-assets-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/FEDWIKI-ASSETS/TESTS
                                 :RUN-FEDWIKI-ASSETS-TESTS)
     (ERROR "Dreyeck FedWiki assets tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-JOURNAL
  :DESCRIPTION
  "Generic invariant checks and inspectable findings for Federated Wiki journals"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:HYPERBOOK/FEDWIKI #:LOCAL-TIME)
  :COMPONENTS
  ((:FILE "fedwiki-journal-package") (:FILE "fedwiki-journal"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/fedwiki-journal/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-JOURNAL/TESTS
  :DESCRIPTION
  "Deterministic tests for generic Federated Wiki journal checks"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/FEDWIKI-JOURNAL)
  :COMPONENTS
  ((:FILE "fedwiki-journal-test-package") (:FILE "fedwiki-journal-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/FEDWIKI-JOURNAL/TESTS
                                 :RUN-FEDWIKI-JOURNAL-TESTS)
     (ERROR "Dreyeck FedWiki journal tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/PAGE-ATTACHED-ASDF
  :DESCRIPTION
  "Observable registration of trusted page-attached ASDF definitions"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:ASDF #:UIOP)
  :COMPONENTS
  ((:FILE "page-attached-asdf-package") (:FILE "page-attached-asdf"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/page-attached-asdf/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/PAGE-ATTACHED-ASDF/TESTS
  :DESCRIPTION
  "Deterministic tests for page-attached ASDF registration"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/PAGE-ATTACHED-ASDF)
  :COMPONENTS
  ((:FILE "page-attached-asdf-test-package") (:FILE "page-attached-asdf-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/PAGE-ATTACHED-ASDF/TESTS
                                 :RUN-PAGE-ATTACHED-ASDF-TESTS-IN-FRESH-PROCESS)
     (ERROR "Dreyeck page-attached ASDF tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/page-attached-system-projection"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  ("asdf" "dreyeck/page-attached-asdf" "dreyeck/topicmap")
  :COMPONENTS
  ((:FILE "page-attached-system-projection-package")
   (:FILE "page-attached-system-projection"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP
     "dreyeck/page-attached-system-projection/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/page-attached-system-projection/tests"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  ("asdf" "dreyeck/page-attached-asdf"
   "dreyeck/page-attached-system-projection"
   "dreyeck/page-attached-workspace-reconstruction" "dreyeck/topicmap")
  :COMPONENTS
  ((:FILE "page-attached-system-projection-package")
   (:FILE "page-attached-system-projection")
   (:FILE "page-attached-workspace-contract"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/PAGE-ATTACHED-SYSTEM-PROJECTION/TESTS
                             :RUN-PAGE-ATTACHED-SYSTEM-PROJECTION-TESTS)
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/PAGE-ATTACHED-SYSTEM-PROJECTION/TESTS
                             :RUN-PAGE-ATTACHED-WORKSPACE-CONTRACT-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/page-attached-workspace-reconstruction"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  ("asdf" "dreyeck/page-attached-asdf"
   "dreyeck/page-attached-system-projection" "dreyeck/topicmap")
  :COMPONENTS
  ((:FILE "page-attached-workspace-reconstruction")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/page-attached-workspace-reconstruction-runner"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  ("asdf" "uiop" "dreyeck/page-attached-workspace-reconstruction")
  :COMPONENTS
  ((:FILE "page-attached-workspace-reconstruction-runner")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/PAGE-ATTACHED-HYPERDOC
  :DESCRIPTION
  "Observe HyperDocs registered by explicitly loaded ASDF systems"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:ASDF #:HYPERBOOK #:HYPERDOC)
  :COMPONENTS
  ((:FILE "page-attached-hyperdoc-package") (:FILE "page-attached-hyperdoc"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/page-attached-hyperdoc/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/PAGE-ATTACHED-HYPERDOC/TESTS
  :DESCRIPTION
  "Deterministic tests for page-attached HyperDoc activation"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/PAGE-ATTACHED-HYPERDOC)
  :COMPONENTS
  ((:FILE "page-attached-hyperdoc-test-package")
   (:FILE "page-attached-hyperdoc-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/PAGE-ATTACHED-HYPERDOC/TESTS
                                 :RUN-PAGE-ATTACHED-HYPERDOC-TESTS-IN-FRESH-PROCESS)
     (ERROR "Dreyeck page-attached HyperDoc tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-HYPERDOC
  :DESCRIPTION
  "Activate local page-attached HyperDocs from FedWiki assets"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:ASDF #:UIOP #:HYPERBOOK #:HYPERDOC #:DREYECK/FEDWIKI-ASSETS
   #:DREYECK/PAGE-ATTACHED-ASDF #:DREYECK/PAGE-ATTACHED-HYPERDOC)
  :COMPONENTS
  ((:FILE "fedwiki-hyperdoc-package") (:FILE "fedwiki-hyperdoc"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/fedwiki-hyperdoc/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-HYPERDOC-DEMO
  :DESCRIPTION
  "Executable demonstration of local FedWiki page-attached HyperDoc activation"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/FEDWIKI-HYPERDOC #:HYPERDOC/EXPLORER)
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/fedwiki-hyperdoc-demo/tests")))
  :COMPONENTS
  ((:MODULE "dreyeck/pages/fedwiki-hyperdoc-demo" :PATHNAME
    "dreyeck/pages/fedwiki-hyperdoc-demo/")
   (:MODULE "dreyeck/src" :PATHNAME "dreyeck/src/" :COMPONENTS
    ((:FILE "fedwiki-hyperdoc-demo")))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-HYPERDOC-DEMO/TESTS
  :DESCRIPTION
  "Smoke tests for the executable FedWiki HyperDoc demonstration"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/FEDWIKI-HYPERDOC-DEMO)
  :COMPONENTS
  ((:FILE "fedwiki-hyperdoc-demo-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/FEDWIKI-HYPERDOC-DEMO/TESTS
                                 :RUN-FEDWIKI-HYPERDOC-DEMO-TESTS)
     (ERROR "Dreyeck FedWiki HyperDoc demo tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-HYPERDOC/TESTS
  :DESCRIPTION
  "End-to-end tests for local FedWiki page-attached HyperDoc activation"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/FEDWIKI-HYPERDOC)
  :COMPONENTS
  ((:FILE "fedwiki-hyperdoc-test-package") (:FILE "fedwiki-hyperdoc-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/FEDWIKI-HYPERDOC/TESTS
                                 :RUN-FEDWIKI-HYPERDOC-TESTS-IN-FRESH-PROCESS)
     (ERROR "Dreyeck FedWiki HyperDoc tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/LOCAL-FEDWIKI-PAGE
  :DESCRIPTION
  "Local Federated Wiki pages with explicit local provenance"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:UIOP #:HYPERBOOK/FEDWIKI #:DREYECK/FEDWIKI-ASSETS)
  :COMPONENTS
  ((:FILE "local-fedwiki-page-package") (:FILE "local-fedwiki-page"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/local-fedwiki-page/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/LOCAL-FEDWIKI-PAGE/INSPECTOR
  :DESCRIPTION
  "Inspector integration for local Federated Wiki page provenance"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/LOCAL-FEDWIKI-PAGE #:HYPERBOOK/FEDWIKI #:HTML-INSPECTOR-VIEWS)
  :COMPONENTS
  ((:FILE "local-fedwiki-page-inspector-package")
   (:FILE "local-fedwiki-page-inspector")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/LOCAL-FEDWIKI-PAGE/TESTS
  :DESCRIPTION
  "Fresh-process tests for local FedWiki provenance and inspector discovery"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/LOCAL-FEDWIKI-PAGE/INSPECTOR)
  :COMPONENTS
  ((:FILE "local-fedwiki-page-test-package") (:FILE "local-fedwiki-page-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/LOCAL-FEDWIKI-PAGE/TESTS
                                 :RUN-LOCAL-FEDWIKI-PAGE-TESTS-IN-FRESH-PROCESS)
     (ERROR "Dreyeck local FedWiki page tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/LOCAL-FEDWIKI-PAGE/ACTIVATION-INSPECTOR
  :DESCRIPTION
  "Explicit HyperDoc activation from local Federated Wiki page inspection"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/LOCAL-FEDWIKI-PAGE/INSPECTOR #:DREYECK/FEDWIKI-HYPERDOC)
  :COMPONENTS
  ((:FILE "local-fedwiki-page-activation-inspector"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP
     "dreyeck/local-fedwiki-page/activation-inspector/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/LOCAL-FEDWIKI-PAGE/ACTIVATION-INSPECTOR/TESTS
  :DESCRIPTION
  "Fresh-process tests for explicit local FedWiki HyperDoc activation"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/LOCAL-FEDWIKI-PAGE/ACTIVATION-INSPECTOR)
  :COMPONENTS
  ((:FILE "local-fedwiki-page-activation-inspector-test-package")
   (:FILE "local-fedwiki-page-activation-inspector-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL
        :DREYECK/LOCAL-FEDWIKI-PAGE/ACTIVATION-INSPECTOR/TESTS
        :RUN-LOCAL-FEDWIKI-PAGE-ACTIVATION-INSPECTOR-TESTS-IN-FRESH-PROCESS)
     (ERROR "Dreyeck local FedWiki page activation-inspector tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/WIKI-ASSETS-ACCEPTANCE/TESTS
  :DESCRIPTION
  "Fresh-process acceptance of tracked page-attached Wiki asset ASDF systems"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:ASDF #:UIOP)
  :COMPONENTS
  ((:FILE "wiki-assets-acceptance-test-package")
   (:FILE "wiki-assets-acceptance-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/WIKI-ASSETS-ACCEPTANCE/TESTS
                                 :RUN-WIKI-ASSETS-ACCEPTANCE-TESTS-IN-FRESH-PROCESS)
     (ERROR "Dreyeck Wiki-assets acceptance failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/LOCAL-FEDWIKI-VIEW
  :DESCRIPTION
  "Serve locally persisted Federated Wiki JSON through /view/<slug>"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/LOCAL-FEDWIKI-PAGE #:HYPERBOOK/SERVER #:DREYECK/PAGE-ATTACHED-ASDF
   #:DREYECK/CATALOG #:DREYECK/GESTURE/CLOG)
  :COMPONENTS
  ((:FILE "local-fedwiki-view-package") (:FILE "local-fedwiki-view"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/local-fedwiki-view/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/LOCAL-FEDWIKI-VIEW/TESTS
  :DESCRIPTION
  "Server-independence tests for local FedWiki JSON rendering"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/LOCAL-FEDWIKI-VIEW)
  :COMPONENTS
  ((:FILE "local-fedwiki-view-test-package") (:FILE "local-fedwiki-view-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/LOCAL-FEDWIKI-VIEW/TESTS
                                 :RUN-LOCAL-FEDWIKI-VIEW-TESTS)
     (ERROR "Local FedWiki /view tests failed."))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/LOCAL-FEDWIKI-VIEW/TESTS
                                 :RUN-BIND-ADDRESS-TESTS)
     (ERROR "Bind address tests failed."))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/LOCAL-FEDWIKI-VIEW/TESTS
                                 :RUN-LAUNCHER-ROUTE-TESTS)
     (ERROR "Launcher route tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-PAGE-MATERIALIZATION
  :DESCRIPTION
  "Persist raw Federated Wiki Page JSON; fork provenance is an explicit operation"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/FEDWIKI-ASSETS #:SHASHT #:UIOP)
  :COMPONENTS
  ((:FILE "fedwiki-page-materialization-package")
   (:FILE "fedwiki-page-materialization"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/fedwiki-page-materialization/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-PAGE-MATERIALIZATION/TESTS
  :DESCRIPTION
  "Deterministic tests for local FedWiki page materialization"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/FEDWIKI-PAGE-MATERIALIZATION)
  :COMPONENTS
  ((:FILE "fedwiki-page-materialization-test-package")
   (:FILE "fedwiki-page-materialization-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/FEDWIKI-PAGE-MATERIALIZATION/TESTS
                                 :RUN-FEDWIKI-PAGE-MATERIALIZATION-TESTS)
     (ERROR "FedWiki page materialization tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/SHOP3
  :DESCRIPTION
  "SHOP3-backed HTN planning layer owned by Dreyeck"
  :AUTHOR
  "Ralf Barkow <ralf.barkow@me.com>"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T
  :DEPENDS-ON
  (#:HYPERDOC #:SHOP3)
  :COMPONENTS
  ((:MODULE "dreyeck/shop3" :SERIAL T :COMPONENTS
    ((:FILE "package") (:FILE "manual-topics") (:FILE "plan-objects")
     (:FILE "examples") (:FILE "views")))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/STATE-MACHINE
  :DESCRIPTION
  "Generic evidence-bearing state-machine runtime"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :COMPONENTS
  ((:FILE "state-machine-package") (:FILE "state-machine"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/state-machine/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/STATE-MACHINE/TESTS
  :DESCRIPTION
  "Deterministic tests for the generic state-machine runtime"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/STATE-MACHINE)
  :COMPONENTS
  ((:FILE "state-machine-test-package") (:FILE "state-machine-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/STATE-MACHINE/TESTS
                                 :RUN-STATE-MACHINE-TESTS)
     (ERROR "Dreyeck state-machine tests failed."))))

(DEFSYSTEM #:DREYECK/GESTURE-BINDING-WITNESS
  :DESCRIPTION
  "Transient Gesture/Binding recognizer stopping at operation identity"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/STATE-MACHINE #:DREYECK/TOPICMAP)
  :COMPONENTS
  ((:FILE "gesture-binding-witness"))
  :IN-ORDER-TO
  ((TEST-OP (TEST-OP "dreyeck/gesture-binding-witness/tests"))))

(DEFSYSTEM #:DREYECK/GESTURE-BINDING-WITNESS/TESTS
  :DESCRIPTION
  "Counterexample traces that once falsified the Gesture/Binding witness"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/GESTURE-BINDING-WITNESS)
  :COMPONENTS
  ((:FILE "gesture-binding-witness-smoke"))
  :PERFORM
  (TEST-OP (OPERATION COMPONENT) (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (SYMBOL-CALL :DREYECK/GESTURE-BINDING-WITNESS/TESTS
                    :RUN-GESTURE-BINDING-WITNESS-TESTS)
     (ERROR "Gesture/Binding witness tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/gesture/transport"
  :DESCRIPTION
  "Ordered pointer transport feeding the Gesture witness"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T
  :DEPENDS-ON
  ("dreyeck/gesture-binding-witness" "bordeaux-threads" "uiop")
  :COMPONENTS
  ((:FILE "dreyeck/src/gesture-clog-transport")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/gesture/transport/tests"
  :DESCRIPTION
  "Falsifiers for contiguous ordered pointer delivery"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T
  :DEPENDS-ON
  ("dreyeck/gesture/transport" "dreyeck/gesture/reading"
   "dreyeck/gesture-binding-witness/tests")
  :COMPONENTS
  ((:FILE "dreyeck/tests/gesture-clog-transport-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)
   (DECLARE (IGNORE ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/GESTURE/TRANSPORT/TESTS
                             :RUN-GESTURE-TRANSPORT-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/gesture/operation-request"
  :DESCRIPTION
  "An operation and the Lisp source definition it is for, before anything runs"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T
  :DEPENDS-ON
  ("alexandria" "concrete-syntax-tree" "html-inspector-views"
   "html-inspector-views/standard" "hyperdoc" "hyperdoc/explorer"
   "dreyeck/workflow" "dreyeck/gesture-binding-witness"
   "dreyeck/gesture/clog" "clog-moldable-inspector")
  :COMPONENTS
  ((:FILE "dreyeck/src/gesture-operation-request")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/gesture/operation-request/tests"
  :DESCRIPTION
  "What makes two operation requests the same request"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T
  :DEPENDS-ON
  ("dreyeck/gesture/operation-request" "dreyeck/gesture/reading")
  :COMPONENTS
  ((:FILE "dreyeck/tests/gesture-operation-request")
   (:FILE "dreyeck/tests/gesture-source-occurrence")
   (:FILE "dreyeck/tests/gesture-code-page"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)
   (DECLARE (IGNORE ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT))
   (PROGN
    (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/GESTURE/OPERATION-REQUEST/TESTS
                              :RUN-OPERATION-REQUEST-TESTS)
    (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/GESTURE/OPERATION-REQUEST/TESTS
                              :RUN-SOURCE-OCCURRENCE-TESTS)
    (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/GESTURE/CODE-PAGE/TESTS
                              :RUN-CODE-PAGE-GESTURE-TESTS))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/gesture/operation-request/authoring"
  :DESCRIPTION
  "Plan a fully specified operation request as an exact insertion; authoring-side, never in the Catalog"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T
  :DEPENDS-ON
  ("dreyeck/gesture/operation-request" "dreyeck/workflow/authoring")
  :COMPONENTS
  ((:FILE "dreyeck/src/gesture-operation-plan")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/gesture/operation-request/authoring/tests"
  :DESCRIPTION
  "What turns an operation request into a plan, and what refuses to"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T
  :DEPENDS-ON
  ("dreyeck/gesture/operation-request/authoring" "dreyeck/gesture/reading")
  :COMPONENTS
  ((:FILE "dreyeck/tests/gesture-operation-plan"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)
   (DECLARE (IGNORE ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/GESTURE/OPERATION-PLAN/TESTS
                             :RUN-OPERATION-PLAN-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/gesture/clog"
  :DESCRIPTION
  "A CLOG window that owns one marking-menu interaction"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T
  :DEPENDS-ON
  ("clog" "bordeaux-threads" "dreyeck/gesture/transport"
   "dreyeck/gesture-binding-witness" "dreyeck/state-machine")
  :COMPONENTS
  ((:FILE "dreyeck/src/gesture-clog-binder")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/gesture/clog/tests"
  :DESCRIPTION
  "Per-window ownership and serialization of the CLOG gesture binder"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T
  :DEPENDS-ON
  ("dreyeck/gesture/clog")
  :COMPONENTS
  ((:FILE "dreyeck/tests/gesture-clog-binder"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)
   (DECLARE (IGNORE ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/GESTURE/CLOG/TESTS
                             :RUN-GESTURE-CLOG-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/gesture/reading"
  :DESCRIPTION
  "Reading the corrected Gesture/Binding witness through its evidence"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :SERIAL
  T
  :DEPENDS-ON
  ("dreyeck/hyperdoc" "dreyeck/gesture-binding-witness" "dreyeck/state-machine"
   "dreyeck/gesture/transport" "hyperdoc/explorer"
   "dreyeck/gesture/operation-request")
  :COMPONENTS
  ((:MODULE "dreyeck/src" :COMPONENTS ((:FILE "gesture-binding-reading")
                                        (:FILE "gesture-ordering-reading")))
   (:MODULE "dreyeck/pages/gesture" :COMPONENTS
    ((:STATIC-FILE "Falsifying a Gesture-Binding Witness.html")
     (:STATIC-FILE "When Does a Mark Become a Menu.html")))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/gesture/reading/tests" :DESCRIPTION
                                "Falsifiers for the derived reading of a gesture session"
                                :LICENSE "BSD" :VERSION "0.0.1" :SERIAL T
                                :DEPENDS-ON
                                ("dreyeck/gesture/reading" "dreyeck/catalog")
                                :COMPONENTS
                                ((:FILE
                                        "dreyeck/tests/gesture-binding-reading-smoke"))
                                :PERFORM
                                (ASDF/LISP-ACTION:TEST-OP
                                                          (ASDF/OPERATION:OPERATION
                                                                                    ASDF/COMPONENT:COMPONENT)
                                                          (DECLARE
                                                                   (IGNORE
                                                                           ASDF/OPERATION:OPERATION
                                                                           ASDF/COMPONENT:COMPONENT))
                                                          (UIOP/PACKAGE:SYMBOL-CALL
                                                                                    :DREYECK/GESTURE/READING/TESTS
                                                                                    :RUN-GESTURE-READING-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/LISP-CRITIC
  :DESCRIPTION
  "Generic LISP-CRITIC execution contracts and run records"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:ASDF #:UIOP)
  :COMPONENTS
  ((:FILE "lisp-critic-package") (:FILE "lisp-critic"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/lisp-critic/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/LISP-CRITIC/TESTS
  :DESCRIPTION
  "Deterministic tests for generic LISP-CRITIC execution contracts"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/LISP-CRITIC)
  :COMPONENTS
  ((:FILE "lisp-critic-test-package") (:FILE "lisp-critic-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/LISP-CRITIC/TESTS
                                 :RUN-LISP-CRITIC-TESTS)
     (ERROR "Dreyeck LISP-CRITIC tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/EVALUATION-RECORD
  :DESCRIPTION
  "Generic protocol for projecting execution objects as evaluation records"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :COMPONENTS
  ((:FILE "evaluation-record-package") (:FILE "evaluation-record"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/evaluation-record/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/EVALUATION-RECORD/STATE-MACHINE
  :DESCRIPTION
  "Evaluation-record projection for state-machine runs"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :DEPENDS-ON
  (#:DREYECK/EVALUATION-RECORD #:DREYECK/STATE-MACHINE)
  :COMPONENTS
  ((:FILE "evaluation-record-state-machine")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/EVALUATION-RECORD/LISP-CRITIC
  :DESCRIPTION
  "Evaluation-record projection for LISP-CRITIC run records"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :DEPENDS-ON
  (#:DREYECK/EVALUATION-RECORD #:DREYECK/LISP-CRITIC)
  :COMPONENTS
  ((:FILE "evaluation-record-lisp-critic")))

(asdf:defsystem "dreyeck/lisp-critic/critique"
  :description "One-rule Critic execution with explicit domain findings"
  :depends-on ("dreyeck/evaluation-record/lisp-critic" "shasht")
  :components ((:file "dreyeck/src/lisp-critic-critique")
               (:file "dreyeck/src/lisp-critic-snapshot"
                :depends-on ("dreyeck/src/lisp-critic-critique")))
  :in-order-to ((asdf:test-op (asdf:test-op "dreyeck/lisp-critic/critique/tests"))))

(asdf:defsystem "dreyeck/inspector/lisp-critic"
  :depends-on ("dreyeck/lisp-critic/critique" "html-inspector-views")
  :components ((:file "dreyeck/src/lisp-critic-critique-views")))

(asdf:defsystem "dreyeck/lisp-critic/critique/tests"
  :depends-on ("dreyeck/inspector/lisp-critic")
  :components ((:file "dreyeck/tests/lisp-critic-critique"))
  :perform (asdf:test-op (op component)
             (declare (ignore op component))
             (uiop:symbol-call :dreyeck/lisp-critic/critique/tests :run-tests)))

(asdf:defsystem "dreyeck/lisp-critic/reading"
  :description "Source-backed reading of the Lisp Critic genealogy"
  :depends-on ("dreyeck/hyperdoc" "dreyeck/inspector/lisp-critic"
               "dreyeck/inspector/topicmap" "dreyeck/fedwiki-assets"
               "dreyeck/asdf-source"
               "dreyeck/page-attached-workspace-reconstruction"
               "dreyeck/page-attached-workspace-offer"
               ;; The source structure is projected through the same
               ;; readable-D2 boundary the other readings use.
               "dreyeck/topicmap/tala"
               "hyperdoc/explorer")
  :components ((:module "dreyeck/src" :components
                        ((:file "lisp-critic-reading")
                         (:file "historical-claims-views"
                          :depends-on ("lisp-critic-reading"))
                         (:file "lisp-critic-source-projection"
                          :depends-on ("lisp-critic-reading"))))
               (:module "dreyeck/pages/lisp-critic" :components
                        ((:static-file "Reading the Lisp Critic Genealogy.html")
                         (:static-file "The Fischer Critic as an Environment.html")
                         (:static-file "Reading Riesbeck's Lisp Critic.html")
                         (:static-file "From Riesbeck Run to HyperDoc Critique.html")
                         (:static-file "Anatomy of a Critique.html")
                         (:static-file "Where the Source Lives.html"))))
  :in-order-to ((asdf:test-op (asdf:test-op "dreyeck/lisp-critic/reading/tests"))))

(asdf:defsystem "dreyeck/lisp-critic/reading/tests"
  :description "Contracts for the Lisp Critic genealogy reading"
  :depends-on ("dreyeck/lisp-critic/reading")
  :components ((:file "dreyeck/tests/lisp-critic-reading"))
  :perform (asdf:test-op (op component)
             (declare (ignore op component))
             (uiop:symbol-call :dreyeck/lisp-critic/reading/tests :run-tests)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/EVALUATION-RECORD/TESTS
  :DESCRIPTION
  "Tests for generic evaluation-record projections"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/EVALUATION-RECORD/STATE-MACHINE
   #:DREYECK/EVALUATION-RECORD/LISP-CRITIC #:DREYECK/STATE-MACHINE/TESTS)
  :COMPONENTS
  ((:FILE "evaluation-record-test-package") (:FILE "evaluation-record-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/EVALUATION-RECORD/TESTS
                                 :RUN-EVALUATION-RECORD-TESTS)
     (ERROR "Dreyeck evaluation-record tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/WORKSPACE-OPERATION
  :DESCRIPTION
  "Generic workspace operation and invocation records"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :COMPONENTS
  ((:FILE "workspace-operation-package") (:FILE "workspace-operation"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/workspace-operation/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/WORKSPACE-OPERATION/TESTS
  :DESCRIPTION
  "Deterministic tests for workspace operation invocation"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/WORKSPACE-OPERATION)
  :COMPONENTS
  ((:FILE "workspace-operation-test-package")
   (:FILE "workspace-operation-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/WORKSPACE-OPERATION/TESTS
                                 :RUN-WORKSPACE-OPERATION-TESTS)
     (ERROR "Dreyeck workspace-operation tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/EVALUATION-RECORD/WORKSPACE-OPERATION
  :DESCRIPTION
  "Evaluation-record projection for workspace operation invocations"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/EVALUATION-RECORD #:DREYECK/WORKSPACE-OPERATION)
  :COMPONENTS
  ((:FILE "evaluation-record-workspace-operation"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP
     "dreyeck/evaluation-record/workspace-operation/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/EVALUATION-RECORD/WORKSPACE-OPERATION/TESTS
  :DESCRIPTION
  "Tests for workspace operation evaluation-record projection"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/EVALUATION-RECORD/WORKSPACE-OPERATION)
  :COMPONENTS
  ((:FILE "evaluation-record-workspace-operation-test-package")
   (:FILE "evaluation-record-workspace-operation-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL
        :DREYECK/EVALUATION-RECORD/WORKSPACE-OPERATION/TESTS
        :RUN-WORKSPACE-OPERATION-EVALUATION-RECORD-TESTS)
     (ERROR "Workspace-operation evaluation-record tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/SLICE-SUMMARY
  :DESCRIPTION
  "Summary projections over ordered evaluation records"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/EVALUATION-RECORD)
  :COMPONENTS
  ((:FILE "slice-summary-package") (:FILE "slice-summary"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/slice-summary/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/SLICE-SUMMARY/TESTS
  :DESCRIPTION
  "Tests for heterogeneous evaluation-record summaries"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/SLICE-SUMMARY #:DREYECK/EVALUATION-RECORD/STATE-MACHINE
   #:DREYECK/EVALUATION-RECORD/LISP-CRITIC
   #:DREYECK/EVALUATION-RECORD/WORKSPACE-OPERATION
   #:DREYECK/STATE-MACHINE/TESTS)
  :COMPONENTS
  ((:FILE "slice-summary-test-package") (:FILE "slice-summary-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/SLICE-SUMMARY/TESTS
                                 :RUN-SLICE-SUMMARY-TESTS)
     (ERROR "Dreyeck slice-summary tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/SLY-MREPL
  :DESCRIPTION
  "Model observed SLY mREPL evaluation records"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :COMPONENTS
  ((:FILE "sly-mrepl-package") (:FILE "sly-mrepl")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/EVALUATION-RECORD/SLY-MREPL
  :DESCRIPTION
  "Evaluation-record adapter for SLY mREPL evaluations"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/EVALUATION-RECORD #:DREYECK/SLY-MREPL)
  :COMPONENTS
  ((:FILE "evaluation-record-sly-mrepl"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/evaluation-record/sly-mrepl/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/EVALUATION-RECORD/SLY-MREPL/TESTS
  :DESCRIPTION
  "Tests for SLY mREPL evaluation-record integration"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/EVALUATION-RECORD/SLY-MREPL #:DREYECK/SLICE-SUMMARY)
  :COMPONENTS
  ((:FILE "evaluation-record-sly-mrepl-test-package")
   (:FILE "evaluation-record-sly-mrepl-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/EVALUATION-RECORD/SLY-MREPL/TESTS
                                 :RUN-SLY-MREPL-EVALUATION-RECORD-TESTS)
     (ERROR "Dreyeck SLY mREPL evaluation-record tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/SLY-MREPL/RECORDING
  :DESCRIPTION
  "Capture SLY mREPL evaluations as Dreyeck records"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:SLYNK/MREPL #:DREYECK/SLY-MREPL)
  :COMPONENTS
  ((:FILE "sly-mrepl-recording-package") (:FILE "sly-mrepl-recording"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/sly-mrepl/recording/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/SLY-MREPL/RECORDING/TESTS
  :DESCRIPTION
  "Tests for SLY mREPL evaluation capture"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/SLY-MREPL/RECORDING #:DREYECK/EVALUATION-RECORD/SLY-MREPL)
  :COMPONENTS
  ((:FILE "sly-mrepl-recording-test-package")
   (:FILE "sly-mrepl-recording-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/SLY-MREPL/RECORDING/TESTS
                                 :RUN-SLY-MREPL-RECORDING-TESTS)
     (ERROR "Dreyeck SLY mREPL recording tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/IMAGE-AUDIT
  :DESCRIPTION
  "Function reconstruction audits for Dreyeck"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  NIL
  :COMPONENTS
  ((:FILE "image-audit-package") (:FILE "image-function-audit"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/image-audit/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/IMAGE-AUDIT/TESTS
  :DESCRIPTION
  "Fresh-image smoke tests for Dreyeck image function audits"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/IMAGE-AUDIT)
  :COMPONENTS
  ((:FILE "image-audit-test-package") (:FILE "image-function-audit-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/IMAGE-AUDIT/TESTS
                                 :RUN-IMAGE-FUNCTION-AUDIT-TESTS-IN-FRESH-PROCESS)
     (ERROR "Dreyeck image function audit tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/INSPECTOR/IMAGE
  :DESCRIPTION
  "Dreyeck Inspector views for Lisp image reconstruction audits"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/IMAGE-AUDIT #:HYPERDOC/INSPECTOR #:HTML-INSPECTOR-VIEWS/STANDARD)
  :COMPONENTS
  ((:FILE "image-inspector-package") (:FILE "image-only-functions-view")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/ISSUE
  :DESCRIPTION
  "Issue references and repository work contexts for Dreyeck"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/src/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/GIT #:DREYECK/TOPICMAP)
  :COMPONENTS
  ((:FILE "issue-package") (:FILE "issue-reference")
   (:FILE "issue-work-context") (:FILE "issue-work-context-topicmap"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP (ASDF/LISP-ACTION:TEST-OP "dreyeck/issue/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/ISSUE/TESTS
  :DESCRIPTION
  "Smoke tests for Dreyeck issue work contexts and Topicmap projection"
  :LICENSE
  "BSD"
  :VERSION
  "0.0.1"
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  (#:DREYECK/ISSUE #:DREYECK/GIT/TESTS #:DREYECK/INSPECTOR/TOPICMAP)
  :COMPONENTS
  ((:FILE "issue-work-context-topicmap-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/ISSUE/TESTS
                             :RUN-ISSUE-WORK-CONTEXT-TOPICMAP-SMOKE-TESTS)))

(DEFSYSTEM #:DREYECK/FEDWIKI-PUBLICATION :DESCRIPTION
 "Reconstruct publication inputs for a local Federated Wiki context" :LICENSE
 "BSD" :VERSION "0.0.1" :PATHNAME "dreyeck/src/" :SERIAL T :DEPENDS-ON
 (#:DREYECK/GIT #:DREYECK/FEDWIKI-ASSETS #:DREYECK/LOCAL-FEDWIKI-PAGE)
 :COMPONENTS
 ((:FILE "fedwiki-publication-package") (:FILE "fedwiki-publication"))
 :IN-ORDER-TO ((TEST-OP (TEST-OP "dreyeck/fedwiki-publication/tests"))))

(DEFSYSTEM #:DREYECK/FEDWIKI-PUBLICATION/TESTS :DESCRIPTION
 "Tests for FedWiki publication reconstruction" :LICENSE "BSD" :VERSION "0.0.1"
 :PATHNAME "dreyeck/tests/" :SERIAL T :DEPENDS-ON
 (#:DREYECK/FEDWIKI-PUBLICATION) :COMPONENTS
 ((:FILE "fedwiki-publication-test-package")
  (:FILE "fedwiki-publication-smoke"))
 :PERFORM
 (TEST-OP (OPERATION COMPONENT) (DECLARE (IGNORE OPERATION COMPONENT))
  (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/FEDWIKI-PUBLICATION/TESTS
                            :RUN-FEDWIKI-PUBLICATION-SMOKE-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-JOURNAL/TOPICMAP
  :PATHNAME
  "dreyeck/src/"
  :DEPENDS-ON
  ("dreyeck/fedwiki-journal" "dreyeck/topicmap")
  :COMPONENTS
  ((:FILE "fedwiki-journal-topicmap"))
  :IN-ORDER-TO
  ((ASDF/LISP-ACTION:TEST-OP
    (ASDF/LISP-ACTION:TEST-OP "dreyeck/fedwiki-journal/topicmap/tests"))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM #:DREYECK/FEDWIKI-JOURNAL/TOPICMAP/TESTS
  :PATHNAME
  "dreyeck/tests/"
  :SERIAL
  T
  :DEPENDS-ON
  ("dreyeck/fedwiki-journal/topicmap")
  :COMPONENTS
  ((:FILE "fedwiki-journal-topicmap-test-package")
   (:FILE "fedwiki-journal-topicmap-smoke"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UNLESS
       (UIOP/PACKAGE:SYMBOL-CALL "DREYECK/FEDWIKI-JOURNAL/TOPICMAP/TESTS"
                                 "RUN-FEDWIKI-JOURNAL-TOPICMAP-TESTS")
     (ERROR "FedWiki journal Topicmap tests failed."))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/page-attached-workspace-offer"
  :DEPENDS-ON
  ("hyperbook" "html-inspector-views"
   "dreyeck/page-attached-workspace-reconstruction")
  :COMPONENTS
  ((:FILE "dreyeck/src/page-attached-workspace-offer")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/page-attached-workspace-offer/tests"
  :DEPENDS-ON
  ("dreyeck/page-attached-workspace-offer")
  :COMPONENTS
  ((:FILE "dreyeck/src/page-attached-workspace-offer-tests")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/fresh-image-runner"
  :DEPENDS-ON
  ("asdf")
  :COMPONENTS
  ((:FILE "dreyeck/src/fresh-image-runner")))


(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/workflow" :DEPENDS-ON
                                ("asdf"
                                 "uiop"
                                 "sb-introspect"
                                 "html-inspector-views/standard")
                                :COMPONENTS
                                ((:FILE "dreyeck/src/workflow-model")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/workflow/authoring" :DESCRIPTION
                                "Explicit pinned authoring capability; excluded from ordinary Catalog"
                                :DEPENDS-ON ("dreyeck/workflow") :COMPONENTS
                                ((:FILE "dreyeck/src/workflow-authoring")
                                 (:FILE "dreyeck/src/workflow-insert")
                                 (:FILE "dreyeck/src/workflow-cst-replace")
                                 (:FILE "dreyeck/src/workflow-source-range")))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/workflow/reading" :DESCRIPTION
                                "Executable ownership, persistence and reconstruction reading"
                                :SERIAL T :DEPENDS-ON
                                ("dreyeck/hyperdoc"
                                 "dreyeck/workflow"
                                 "hyperdoc/explorer"
                                 "dreyeck/inspector/topicmap/tala")
                                :COMPONENTS
                                ((:MODULE "dreyeck/src" :SERIAL T :COMPONENTS
                                          ((:FILE "workflow-reading")))
                                 (:MODULE "dreyeck/pages/workflow" :COMPONENTS
                                          ((:STATIC-FILE
                                                         "Reconstructing Workflow.html")))))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/workflow/authoring/tests" :DEPENDS-ON
                                ("dreyeck/workflow/authoring"
                                 "dreyeck/workflow/tests")
                                :COMPONENTS
                                ((:FILE "dreyeck/tests/workflow-authoring")
                                 (:FILE "dreyeck/tests/workflow-insert")
                                 (:FILE "dreyeck/tests/workflow-cst-replace")
                                 (:FILE "dreyeck/tests/workflow-source-range")
                                 (:FILE "dreyeck/tests/workflow-persist"))
                                :PERFORM
                                (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
                                                          (DECLARE
                                                                   (IGNORE
                                                                           OPERATION
                                                                           COMPONENT))
                                                          (UIOP/PACKAGE:SYMBOL-CALL
                                                                                    :DREYECK/WORKFLOW/TESTS
                                                                                    :RUN-AUTHORING-TESTS)
                                                          (UIOP/PACKAGE:SYMBOL-CALL
                                                                                    :DREYECK/WORKFLOW/INSERT/TESTS
                                                                                    :RUN-INSERT-TESTS)
                                                          (UIOP/PACKAGE:SYMBOL-CALL
                                                                                    :DREYECK/WORKFLOW/CST-REPLACE/TESTS
                                                                                    :RUN-CST-REPLACE-TESTS)
                                                          (UIOP/PACKAGE:SYMBOL-CALL
                                                                                    :DREYECK/WORKFLOW/SOURCE-RANGE/TESTS
                                                                                    :RUN-SOURCE-RANGE-TESTS)
                                                          (UIOP/PACKAGE:SYMBOL-CALL
                                                                                    :DREYECK/WORKFLOW/PERSIST/TESTS
                                                                                    :RUN-PERSIST-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/workflow/reading/tests"
  :DEPENDS-ON
  ("dreyeck/workflow/reading" "dreyeck/workflow/tests")
  :COMPONENTS
  ((:FILE "dreyeck/tests/workflow-reading"))
  :PERFORM
  (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
   (DECLARE (IGNORE OPERATION COMPONENT))
   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/WORKFLOW/TESTS :RUN-READING-TESTS)))

(ASDF/PARSE-DEFSYSTEM:DEFSYSTEM "dreyeck/workflow/tests" :PERFORM
                                (ASDF/LISP-ACTION:TEST-OP (OPERATION COMPONENT)
                                                          (DECLARE
                                                                   (IGNORE
                                                                           OPERATION
                                                                           COMPONENT))
                                                          (UIOP/PACKAGE:SYMBOL-CALL
                                                                                    :DREYECK/WORKFLOW/TESTS
                                                                                    :RUN-TESTS))
                                :PATHNAME "dreyeck/tests/" :SERIAL T
                                :DEPENDS-ON ("dreyeck/workflow") :COMPONENTS
                                ((:FILE "workflow-model")))


(defsystem "dreyeck/topicmap/tala"
  :description "Experimental deterministic Projection to D2/TALA rendering boundary"
  :license "BSD" :serial t
  :depends-on ("dreyeck/topicmap" "uiop" "plump" "cl-base64")
  :components ((:file "dreyeck/src/topicmap-tala")))

(defsystem "dreyeck/inspector/topicmap/tala"
  :description "Explicit native/TALA comparison of an existing Topicmap Workspace"
  :license "BSD" :serial t
  :depends-on ("dreyeck/topicmap/tala" "dreyeck/inspector/topicmap" "dreyeck/git" "babel"
               "plump")
  :components ((:file "dreyeck/src/topicmap-tala-inspector")))

(asdf/parse-defsystem:defsystem "dreyeck/topicmap/tala/reading" :description
                                "Executable reading companion for the experimental TALA layout boundary"
                                :license "BSD" :serial t :depends-on
                                ("dreyeck/hyperdoc"
                                 "dreyeck/inspector/topicmap/tala"
                                 "dreyeck/lisp-image/topicmap"
                                 "hyperdoc/explorer")
                                :components
                                ((:module "dreyeck/src" :components
                                          ((:file "topicmap-tala-reading")
                                           (:file "topicmap-tala-authored")
                                           (:file "topicmap-tala-dispatch-reading")
                                           (:file "topicmap-tala-reference-reading")))
                                 (:module "dreyeck/pages/topicmap-tala"
                                          :components
                                          ((:static-file
                                                         "Reading TALA as a Layout Layer.html")
                                           (:static-file
                                                         "Writing D2 by Hand.html")
                                           (:static-file
                                                         "From DEFVIEW to Generic Dispatch.html")
                                           (:static-file
                                                         "A Reference Is Not Necessarily a Widget.html")))))

(asdf/parse-defsystem:defsystem "dreyeck/topicmap/tala/reading/tests"
  :description
  "Fresh reconstruction and executable reading-page tests"
  :license
  "BSD"
  :serial
  t
  :depends-on
  ("dreyeck/topicmap/tala/reading" "dreyeck/topicmap/tests")
  :components
  ((:file "dreyeck/tests/topicmap-tala-reading-smoke")
   (:file "dreyeck/tests/topicmap-tala-authored-smoke")
   (:file "dreyeck/tests/topicmap-tala-dispatch-reading-smoke")
   (:file "dreyeck/tests/topicmap-tala-reference-reading-smoke"))
  :perform
  (asdf/lisp-action:test-op (operation component)
   (declare (ignore operation component))
   (uiop/package:symbol-call :dreyeck/topicmap/tests
                             :run-tala-integration-tests)
   (uiop/package:symbol-call :dreyeck/topicmap/tests :run-tala-reading-tests)
   (uiop/package:symbol-call :dreyeck/topicmap/tests :run-authored-d2-tests)
   (uiop/package:symbol-call :dreyeck/topicmap/tests :run-dispatch-reading-tests)
   (uiop/package:symbol-call :dreyeck/topicmap/tests
                             :run-reference-reading-tests)))

(defsystem "dreyeck/upstream-intake/temporal"
  :description "The observed page-loading history as a Topicmap, D2 and TALA projection"
  :license "BSD" :serial t
  :depends-on ("dreyeck/upstream-intake" "dreyeck/inspector/topicmap/tala"
               "dreyeck/hyperdoc" "hyperdoc/explorer")
  :components ((:module "dreyeck/src"
                :components ((:file "upstream-temporal-projection")))
               (:module "dreyeck/pages/upstream-temporal"
                :components ((:static-file "Page-Loading Contract Evolution.html"))))
  :in-order-to ((test-op (test-op "dreyeck/upstream-intake/temporal/tests"))))

(defsystem "dreyeck/upstream-intake/temporal/tests"
  :description "The temporal projection derives from the history and mutates nothing"
  :license "BSD" :serial t
  ;; dreyeck/lisp-critic/reading is here for what it defines, not for what
  ;; it does: views specialized on CONS. Those are offered every list in
  ;; the image, so one of them reading an unchecked GETF broke Inspector
  ;; panes for the identity maps. Without this system loaded the
  ;; regression test cannot see the defect it exists to catch.
  :depends-on ("dreyeck/upstream-intake/temporal" "dreyeck/topicmap/tests"
               "dreyeck/lisp-critic/reading")
  :components ((:file "dreyeck/tests/upstream-temporal-projection-smoke"))
  :perform (test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :dreyeck/upstream-intake/temporal/tests
                               :run-temporal-projection-tests)))

(defsystem "dreyeck/topicmap/tala/tests"
  :description "Fresh-process integration proof requiring pinned D2/TALA"
  :depends-on ("dreyeck/topicmap/tests")
  :perform (test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :dreyeck/topicmap/tests :run-tala-integration-tests)))

(defsystem "dreyeck/topicmap/gesture/tests"
  :description "Workspace action sign occurrences and contextual input"
  :depends-on ("dreyeck/topicmap/tala/reading")
  :serial t
  :components ((:file "dreyeck/tests/topicmap-gesture")
               (:file "dreyeck/tests/topicmap-gesture-browser"))
  :perform (test-op (op component)
             (declare (ignore op component))
             (uiop:symbol-call :dreyeck/topicmap/gesture/tests
                               :run-workspace-action-sign-tests)))

(defsystem "dreyeck/work/reading"
  :description "HyperDoc work pages and one complete D2 Connections example"
  :depends-on ("dreyeck/topicmap/tala/reading")
  :serial t
  :components ((:module "dreyeck/work" :components ((:file "reading")))
               (:module "dreyeck/pages/work" :components
                ((:static-file "Work Breakdown.html")
                 (:static-file "Interaction.html")
                 (:static-file "Operations and Change.html")
                 (:static-file "Connect and Associations.html")
                 (:static-file "State and Persistence.html")
                 (:static-file "HyperDoc Dogfooding.html")
                 (:static-file "D2 Corpus.html")
                 (:static-file "Planning with SHOP3.html")
                 (:static-file "D2 Connections.html")
                 (:static-file "Relation Contract informs.html")))))

(defsystem "dreyeck/work/reading/tests"
  :depends-on ("dreyeck/work/reading" "clog-moldable-inspector" "fset")
  :serial t
  :components ((:file "dreyeck/tests/work-reading")
               (:file "dreyeck/tests/work-reading-live"))
  :perform (test-op (op component)
             (declare (ignore op component))
             (uiop:symbol-call :dreyeck/work/tests :run-tests)))

(defsystem "dreyeck/work/planning"
  :description "Optional in-memory SHOP3 documentation experiment; no executor"
  :depends-on ("dreyeck/work/reading" "dreyeck/shop3")
  :components ((:file "dreyeck/work/planning")))

(defsystem "dreyeck/work/planning/tests"
  :depends-on ("dreyeck/work/planning")
  :components ((:file "dreyeck/tests/work-planning"))
  :perform (test-op (op component)
             (declare (ignore op component))
             (uiop:symbol-call :dreyeck/work/planning :check-plan)))
