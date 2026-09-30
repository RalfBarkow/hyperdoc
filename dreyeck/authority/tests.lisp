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
       (labels ((thunks (refs)
                  (loop for ref in refs append
                    (cond ((typep ref 'dreyeck/authority-policy:example-thunk) (list ref))
                          ((typep ref 'html-inspector-views:view)
                           (html-inspector-views:view-html ref)
                           (thunks (mapcar #'cdr (html-inspector-views:view-references ref))))))))
         (html-inspector-views:view-html source)
         (let ((runs (thunks (mapcar #'cdr (html-inspector-views:view-references source)))))
           (assert (= 6 (length runs)))
           ;; Execute the actual served Source widgets, not just their functions.
           (dolist (run runs)
             (assert (not (typep (html-inspector-views:eval-thunk run)
                                'dreyeck/authority-policy:invocation-refused))))))))))

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
     (lambda () (check-reading-sequence book) (check-source-views code)))
    (assert (= 5 (hash-table-count (hyperdoc::pages-of book))))
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
    (format t "~&AUTHORITY-READING-PASS: five linked Pages; conceptual Library definitions first; actual source transcluded; six served Source examples run; visible uncontracted method refused before body; contracted observation permitted; gate-removal control fails.~%")
    t))
