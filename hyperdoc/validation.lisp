;;;; Documentation validation helpers
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *default-documentation-topic-coverage-pages*
  '("hyperdoc/official-tutorial-nixos-sd-image-on-raspberry-pi-4-400.html"
    "hyperdoc/two-installation-models-sd-image-vs-classic-installer.html"
    "hyperdoc/invariant-boot-partition-must-be-big-enough.html"
    "hyperdoc/preflight-checklist-for-raspberry-pi-nixos-sd-images.html"
    "hyperdoc/Runbook - Build and Flash NixOS SD Image for Kioskberrli.html"
    "hyperdoc/Prepare the AArch64 image.html"))

(defclass documentation-validation-check ()
  ((id :reader documentation-validation-check-id-of
       :initarg :id
       :type string)
   (label :reader documentation-validation-check-label-of
          :initarg :label
          :type string)
   (status :reader documentation-validation-check-status-of
           :initarg :status)
   (detail :reader documentation-validation-check-detail-of
           :initarg :detail
           :initform nil)
   (payload :reader documentation-validation-check-payload-of
            :initarg :payload
            :initform nil)))

(defmethod print-object ((check documentation-validation-check) stream)
  (print-unreadable-object (check stream :type t :identity t)
    (format stream "~A ~A"
            (documentation-validation-check-status-of check)
            (documentation-validation-check-label-of check))))

(defclass topic-coverage-reference ()
  ((page :reader topic-coverage-reference-page-of
         :initarg :page
         :type string)
   (expr :reader topic-coverage-reference-expr-of
         :initarg :expr
         :type string)))

(defclass topic-coverage-missing-symbol ()
  ((symbol :reader topic-coverage-missing-symbol-of
           :initarg :symbol
           :type symbol)
   (symbol-key :reader topic-coverage-missing-symbol-key-of
               :initarg :symbol-key
               :type string)
   (references :reader topic-coverage-missing-symbol-references-of
               :initarg :references
               :initform nil)))

(defclass topic-coverage-report ()
  ((pages :reader topic-coverage-pages-of
          :initarg :pages
          :initform nil)
   (checked-symbol-count :reader topic-coverage-checked-symbol-count-of
                         :initarg :checked-symbol-count
                         :initform 0)
   (duplicate-symbol-count :reader topic-coverage-duplicate-symbol-count-of
                           :initarg :duplicate-symbol-count
                           :initform 0)
   (page-symbol-counts :reader topic-coverage-page-symbol-counts-of
                       :initarg :page-symbol-counts
                       :initform nil)
   (missing-symbols :reader topic-coverage-missing-symbols-of
                    :initarg :missing-symbols
                    :initform nil)
   (pass? :reader documentation-topic-coverage-pass-p
          :initarg :pass?
          :initform t)))

(defmethod print-object ((report topic-coverage-report) stream)
  (print-unreadable-object (report stream :type t :identity t)
    (format stream "~:[fail~;ok~] pages=~D symbols=~D missing=~D"
            (documentation-topic-coverage-pass-p report)
            (length (topic-coverage-pages-of report))
            (topic-coverage-checked-symbol-count-of report)
            (length (topic-coverage-missing-symbols-of report)))))

(defclass documentation-slice-validation-report ()
  ((page :reader documentation-validation-page-of
         :initarg :page)
   (topics :reader documentation-validation-topics-of
           :initarg :topics
           :initform nil)
   (fedwiki-pages :reader documentation-validation-fedwiki-pages-of
                  :initarg :fedwiki-pages
                  :initform nil)
   (checks :reader documentation-validation-checks-of
           :initarg :checks
           :initform nil)
   (topic-coverage-report :reader documentation-validation-coverage-report-of
                          :initarg :topic-coverage-report
                          :initform nil)
   (passed-count :reader documentation-validation-passed-count-of
                 :initarg :passed-count
                 :initform 0)
   (failed-count :reader documentation-validation-failed-count-of
                 :initarg :failed-count
                 :initform 0)
   (skipped-count :reader documentation-validation-skipped-count-of
                  :initarg :skipped-count
                  :initform 0)
   (pass? :reader documentation-slice-validation-pass-p
          :initarg :pass?
          :initform t)))

(defmethod print-object ((report documentation-slice-validation-report) stream)
  (print-unreadable-object (report stream :type t :identity t)
    (format stream "~:[fail~;ok~] checks=~D failed=~D"
            (documentation-slice-validation-pass-p report)
            (length (documentation-validation-checks-of report))
            (documentation-validation-failed-count-of report))))

(defun documentation-validation-repo-root-pathname ()
  (asdf:system-relative-pathname :hyperdoc ""))

(defun documentation-validation-file-path (path &key (missing-label "Validation file"))
  (or (uiop:file-exists-p path)
      (uiop:file-exists-p
       (merge-pathnames (pathname path)
                        (documentation-validation-repo-root-pathname)))
      (error "~A not found: ~A" missing-label path)))

(defun documentation-whitespace-char-p (char)
  (or (char= char #\Space)
      (char= char #\Tab)
      (char= char #\Newline)
      (char= char #\Return)))

(defun extract-expr-forms (html)
  (loop with pos = 0
        for start = (search "expr=\"" html :start2 pos)
        while start
        for value-start = (+ start 6)
        for value-end = (position #\" html :start value-start)
        when value-end
          collect (subseq html value-start value-end)
          and do (setf pos (1+ value-end))
        else
          do (setf pos (1+ value-start))))

(defun expr-function-token (expr)
  (let ((open (position #\( expr)))
    (when open
      (let* ((start (or (position-if-not #'documentation-whitespace-char-p
                                         expr
                                         :start (1+ open))
                        (1+ open)))
             (end (position-if #'(lambda (char)
                                   (or (documentation-whitespace-char-p char)
                                       (char= char #\))))
                               expr
                               :start start)))
        (subseq expr start (or end (length expr)))))))

(defun expr-token-symbol (token)
  (let ((*package* (find-package :hyperdoc)))
    (handler-case
        (multiple-value-bind (symbol position)
            (read-from-string token)
          (declare (ignore position))
          symbol)
      (error () nil))))

(defun hyperdoc-symbol-p (symbol)
  (and symbol
       (symbol-package symbol)
       (string-equal (package-name (symbol-package symbol)) "HYPERDOC")))

(defun topic-symbol-key (symbol)
  (format nil "~A::~A"
          (package-name (symbol-package symbol))
          (symbol-name symbol)))

(defun normalize-topic-designator (designator)
  (etypecase designator
    (symbol designator)
    (string
     (or (expr-token-symbol designator)
         (error "Topic designator could not be resolved: ~A" designator)))))

(defun collect-page-symbol-exprs (pathname)
  (let* ((html (uiop:read-file-string pathname))
         (exprs (extract-expr-forms html))
         (seen (make-hash-table :test #'eq)))
    (loop for expr in exprs
          for token = (expr-function-token expr)
          for symbol = (and token (expr-token-symbol token))
          when (and (hyperdoc-symbol-p symbol)
                    (not (gethash symbol seen)))
            collect (progn
                      (setf (gethash symbol seen) t)
                      (cons symbol expr)))))

(defun sorted-page-symbol-counts (table)
  (sort (loop for page being the hash-keys of table
              using (hash-value count)
              collect (cons page count))
        #'string<
        :key #'car))

(defun documentation-topic-coverage-report (&key pages)
  "Return an inspectable report for topic coverage on the selected HyperDoc pages."
  (let* ((selected-pages
           (mapcar #'(lambda (page)
                       (documentation-validation-file-path
                        page
                        :missing-label "Topic coverage page"))
                   (or pages *default-documentation-topic-coverage-pages*)))
         (all-symbols '())
         (symbol-sources (make-hash-table :test #'eq))
         (symbol-reference-counts (make-hash-table :test #'eq))
         (page-symbol-counts (make-hash-table :test #'equal)))
    (dolist (page selected-pages)
      (let* ((page-name (namestring page))
             (page-symbols (collect-page-symbol-exprs page)))
        (setf (gethash page-name page-symbol-counts)
              (length page-symbols))
        (dolist (symbol+expr page-symbols)
          (destructuring-bind (symbol . expr) symbol+expr
            (pushnew symbol all-symbols :test #'eq)
            (incf (gethash symbol symbol-reference-counts 0))
            (pushnew (make-instance 'topic-coverage-reference
                                    :page page-name
                                    :expr expr)
                     (gethash symbol symbol-sources)
                     :test #'(lambda (left right)
                               (and (string= (topic-coverage-reference-page-of left)
                                             (topic-coverage-reference-page-of right))
                                    (string= (topic-coverage-reference-expr-of left)
                                             (topic-coverage-reference-expr-of right)))))))))
    (let* ((missing-symbols
             (sort (loop for symbol in all-symbols
                         unless (fboundp symbol)
                           collect (make-instance 'topic-coverage-missing-symbol
                                                  :symbol symbol
                                                  :symbol-key (topic-symbol-key symbol)
                                                  :references
                                                  (sort (copy-list (gethash symbol symbol-sources))
                                                        #'string<
                                                        :key #'topic-coverage-reference-page-of)))
                   #'string<
                   :key #'topic-coverage-missing-symbol-key-of))
           (duplicate-symbol-count
             (loop for symbol in all-symbols
                   count (> (gethash symbol symbol-reference-counts 0) 1))))
      (make-instance 'topic-coverage-report
                     :pages (mapcar #'namestring selected-pages)
                     :checked-symbol-count (length all-symbols)
                     :duplicate-symbol-count duplicate-symbol-count
                     :page-symbol-counts (sorted-page-symbol-counts page-symbol-counts)
                     :missing-symbols missing-symbols
                     :pass? (null missing-symbols)))))

(defun make-documentation-validation-check
    (id label status &key detail payload)
  (make-instance 'documentation-validation-check
                 :id id
                 :label label
                 :status status
                 :detail detail
                 :payload payload))

(defun documentation-validation-status-label (status)
  (ecase status
    (:passed "PASS ")
    (:failed "FAIL ")
    (:skipped "SKIP ")))

(defun print-prefixed-lines (stream prefix text)
  (dolist (line (uiop:split-string (princ-to-string text)
                                   :separator '(#\Newline)))
    (format stream "~A~A~%" prefix line)))

(defun print-documentation-topic-coverage-report
    (report &optional (stream *standard-output*))
  "Print REPORT in the legacy topic-coverage gate format."
  (format stream "~A~%"
          (if (documentation-topic-coverage-pass-p report)
              "TOPIC_COVERAGE_OK"
              "TOPIC_COVERAGE_FAIL"))
  (unless (documentation-topic-coverage-pass-p report)
    (dolist (missing (topic-coverage-missing-symbols-of report))
      (format stream "MISSING ~A~%"
              (topic-coverage-missing-symbol-key-of missing))
      (dolist (source (topic-coverage-missing-symbol-references-of missing))
        (format stream "  REFERENCED_BY ~A~%"
                (topic-coverage-reference-page-of source))
        (format stream "  EXPR ~A~%"
                (topic-coverage-reference-expr-of source)))))
  (format stream "CHECKED_PAGES=~D~%"
          (length (topic-coverage-pages-of report)))
  (format stream "CHECKED_SYMBOLS=~D~%"
          (topic-coverage-checked-symbol-count-of report))
  (format stream "DUPLICATE_SYMBOLS=~D~%"
          (topic-coverage-duplicate-symbol-count-of report))
  (dolist (entry (topic-coverage-page-symbol-counts-of report))
    (format stream "PAGE_SYMBOLS ~A ~D~%"
            (car entry)
            (cdr entry)))
  report)

(defun count-documentation-validation-checks (checks)
  (loop with passed = 0
        with failed = 0
        with skipped = 0
        for check in checks
        do (ecase (documentation-validation-check-status-of check)
             (:passed (incf passed))
             (:failed (incf failed))
             (:skipped (incf skipped)))
        finally (return (values passed failed skipped))))

(defun validate-fedwiki-json-syntax (path)
  (let ((resolved-path (documentation-validation-file-path
                        path
                        :missing-label "FedWiki page")))
    (with-open-file (stream resolved-path
                            :direction :input
                            :external-format :utf-8)
      (shasht:read-json stream))
    resolved-path))

(defun validate-documentation-slice (&key page topics fedwiki-pages)
  "Return an inspectable documentation validation report for one page slice."
  (unless page
    (error "Missing required :page argument for documentation validation."))
  (let ((checks '())
        (resolved-topics '())
        (resolved-fedwiki-pages '())
        (resolved-page nil)
        (coverage-report nil))
    (handler-case
        (setf resolved-page
              (documentation-validation-file-path
               page
               :missing-label "HyperDoc page"))
      (error (condition)
        (push (make-documentation-validation-check
               "page"
               (format nil "HyperDoc page ~A" page)
               :failed
               :detail condition)
              checks)))
    (when resolved-page
      (push (make-documentation-validation-check
             "page"
             (format nil "HyperDoc page ~A" (namestring resolved-page))
             :passed
             :payload resolved-page)
            checks))
    (if (null topics)
        (push (make-documentation-validation-check
               "topics"
               "topic fboundp checks (no --topic provided)"
               :skipped)
              checks)
        (dolist (topic-designator topics)
          (handler-case
              (let* ((topic-symbol (normalize-topic-designator topic-designator))
                     (status (if (fboundp topic-symbol) :passed :failed))
                     (detail (unless (fboundp topic-symbol)
                               (format nil "Function is not fboundp: ~A"
                                       (topic-symbol-key topic-symbol)))))
                (push topic-symbol resolved-topics)
                (push (make-documentation-validation-check
                       "topic"
                       (format nil "fboundp ~A" (topic-symbol-key topic-symbol))
                       status
                       :detail detail
                       :payload topic-symbol)
                      checks))
            (error (condition)
              (push (make-documentation-validation-check
                     "topic"
                     (format nil "topic designator ~A" topic-designator)
                     :failed
                     :detail condition)
                    checks)))))
    (if resolved-page
        (handler-case
            (setf coverage-report
                  (documentation-topic-coverage-report
                   :pages (list resolved-page)))
          (error (condition)
            (push (make-documentation-validation-check
                   "coverage"
                   (format nil "topic coverage ~A" (namestring resolved-page))
                   :failed
                   :detail condition)
                  checks)))
        (push (make-documentation-validation-check
               "coverage"
               (format nil "topic coverage ~A" page)
               :failed
               :detail "Coverage could not run because the page path did not resolve.")
              checks))
    (when coverage-report
      (push (make-documentation-validation-check
             "coverage"
             (format nil "topic coverage ~A" (namestring resolved-page))
             (if (documentation-topic-coverage-pass-p coverage-report)
                 :passed
                 :failed)
             :payload coverage-report)
            checks))
    (if (null fedwiki-pages)
        (push (make-documentation-validation-check
               "fedwiki"
               "FedWiki JSON syntax checks (no --fedwiki provided)"
               :skipped)
              checks)
        (dolist (fedwiki-page fedwiki-pages)
          (handler-case
              (let ((resolved-fedwiki-page
                      (validate-fedwiki-json-syntax fedwiki-page)))
                (push resolved-fedwiki-page resolved-fedwiki-pages)
                (push (make-documentation-validation-check
                       "fedwiki"
                       (format nil "FedWiki JSON syntax ~A"
                               (namestring resolved-fedwiki-page))
                       :passed
                       :payload resolved-fedwiki-page)
                      checks))
            (error (condition)
              (push (make-documentation-validation-check
                     "fedwiki"
                     (format nil "FedWiki JSON syntax ~A" fedwiki-page)
                     :failed
                     :detail condition)
                    checks)))))
    (let* ((ordered-checks (nreverse checks))
           (pass? (notany #'(lambda (check)
                              (eql (documentation-validation-check-status-of check)
                                    :failed))
                          ordered-checks)))
      (multiple-value-bind (passed failed skipped)
          (count-documentation-validation-checks ordered-checks)
        (make-instance 'documentation-slice-validation-report
                       :page resolved-page
                       :topics (nreverse resolved-topics)
                       :fedwiki-pages (nreverse resolved-fedwiki-pages)
                       :checks ordered-checks
                       :topic-coverage-report coverage-report
                       :passed-count passed
                       :failed-count failed
                       :skipped-count skipped
                       :pass? pass?)))))

(defun print-documentation-slice-validation-report
    (report &optional (stream *standard-output*))
  "Print REPORT in the validate-documentation-slice helper format."
  (dolist (check (documentation-validation-checks-of report))
    (format stream "~A ~A~%"
            (documentation-validation-status-label
             (documentation-validation-check-status-of check))
            (documentation-validation-check-label-of check))
    (when (documentation-validation-check-detail-of check)
      (print-prefixed-lines stream
                            "      "
                            (documentation-validation-check-detail-of check)))
    (when (and (string= (documentation-validation-check-id-of check) "coverage")
               (eql (documentation-validation-check-status-of check) :failed)
               (typep (documentation-validation-check-payload-of check)
                      'topic-coverage-report))
      (print-documentation-topic-coverage-report
       (documentation-validation-check-payload-of check)
       stream)))
  (format stream "----~%")
  (format stream "SUMMARY passes=~D fails=~D skips=~D~%"
          (documentation-validation-passed-count-of report)
          (documentation-validation-failed-count-of report)
          (documentation-validation-skipped-count-of report))
  (format stream "~A~%"
          (if (documentation-slice-validation-pass-p report)
              "DOC_SLICE_VALIDATION_OK"
              "DOC_SLICE_VALIDATION_FAIL"))
  report)
