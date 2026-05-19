;;;; Smoke tests for the source-station-backed LISP-CRITIC contract.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-LISP-CRITIC-CONTRACT-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun lisp-critic-contract-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun lisp-critic-contract-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun lisp-critic-contract-assert-member (item list message)
  (unless (member item list :test #'eql)
    (error "~A -- expected ~S in ~S" message item list)))

(defun lisp-critic-contract-view-html (object title)
  (let ((view (find title
                    (html-inspector-views:all-views object)
                    :key #'html-inspector-views:view-title
                    :test #'string=)))
    (lisp-critic-contract-assert-true
     view
     (format nil "Expected inspector view ~S for ~S" title object))
    (let ((html (html-inspector-views:view-html view)))
      (lisp-critic-contract-assert-true
       (and (stringp html)
            (plusp (length html)))
       (format nil "Inspector view ~S must render non-empty HTML" title))
      html)))

(defun lisp-critic-contract-test-target-path ()
  (namestring
   (asdf:system-relative-pathname
    :hyperdoc
    "hyperdoc/lisp-critic-review-plan.lisp")))

(defun lisp-critic-contract-missing-source-station ()
  (let* ((source-station (hyperdoc:default-lisp-critic-source-station))
         (missing-root
           (format nil "/private/tmp/hyperdoc-missing-lisp-critic-source-~D/"
                   (get-universal-time))))
    (make-instance
     'hyperdoc:lisp-critic-source-station
     :id "missing-fedwiki-lisp-critic-source-station"
     :title "Missing test LISP-CRITIC source station"
     :site (hyperdoc::lisp-critic-source-station-site-of source-station)
     :page (hyperdoc::lisp-critic-source-station-page-of source-station)
     :asset-root missing-root
     :wrapper-system
     (hyperdoc::lisp-critic-source-station-wrapper-system-of source-station)
     :wrapper-package
     (hyperdoc::lisp-critic-source-station-wrapper-package-of source-station)
     :wrapper-loader-symbol
     (hyperdoc::lisp-critic-source-station-wrapper-loader-symbol-of
      source-station)
     :wrapper-entrypoint-symbol
     (hyperdoc::lisp-critic-source-station-wrapper-entrypoint-symbol-of
      source-station)
     :upstream-system
     (hyperdoc::lisp-critic-source-station-upstream-system-of source-station)
     :upstream-package
     (hyperdoc::lisp-critic-source-station-upstream-package-of source-station)
     :upstream-file-entrypoint-symbol
     (hyperdoc::lisp-critic-source-station-upstream-file-entrypoint-symbol-of
      source-station)
     :provenance '(:test-fixture :missing-source-station))))

(defun lisp-critic-contract-missing-asset-contract ()
  (make-instance
   'hyperdoc:lisp-critic-contract
   :id "missing-lisp-critic-contract"
   :title "Missing LISP-CRITIC contract test fixture"
   :source-station (lisp-critic-contract-missing-source-station)
   :input-policy '(:test-lisp-file)
   :invocation-policy '(:must-not-run-when-asset-is-missing)
   :output-policy '(:raw-output-only)
   :availability-policy '(:missing-asset-produces-run-record)
   :failure-policy '(:return-run-record-by-default)
   :review-contract-role '(:test-critic-engine)))

(defun run-lisp-critic-contract-object-smoke-test ()
  (let ((source-station (hyperdoc:default-lisp-critic-source-station))
        (contract (hyperdoc:default-lisp-critic-contract)))
    (lisp-critic-contract-assert-true
     (typep source-station 'hyperdoc:lisp-critic-source-station)
     "Default source station object must exist.")
    (lisp-critic-contract-assert-true
     (typep contract 'hyperdoc:lisp-critic-contract)
     "Default LISP-CRITIC contract object must exist.")
    (lisp-critic-contract-assert-equal
     "wiki.ralfbarkow.ch"
     (hyperdoc::lisp-critic-source-station-site-of source-station)
     "Default source station site must be represented as data.")
    (lisp-critic-contract-assert-equal
     "a-critic-for-lisp"
     (hyperdoc::lisp-critic-source-station-page-of source-station)
     "Default source station page must be represented as data.")
    (lisp-critic-contract-assert-equal
     "~/.wiki/wiki.ralfbarkow.ch/assets/pages/a-critic-for-lisp/"
     (hyperdoc::lisp-critic-source-station-asset-root-of source-station)
     "Default source station asset root must be represented as data.")
    (lisp-critic-contract-assert-true
     (eql source-station
          (hyperdoc::lisp-critic-contract-source-station-of contract))
     "Default contract must refer to the default source station.")))

(defun run-lisp-critic-contract-missing-asset-smoke-test ()
  (let* ((contract (lisp-critic-contract-missing-asset-contract))
         (record
           (hyperdoc:run-lisp-critic-contract
            contract
            (list (lisp-critic-contract-test-target-path)))))
    (lisp-critic-contract-assert-true
     (typep record 'hyperdoc:lisp-critic-run-record)
     "Missing source-station invocation must return a run record.")
    (lisp-critic-contract-assert-equal
     :asset-missing
     (hyperdoc:lisp-critic-run-record-status record)
     "Missing source-station invocation must be graceful.")
    (lisp-critic-contract-assert-true
     (stringp (hyperdoc:lisp-critic-run-record-raw-output record))
     "Missing source-station run record must still expose a raw output string.")
    record))

(defun run-lisp-critic-contract-default-run-smoke-test ()
  (let* ((asset-present?
           (hyperdoc:lisp-critic-source-station-present-p
            (hyperdoc:default-lisp-critic-source-station)))
         (record
           (hyperdoc:run-lisp-critic-contract
            (hyperdoc:default-lisp-critic-contract)
            (list (lisp-critic-contract-test-target-path))))
         (status (hyperdoc:lisp-critic-run-record-status record)))
    (lisp-critic-contract-assert-true
     (typep record 'hyperdoc:lisp-critic-run-record)
     "Default contract invocation must return a run record.")
    (lisp-critic-contract-assert-true
     (stringp (hyperdoc:lisp-critic-run-record-raw-output record))
     "Default run record must expose a raw output string.")
    (if asset-present?
        (progn
          (lisp-critic-contract-assert-member
           status
           '(:completed :load-failed :critic-unavailable :failed)
           "Present source station must complete or report an inspectable failure.")
          (unless (eql status :completed)
            (lisp-critic-contract-assert-true
             (hyperdoc::lisp-critic-run-record-condition-summary-of record)
             "Inspectable failure statuses must preserve a condition summary.")))
        (lisp-critic-contract-assert-equal
         :asset-missing
         status
         "Absent source station must produce :asset-missing."))
    (format t "~&Default LISP-CRITIC contract run status: ~S (asset present: ~:[no~;yes~]).~%"
            status
            asset-present?)
    record))

(defun run-lisp-critic-contract-view-smoke-test ()
  (let* ((source-station (hyperdoc:default-lisp-critic-source-station))
         (contract (hyperdoc:default-lisp-critic-contract))
         (missing-record
           (run-lisp-critic-contract-missing-asset-smoke-test))
         (source-html
           (lisp-critic-contract-view-html source-station "Summary"))
         (contract-html
           (lisp-critic-contract-view-html contract "Summary"))
         (run-html
           (lisp-critic-contract-view-html missing-record "Summary"))
         (raw-output-html
           (lisp-critic-contract-view-html missing-record "Raw output"))
         (failure-html
           (lisp-critic-contract-view-html
            missing-record
            "Failure / condition")))
    (lisp-critic-contract-assert-true
     (search "FedWiki LISP-CRITIC source station" source-html
             :test #'char=)
     "Source-station summary view must render the source station title.")
    (lisp-critic-contract-assert-true
     (search "raw-output-only" contract-html :test #'char=)
     "Contract summary view must render the raw output policy.")
    (lisp-critic-contract-assert-true
     (search "asset-missing" run-html :test #'char=)
     "Run-record summary view must render the run status.")
    (lisp-critic-contract-assert-true
     (search "Raw LISP-CRITIC output" raw-output-html :test #'char=)
     "Run-record raw output view must render.")
    (lisp-critic-contract-assert-true
     (search "Failure / condition" failure-html :test #'char=)
     "Run-record failure view must render.")))

(defun run-lisp-critic-contract-documentation-smoke-test ()
  (lisp-critic-contract-assert-true
   (probe-file
    (asdf:system-relative-pathname
     :hyperdoc
     "hyperdoc/LISP-CRITIC execution adapter contract.html"))
   "LISP-CRITIC execution adapter contract page must exist."))

(defun run-lisp-critic-contract-smoke-tests ()
  (run-lisp-critic-contract-object-smoke-test)
  (let ((missing-record
          (run-lisp-critic-contract-missing-asset-smoke-test))
        (default-record
          (run-lisp-critic-contract-default-run-smoke-test)))
    (run-lisp-critic-contract-view-smoke-test)
    (run-lisp-critic-contract-documentation-smoke-test)
    (format t "~&Observed LISP-CRITIC contract statuses: missing fixture=~S default=~S.~%"
            (hyperdoc:lisp-critic-run-record-status missing-record)
            (hyperdoc:lisp-critic-run-record-status default-record)))
  (format t "~&LISP-CRITIC contract smoke tests passed.~%")
  t)
