;;;; Smoke tests for generic page-as-ASDF-system reload boundaries.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-PAGE-SYSTEM-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun page-system-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun page-system-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun page-system-assert-contains (needle haystack message)
  (unless (and haystack (search needle haystack :test #'char=))
    (error "~A -- missing substring: ~S" message needle)))

(defun page-system-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun page-system-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun page-system-render-view (object title)
  (let* ((views (page-system-load-inspector-views-for-object object))
         (view (page-system-find-view-by-title views title)))
    (unless view
      (error "Missing inspector view ~S in ~S"
             title
             (mapcar #'html-inspector-views:view-title views)))
    (html-inspector-views:view-html view)))

(defun run-page-system-registry-smoke-test ()
  (let* ((registry (hyperdoc:page-system-registry))
         (systems (hyperdoc:page-system-registry-systems registry))
         (mobile (hyperdoc:find-page-system
                  :hyperdoc/page/mobile-progressive-chrome))
         (dm6 (hyperdoc:find-page-system
               :hyperdoc/page/dm6-appembed-inline-proof))
         (fedwiki (hyperdoc:find-page-system
                   :fedwiki/page/wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc)))
    (page-system-assert-true
     (typep registry 'hyperdoc::page-system-registry)
     "Page-system registry must be an inspectable object")
    (page-system-assert-true
     (>= (length systems) 3)
     "Registry must contain the representative page systems")
    (dolist (system (list mobile dm6 fedwiki))
      (page-system-assert-true
       (typep system 'hyperdoc:page-system)
       (format nil "Registered object must be a page-system: ~A" system)))
    (page-system-assert-equal
     mobile
     (hyperdoc:find-page-system
      "hyperdoc:Mobile progressive chrome in HyperDoc"
      :by :page-locator)
     "Registry must find page systems by page locator")
    (page-system-assert-equal
     fedwiki
     (hyperdoc:find-page-system
      "fedwiki:wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc"
      :by :page-locator)
     "Registry must find FedWiki page systems by page locator")))

(defun run-page-system-asdf-smoke-test ()
  (let ((mobile (hyperdoc:find-page-system
                 :hyperdoc/page/mobile-progressive-chrome)))
    (page-system-assert-true
     (asdf:find-system :hyperdoc/page/mobile-progressive-chrome)
     "ASDF must resolve :hyperdoc/page/mobile-progressive-chrome")
    (asdf:load-system :hyperdoc/page/mobile-progressive-chrome :force t)
    (let ((report (hyperdoc:page-system-reload mobile :force t)))
      (page-system-assert-true
       (typep report 'hyperdoc:page-system-reload-report)
       "page-system-reload must return a reload report")
      (page-system-assert-equal
       "hyperdoc/page/mobile-progressive-chrome"
       (hyperdoc:page-system-reload-report-asdf-system-name report)
       "Reload report must record the delegated ASDF system")
      (page-system-assert-true
       (hyperdoc:page-system-reload-report-loaded-p report)
       "Reload report must record successful ASDF load")
      (page-system-assert-true
       (hyperdoc:page-system-reload-report-display-ready-p report)
       "Reload report must verify the display contract"))))

(defun run-page-system-hyperdoc-mobile-smoke-test ()
  (let ((system (hyperdoc:find-page-system
                 :hyperdoc/page/mobile-progressive-chrome)))
    (page-system-assert-equal
     "Mobile progressive chrome in HyperDoc"
     (hyperdoc:page-system-title system)
     "Mobile page system must report the central page title")
    (page-system-assert-true
     (member "hyperdoc/mobile-progressive-chrome"
             (hyperdoc:page-system-runtime-systems system)
             :test #'string=)
     "Mobile page system must include the feature-slice runtime system")
    (dolist (needle '("Boundary handles"
                      "Capabilities collapse"
                      "Route capture starts only after explicit Connect"))
      (page-system-assert-true
       (find needle
             (hyperdoc:page-system-display-contract system)
             :test #'search)
       (format nil "Mobile display contract must mention ~A" needle)))
    (page-system-assert-true
     (typep (hyperbook:find-page hyperdoc:*hyperdoc*
                                 "Mobile progressive chrome in HyperDoc"
                                 :signal-error? t)
            'hyperdoc::html-page)
     "Mobile page must be discoverable through HyperDoc page lookup")))

(defun run-page-system-dm6-smoke-test ()
  (let ((system (hyperdoc:find-page-system
                 :hyperdoc/page/dm6-appembed-inline-proof)))
    (page-system-assert-equal
     "DM6 AppEmbed HyperDoc Inline Proof"
     (hyperdoc:page-system-title system)
     "DM6 page system must report the proof page")
    (multiple-value-bind (ready warnings)
        (hyperdoc:page-system-display-ready-p system)
      (page-system-assert-true
       ready
       (format nil "DM6 display contract must pass: ~S" warnings)))
    (dolist (path '("assets/dm6-elm/app.js"
                    "assets/dm6-elm/hyperdoc-dm6-inline.js"
                    "assets/dm6-elm/hyperdoc-dm6-inline.css"))
      (page-system-assert-true
       (member path (hyperdoc:page-system-source-files system) :test #'string=)
       (format nil "DM6 page system must expose AppEmbed asset ~A" path)))
    (page-system-assert-true
     (find "Page contains exactly one generated script.dm6-stored"
           (hyperdoc:page-system-display-contract system)
           :test #'string=)
     "DM6 display contract must expose the generated seed invariant")))

(defun run-page-system-fedwiki-smoke-test ()
  (let ((system (hyperdoc:find-page-system
                 :fedwiki/page/wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc)))
    (page-system-assert-contains
     "wiki.ralfbarkow.ch"
     (hyperdoc:page-system-page-locator system)
     "FedWiki page system must report its domain")
    (page-system-assert-contains
     "mobile-progressive-chrome-in-hyperdoc"
     (hyperdoc:page-system-page-locator system)
     "FedWiki page system must report its slug")
    (page-system-assert-true
     (member "hyperbook/fedwiki"
             (hyperdoc:page-system-runtime-systems system)
             :test #'string=)
     "FedWiki page system must include the FedWiki runtime")
    (page-system-assert-true
     (find "Materialization metadata remains inspectable"
           (hyperdoc:page-system-display-contract system)
           :test #'string=)
     "FedWiki page system must expose the materialization contract")
    (multiple-value-bind (ready warnings)
        (hyperdoc:page-system-display-ready-p system)
      (page-system-assert-true
       ready
       (format nil "FedWiki display contract must pass without live network: ~S"
               warnings)))))

(defun run-page-system-inspector-view-smoke-test ()
  (let* ((system (hyperdoc:find-page-system
                  :hyperdoc/page/mobile-progressive-chrome))
         (html (page-system-render-view system "Overview"))
         (provider-html
          (page-system-render-view
           (first (hyperdoc:page-system-runtime-providers system))
           "Overview"))
         (report-html
          (page-system-render-view
           (hyperdoc:page-system-reload system :force nil)
           "Overview"))
         (registry-html
          (page-system-render-view (hyperdoc:page-system-registry) "Overview")))
    (dolist (needle '("hyperdoc/page/mobile-progressive-chrome"
                      "Runtime systems"
                      "Display contract"))
      (page-system-assert-contains
       needle
       html
       "Page-system Overview view must expose ASDF, runtime, and contract"))
    (page-system-assert-contains
     "hyperdoc-runtime"
     provider-html
     "Runtime-provider Overview view must render")
    (page-system-assert-contains
     "Display ready"
     report-html
     "Reload-report Overview view must render")
    (page-system-assert-contains
     "Page system registry"
     registry-html
     "Registry Overview view must render")))

(defun run-page-system-documentation-smoke-test ()
  (let ((page (hyperbook:find-page hyperdoc:*hyperdoc*
                                   "Page systems as ASDF reload boundaries"
                                   :signal-error? t))
        (mobile (hyperbook:find-page hyperdoc:*hyperdoc*
                                     "Mobile progressive chrome in HyperDoc"
                                     :signal-error? t)))
    (dolist (pair `((,page "Page systems as ASDF reload boundaries"
                    ("page-system protocol"
                     "hyperdoc/page/mobile-progressive-chrome"
                     "fedwiki/page/wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc"))
                   (,mobile "Mobile progressive chrome page"
                    ("hyperdoc/page/mobile-progressive-chrome"
                     "page-system protocol"))))
      (let ((text (plump:text (hyperbook:dom-of (first pair)))))
        (dolist (needle (third pair))
          (page-system-assert-contains
           needle
           text
           (format nil "~A documentation must mention ~A"
                   (second pair)
                   needle)))))))

(defun run-page-system-topic-smoke-test ()
  (dolist (title '("Page system"
                   "Page system ASDF boundary"
                   "Page runtime provider"
                   "HyperDoc page system"
                   "FedWiki page system"
                   "Page display contract"
                   "Page reload report"))
    (page-system-assert-true
     (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
     (format nil "Topic cluster must include ~A" title))))

(defun run-page-system-smoke-tests ()
  (run-page-system-registry-smoke-test)
  (run-page-system-asdf-smoke-test)
  (run-page-system-hyperdoc-mobile-smoke-test)
  (run-page-system-dm6-smoke-test)
  (run-page-system-fedwiki-smoke-test)
  (run-page-system-inspector-view-smoke-test)
  (run-page-system-documentation-smoke-test)
  (run-page-system-topic-smoke-test)
  (format t "~&Page-system smoke tests passed.~%")
  t)
