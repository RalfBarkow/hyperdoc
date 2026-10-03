;;;; Authority reading acceptance: real references, live guard and control.
(defpackage #:dreyeck/authority/reading/tests
  (:use #:cl)
  (:export #:run-tests))
(in-package #:dreyeck/authority/reading/tests)
(defun check-reading-sequence (book)
  (let ((titles '("Using HyperDoc as a Library"
                  "Reading the HyperDoc Authority Surface"
                  "Authority Surface Witnesses"
                  "Extending HyperDoc Without Granting Authority"
                  "Using Upstream Safely")))
    (loop for rest on titles
          for title = (first rest)
          for page = (hyperbook:find-page book title :signal-error? t)
          do (if (equal title "Authority Surface Witnesses")
                 (assert (typep page 'hyperdoc::code-page))
                 (progn
                   (assert (typep page 'hyperdoc::html-page))
                   (let* ((view (find "Content" (html-inspector-views:all-views page)
                                      :key #'html-inspector-views:view-title :test #'equal))
                          (html (html-inspector-views:view-html view))
                          (refs (mapcar #'cdr (html-inspector-views:view-references view))))
                     (assert (plusp (length html)))
                     (assert (notany (lambda (ref) (typep ref 'condition)) refs))
                     (when (second rest)
                       (assert (member (hyperbook:find-page book (second rest) :signal-error? t) refs)))))))
    ;; Source-backed SEE links lead onward from the Code Page as real Pages.
    (let* ((code (dreyeck/authority/reading:reading-target))
           (links (hyperbook:links-of code)))
      (assert links)
      (assert (find "Extending HyperDoc Without Granting Authority"
                    (hyperbook::page-links-of links) :key #'hyperbook::target-page-of :test #'equal)))
    (assert (equal (hyperbook:main-page-id-of book)
                (first titles)))))

(defun %example-runs (view)
  "The run widgets of the examples in VIEW and the views it transcludes."
  (html-inspector-views:view-html view)
  (loop for ref in (mapcar #'cdr (html-inspector-views:view-references view)) append
    (cond ((typep ref 'dreyeck/authority-policy:example-thunk) (list ref))
          ((typep ref 'html-inspector-views:view) (%example-runs ref)))))

(defun %squeeze (text)
  "TEXT with every run of whitespace read as one space."
  (format nil "~{~A~^ ~}" (remove "" (uiop:split-string text :separator '(#\Space #\Newline #\Tab))
                                  :test #'string=)))

(defun %content (page)
  "PAGE's Content view: its HTML and the objects it refers to."
  (let ((view (find "Content" (html-inspector-views:all-views page)
                    :key #'html-inspector-views:view-title :test #'equal)))
    (values (html-inspector-views:view-html view)
            (mapcar #'cdr (html-inspector-views:view-references view)))))

(defun check-source-views (code)
  (let* ((views (html-inspector-views:all-views code))
         (source (find "Source" views :key #'html-inspector-views:view-title :test #'equal))
         (external (find "Library definitions" views :key #'html-inspector-views:view-title :test #'equal)))
    (assert source)
    (assert external)
    (assert (< (html-inspector-views:view-priority external) (html-inspector-views:view-priority source)))
    (assert (not (find "Reading guide" views :key #'html-inspector-views:view-title :test #'equal)))
    (let ((html (html-inspector-views:view-html external)))
      (assert (search "find-applicable-methods" html))
      (assert (search "eval-button" html))
      (assert (search "set-event-handlers" html))
      (assert (search "load-page" html))
      (assert (search "invocation-decision" html))
      (assert (notany (lambda (ref) (typep ref 'condition))
                      (mapcar #'cdr (html-inspector-views:view-references external)))))
    (dreyeck/authority/reading::under-served-policy
     (lambda ()
       (let ((runs (%example-runs source)))
         (assert (= 6 (length runs)))
         ;; Execute the actual served Source widgets, not just their functions.
         (dolist (run runs)
           (assert (not (typep (html-inspector-views:eval-thunk run)
                              'dreyeck/authority-policy:invocation-refused)))))))))

(defun check-navigation-page (book)
  "Open in Browser Is Navigation follows the five stops as a related case. It
starts from upstream and says that its resolution removes an invocation rather
than authorizing one; its browser witness is local, not dreyeck.ch; it names the
public commit and how the page changes when the adapter goes. Every source it
links or transcludes resolves."
  (let ((page (hyperbook:find-page book "Open in Browser Is Navigation" :signal-error? t))
        (before (hyperbook:find-page book "Using Upstream Safely" :signal-error? t)))
    (assert (typep page 'hyperdoc::html-page))
    (assert (member page (nth-value 1 (%content before))))
    (multiple-value-bind (html refs) (%content page)
      (assert (notany (lambda (ref) (typep ref 'condition)) refs))
      (assert (member before refs))
      (dolist (phrase '("removes the invocation rather than authorizing it"
                        "https://codeberg.org/rgb/hyperdoc/commit/ea31d6c3ce219d5df20bda2291c51e5e49e21ec0"
                        "not against dreyeck.ch"
                        "this reading does not reproduce it"
                        "revise this page to point at upstream"))
        (assert (search phrase (%squeeze html)) () "The page does not say ~S." phrase))
      ;; Upstream objects come first; dreyeck's commits only after them.
      (let ((commit (search "ea31d6c3" html)))
        (dolist (upstream '("WIKIPEDIA-PAGE" "PAGE-URL" "ACTION-BUTTON" "THUNK" "CLOG:OPEN-BROWSER"))
          (assert (< (search upstream html) commit) () "~A appears after the commit." upstream))
        (assert (< commit (search "35a83fdf" html)))))
    (loop for (key) in dreyeck/authority/reading::+navigation-sources+
          do (assert (dreyeck/authority/reading::navigation-source key)))
    (assert (dreyeck/authority/reading::title-bar-action-css)))
  t)

(defun check-navigation-topicmap ()
  "The topicmap's subjects are the upstream and downstream objects themselves,
each relation has a status and a warrant, only CLOG:OPEN-BROWSER reaches the
server host, and nothing in it is about RUNNABLE?."
  (let* ((workspace (dreyeck/authority/reading::open-in-browser-topicmap))
         (projection (dreyeck/topicmap:topicmap-workspace-projection-of workspace))
         (topics (dreyeck/topicmap:topicmap-projection-topics-of projection))
         (associations (dreyeck/topicmap:topicmap-projection-associations-of projection))
         (page-class (find-class 'hyperbook/wikipedia::wikipedia-page)))
    (flet ((object (id)
             (dreyeck/topicmap:topicmap-topic-object-of
              (dreyeck/topicmap:topicmap-projection-topic-by-id projection id)))
           (status (id)
             (getf (dreyeck/topicmap:topicmap-association-properties-of
                    (find id associations :key #'dreyeck/topicmap:topicmap-association-id-of :test #'string=))
                   :epistemic-status))
           (warrant (id)
             (getf (dreyeck/topicmap:topicmap-association-properties-of
                    (find id associations :key #'dreyeck/topicmap:topicmap-association-id-of :test #'string=))
                   :warrant)))
      (assert (eq page-class (object "wikipedia-page")))
      (assert (eq #'hyperbook/wikipedia::page-url (object "page-url")))
      (assert (eq #'html-inspector-views:action-button (object "action-button")))
      (assert (eq (find-class 'html-inspector-views:thunk) (object "thunk")))
      (assert (eq #'clog:open-browser (object "open-browser")))
      (assert (eq (find-method #'html-inspector-views:title-bar-action-buttons '() (list page-class))
                  (object "adapter")))
      ;; ... and that method is the adapter's, not upstream's.
      (assert (equal "wikipedia-title-bar"
                     (pathname-name (sb-introspect:definition-source-pathname
                                     (sb-introspect:find-definition-source (object "adapter"))))))
      ;; The image runs the adapter's method; upstream's is read from its source.
      (assert (search "(clog:open-browser :url (page-url page))"
                      (dreyeck/authority/reading::source-evidence-text (object "upstream-method"))))
      (assert (search ":target \"_blank\""
                      (dreyeck/authority/reading::source-evidence-text (object "external-link"))))
      (assert (equal "ea31d6c3ce219d5df20bda2291c51e5e49e21ec0" (getf (object "commit") :commit)))
      (assert (equal "dreyeck.ch" (getf (object "browser-witness") :not-run-against)))
      (assert (eq (asdf:find-system "dreyeck/wikipedia-title-bar") (object "adapter-system")))
      (dolist (association associations)
        (let ((properties (dreyeck/topicmap:topicmap-association-properties-of association)))
          ;; The statuses other dreyeck topicmaps already use; none invented here.
          (assert (member (getf properties :epistemic-status)
                          '(:source-observed :directly-observed :mechanically-derived
                            :design-inference :working-hypothesis)))
          (assert (stringp (getf properties :warrant)))))
      ;; The page links the map with view="Topicmap"; that view renders.
      (let ((view (find "Topicmap" (html-inspector-views:all-views workspace)
                        :key #'html-inspector-views:view-title :test #'equal)))
        (assert view)
        (assert (plusp (length (html-inspector-views:view-html view)))))
      (assert (eq :source-observed (status "thunk-calls")))
      (assert (eq :directly-observed (status "adapter-emits")))
      (assert (eq :directly-observed (status "link-navigates")))
      (assert (eq :mechanically-derived (status "system-contains")))
      (assert (eq :design-inference (status "url-is-data")))
      (assert (eq :design-inference (status "proposed-for")))
      (assert (search "Proposed upstream change" (warrant "proposed-for")))
      (assert (search "Adapter deletion condition" (warrant "deleted-when")))
      (assert (equal '("open-browser")
                     (loop for association in associations
                           when (string= "server-host" (dreyeck/topicmap:topicmap-association-to-of association))
                             collect (dreyeck/topicmap:topicmap-association-from-of association))))
      (dolist (topic topics)
        (assert (not (search "RUNNABLE" (string-upcase
                                         (format nil "~A ~A" (dreyeck/topicmap:topicmap-topic-id-of topic)
                                                 (dreyeck/topicmap:topicmap-topic-label-of topic))))))
        (let ((object (dreyeck/topicmap:topicmap-topic-object-of topic)))
          (assert (not (and (functionp object)
                            (search "RUNNABLE" (string-upcase (princ-to-string object))))))))
      (dolist (association associations)
        (assert (not (search "RUNNABLE"
                             (string-upcase
                              (format nil "~A ~A ~A" (dreyeck/topicmap:topicmap-association-id-of association)
                                      (dreyeck/topicmap:topicmap-association-type-of association)
                                      (getf (dreyeck/topicmap:topicmap-association-properties-of association)
                                            :warrant)))))))))
  t)

(defun check-title-bar-now (book)
  "The one executable example: served and developing, the same ordinary link to
PAGE-URL in a new tab and no reference. It is the only run widget of its code
page and runs on a served Catalog."
  (let* ((result (dreyeck/authority/reading::title-bar-now))
         (url (getf result :page-url)))
    (assert (string= "https://en.wikipedia.org/wiki/Blog" url))
    (dolist (mode '(:served :development))
      (let* ((bar (getf result mode))
             (links (plump:get-elements-by-tag-name (plump:parse (getf bar :html)) "a")))
        (assert (null (getf bar :references)) () "~A: the title bar offers ~S." mode (getf bar :references))
        (assert (= 1 (length links)))
        (assert (string= url (plump:attribute (first links) "href")))
        (assert (string= "_blank" (plump:attribute (first links) "target")))))
    (assert (equal (getf (getf result :served) :html) (getf (getf result :development) :html))))
  (let* ((code (hyperbook:find-page book "Open in Browser Evidence" :signal-error? t))
         (source (find "Source" (html-inspector-views:all-views code)
                       :key #'html-inspector-views:view-title :test #'equal)))
    (assert (typep code 'hyperdoc::code-page))
    (dreyeck/authority/reading::under-served-policy
     (lambda ()
       (let ((runs (%example-runs source)))
         (assert (= 1 (length runs)))
         (assert (not (typep (html-inspector-views:eval-thunk (first runs))
                             'dreyeck/authority-policy:invocation-refused)))))))
  t)

(defun check-live-witness ()
  (let* ((result (dreyeck/authority/reading:authority-demonstration))
         (negative (getf result :uncontracted))
         (positive (getf result :contracted)))
    (assert (getf result :policy-enforced))
    (dolist (facts (list negative positive))
      (dolist (key '(:exists :applicable :inspector-visible))
        (assert (getf facts key))))
    (assert (null (getf negative :contract)))
    (assert (null (getf negative :evaluate-offered)))
    (assert (eq :refused (getf negative :invocation)))
    (assert (zerop (getf negative :thunk-body-calls)))
    (assert
     (typep (getf negative :result)
            'dreyeck/authority-policy:invocation-refused))
    (assert (getf positive :contract))
    (assert (equal '(:observational) (getf positive :effect-classes)))
    (assert (eq :none (getf positive :required-capability)))
    (assert (getf positive :capability-present))
    (assert (getf positive :invocation-permitted))
    (assert (equal "Authority Surface Witnesses" (getf positive :result)))
    (assert (getf positive :page-id-unchanged))))

(defun run-tests ()
  (let* ((book (hyperbook:find-hyperbook "dreyeck/authority/reading" :signal-error? t))
         (code (dreyeck/authority/reading:reading-target)))
    (dreyeck/authority/reading::under-served-policy
     (lambda () (check-reading-sequence book) (check-source-views code)
       (check-navigation-page book)))
    (check-navigation-topicmap)
    (check-title-bar-now book)
    ;; Five stops, the related navigation page and two code pages.
    (assert (= 7 (hash-table-count (hyperdoc::pages-of book))))
    (dolist (fn '(dreyeck/authority/reading::library-boundary
                 dreyeck/authority/reading::discovery-sources
                 dreyeck/authority/reading::upstream-page-methods
                 dreyeck/authority/reading::policy-sources
                 dreyeck/authority/reading::disclosure-sources
                 dreyeck/authority/reading::intake-sources
                 ;; Current policy-test source: reading fails if those tests are renamed.
                 dreyeck/authority/reading:policy-test-source))
      (assert (funcall fn)))
    (check-live-witness)
    ;; Falsifier: removing the real gate must break the same harmless witness.
    ;; The actual method is restored even if the control itself fails.
    (let* ((gf #'html-inspector-views:eval-thunk)
           (gate (find-method gf '() (list (find-class 'dreyeck/authority-policy:operation-thunk)))))
      (unwind-protect
           (progn (remove-method gf gate)
                  (assert (handler-case
                              (progn (dreyeck/authority/reading:authority-demonstration) nil)
                            (error () t))))
        (add-method gf gate)))
    (check-live-witness)
    (format t "~&AUTHORITY-READING-PASS: five linked Pages; conceptual Library definitions first; actual source transcluded; six served Source examples run; visible uncontracted method refused before body; contracted observation permitted; gate-removal control fails. ~
Open in Browser Is Navigation follows as a related case: upstream first, its sources resolve, its topicmap names the actual objects with a status per relation and no RUNNABLE?, and its one example renders the same link served and developing.~%")
    t))
