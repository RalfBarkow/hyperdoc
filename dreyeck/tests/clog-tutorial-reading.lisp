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
                    (#:ap #:dreyeck/authority-policy)
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

(defparameter *workflow* "Running the CLOG Tutorials in HyperDoc")

(defun %count (needle text)
  (loop for start = (search needle text) then (search needle text :start2 (1+ start))
        while start count t))

(defun check-book-is-the-collection ()
  "The Catalog entry is the collection: titled CLOG Tutorial, opening on an
Overview that lists Tutorials 01 and 02 and links exactly those and the
workflow page. No other tutorial is in the book, and each route state on
the Overview is read from its own route."
  (let* ((book (%book))
         (overview (hyperbook:find-page book "Overview" :signal-error? t))
         (tutorials (list (hyperbook:find-page book *tutorial-01* :signal-error? t)
                          (hyperbook:find-page book *tutorial-02* :signal-error? t))))
    (assert (member book (hyperbook:hyperbooks-of hyperbook:*catalog*)))
    (assert (equal "CLOG Tutorial" (hyperbook:title-of book)))
    (assert (equal "Overview" (hyperbook:main-page-id-of book)))
    (assert (equal (list "Overview" *workflow* *tutorial-01* *tutorial-02*)
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
                 (assert (and (= 3 (length linked))
                              (every (lambda (page) (member page linked))
                                     (cons (hyperbook:find-page book *workflow* :signal-error? t)
                                           tutorials)))))
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

(defun check-in-production-catalog ()
  "The book is a member of the production Catalog: dreyeck/catalog depends
on its system. Control: another known member is seen as one, and a system
that is not a member is not."
  (let ((members (mapcar #'asdf:coerce-name
                         (asdf:system-depends-on (asdf:find-system "dreyeck/catalog")))))
    (assert (member "dreyeck/authority/reading" members :test #'string-equal))
    (assert (not (member "dreyeck/clog-tutorial/reading/tests" members :test #'string-equal)))
    (assert (member "dreyeck/clog-tutorial/reading" members :test #'string-equal)))
  t)

(defun %served (thunk)
  "THUNK run as the served Catalog runs: a server up, not in development mode."
  (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server)) (list (list "700px" nil))
    (funcall thunk)))

(defun %developing (thunk)
  "THUNK run as a development server runs."
  (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server)) (list (list "700px" t))
    (funcall thunk)))

(defun %content-view (page)
  (find "Content" (hv:all-views page) :key #'hv:view-title :test #'equal))

(defun %all-references (view)
  "The objects VIEW refers to, and those of the views it transcludes."
  (hv:view-html view)
  (loop for (nil . object) in (hv:view-references view)
        append (cons object (and (typep object 'hv:view) (%all-references object)))))

(defun %example-thunks (page)
  (remove-if-not (lambda (object) (typep object 'ap:example-thunk))
                 (%all-references (%content-view page))))

(defun check-mount-examples-run-only-in-development ()
  "Each tutorial page offers its mount example in a development server, and
running it mounts the route and nothing else: no INITIALIZE, no browser.
Served, there is no run button, the marker says why, and a run obtained
anyway is refused and mounts nothing. Neither example has a contract, and
the book loads the gate with them."
  (loop for (title example route) in (list (list *tutorial-01* 'r:mount-tutorial-01 #'r:tutorial-1-route)
                                            (list *tutorial-02* 'r:mount-tutorial-02 #'r:tutorial-2-route))
        for page = (hyperbook:find-page (%book) title :signal-error? t)
        do (assert (null (ap:find-example-contract example)))
           (let ((thunks (%developing (lambda () (%example-thunks page)))))
             (assert (find example thunks :key #'ap::example-thunk-example))
             (let ((observed (dreyeck/clog-tutorial/tests::call-with-clog
                              t (lambda ()
                                  (%developing
                                   (lambda ()
                                     (let ((result (hv:eval-thunk
                                                    (find example thunks :key #'ap::example-thunk-example))))
                                       (list (typep result 'r:clog-route)
                                             (r:route-state (funcall route))))))))))
               (assert (equal '(t :mounted) (getf observed :value)))
               (assert (null (getf observed :calls)))))
           (%served
            (lambda ()
              ;; Nothing runnable at all, not only no gated run: upstream's
              ;; own button is a plain thunk.
              (assert (notany (lambda (object) (typep object 'hv:thunk))
                              (%all-references (%content-view page))))
              (assert (some (lambda (object)
                              (and (typep object 'hv:view)
                                   (search "Not run here: no operation contract" (hv:view-html object))))
                            (%all-references (%content-view page))))
              (let ((observed (dreyeck/clog-tutorial/tests::call-with-clog
                               t (lambda ()
                                   (let ((result (hv:eval-thunk
                                                  (make-instance 'ap:example-thunk
                                                                 :fn (lambda () (funcall (symbol-function example)))
                                                                 :example example))))
                                     (list (typep result 'ap:invocation-refused)
                                           (r:route-state (funcall route))))))))
                (assert (equal '(t :not-mounted) (getf observed :value)))))))
  (assert (member "dreyeck/authority-policy"
                  (mapcar #'asdf:coerce-name
                          (asdf:system-depends-on (asdf:find-system "dreyeck/clog-tutorial/reading")))
                  :test #'string-equal))
  t)

(defun check-workflow-page ()
  "The README's workflow, translated. RUN-TUTORIAL, INITIALIZE and
OPEN-BROWSER are linked as source to read, the two mount examples are
linked, and the page offers nothing to run, not even in development."
  (let ((page (hyperbook:find-page (%book) *workflow* :signal-error? t)))
    (%developing
     (lambda ()
       (multiple-value-bind (html references) (%content page)
         (assert (notany (lambda (reference) (typep (cdr reference) 'condition)) references))
         (assert (search "(clog:run-tutorial 1)" html))
         (dolist (function (list #'clog:run-tutorial #'clog:initialize #'clog:open-browser
                                 #'r:mount-tutorial-01 #'r:mount-tutorial-02))
           (assert (find-if (lambda (reference) (%source-code-link-p reference function))
                            references))))
       (assert (notany (lambda (object) (typep object 'hv:thunk))
                       (%all-references (%content-view page))))))
    (dolist (function (list #'clog:run-tutorial #'clog:initialize #'clog:open-browser))
      (assert (find "Source code" (hv:all-views function) :key #'hv:view-title :test #'equal))))
  t)

;;; Public reading against development: the same pages, told apart by the
;;; decision that gates the run buttons.

(defun %tutorials ()
  (list (list *tutorial-01* #'r:tutorial-1-route 'r:mount-tutorial-01
              "(dreyeck/clog-tutorial:install-tutorial-1-route)")
        (list *tutorial-02* #'r:tutorial-2-route 'r:mount-tutorial-02
              "(dreyeck/clog-tutorial:install-tutorial-2-route)")))

(defun check-unmounted-wording-by-mode ()
  "Unmounted, a development server points to the runnable mount example and
the REPL form; a served Catalog says the route is not mounted and why, and
tells the reader to evaluate nothing."
  (dolist (tutorial (%tutorials))
    (destructuring-bind (title route-function example form) tutorial
      (declare (ignore title))
      (call-with-clog
       (lambda ()
         (let ((route (funcall route-function)))
           (%developing
            (lambda ()
              (multiple-value-bind (html references) (%rendered (r:route-relation route))
                (assert (search "to mount it" html))
                (assert (search form html))
                (assert (find-if (lambda (reference)
                                   (%source-code-link-p reference (fdefinition example)))
                                 references)))))
           (%served
            (lambda ()
              (multiple-value-bind (html references) (%rendered (r:route-relation route))
                (assert (search "not offered to readers" html))
                (assert (not (search form html)))
                (assert (not (search "evaluate" html :test #'char-equal)))
                (assert (notany (lambda (reference) (eq (cdr reference) (fdefinition example)))
                                references))
                (assert (notany (lambda (reference) (typep (cdr reference) 'hv:thunk))
                                references))))))))))
  t)

(defun check-public-reading-mounts-nothing ()
  "Showing every page of the book to a served reader leaves CLOG's routes as
they were: both tutorials stay unmounted."
  (let ((observed
          (dreyeck/clog-tutorial/tests::call-with-clog
           t (lambda ()
               (%served
                (lambda ()
                  (dolist (title (list "Overview" *workflow* *tutorial-01* *tutorial-02*))
                    (%all-references
                     (%content-view (hyperbook:find-page (%book) title :signal-error? t))))
                  (list (r:route-state (r:tutorial-1-route))
                        (r:route-state (r:tutorial-2-route)))))))))
    (assert (equal '(:not-mounted :not-mounted) (getf observed :value)))
    (assert (equal (getf observed :before) (getf observed :after)))
    (assert (null (getf observed :calls))))
  t)

(defun %inspector-options (development)
  "The options this book's HyperBook route gives the Inspector for its
Overview, served with DEVELOPMENT. CLOG is replaced by recorders: no socket
is opened and no browser connects."
  (let* ((names '(clog:initialize clog:set-on-new-window clog:location clog:property
                  clog-moldable-inspector:on-new-inspector))
         (saved (mapcar #'fdefinition names))
         (parameters hyperbook/server::*server-parameters*)
         (path (concatenate 'string "/" (hyperbook/server::slug (%book))))
         (routes nil)
         (options nil))
    (unwind-protect
         (progn
           (setf (fdefinition 'clog:initialize) (lambda (&rest arguments) (declare (ignore arguments)))
                 (fdefinition 'clog:set-on-new-window)
                 (lambda (handler &key path) (push (cons path handler) routes))
                 (fdefinition 'clog:location) #'identity
                 (fdefinition 'clog:property) (lambda (object name) (declare (ignore name)) object)
                 (fdefinition 'clog-moldable-inspector:on-new-inspector)
                 (lambda (body &rest arguments) (declare (ignore body)) (setf options arguments)))
           (hyperbook/server:serve-hyperbooks hyperbook:*catalog* :port 0 :development development)
           (funcall (cdr (assoc path routes :test #'equal))
                    (concatenate 'string path "/Overview"))
           options)
      (loop for name in names for definition in saved
            do (setf (fdefinition name) definition))
      (setf hyperbook/server::*server-parameters* parameters))))

(defun check-playground-disabled-when-served ()
  "Served, the book's pages open in an Inspector whose Playground does not
evaluate. Control: a development server's does."
  (let ((served (%inspector-options nil))
        (developing (%inspector-options t)))
    (assert (typep (getf served :object) 'hyperbook:page))
    (assert (equal "Overview" (hyperbook:title-of (getf served :object))))
    (assert (member :playground? served))
    (assert (null (getf served :playground?)))
    (assert (eq t (getf developing :playground?))))
  t)

(defun check-public-source-reference ()
  "Served, the Overview points to the upstream collection with an ordinary
link and names the installed CLOG as text; it refers to no pathname object.
Pathname authority is unchanged: CLOG's directory is still refused to a
served reader, the repository still shown."
  (let ((overview (hyperbook:find-page (%book) "Overview" :signal-error? t)))
    (%served
     (lambda ()
       (let ((html (hv:view-html (%content-view overview))))
         (assert (search "href='https://github.com/rabbibotton/clog/tree/main/tutorial' target='_blank'"
                         html))
         (assert (search (asdf:component-version (asdf:find-system "clog")) html))
         (assert (search (namestring (clog:clog-install-dir)) html)))
       (assert (notany #'pathnamep (%all-references (%content-view overview))))
       (assert (not (ap:pathname-disclosure-permitted-p
                     (merge-pathnames "tutorial/" (clog:clog-install-dir)))))
       (assert (ap:pathname-disclosure-permitted-p (asdf:system-source-directory "dreyeck"))))))
  t)

(defun run-tests ()
  (check-route-reads-clog)
  (check-source-is-the-installed-tutorial)
  (check-book-is-the-collection)
  (check-page-reaches-both-ends)
  (check-tutorial-2-route)
  (check-tutorial-2-page-reaches-both-ends)
  (check-in-production-catalog)
  (check-mount-examples-run-only-in-development)
  (check-workflow-page)
  (check-unmounted-wording-by-mode)
  (check-public-reading-mounts-nothing)
  (check-playground-disabled-when-served)
  (check-public-source-reference)
  (check-runtime-observations)
  (check-instrumentation-audit)
  (check-observation-lifecycle)
  (format t "~&CLOG tutorial reading tests passed: route state, source, collection, page reaches both ends; Tutorial 02 route and page; in the production Catalog; mount examples only in development; workflow page; wording by mode; public reading mounts nothing; Playground disabled when served; public source reference.~%")
  t)
