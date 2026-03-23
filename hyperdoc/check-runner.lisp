;;;; Checks runner
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

;(A narrow in-image check runner for examples and smoke tests.)

(defclass check-spec ()
  ((kind :initarg :kind :reader check-kind-of)
   (id :initarg :id :reader check-id-of)
   (title :initarg :title :reader check-title-of)
   (locator :initarg :locator :reader check-locator-of)
   (tags :initarg :tags :initform nil :reader check-tags-of)))

(defclass check-result ()
  ((spec :initarg :spec :reader check-result-spec-of)
   (status :initarg :status :accessor check-result-status-of)
   (value :initarg :value :initform nil :accessor check-result-value-of)
   (condition :initarg :condition :initform nil :accessor check-result-condition-of)
   (backtrace :initarg :backtrace :initform nil :accessor check-result-backtrace-of)
   (duration-ms :initarg :duration-ms :initform 0 :accessor check-result-duration-ms-of)
   (assertions :initarg :assertions :initform nil :accessor check-result-assertions-of)))

(defclass check-run ()
  ((specs :initarg :specs :initform nil :accessor check-run-specs-of)
   (results :initarg :results :initform nil :accessor check-run-results-of)
   (started-at :initarg :started-at :initform nil :accessor check-run-started-at-of)
   (finished-at :initarg :finished-at :initform nil :accessor check-run-finished-at-of)
   (status-summary :initarg :status-summary :initform nil :accessor check-run-status-summary-of)))

(define-condition check-failure (error)
  ((message :initarg :message :reader check-failure-message))
  (:report (lambda (condition stream)
             (write-string (check-failure-message condition) stream))))

(define-condition check-skipped (condition)
  ((message :initarg :message :reader check-skipped-message))
  (:report (lambda (condition stream)
             (write-string (check-skipped-message condition) stream))))

(defparameter *example-check-registrations* (make-hash-table :test #'eq))
(defparameter *example-check-order* nil)

(defparameter *known-test-check-registrations*
  '((:package "HYPERDOC/TESTS"
     :name "RUN-DMX-TOPIC-PROXY-SMOKE-TESTS"
     :id "test:hyperdoc/tests:run-dmx-topic-proxy-smoke-tests"
     :title "DMX topic proxy smoke tests"
     :system "hyperdoc"
     :tags (:kind :smoke :suite "dmx"))
    (:package "HYPERDOC/TESTS"
     :name "RUN-ZOTERO-BRIDGE-SMOKE-TESTS"
     :id "test:hyperdoc/tests:run-zotero-bridge-smoke-tests"
     :title "Zotero bridge smoke tests"
     :system "hyperdoc"
     :tags (:kind :smoke :suite "zotero-bridge"))
    (:package "HYPERDOC/TESTS"
     :name "RUN-ZOTERO-BRIDGE-LIVE-TESTS"
     :id "test:hyperdoc/tests:run-zotero-bridge-live-tests"
     :title "Zotero bridge live tests"
     :system "hyperdoc"
     :tags (:kind :live :suite "zotero-bridge"))
    (:package "HYPERDOC/TESTS"
     :name "RUN-BIBLIOGRAPHY-SUBCOLLECTIONS-SMOKE-TESTS"
     :id "test:hyperdoc/tests:run-bibliography-subcollections-smoke-tests"
     :title "Bibliography subcollections smoke tests"
     :system "hyperdoc"
     :tags (:kind :smoke :suite "bibliography-subcollections"))
    (:package "HYPERDOC/TESTS"
     :name "RUN-FEDWIKI-SITE-DMX-IMPORT-TESTS"
     :id "test:hyperdoc/tests:run-fedwiki-site-dmx-import-tests"
     :title "FedWiki site DMX import tests"
     :system "hyperdoc"
     :tags (:kind :smoke :suite "fedwiki-dmx-import"))
    (:package "HYPERDOC/TESTS"
     :name "RUN-CHECK-RUNNER-SMOKE-TESTS"
     :id "test:hyperdoc/tests:run-check-runner-smoke-tests"
     :title "Check runner smoke tests"
     :system "hyperdoc"
     :tags (:kind :smoke :suite "check-runner"))
    (:package "HYPERDOC/TESTS"
     :name "RUN-MERGED-DOC-SLICES-SMOKE-TESTS"
     :id "test:hyperdoc/tests:run-merged-doc-slices-smoke-tests"
     :title "Merged documentation slice smoke tests"
     :system "hyperdoc"
     :tags (:kind :smoke :suite "merged-doc-slices"))
    (:package "HYPERDOC"
     :name "RUN-REPO-DOCUMENTATION-SLICE-VALIDATION-CHECK"
     :id "test:hyperdoc:run-repo-documentation-slice-validation-check"
     :title "Documentation-slice validation"
     :system "hyperdoc"
     :tags (:kind :validation :suite "documentation-slice"))))

(defun current-check-timestamp ()
  (get-universal-time))

(defun duration-ms-since (start-ticks)
  (round (* 1000
            (/ (- (get-internal-real-time) start-ticks)
               internal-time-units-per-second))))

(defun normalize-string-designator (value)
  (etypecase value
    (null nil)
    (string (string-downcase value))
    (symbol (string-downcase (symbol-name value)))))

(defun normalize-package-designator (value)
  (typecase value
    (null nil)
    (package (string-upcase (package-name value)))
    (string (string-upcase value))
    (symbol (string-upcase (or (and (find-package value)
                                    (package-name (find-package value)))
                               (symbol-name value))))))

(defun source-file-page-title (pathname)
  (when pathname
    (or (ignore-errors
          (->> pathname
               uiop:read-file-lines
               first
               (string-left-trim " ;")
               (string-right-trim " ")))
        (pathname-name pathname))))

(defun make-check-id (kind function-symbol)
  (format nil "~(~A~):~A:~(~A~)"
          kind
          (package-name (symbol-package function-symbol))
          (symbol-name function-symbol)))

(defun make-check-title (kind function-symbol)
  (format nil "~A: ~A"
          (string-capitalize (string-downcase (symbol-name kind)))
          (string-downcase (symbol-name function-symbol))))

(defun normalized-source-file (pathname)
  (when pathname
    (or (ignore-errors (truename pathname))
        pathname)))

(defun component-defines-source-file-p (component source-file)
  (let ((component-path (normalized-source-file
                         (ignore-errors (asdf:component-pathname component)))))
    (or (and component-path
             (equal component-path source-file))
        (loop for child in (ignore-errors (asdf:component-children component))
              thereis (component-defines-source-file-p child source-file)))))

(defun source-file-system-name (source-file)
  (let ((source-file (normalized-source-file source-file)))
    (when source-file
      (loop for name in (sort (copy-list (asdf:registered-systems)) #'string<)
            for system = (ignore-errors (asdf:find-system name))
            when (and system
                      (component-defines-source-file-p system source-file))
              return (asdf:component-name system)))))

(defun register-example-check (function-symbol &key system
                                              (package (symbol-package function-symbol))
                                              (source-file (or *load-truename*
                                                               *compile-file-truename*))
                                              page
                                              title
                                              tags)
  (let* ((resolved-system (or system
                              (source-file-system-name source-file)
                              "hyperdoc"))
         (package-name (normalize-package-designator package))
         (page-title (or page (source-file-page-title source-file)))
         (registration
           (list :function function-symbol
                 :system (normalize-string-designator resolved-system)
                 :package package-name
                 :source-file source-file
                 :page page-title
                 :title (or title (make-check-title :example function-symbol))
                 :tags tags)))
    (unless (gethash function-symbol *example-check-registrations*)
      (setf *example-check-order* (append *example-check-order*
                                          (list function-symbol))))
    (setf (gethash function-symbol *example-check-registrations*) registration)
    function-symbol))

(defun example-registration-matches-p (registration &key system package page)
  (and (or (null system)
           (equal (getf registration :system)
                  (normalize-string-designator system)))
       (or (null package)
           (equal (getf registration :package)
                  (normalize-package-designator package)))
       (or (null page)
           (equal (getf registration :page) page))))

(defun make-example-check-spec (registration)
  (let ((function-symbol (getf registration :function)))
    (make-instance 'check-spec
                   :kind :example
                   :id (make-check-id :example function-symbol)
                   :title (getf registration :title)
                   :locator (list :function function-symbol
                                  :system (getf registration :system)
                                  :package (getf registration :package)
                                  :page (getf registration :page)
                                  :source-file (getf registration :source-file))
                   :tags (append (list :page (getf registration :page))
                                 (getf registration :tags)))))

(defun resolve-function-symbol (locator)
  (or (getf locator :function)
      (let* ((package-name (getf locator :function-package))
             (function-name (getf locator :function-name))
             (package (and package-name
                           (find-package package-name))))
        (and package function-name
             (find-symbol function-name package)))))

(defun resolve-check-function (check-spec)
  (let ((symbol (resolve-function-symbol (check-locator-of check-spec))))
    (unless (and symbol (fboundp symbol))
      (error "Check function unavailable for ~A" (check-id-of check-spec)))
    (symbol-function symbol)))

(defun ensure-check-run-summary (run)
  (let* ((results (check-run-results-of run))
         (total (length (check-run-specs-of run)))
         (passed 0)
         (failed 0)
         (errored 0)
         (skipped 0))
    (dolist (result results)
      (ecase (check-result-status-of result)
        (:passed (incf passed))
        (:failed (incf failed))
        (:error (incf errored))
        (:skipped (incf skipped))))
    (let ((pending (max 0 (- total (length results)))))
      (setf (check-run-status-summary-of run)
            (list :total total
                  :passed passed
                  :failed failed
                  :error errored
                  :skipped skipped
                  :pending pending
                  :status (cond
                            ((plusp errored) :error)
                            ((plusp failed) :failed)
                            ((plusp skipped) :skipped)
                            ((and (zerop pending) (plusp total)) :passed)
                            (t :pending)))))))

(defmethod initialize-instance :after ((run check-run) &key)
  (ensure-check-run-summary run))

(defun check-run-duration-ms (run)
  (getf (check-run-status-summary-of run) :duration-ms))

(defun condition-backtrace-string (condition)
  (with-output-to-string (stream)
    (ignore-errors
      (uiop:print-condition-backtrace condition :stream stream))))

(defun discover-example-checks (&key system package page)
  (loop for function-symbol in *example-check-order*
        for registration = (gethash function-symbol *example-check-registrations*)
        when (and registration
                  (example-registration-matches-p registration
                                                  :system system
                                                  :package package
                                                  :page page))
          collect (make-example-check-spec registration)))

(defun ensure-test-checks-loaded ()
  (ignore-errors
    (asdf:load-system :hyperdoc/tests))
  t)

(defun test-registration-matches-p (registration &key system package)
  (and (or (null system)
           (equal (getf registration :system)
                  (normalize-string-designator system)))
       (or (null package)
           (equal (getf registration :package)
                  (normalize-package-designator package)))))

(defun make-test-check-spec (registration)
  (make-instance 'check-spec
                 :kind :test
                 :id (getf registration :id)
                 :title (getf registration :title)
                 :locator (list :function-package (getf registration :package)
                                :function-name (getf registration :name)
                                :system (getf registration :system))
                 :tags (getf registration :tags)))

(defun discover-test-checks (&key system package)
  (ensure-test-checks-loaded)
  (loop for registration in *known-test-check-registrations*
        when (and (test-registration-matches-p registration
                                               :system system
                                               :package package)
                  (resolve-function-symbol
                   (list :function-package (getf registration :package)
                         :function-name (getf registration :name))))
          collect (make-test-check-spec registration)))

(defun discover-checks (&key system package page
                             (include-examples t)
                             (include-tests t))
  (append (when include-examples
            (discover-example-checks :system system :package package :page page))
          (when include-tests
            (discover-test-checks :system system :package package))))

(defun run-check (check-spec &key force?)
  (declare (ignore force?))
  (let ((start (get-internal-real-time)))
    (handler-case
        (let ((value (funcall (resolve-check-function check-spec))))
          (make-instance 'check-result
                         :spec check-spec
                         :status :passed
                         :value value
                         :duration-ms (duration-ms-since start)))
      (check-skipped (condition)
        (make-instance 'check-result
                       :spec check-spec
                       :status :skipped
                       :condition condition
                       :backtrace (condition-backtrace-string condition)
                       :duration-ms (duration-ms-since start)))
      (check-failure (condition)
        (make-instance 'check-result
                       :spec check-spec
                       :status :failed
                       :condition condition
                       :backtrace (condition-backtrace-string condition)
                       :duration-ms (duration-ms-since start)))
      (error (condition)
        (make-instance 'check-result
                       :spec check-spec
                       :status :error
                       :condition condition
                       :backtrace (condition-backtrace-string condition)
                       :duration-ms (duration-ms-since start))))))

(defun check-result-failed-p (result)
  (member (check-result-status-of result) '(:failed :error :skipped)))

(defun failed-check-results (run)
  (remove-if-not #'check-result-failed-p (check-run-results-of run)))

(defun result-map-by-id (results)
  (let ((table (make-hash-table :test #'equal)))
    (dolist (result results table)
      (setf (gethash (check-id-of (check-result-spec-of result)) table) result))))

(defun refresh-check-result! (result &key force?)
  (let ((fresh (run-check (check-result-spec-of result) :force? force?)))
    (setf (check-result-status-of result) (check-result-status-of fresh)
          (check-result-value-of result) (check-result-value-of fresh)
          (check-result-condition-of result) (check-result-condition-of fresh)
          (check-result-backtrace-of result) (check-result-backtrace-of fresh)
          (check-result-duration-ms-of result) (check-result-duration-ms-of fresh)
          (check-result-assertions-of result) (check-result-assertions-of fresh))
    result))

(defun run-check-run! (run &key fail-fast? specs)
  (let* ((selected-specs (or specs (check-run-specs-of run)))
         (results '())
         (started-at (current-check-timestamp))
         (start-ticks (get-internal-real-time)))
    (setf (check-run-started-at-of run) started-at)
    (dolist (spec selected-specs)
      (let ((result (run-check spec)))
        (push result results)
        (when (and fail-fast?
                   (member (check-result-status-of result) '(:failed :error)))
          (return))))
    (setf (check-run-results-of run) (nreverse results)
          (check-run-finished-at-of run) (current-check-timestamp))
    (ensure-check-run-summary run)
    (setf (getf (check-run-status-summary-of run) :duration-ms)
          (duration-ms-since start-ticks))
    run))

(defun run-checks (check-specs &key fail-fast?)
  (let ((run (make-instance 'check-run :specs check-specs)))
    (run-check-run! run :fail-fast? fail-fast?)))

(defun rerun-failed-checks! (run &key fail-fast?)
  (let* ((results (check-run-results-of run))
         (failed-results (failed-check-results run))
         (failed-specs (mapcar #'check-result-spec-of failed-results))
         (rerun-run (run-checks failed-specs :fail-fast? fail-fast?))
         (replacement-map (result-map-by-id (check-run-results-of rerun-run)))
         (existing-map (result-map-by-id results))
         (merged-results
           (loop for spec in (check-run-specs-of run)
                 for id = (check-id-of spec)
                 collect (or (gethash id replacement-map)
                             (gethash id existing-map)))))
    (setf (check-run-results-of run) merged-results
          (check-run-started-at-of run) (check-run-started-at-of rerun-run)
          (check-run-finished-at-of run) (check-run-finished-at-of rerun-run))
    (ensure-check-run-summary run)
    (setf (getf (check-run-status-summary-of run) :duration-ms)
          (check-run-duration-ms rerun-run))
    run))

(defun make-discovered-check-run (&key system package page
                                       (include-examples t)
                                       (include-tests t))
  (make-instance 'check-run
                 :specs (discover-checks :system system
                                         :package package
                                         :page page
                                         :include-examples include-examples
                                         :include-tests include-tests)))

(defun run-discovered-checks (&key system package page
                                   (include-examples t)
                                   (include-tests t)
                                   fail-fast?)
  (run-checks (discover-checks :system system
                               :package package
                               :page page
                               :include-examples include-examples
                               :include-tests include-tests)
              :fail-fast? fail-fast?))

(defun print-check-run-summary (run &optional (stream *standard-output*))
  (let ((summary (check-run-status-summary-of run)))
    (format stream
            "~&Checks: ~D total, ~D passed, ~D failed, ~D errored, ~D skipped, ~D pending~@[ in ~D ms~].~%"
            (getf summary :total)
            (getf summary :passed)
            (getf summary :failed)
            (getf summary :error)
            (getf summary :skipped)
            (getf summary :pending)
            (check-run-duration-ms run))
    (dolist (result (failed-check-results run))
      (format stream
              "~A ~A~%"
              (string-upcase (symbol-name (check-result-status-of result)))
              (check-id-of (check-result-spec-of result))))))

(defun check-run-success-p (run)
  (let ((summary (check-run-status-summary-of run)))
    (and (zerop (getf summary :failed))
         (zerop (getf summary :error)))))

(defun run-ci-checks (&key (system "hyperdoc") package page
                           (include-examples t)
                           (include-tests t)
                           fail-fast?
                           (stream *standard-output*)
                           (quit? t))
  (let* ((run (run-discovered-checks :system system
                                     :package package
                                     :page page
                                     :include-examples include-examples
                                     :include-tests include-tests
                                     :fail-fast? fail-fast?))
         (code (if (check-run-success-p run) 0 1)))
    (print-check-run-summary run stream)
    (when quit?
      (uiop:quit code))
    run))
