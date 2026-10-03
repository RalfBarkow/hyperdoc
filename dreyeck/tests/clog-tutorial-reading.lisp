;;;; The CLOG Tutorial book is the collection; its Tutorial 01 page reaches
;;;; both ends of the route, which is read from CLOG.
;;;;
;;;; As in the integration tests, no listener is opened. What is checked is
;;;; what the views say and refer to: the handler's link opens its source,
;;;; and the URL view sends the route's path for the browser to complete.
;;;; That the completed link loads a working tutorial takes a browser.
(defpackage #:dreyeck/clog-tutorial/reading/tests
  (:use #:cl)
  (:local-nicknames (#:r #:dreyeck/clog-tutorial/reading)
                    (#:tut #:dreyeck/clog-tutorial)
                    (#:hv #:html-inspector-views))
  (:export #:run-tests))

(in-package #:dreyeck/clog-tutorial/reading/tests)

(defun call-with-clog (thunk)
  "THUNK's value, with CLOG taken to be running and the route's entries put
back afterwards; see the integration tests' CALL-WITH-CLOG."
  (getf (dreyeck/clog-tutorial/tests::call-with-clog t thunk) :value))

(defun %rendered (view)
  "VIEW's HTML and its references, html-id to object."
  (values (hv:view-html view) (hv:view-references view)))

(defun %source-code-link-p (reference object)
  "True when REFERENCE inspects OBJECT and selects its Source code view."
  (and (eq object (cdr reference))
       (uiop:string-suffix-p (car reference)
                             (concatenate 'string "-" (hv::encode-base32 "Source code")))))

(defun %transcluded-sources (references)
  "The HTML of the Source code views among REFERENCES' transclusions:
what a page's <source-of-function> shows, which is not in the page's own
HTML but in a view the page transcludes."
  (loop for (id . object) in references
        when (and (uiop:string-prefix-p "transclusion-" id)
                  (typep object 'hv:view)
                  (equal "Source code" (hv:view-title object)))
          collect (hv:view-html object)))

(defun %view-titled (title references)
  "The view titled TITLE among REFERENCES, or NIL."
  (cdr (find-if (lambda (object) (and (typep object 'hv:view) (equal title (hv:view-title object))))
                references :key #'cdr)))

(defun check-route-reads-clog ()
  "Unmounted, mounted, and another handler at the same path: three states
of one table, and the live link exists only in the second."
  (call-with-clog
   (lambda ()
     (let* ((route (r:tutorial-1-route))
            (handler (fdefinition (r:route-handler route))))
       (assert (eq :not-mounted (r:route-state route)))
       (assert (null (hyperbook/server::👀url route)))
       (multiple-value-bind (html references) (%rendered (r:route-relation route))
         (assert (search "(dreyeck/clog-tutorial:install-tutorial-1-route)" html))
         (assert (not (search "hyperbook-slug" html)))
         (assert (null (%view-titled "URL" references))))
       (tut:install-tutorial-1-route)
       (assert (eq :mounted (r:route-state route)))
       (let ((url (hyperbook/server::👀url route)))
         (assert (search "<hyperbook-slug>clog-tutorial/01</hyperbook-slug>" (hv:view-html url)))
         (assert (member '(:script . "makeUrl(window.currentInspectorView)") (hv:view-assets url)
                         :test #'equal)))
       (multiple-value-bind (html references) (%rendered (r:route-relation route))
         (assert (search "CLOG dispatches it to this handler" html))
         (assert (%view-titled "URL" references))
         (assert (find-if (lambda (reference) (%source-code-link-p reference handler)) references))
         (assert (find-if (lambda (reference)
                            (%source-code-link-p reference #'tut:install-tutorial-1-route))
                          references)))
       ;; Control: the state is read, not assumed. Another handler at the
       ;; same path is reported, and the live link goes away.
       (clog:set-on-new-window #'identity :path (r:route-path route))
       (assert (eq :other-handler (r:route-state route)))
       (assert (null (hyperbook/server::👀url route))))))
  t)

(defun check-source-is-the-installed-tutorial ()
  (let ((source (r:route-source (r:tutorial-1-route))))
    (assert (equal (truename source) (truename (tut:tutorial-1-source))))
    (assert (uiop:subpathp source (clog:clog-install-dir))))
  t)

(defparameter *tutorial-01* "Tutorial 01 — Hello World")

(defun %book ()
  (hyperbook:find-hyperbook "dreyeck/clog-tutorial/reading"))

(defun %content (page)
  "PAGE's Content view, rendered: its HTML and its references."
  (%rendered (find "Content" (hv:all-views page) :key #'hv:view-title :test #'equal)))

(defparameter *tutorial-02* "Tutorial 02 — Closures in CLOG")

(defun %count (needle text)
  (loop for start = (search needle text) then (search needle text :start2 (1+ start))
        while start count t))

(defun check-book-is-the-collection ()
  "The Catalog entry is the collection: titled CLOG Tutorial, opening on an
Overview that lists Tutorials 01 and 02 and links exactly those. No other
tutorial is in the book, and each route state on the Overview is read from
its own route."
  (let* ((book (%book))
         (overview (hyperbook:find-page book "Overview" :signal-error? t))
         (tutorials (list (hyperbook:find-page book *tutorial-01* :signal-error? t)
                          (hyperbook:find-page book *tutorial-02* :signal-error? t))))
    (assert (member book (hyperbook:hyperbooks-of hyperbook:*catalog*)))
    (assert (equal "CLOG Tutorial" (hyperbook:title-of book)))
    (assert (equal "Overview" (hyperbook:main-page-id-of book)))
    (assert (equal (list "Overview" *tutorial-01* *tutorial-02*)
                   (sort (loop for page being the hash-values of (hyperdoc::text-pages-of book)
                               collect (hyperbook:title-of page))
                         #'string<)))
    (flet ((overview ()
             (multiple-value-bind (html references) (%content overview)
               (assert (notany (lambda (reference) (typep (cdr reference) 'condition)) references))
               (let ((linked (remove-duplicates
                              (loop for (nil . object) in references
                                    when (and (typep object 'hyperbook:page)
                                              (eq book (hyperbook:hyperbook-of object))
                                              (not (eq object overview)))
                                      collect object))))
                 (assert (and (= 2 (length linked))
                              (every (lambda (page) (member page linked)) tutorials))))
               html)))
      (let ((neither (call-with-clog #'overview))
            (first-only (call-with-clog (lambda ()
                                          (tut:install-tutorial-1-route)
                                          (overview))))
            (both (call-with-clog (lambda ()
                                    (tut:install-tutorial-1-route)
                                    (tut:install-tutorial-2-route)
                                    (overview)))))
        (assert (= 2 (%count ":NOT-MOUNTED" neither)))
        (assert (and (= 1 (%count ":MOUNTED" first-only)) (= 1 (%count ":NOT-MOUNTED" first-only))))
        (assert (and (= 2 (%count ":MOUNTED" both)) (zerop (%count ":NOT-MOUNTED" both)))))))
  t)

(defun check-page-reaches-both-ends ()
  "From the Tutorial 01 page: the handler, opening on its source, and -- once
the route is mounted -- the transcluded Route view, which carries the URL view."
  (let* ((page (hyperbook:find-page (%book) *tutorial-01* :signal-error? t))
         (handler (fdefinition (r:route-handler (r:tutorial-1-route)))))
    (flet ((content () (%content page)))
      (call-with-clog
       (lambda ()
         (tut:install-tutorial-1-route)
         (multiple-value-bind (html references) (content)
           (declare (ignore html))
           (assert (notany (lambda (reference) (typep (cdr reference) 'condition)) references))
           (let ((sources (%transcluded-sources references)))
             (assert (some (lambda (source) (search "Tutorial 01" source)) sources))
             (assert (notany (lambda (source) (search "Clicked" source)) sources)))
           (assert (find-if (lambda (reference) (%source-code-link-p reference handler))
                            references))
           (let ((route-view (%view-titled "Route" references)))
             (assert route-view)
             (assert (typep (hv:view-object route-view) 'r:clog-route))
             (assert (%view-titled "URL" (nth-value 1 (%rendered route-view))))))))
      ;; Unmounted, the page still renders and still reaches the handler.
      (call-with-clog
       (lambda ()
         (multiple-value-bind (html references) (content)
           (declare (ignore html))
           (assert (notany (lambda (reference) (typep (cdr reference) 'condition)) references))
           (assert (find-if (lambda (reference) (%source-code-link-p reference handler))
                            references))
           (assert (null (%view-titled "URL" (nth-value 1 (%rendered
                                                           (%view-titled "Route" references)))))))))))
  t)


(defun check-tutorial-2-route ()
  "Tutorial 02's route is read from its own entry: mounting Tutorial 01
does not mount it, and once mounted its view links Tutorial 02's handler
and mount function, not Tutorial 01's."
  (call-with-clog
   (lambda ()
     (let* ((route (r:tutorial-2-route))
            (handler (fdefinition (r:route-handler route))))
       (assert (equal "/clog-tutorial/02" (r:route-path route)))
       (assert (not (eq handler (fdefinition (r:route-handler (r:tutorial-1-route))))))
       (assert (eq :not-mounted (r:route-state route)))
       (assert (search "(dreyeck/clog-tutorial:install-tutorial-2-route)"
                       (hv:view-html (r:route-relation route))))
       (tut:install-tutorial-1-route)
       (assert (eq :not-mounted (r:route-state route)))
       (assert (null (hyperbook/server::👀url route)))
       (tut:install-tutorial-2-route)
       (assert (eq :mounted (r:route-state route)))
       (assert (search "<hyperbook-slug>clog-tutorial/02</hyperbook-slug>"
                       (hv:view-html (hyperbook/server::👀url route))))
       (multiple-value-bind (html references) (%rendered (r:route-relation route))
         (assert (search "CLOG dispatches it to this handler" html))
         (assert (%view-titled "URL" references))
         (assert (find-if (lambda (reference) (%source-code-link-p reference handler)) references))
         (assert (find-if (lambda (reference)
                            (%source-code-link-p reference #'tut:install-tutorial-2-route))
                          references))
         (assert (notany (lambda (reference)
                           (eq (cdr reference) #'tut:install-tutorial-1-route))
                         references))))))
  (let ((source (r:route-source (r:tutorial-2-route))))
    (assert (equal (truename source) (truename (tut:tutorial-2-source))))
    (assert (uiop:subpathp source (clog:clog-install-dir))))
  t)

(defun check-tutorial-2-page-reaches-both-ends ()
  "From the Tutorial 02 page: its handler, opening on its source, and the
Route view of /clog-tutorial/02 carrying the URL view once mounted."
  (let* ((page (hyperbook:find-page (%book) *tutorial-02* :signal-error? t))
         (handler (fdefinition (r:route-handler (r:tutorial-2-route)))))
    (call-with-clog
     (lambda ()
       (tut:install-tutorial-2-route)
       (multiple-value-bind (html references) (%content page)
         (declare (ignore html))
         (assert (notany (lambda (reference) (typep (cdr reference) 'condition)) references))
         (assert (some (lambda (source) (search "Clicked ~A times." source))
                       (%transcluded-sources references)))
         (assert (find-if (lambda (reference) (%source-code-link-p reference handler))
                          references))
         (let ((route-view (%view-titled "Route" references)))
           (assert (equal "/clog-tutorial/02" (r:route-path (hv:view-object route-view))))
           (assert (%view-titled "URL" (nth-value 1 (%rendered route-view)))))))))
  t)

(defun check-not-in-production-catalog ()
  "The book is reachable by loading its system, not by belonging to the
production Catalog. Control: a known member is seen as one."
  (let ((members (mapcar #'asdf:coerce-name
                         (asdf:system-depends-on (asdf:find-system "dreyeck/catalog")))))
    (assert (member "dreyeck/authority/reading" members :test #'string-equal))
    (assert (not (member "dreyeck/clog-tutorial/reading" members :test #'string-equal))))
  t)

(defun run-tests ()
  (check-route-reads-clog)
  (check-source-is-the-installed-tutorial)
  (check-book-is-the-collection)
  (check-page-reaches-both-ends)
  (check-tutorial-2-route)
  (check-tutorial-2-page-reaches-both-ends)
  (check-not-in-production-catalog)
  (format t "~&CLOG tutorial reading tests passed: route state, source, collection, page reaches both ends; Tutorial 02 route and page; not in the production Catalog.~%")
  t)
