;;;; Open in Browser Evidence
;;;;
;;;; Source objects, one executable example and a topicmap for the page "Open
;;;; in Browser Is Navigation". Upstream definitions are read from the installed
;;;; source, as on Authority Surface Witnesses: the running image no longer has
;;;; upstream's Wikipedia title-bar method, because dreyeck/wikipedia-title-bar
;;;; replaces it. When that adapter is deleted, revise this file and the page to
;;;; read upstream's own implementation; do not delete them.

(in-package #:dreyeck/authority/reading)

(hyperdoc:see (hyperdoc:page "Open in Browser Is Navigation" :hyperbook "dreyeck/authority/reading"))

;;; Where each object of the reading is defined, in the page's order.
(defparameter +navigation-sources+
  '((:wikipedia-page "hyperbook/wikipedia" "hyperbook-wikipedia/wikipedia.lisp"
     "(defclass wikipedia-page")
    (:page-url "hyperbook/wikipedia" "hyperbook-wikipedia/wikipedia.lisp"
     "(defun page-url")
    (:upstream-title-bar "hyperbook/wikipedia" "hyperbook-wikipedia/wikipedia.lisp"
     "(defmethod views:title-bar-action-buttons ((page wikipedia-page))")
    (:title-bar-generic "html-inspector-views" "title-bar.lisp"
     "(defgeneric title-bar-action-buttons")
    (:action-button "html-inspector-views" "html.lisp" "(defun action-button")
    (:thunk "html-inspector-views" "thunks.lisp" "(defmacro thunk")
    (:click-handler "clog-moldable-inspector" "inspector.lisp" "(defun set-event-handlers")
    (:open-browser "clog" "source/clog-system.lisp" "(defun open-browser")
    (:content-links "hyperbook/wikipedia" "hyperbook-wikipedia/wikipedia.lisp"
     "(defun adapt-dom")
    (:adapter "dreyeck/wikipedia-title-bar" "dreyeck/src/wikipedia-title-bar.lisp"
     "(defmethod html-inspector-views:title-bar-action-buttons")
    (:active-button "clog-moldable-inspector" "inspector.lisp"
     "(defun eval-thunk-with-active-button")
    (:adapter-test "dreyeck" "dreyeck/tests/wikipedia-title-bar.lisp"
     "(defun check-title-bar-link")
    (:adapter-titles "dreyeck" "dreyeck/tests/wikipedia-title-bar.lisp"
     "(defun check-titles")
    (:navigation-test "dreyeck" "dreyeck/tests/authority-policy.lisp"
     "(defun check-wikipedia-open-is-navigation")
    (:proposed-method "dreyeck" "dreyeck/tests/wikipedia-title-bar.lisp"
     "(defparameter +linked-upstream-method+")
    (:staleness-test "dreyeck" "dreyeck/tests/wikipedia-title-bar.lisp"
     "(defun upstream-still-replaced-p")
    (:render-fetch "hyperbook/wikipedia" "hyperbook-wikipedia/wikipedia.lisp"
     "(views:defview views:👀source (page wikipedia-page)")
    (:fedwiki-open "hyperbook/fedwiki" "hyperbook-fedwiki/views.lisp"
     "(defmethod views:title-bar-action-buttons ((wiki fedwiki))")
    (:fedwiki-page-open "hyperbook/fedwiki" "hyperbook-fedwiki/pages.lisp"
     "(defmethod views:title-bar-action-buttons ((page fedwiki-page))")
    (:remote-fedwiki-page-open "hyperbook/fedwiki" "hyperbook-fedwiki/pages.lisp"
     "(defmethod views:title-bar-action-buttons ((page remote-fedwiki-page))")))

(defun navigation-source (key)
  (destructuring-bind (system file marker) (rest (assoc key +navigation-sources+))
    (source-form system file marker)))

(defun navigation-source-view (key)
  (evidence-source (navigation-source key)))

(defun title-bar-action-css ()
  "The CSS rule that gives a title-bar element with class inspector-action its look."
  (let* ((file "inspector.lisp")
         (marker ".inspector-title-bar .inspector-action {")
         (text (uiop:read-file-string (asdf:system-relative-pathname "clog-moldable-inspector" file)
                                      :external-format :utf-8))
         (start (search marker text))
         (end (and start (position #\} text :start start))))
    (assert end () "CSS rule absent: clog-moldable-inspector / ~A: ~A" file marker)
    (let ((rule (subseq text start (1+ end))))
      (make-source-evidence
       :origin (format nil "clog-moldable-inspector / ~A — ~A [source SHA-256 ~A]"
                       file marker
                       (ironclad:byte-array-to-hex-string
                        (ironclad:digest-sequence :sha256
                         (sb-ext:string-to-octets rule :external-format :utf-8))))
       :text rule))))

;;; The commit and the manual browser witness, as recorded; not re-run here.
(defparameter +navigation-commit+
  '(:commit "ea31d6c3ce219d5df20bda2291c51e5e49e21ec0"
    :url "https://codeberg.org/rgb/hyperdoc/commit/ea31d6c3ce219d5df20bda2291c51e5e49e21ec0"
    :subject "fix(wikipedia): open external pages in the client browser"
    :replaces-upstream "khinsen/hyperdoc 8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"))

(defparameter +manual-browser-witness+
  '(:kind :manual-browser-witness :commit "ea31d6c3"
    :sources :packaged :host "127.0.0.1"
    :servers (:public-mode-catalog :development-server)
    :not-run-against "dreyeck.ch"
    :reproduced-by-this-reading nil
    :click :trusted :reached :window-bubble-phase :default-prevented nil
    :control "a handler that cancels the click was detected as cancelled"
    :external-navigation :cancelled-by-the-witness
    :clog-open-browser-calls 0
    :separately "one render-time Wikipedia API request from upstream's Source or Parse tree view, intercepted on the server; not on the title-bar path"))

;;; The one executable example. Which method renders the title bar depends on
;;; what the image has loaded, so the claim "an ordinary link, no reference,
;;; served and developing alike" is checked only by running it. It allocates an
;;; unregistered page and fetches nothing; nothing is clicked.
(defun %title-bar-with-server-parameters (parameters page)
  (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server)) (list parameters)
    (let* ((view (hv:title-bar-action-buttons page))
           (html (hv:view-html view)))
      (list :html html :references (hv:view-references view)))))

(hyperdoc:defexample title-bar-now
  (let ((page (make-instance 'hyperbook/wikipedia::wikipedia-page
                             :hyperbook (hyperbook/wikipedia::make-wikipedia "en" "Wikipedia" "Main Page")
                             :id "Blog" :title "Blog")))
    (list :page-url (hyperbook/wikipedia::page-url page)
          :method (find-method #'hv:title-bar-action-buttons '()
                               (list (find-class 'hyperbook/wikipedia::wikipedia-page)))
          :served (%title-bar-with-server-parameters '("700px" nil) page)
          :development (%title-bar-with-server-parameters '("700px" t) page))))

(ap:register-operation-contract
 :identity "authority-reading/title-bar-now"
 :operation "DREYECK/AUTHORITY/READING::TITLE-BAR-NOW"
 :applicability :example :status :contracted :effect-classes '(:observational)
 :effect-extent "Allocates an unregistered Wikipedia book and page and renders its title bar under dynamic served and development parameters; fetches nothing and clicks nothing"
 :authority "the named reading example and the title-bar methods loaded in the image"
 :preconditions "reading system loaded"
 :postconditions "no file, registry, page cache, server, network or inspected target is changed by running the example"
 :verification-evidence "dreyeck/authority/reading/tests: one link to PAGE-URL in a new tab, no reference, served and developing alike"
 :replay-semantics "repeatable observation"
 :audit-provenance "dreyeck/authority/reading, source reviewed 2026-10-03")

;;; Two paths from PAGE-URL, with the status of each relation.
(defun open-in-browser-topicmap ()
  (flet ((topic (id label object x y)
           (dreyeck/topicmap:make-topicmap-topic :id id :type :open-in-browser :label label :object object
                                   :view-properties (list :x x :y y :visible t))))
    ;; Boxes are 210 wide; the view centres on its point, PAGE-URL, so the map is
    ;; laid out around it: upstream path left, downstream path right, evidence
    ;; outside that.
    (let* ((topics
             (list (topic "wikipedia-page" "WIKIPEDIA-PAGE"
                          (find-class 'hyperbook/wikipedia::wikipedia-page) 515 40)
                   (topic "page-url" "PAGE-URL" #'hyperbook/wikipedia::page-url 515 350)
                   (topic "upstream-method" "upstream method (8a114919)"
                          (navigation-source :upstream-title-bar) 30 40)
                   (topic "action-button" "ACTION-BUTTON" #'hv:action-button 30 190)
                   (topic "thunk" "THUNK" (find-class 'hv:thunk) 30 350)
                   (topic "open-browser" "CLOG:OPEN-BROWSER" #'clog:open-browser 30 510)
                   (topic "server-host" "process on the server host" nil 30 660)
                   (topic "proposed-change" "minimal HyperDoc change" (navigation-source :proposed-method) 275 660)
                   (topic "adapter" "adapter method (ea31d6c3)"
                          (find-method #'hv:title-bar-action-buttons '()
                                       (list (find-class 'hyperbook/wikipedia::wikipedia-page)))
                          770 160)
                   (topic "external-link" "link, target _blank" (navigation-source :adapter) 770 350)
                   (topic "visitor-browser" "visitor's browser" nil 770 530)
                   (topic "commit" "commit ea31d6c3" +navigation-commit+ 1000 40)
                   (topic "regression" "navigation regression" (navigation-source :navigation-test) 1000 250)
                   (topic "browser-witness" "manual browser witness" +manual-browser-witness+ 1000 440)
                   (topic "adapter-system" "adapter system, temporary"
                          (asdf:find-system "dreyeck/wikipedia-title-bar") 1000 660)))
           ;; Statuses are those the other dreyeck topicmaps use: SOURCE-OBSERVED
           ;; read in source, DIRECTLY-OBSERVED in a running image or run,
           ;; MECHANICALLY-DERIVED by a fixed rule, DESIGN-INFERENCE a judgment
           ;; about a representation or decision.
           (associations
             (loop for (id from to type status warrant)
                     in '(("url-of" "page-url" "wikipedia-page" :reads :source-observed
                           "PAGE-URL builds the address from the page's edition and title.")
                          ("upstream-for" "upstream-method" "wikipedia-page" :specializes-on :source-observed
                           "The upstream method's only parameter is a WIKIPEDIA-PAGE.")
                          ("upstream-uses-url" "upstream-method" "page-url" :reads :source-observed
                           "The thunk body passes (page-url page) to CLOG:OPEN-BROWSER.")
                          ("upstream-button" "upstream-method" "action-button" :constructs :source-observed
                           "Upstream source: the method returns an ACTION-BUTTON.")
                          ("button-thunk" "action-button" "thunk" :refers-to :source-observed
                           "ACTION-BUTTON gives the button an action- id for the THUNK; the Inspector's click handler evaluates it.")
                          ("thunk-calls" "thunk" "open-browser" :calls :source-observed
                           "Upstream source: the thunk's body is (clog:open-browser :url (page-url page)).")
                          ("opens-on-host" "open-browser" "server-host" :launches :source-observed
                           "CLOG source: UIOP:LAUNCH-PROGRAM of open or xdg-open, a web browser on the local machine, which is the machine running the server.")
                          ("url-is-data" "page-url" "external-link" :can-be-carried-by :design-inference
                           "PAGE-URL exists before any thunk and following a URL needs no Lisp, so an href can carry it in place of the action.")
                          ("adapter-replaces" "adapter" "upstream-method" :replaces :directly-observed
                           "FIND-METHOD for WIKIPEDIA-PAGE in this image returns the method defined in dreyeck/src/wikipedia-title-bar.lisp.")
                          ("adapter-uses-url" "adapter" "page-url" :reads :source-observed
                           "The adapter's href is (cl-who:escape-string (page-url page)).")
                          ("adapter-emits" "adapter" "external-link" :emits :directly-observed
                           "Tests: one anchor, class href target only, href reads back as PAGE-URL, no reference.")
                          ("link-navigates" "external-link" "visitor-browser" :navigates :directly-observed
                           "Manual browser witness: the click reached window bubble phase with defaultPrevented=false; the witness then cancelled navigation itself.")
                          ("commit-introduces" "commit" "adapter" :introduces :source-observed
                           "ea31d6c3 adds dreyeck/src/wikipedia-title-bar.lisp.")
                          ("regression-asserts" "regression" "external-link" :asserts :directly-observed
                           "Run served and developing: the same visible link, no reference, zero CLOG:OPEN-BROWSER calls.")
                          ("witness-observes" "browser-witness" "external-link" :observes :directly-observed
                           "Packaged sources on 127.0.0.1, a public-mode Catalog and a development server, not dreyeck.ch.")
                          ("system-contains" "adapter-system" "adapter" :contains :mechanically-derived
                           "The ASDF system's only component is the file that defines the method.")
                          ("proposed-for" "proposed-change" "upstream-method" :would-replace :design-inference
                           "Proposed upstream change for khinsen/hyperdoc: the same link, rendered by upstream's own method.")
                          ("deleted-when" "adapter-system" "proposed-change" :deleted-when-pinned :design-inference
                           "Adapter deletion condition: once pinned upstream navigates in the client, delete the adapter, its test and systems; keep the regression; revise the reading."))
                   collect (dreyeck/topicmap:make-topicmap-association
                            :id id :type type :from from :to to
                            :properties (list :presentation :relation
                                              :epistemic-status status :warrant warrant)))))
      (dreyeck/topicmap:make-topicmap-workspace
       (dreyeck/topicmap:make-topicmap-projection :source "Open in Browser Is Navigation"
                                    :topics topics :associations associations
                                    :view-properties '(:width 1240 :height 760))
       "page-url"))))
