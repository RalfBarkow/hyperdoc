(in-package #:dreyeck/topicmap/tests)

(defun %authored-widget-count (page)
  "How many source widgets the page file asks for.
This is obtained from the authored HTML, independently of anything the
rendering machinery reports, so the two numbers can disagree."
  (length (plump-dom:get-elements-by-tag-name
           (plump-parser:parse (hyperdoc:file-of page))
           "source-of-function")))

(defun run-reference-reading-tests ()
  (let* ((book (hyperbook:find-hyperbook "dreyeck/topicmap/tala/reading"
                                         :signal-error? t))
         (page (hyperbook:find-page book "A Reference Is Not Necessarily a Widget"
                                    :signal-error? t))
         (non-widget-types nil)
         (pages-checked 0))
    ;; Every page of this book, not only the two the example reports on.
    (loop for candidate being the hash-values of (hyperdoc:pages-of book)
          do (let ((view (find "Content"
                               (html-inspector-views:all-views candidate)
                               :key #'html-inspector-views:view-title
                               :test #'string=)))
               (when view
                 (incf pages-checked)
                 (html-inspector-views:view-html view)
                 (let* ((references (html-inspector-views:view-references view))
                        (widgets (dreyeck/inspector/topicmap/tala::page-widget-references view))
                        (rejected (set-difference references widgets :test #'eq)))
                   ;; The widget count is checked against the authored page,
                   ;; not against a remembered integer.
                   (assert (= (length widgets) (%authored-widget-count candidate)))
                   (dolist (reference rejected)
                     (assert (not (typep (cdr reference)
                                         'html-inspector-views:view)))
                     (pushnew (type-of (cdr reference)) non-widget-types
                              :test #'equal))
                   ;; A transcluded definition is readable; only an
                   ;; example widget also carries a thunk to run. Every
                   ;; thunk that is there must work.
                   (let ((runnable 0))
                     (dolist (widget widgets)
                       (assert (plusp (length (html-inspector-views:view-html
                                               (cdr widget)))))
                       (let ((thunks (remove-if-not
                                      (lambda (reference)
                                        (typep (cdr reference)
                                               'html-inspector-views:thunk))
                                      (html-inspector-views:view-references
                                       (cdr widget)))))
                         (assert (>= 1 (length thunks)))
                         (dolist (thunk thunks)
                           (assert (html-inspector-views:eval-thunk (cdr thunk)))
                           (incf runnable))))
                     (assert (or (zerop (length widgets)) (plusp runnable))))
                   ;; Rendering again must not accumulate references.
                   (html-inspector-views:view-html view)
                   (assert (= (length references)
                              (length (html-inspector-views:view-references view))))
                   (assert (= (length widgets)
                              (length (dreyeck/inspector/topicmap/tala::page-widget-references
                                       view))))))))
    (assert (<= 4 pages-checked))
    ;; The rejected set is heterogeneous: were it only page links, the
    ;; predicate could have been a link test instead of a type test.
    (assert (member 'dreyeck/hyperdoc:html-page non-widget-types :test #'equal))
    (assert (member 'standard-generic-function non-widget-types :test #'equal))
    (assert (< 2 (length non-widget-types)))
    ;; What the page's own example reports must be what the predicate says.
    (let ((reports (dreyeck/inspector/topicmap/tala::reading-page-reference-classification)))
      (assert (= 2 (length reports)))
      (dolist (report reports)
        (let* ((view (dreyeck/inspector/topicmap/tala::reading-page-content-view
                      (getf report :page)))
               (widgets (dreyeck/inspector/topicmap/tala::page-widget-references view)))
          (assert (= (getf report :references)
                     (length (html-inspector-views:view-references view))))
          (assert (= (getf report :widgets) (length widgets)))
          (assert (< (getf report :widgets) (getf report :references)))
          (assert (= (getf report :references) (length (getf report :entries))))
          (assert (= (getf report :widgets)
                     (count t (getf report :entries) :key (lambda (entry)
                                                            (getf entry :widget-p))))))))
    ;; The page is reachable from the book's entry page and links back.
    (let* ((landing (hyperbook:find-page book "Reading TALA as a Layout Layer"
                                         :signal-error? t))
           (content (find "Content" (html-inspector-views:all-views landing)
                          :key #'html-inspector-views:view-title :test #'string=)))
      (html-inspector-views:view-html content)
      (assert (find page (html-inspector-views:view-references content)
                    :key #'cdr :test #'eq))
      (let ((own (find "Content" (html-inspector-views:all-views page)
                       :key #'html-inspector-views:view-title :test #'string=)))
        (html-inspector-views:view-html own)
        (assert (find landing (html-inspector-views:view-references own)
                      :key #'cdr :test #'eq))))
    (format t "~&REFERENCE-READING-PASS: ~D pages, widget count from the authored ~
page, ~D kinds of non-widget reference.~%"
            pages-checked (length non-widget-types))
    t))
