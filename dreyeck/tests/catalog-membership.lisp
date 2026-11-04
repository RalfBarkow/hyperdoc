;;;; Tests of the Catalog membership properties. Two parts.
;;;;
;;;; RUN-SELF-TESTS gives the checkers faulty input (a Catalog with a missing, doubled, replaced or foreign HyperBook, a loader that removes
;;;; or replaces a member, a registration that replaces) and requires them to say so. A checker that could not fail would pass any Catalog,
;;;; so this is what makes the second part mean anything. It needs no loaded Catalog.
;;;;
;;;; RUN-CATALOG-TESTS holds the real Catalog to the properties: what the ASDF closure of dreyeck/catalog and the sources of its systems
;;;; declare is what was materialized, each book once with its main page; loading again changes nothing; loading more only adds;
;;;; registering a second book under an id keeps the first. There is no list of ids and no count anywhere in this file.
(defpackage #:dreyeck/catalog/membership/tests
  (:use #:cl)
  (:local-nicknames (#:m #:dreyeck/catalog/membership))
  (:export #:run-tests #:run-self-tests #:run-catalog-tests))
(in-package #:dreyeck/catalog/membership/tests)

(defun expect-error (label thunk &optional fragment)
  "THUNK must signal an error (whose message contains FRAGMENT): the checker detects LABEL."
  (let ((message (handler-case (progn (funcall thunk) nil)
                   (error (condition) (princ-to-string condition)))))
    (unless message (error "The checker did not detect: ~A" label))
    (when fragment
      (unless (search fragment message :test #'char-equal)
        (error "The checker detected ~A, but by another message: ~A" label message)))
    t))

(defun fabricated-hyperdoc (id system) (make-instance 'hyperdoc:hyperdoc :id id :asdf-system-name system))
(defun fabricated-catalog (&rest books)
  (let ((catalog (make-instance 'hyperbook:catalog))) (setf (hyperbook:hyperbooks-of catalog) (copy-list books)) catalog))

;;; Part one: the checkers detect faults

(defparameter +sample-source+
  "(in-package :x)
;; (defhyperdoc *commented* :id \"commented\" :asdf-system-name \"c\")
(dreyeck/hyperdoc:defhyperdoc *a* :title \"A (open paren\" :id \"a/id\" :asdf-system-name \"sys-a\"
  :subdirectory \"d\" :main-page-id \"Main A\")
(DREYECK/HYPERDOC:DEFHYPERDOC *B* :ID \"b\" :ASDF-SYSTEM-NAME \"sys-b\")
(hyperdoc:defhyperdoc *c* :id (computed-id) :asdf-system-name \"sys-c\")
(defun not-a-hyperdoc () \"defhyperdoc\" #\\( #\\;)")

(defun check-the-source-scan ()
  (let ((entries (m:scan-hyperdocs-in-text +sample-source+)))
    (assert (equal '("a/id" "b" nil) (mapcar (lambda (e) (getf e :id)) entries)) () "scan found ~S" entries)
    (assert (equal '("sys-a" "sys-b" "sys-c") (mapcar (lambda (e) (getf e :system)) entries)))
    (assert (equal "Main A" (getf (first entries) :main-page)))
    (assert (null (getf (second entries) :main-page)))
    ;; a comment is not a declaration; neither is a string
    (assert (null (m:scan-hyperdocs-in-text ";; (defhyperdoc *x* :id \"x\" :asdf-system-name \"y\")
(defun f () \"(defhyperdoc *x* :id \\\"x\\\")\")")))
    t))

(defun check-the-report-detects-faults ()
  (let* ((systems '("s1" "s2"))
         (declared (list (list :id "a" :system "s1" :main-page nil :file #p"a.lisp")
                         (list :id "b" :system "s2" :main-page nil :file #p"b.lisp")))
         (report (lambda (catalog &optional (declared declared)) (m:membership-report :catalog catalog :systems systems :declared declared)))
         (problems (lambda (catalog &optional (declared declared)) (m:report-problems (funcall report catalog declared)))))
    ;; the faultless Catalog has no problem
    (assert (null (funcall problems (fabricated-catalog (fabricated-hyperdoc "a" "s1") (fabricated-hyperdoc "b" "s2")))))
    ;; each fault is named, under its own key
    (assert (equal '(:missing ("b")) (funcall problems (fabricated-catalog (fabricated-hyperdoc "a" "s1")))))
    (assert (equal '(:duplicated ("a"))
                   (funcall problems (fabricated-catalog (fabricated-hyperdoc "a" "s1") (fabricated-hyperdoc "a" "s1") (fabricated-hyperdoc "b" "s2")))))
    (assert (equal '(:wrong-system ("b")) (funcall problems (fabricated-catalog (fabricated-hyperdoc "a" "s1") (fabricated-hyperdoc "b" "s1")))))
    (assert (equal '(:undeclared ("c"))
                   (funcall problems (fabricated-catalog (fabricated-hyperdoc "a" "s1") (fabricated-hyperdoc "b" "s2") (fabricated-hyperdoc "c" "s3")))))
    (assert (equal '(:undeclared ("d"))
                   (funcall problems (fabricated-catalog (fabricated-hyperdoc "a" "s1") (fabricated-hyperdoc "b" "s2") (fabricated-hyperdoc "d" "s1")))))
    (assert (equal '(:unattributed ("p"))
                   (funcall problems (fabricated-catalog (fabricated-hyperdoc "a" "s1") (fabricated-hyperdoc "b" "s2")
                                                         (make-instance 'hyperbook:hyperbook :id "p")))))
    (assert (equal '(:unscanned (#p"c.lisp"))
                   (funcall problems (fabricated-catalog (fabricated-hyperdoc "a" "s1") (fabricated-hyperdoc "b" "s2"))
                            (append declared (list (list :id nil :system "s1" :main-page nil :file #p"c.lisp"))))))
    ;; a Catalog that merely equals itself is no evidence: the declaration, not the Catalog, is what it is held to
    (let ((catalog (fabricated-catalog (fabricated-hyperdoc "a" "s1"))))
      (assert (funcall problems catalog))
      (assert (null (funcall problems catalog (list (first declared))))))
    t))

(defun check-the-loading-checks-detect-faults ()
  (flet ((catalog-with (&rest ids) (apply #'fabricated-catalog (mapcar (lambda (id) (fabricated-hyperdoc id "s")) ids)))
         (members (catalog) (hyperbook:hyperbooks-of catalog)))
    ;; additive: adding is fine, and reported
    (let ((catalog (catalog-with "a" "b")))
      (assert (equal '("c")
                     (m:assert-additive :catalog catalog
                                        :loader (lambda () (setf (hyperbook:hyperbooks-of catalog)
                                                                 (append (members catalog) (list (fabricated-hyperdoc "c" "s")))))))))
    ;; removing, replacing and doubling a member are each detected
    (let ((catalog (catalog-with "a" "b")))
      (expect-error "a loader that removes a member"
                    (lambda () (m:assert-additive :catalog catalog :loader (lambda () (setf (hyperbook:hyperbooks-of catalog) (rest (members catalog))))))
                    "0 times"))
    (let ((catalog (catalog-with "a" "b")))
      (expect-error "a loader that replaces a member by another object"
                    (lambda () (m:assert-additive :catalog catalog
                                                  :loader (lambda () (setf (hyperbook:hyperbooks-of catalog)
                                                                           (cons (fabricated-hyperdoc "a" "s") (rest (members catalog)))))))
                    "replaced"))
    (let ((catalog (catalog-with "a" "b")))
      (expect-error "a loader that doubles a member"
                    (lambda () (m:assert-additive :catalog catalog :loader (lambda () (push (first (members catalog)) (hyperbook:hyperbooks-of catalog)))))
                    "2 times"))
    ;; idempotent: a no-op passes; adding, removing and reordering do not
    (let ((catalog (catalog-with "a" "b")))
      (assert (m:assert-idempotent :catalog catalog :loader (lambda ())))
      (expect-error "a repeated load that adds a book"
                    (lambda () (m:assert-idempotent :catalog catalog :loader (lambda () (push (fabricated-hyperdoc "z" "s") (hyperbook:hyperbooks-of catalog))))))
      (setf (hyperbook:hyperbooks-of catalog) (list (fabricated-hyperdoc "a" "s") (fabricated-hyperdoc "b" "s")))
      (expect-error "a repeated load that reorders"
                    (lambda () (m:assert-idempotent :catalog catalog :loader (lambda () (setf (hyperbook:hyperbooks-of catalog) (reverse (members catalog))))))))
    ;; registration keeps the first book of an id: a correct, a replacing and a doubling registration
    (let* ((catalog (catalog-with "a" "b"))
           (correct (lambda (book) (pushnew book (hyperbook:hyperbooks-of catalog) :key #'hyperbook:id-of :test #'equal)))
           (replacing (lambda (book) (setf (hyperbook:hyperbooks-of catalog)
                                           (cons book (remove (hyperbook:id-of book) (members catalog) :key #'hyperbook:id-of :test #'equal)))))
           (doubling (lambda (book) (push book (hyperbook:hyperbooks-of catalog)))))
      (assert (m:assert-registration-keeps-first :catalog catalog :register correct))
      (expect-error "a registration that replaces the first book" (lambda () (m:assert-registration-keeps-first :catalog catalog :register replacing)))
      (expect-error "a registration that doubles the id" (lambda () (m:assert-registration-keeps-first :catalog catalog :register doubling)))
      ;; and the checker leaves the Catalog as it was, even when it fails
      (assert (equal '("a" "b") (mapcar #'hyperbook:id-of (members catalog)))))
    t))

(defun run-self-tests ()
  (check-the-source-scan)
  (check-the-report-detects-faults)
  (check-the-loading-checks-detect-faults)
  (format t "~&CATALOG-MEMBERSHIP-SELF-TESTS-PASS: the source scan reads declarations and ignores comments and strings; the report names a missing, doubled, wrong-system, undeclared, unattributed and unscanned book; the loading checks name a removed, replaced, doubled or reordered member and a registration that replaces.~%")
  t)

;;; Part two: the real Catalog

(defun run-catalog-tests ()
  (let ((report (m:assert-membership :check-pages t)))
    (declare (ignore report))
    (assert (plusp (length (m:source-hyperdocs))) () "no HyperDoc is declared in the sources of dreyeck/catalog's systems")
    ;; one id, one book
    (let ((ids (m:catalog-ids)))
      (assert (= (length ids) (length (remove-duplicates ids :test #'string=)))))
    ;; the reading of the CCNx Federated Wiki is a regular member: no HYPERDOC_CATALOG_SYSTEM, once, with its declared main page
    (assert (zerop (length (or (uiop:getenv "HYPERDOC_CATALOG_SYSTEM") "")))
            () "HYPERDOC_CATALOG_SYSTEM is set: the regular Catalog start cannot be observed")
    (m:assert-hyperbook-present "dreyeck/ccnx-federated-wiki")
    ;; the first book of an id is kept
    (m:assert-registration-keeps-first)
    ;; loading again changes nothing, not even when a member's source files, and so its DEFHYPERDOC form, are evaluated again
    (m:assert-idempotent :loader (lambda ()
                                   (m:load-systems '("dreyeck/catalog" "dreyeck/ccnx-federated-wiki"))
                                   (m:load-systems '("dreyeck/ccnx-federated-wiki") :reload-sources t)))
    ;; loading more only adds: a further book is registered, every member stays, once, and the same object
    (let* ((id "dreyeck/membership-test-extension") (saved (copy-list (hyperbook:hyperbooks-of hyperbook:*catalog*))))
      (assert (not (member id (m:catalog-ids) :test #'string=)))
      (unwind-protect
           (let ((added (m:assert-additive :loader (lambda () (hyperbook:register (make-instance 'hyperbook:hyperbook :id id))))))
             (assert (equal (list id) added))
             ;; the extension is what no source declares: the report names it
             (assert (equal (list id) (getf (m:report-problems (m:membership-report)) :unattributed)))
             )
        (setf (hyperbook:hyperbooks-of hyperbook:*catalog*) saved))
      (assert (null (m:report-problems (m:membership-report)))))
    t))

(defun run-tests ()
  (run-self-tests)
  (run-catalog-tests)
  (format t "~&CATALOG-MEMBERSHIP-PASS: what the ASDF closure of dreyeck/catalog and the sources of its systems declare is what the Catalog materialized, each book once with its declared main page; the CCNx reading is a regular member without HYPERDOC_CATALOG_SYSTEM; the first book of an id is kept; loading again changes nothing; loading more only adds.~%")
  t)
