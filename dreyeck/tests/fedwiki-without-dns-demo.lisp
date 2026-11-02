;;;; The "Reading a Wiki Page Without DNS" demo: not in the default Catalog, one member once it is named, its page and Inspector views show the
;;;; observed access paths and keep observed, derived, inferred and hypothesized apart, offer no network or write action of their own, and
;;;; touch neither the committed record nor the frozen page. The committed record is checked for consistency, as data.
(defpackage #:dreyeck/fedwiki-without-dns-demo/tests
  (:use #:cl)
  (:local-nicknames (#:demo #:dreyeck/fedwiki-without-dns-demo)
                    (#:x #:dreyeck/fedwiki-without-dns)
                    (#:hv #:html-inspector-views))
  (:export #:run-tests))
(in-package #:dreyeck/fedwiki-without-dns-demo/tests)

(defparameter +id+ "dreyeck/fedwiki-without-dns-demo")
(defparameter +page-title+ "Reading One Wiki Page Without DNS")

(defun served (thunk)
  (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server)) (list (list "700px" nil)) (funcall thunk)))

(defun %html-of-views (object &key (only nil))
  "The HTML of each HTML view of OBJECT (or those titled ONLY), as a served visitor gets it, joined."
  (served (lambda ()
            (format nil "~{~A~^~%~}"
                    (loop for view in (hv:all-views object)
                          when (and (typep view 'hv:html-view) (or (null only) (member (hv:view-title view) only :test #'string=)))
                            collect (hv:view-html view))))))

(defun %controls (object &key titles)
  "The controls (references with an eval- or action- id) of OBJECT's HTML views, served; of the views titled TITLES, or of all."
  (served (lambda ()
            (loop for view in (hv:all-views object)
                  when (and (typep view 'hv:html-view) (or (null titles) (member (hv:view-title view) titles :test #'string=)))
                    append (progn (hv:view-html view)
                                  (remove-if-not (lambda (reference)
                                                   (and (consp reference) (stringp (car reference))
                                                        (or (uiop:string-prefix-p "eval-" (car reference))
                                                            (uiop:string-prefix-p "action-" (car reference)))))
                                                 (hv:view-references view)))))))

(defparameter +own-view-titles+ '("Comparison of the access paths" "Claims by warrant" "Setup" "Record as data" "Observation" "Claim"))

(defun %octets (pathname)
  (with-open-file (in pathname :element-type '(unsigned-byte 8))
    (let ((octets (make-array (file-length in) :element-type '(unsigned-byte 8)))) (read-sequence octets in) octets)))

(defun %sha (pathname) (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 (%octets pathname))))

(defvar *network-calls* '() "The ways into the network that were called while they were forbidden.")

(defmacro with-network-forbidden (&body body)
  "BODY with every way into the network that the demo's libraries have recorded and refused. A call is noted before it signals, so that a
handler that swallows the condition does not hide it."
  `(progn
     (setf *network-calls* '())
     ,@(loop for name in '(drakma:http-request usocket:socket-connect usocket:get-hosts-by-name)
             collect `(sb-int:encapsulate ',name 'forbid
                                          (lambda (function &rest arguments) (declare (ignore function arguments))
                                            (push ',name *network-calls*) (error "network access by the demo: ~S" ',name))))
     (unwind-protect (progn ,@body)
       ,@(loop for name in '(drakma:http-request usocket:socket-connect usocket:get-hosts-by-name)
               collect `(sb-int:unencapsulate ',name 'forbid)))
     (assert (null *network-calls*) () "the demo went to the network: ~S" *network-calls*)))

(defun check-membership-in-a-fresh-image ()
  "Not in the default Catalog, exactly one member when named, nothing more when named again: scripts/check-without-dns-demo-membership.lisp."
  (multiple-value-bind (output error-output status)
      (uiop:run-program (list (namestring sb-ext:*runtime-pathname*) "--core" (namestring sb-ext:*core-pathname*)
                              "--noinform" "--no-sysinit" "--no-userinit" "--non-interactive"
                              "--load" (namestring (asdf:system-relative-pathname +id+ "scripts/check-without-dns-demo-membership.lisp")))
                        :output :string :error-output :string :ignore-error-status t)
    (assert (and (eql 0 status) (search "WITHOUT-DNS-DEMO-MEMBERSHIP-PASS" output)) ()
            "membership proof failed (exit ~A):~%~A~%~A" status (subseq output (max 0 (- (length output) 600))) (subseq error-output (max 0 (- (length error-output) 600)))))
  t)

(defun check-record-is-consistent ()
  "The committed record as data: each observation is what the experiment says it is, and the endpoint mapping is what it claims to be."
  (let* ((record (demo:current-record)) (id (lambda (name) (x:find-observation record name))))
    (assert record () "the committed experiment record cannot be read")
    (assert (equal "wiki.without-dns.test" (x:record-site record)))
    (assert (equal "without-dns-test-page" (x:record-slug record)))
    (assert (equal (x:record-fixture-sha256 record) (%sha (merge-pathnames "pages/without-dns-test-page" (demo:frozen-site-root)))) ()
            "the frozen page is not the page the experiment read")
    (assert (equal '("A" "B" "C" "D" "E" "F") (mapcar #'x:observation-id (x:record-observations record))))
    (let ((a (funcall id "A")) (b (funcall id "B")) (c (funcall id "C")) (d (funcall id "D")) (e (funcall id "E")) (f (funcall id "F")))
      ;; A: ordinary resolution worked
      (assert (eq :ordinary-resolution (x:observation-access a)))
      (assert (eq :resolved (getf (x:observation-dns a) :outcome)))
      (assert (eql 200 (getf (x:observation-http a) :status)))
      (assert (eq :read-identical (x:observation-verdict a)))
      ;; B: the same request, resolution failing, no connection
      (assert (eq :ordinary-resolution (x:observation-access b)))
      (assert (eq :failed (getf (x:observation-dns b) :outcome)))
      (assert (eq :name-resolution (getf (x:observation-connection b) :stage)))
      (assert (null (x:observation-http b))) (assert (null (x:observation-json-sha256 b)))
      ;; C: resolution still failing, the endpoint given, taken from A's resolution, the same bytes
      (assert (eq :explicit-endpoint (x:observation-access c)))
      (assert (eq :failed (getf (x:observation-dns c) :outcome)))
      (assert (equal '(:earlier-resolution "A") (x:observation-endpoint-origin c)))
      (assert (member (x:observation-endpoint c) (getf (x:observation-dns a) :addresses) :test #'equal))
      (assert (eql 200 (getf (x:observation-http c) :status)))
      (assert (equal (x:observation-json-sha256 a) (x:observation-json-sha256 c)))
      (assert (eq :read-identical (x:observation-verdict c)))
      (assert (eq :equivalent-json (getf (x:observation-content c) :relation)))
      ;; the site identity is the same name in every observation, never an address
      (assert (every (lambda (o) (equal (x:record-site record) (x:observation-site o))) (x:record-observations record)))
      (assert (notany (lambda (o) (and (x:observation-endpoint o) (search (x:observation-endpoint o) (x:observation-site o)))) (x:record-observations record)))
      ;; the controls
      (assert (eq :page-absent (x:observation-verdict d))) (assert (eql 404 (getf (x:observation-http d) :status)))
      (assert (eq :unreachable (x:observation-verdict e))) (assert (null (x:observation-http e)))
      (assert (eq :read-different (x:observation-verdict f)))
      (assert (not (equal (x:observation-json-sha256 a) (x:observation-json-sha256 f)))))
    (assert (every (lambda (o) (eq :observed (x:observation-warrant o))) (x:record-observations record)))
    (assert (every (lambda (o) (eq :not-performed (getf (x:observation-tls o) :status))) (x:record-observations record)))
    (assert (demo:stored-page-digest-current-p record)))
  t)

(defun check-page-and-views ()
  (let* ((book (hyperbook:find-hyperbook +id+ :signal-error? t))
         (page (hyperbook:find-page book +page-title+ :signal-error? t))
         (record (demo:current-record))
         (html (%html-of-views page :only '("Content"))))
    ;; The page's own content (the Inspector's generic Operations view of any object has buttons; the policy decides when they are used):
    ;; the page that is read, and the experiment in one table
    (dolist (needle '("wiki.without-dns.test" "without-dns-test-page" "Without DNS Test Page" "10.77.0.1" "failed: NS-TRY-AGAIN-ERROR"
                      "name resolution failed" "read; the same page" "answered; no page" "unreachable" "read; other content"
                      "Experiment record" "authenticates nothing"))
      (assert (search needle html) () "the page does not show ~S" needle))
    (assert (search (x:record-fixture-sha256 record) html) () "the page does not show the stored page's digest")
    (dolist (forbidden '("<iframe" "<button" "<form" "<input"))
      (assert (not (search forbidden html)) () "the page contains ~S" forbidden))
    ;; The Inspector views of the record: the comparison names both paths, and the claims are kept apart by warrant
    (let ((comparison (%html-of-views record :only '("Comparison of the access paths"))))
      (dolist (needle '("ordinary resolution" "endpoint 10.77.0.1 (from A)" "(declared)" "the address that the resolution in observation A gave"
                        "failed: NS-TRY-AGAIN-ERROR" "resolved 10.77.0.1" "HTTP 200" "HTTP 404" "none: name-resolution" "none: timeout"
                        "equivalent-json" "not-performed" "Endpoint mappings"
                        "What was observed, derived, inferred and only hypothesized" "What this record does not show"))
        (assert (search needle comparison) () "the comparison does not show ~S" needle))
      (dolist (word '("observed" "derived" "inferred" "hypothesized"))
        (assert (search word comparison) () "the comparison lacks the warrant ~S" word)))
    (let ((by-warrant (%html-of-views record :only '("Claims by warrant"))))
      (dolist (heading '("Observed" "Derived" "Inferred" "Hypothesized"))
        (assert (search (format nil "<h3>~A</h3>" heading) by-warrant) () "no section ~S" heading)))
    (let ((observation (%html-of-views (x:find-observation record "C") :only '("Observation"))))
      (dolist (needle '("Origin of the endpoint mapping" "Endpoint used" "10.77.0.1" "JSON SHA-256 of the served octets" "Warrant" "derived" "observed"))
        (assert (search needle observation) () "the observation view does not show ~S" needle)))
    ;; Each claim has its own view
    (assert (find "Claim" (hv:all-views (first (x:derive-findings record))) :key #'hv:view-title :test #'string=)))
  t)

(defun check-no-network-or-write-action ()
  (let* ((record (demo:current-record))
         (objects (append (list record) (x:record-observations record) (x:derive-findings record)))
         (record-file (demo:record-pathname)) (frozen-file (merge-pathnames "pages/without-dns-test-page" (demo:frozen-site-root)))
         (before (list (%octets record-file) (%octets frozen-file))))
    ;; Our own views carry no control at all
    (dolist (object objects)
      (let ((own (%controls object :titles +own-view-titles+)))
        (assert (null own) () "a view of the demo offers a control: ~S" own)))
    ;; The Inspector's generic Operations stay under dreyeck/authority-policy: every control is a policy Operation, none is ours
    (dolist (object objects)
      (let ((controls (%controls object)))
        (assert (notany (lambda (reference) (typep (cdr reference) 'dreyeck/authority-policy:reviewed-thunk)) controls))
        (assert (every (lambda (reference) (typep (cdr reference) 'dreyeck/authority-policy:operation-thunk)) controls) ()
                "a control that is not a policy Operation: ~S" controls)))
    ;; Rendering and viewing open no connection and resolve no name
    (with-network-forbidden
      (let ((book (hyperbook:find-hyperbook +id+ :signal-error? t)))
        (%html-of-views (hyperbook:find-page book +page-title+ :signal-error? t)))
      (dolist (object objects) (%html-of-views object)))
    ;; Nothing was written
    (assert (equalp before (list (%octets record-file) (%octets frozen-file)))))
  t)

(defun %render (thunk)
  "What THUNK writes to the Inspector's HTML stream, as a visitor gets it: inside an HTML view, so that references are collected."
  (served (lambda () (hv:view-html (hv:html-view :title "test" (funcall thunk))))))

(defun check-unreadable-record-and-changed-page ()
  ;; No record: the page says so and signals nothing
  (let ((html (%render (lambda () (demo:render-demo (merge-pathnames "no-such-record.lisp-data" (uiop:temporary-directory)))))))
    (assert (search "could not be read" html))
    (assert (not (search "<table" html))))
  ;; A damaged record is refused, not evaluated
  (let ((file (merge-pathnames (format nil "without-dns-damaged-~D.lisp-data" (random 1000000 (make-random-state t))) (uiop:temporary-directory))))
    (unwind-protect
         (progn (with-open-file (out file :direction :output) (write-string "(:fedwiki-without-dns-record :version 1 :title #.(+ 1 2))" out))
                (assert (search "could not be read" (%render (lambda () (demo:render-demo file))))))
      (ignore-errors (delete-file file))))
  ;; A frozen page that is no longer the page the experiment read is noticed, not hidden
  (let* ((root (uiop:ensure-directory-pathname (merge-pathnames (format nil "without-dns-site-~D/" (random 1000000 (make-random-state t))) (uiop:temporary-directory))))
         (file (merge-pathnames "pages/without-dns-test-page" root)) (record (demo:current-record)))
    (ensure-directories-exist file)
    (unwind-protect
         (progn
           (with-open-file (out file :direction :output :external-format :utf-8)
             (write-string (substitute #\Space #\c (uiop:read-file-string (merge-pathnames "pages/without-dns-test-page" (demo:frozen-site-root))) :count 1 :start 100) out))
           (let ((demo:*frozen-site-root* root))
             (assert (not (demo:stored-page-digest-current-p record)))
             (assert (search "NOT the digest the experiment recorded" (%render (lambda () (demo:render-demo)))))))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))
    (assert (demo:stored-page-digest-current-p record)))
  t)

(defun run-tests ()
  (check-record-is-consistent)
  (check-membership-in-a-fresh-image)
  (check-page-and-views)
  (check-no-network-or-write-action)
  (check-unreadable-record-and-changed-page)
  (format t "~&FEDWIKI-WITHOUT-DNS-DEMO-PASS: not in the default Catalog; one member when named; the committed record consistent; the Inspector views separate the paths and the warrants; no control of its own; no network, no write.~%")
  t)
