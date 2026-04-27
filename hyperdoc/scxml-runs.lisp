;;;; SCXML run objects for repair-protocol dry-runs
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *uscxml-browser*
  (or (uiop:getenv "USCXML_BROWSER")
      "/Users/rgb/workspace/uscxml/build/bin/uscxml-browser"))

(defparameter *page-lookup-topic-repair-stub-scxml*
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/page-lookup-issue-topic-repair.stub.scxml"))

(defparameter *page-promotion-output-sync-expectation-scxml*
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/page-promotion-output-sync-expectation.scxml"))

(defclass page-lookup-topic-repair-scxml-run ()
  ((issue :reader scxml-run-issue-of
          :initarg :issue
          :initform nil)
   (scxml-path :reader scxml-run-scxml-path-of
               :initarg :scxml-path)
   (command :reader scxml-run-command-of
            :initarg :command)
   (stdout :reader scxml-run-stdout-of
           :initarg :stdout)
   (stderr :reader scxml-run-stderr-of
           :initarg :stderr)
   (exit-code :reader scxml-run-exit-code-of
              :initarg :exit-code)))

(defclass page-lookup-topic-repair-native-scxml-run ()
  ((issue :reader native-scxml-run-issue-of
          :initarg :issue
          :initform nil)
   (scxml-path :reader native-scxml-run-scxml-path-of
               :initarg :scxml-path)
   (generated-package :reader native-scxml-run-generated-package-of
                      :initarg :generated-package)
   (generated-function :reader native-scxml-run-generated-function-of
                       :initarg :generated-function)
   (trace :reader native-scxml-run-trace-of
          :initarg :trace
          :initform nil)
   (final-state :reader native-scxml-run-final-state-of
                :initarg :final-state
                :initform nil)
   (done-p :reader native-scxml-run-done-p-of
           :initarg :done-p
           :initform nil)
   (validation-findings :reader native-scxml-run-validation-findings-of
                        :initarg :validation-findings
                        :initform nil)))

(defclass scxml-expectation-run ()
  ((scxml-path :reader scxml-expectation-run-scxml-path-of
               :initarg :scxml-path)
   (expected-subject :reader scxml-expectation-run-expected-subject-of
                     :initarg :expected-subject
                     :initform nil)
   (input-events :reader scxml-expectation-run-input-events-of
                 :initarg :input-events
                 :initform nil)
   (semantic-facts :reader scxml-expectation-run-semantic-facts-of
                   :initarg :semantic-facts
                   :initform nil)
   (validation-findings :reader scxml-expectation-run-validation-findings-of
                        :initarg :validation-findings
                        :initform nil)
   (generated-package :reader scxml-expectation-run-generated-package-of
                      :initarg :generated-package
                      :initform nil)
   (generated-function :reader scxml-expectation-run-generated-function-of
                       :initarg :generated-function
                       :initform nil)
   (trace :reader scxml-expectation-run-trace-of
          :initarg :trace
          :initform nil)
   (final-state :reader scxml-expectation-run-final-state-of
                :initarg :final-state
                :initform nil)
   (done-p :reader scxml-expectation-run-done-p-of
           :initarg :done-p
           :initform nil)
   (passed-p :reader scxml-expectation-run-passed-p-of
             :initarg :passed-p
             :initform nil)))

(defun uscxml-browser-pathname ()
  (let ((browser *uscxml-browser*))
    (and browser (probe-file browser))))

(defun run-page-lookup-topic-repair-stub-scxml (&optional issue)
  (let ((browser (uscxml-browser-pathname)))
    (unless browser
      (error "uSCXML browser not found. Set USCXML_BROWSER or update HYPERDOC::*USCXML-BROWSER*."))

    (let* ((command (list (namestring browser)
                          "-v"
                          "-l5"
                          (namestring *page-lookup-topic-repair-stub-scxml*))))
      (multiple-value-bind (stdout stderr exit-code)
          (uiop:run-program command
                            :output :string
                            :error-output :string
                            :ignore-error-status t)
        (make-instance 'page-lookup-topic-repair-scxml-run
                       :issue issue
                       :scxml-path *page-lookup-topic-repair-stub-scxml*
                       :command command
                       :stdout stdout
                       :stderr stderr
                       :exit-code exit-code)))))

(defun ensure-hyperdoc-scxml-system-loaded ()
  (asdf:load-system :hyperdoc/scxml))

(defun call-hyperdoc-scxml (function &rest arguments)
  (ensure-hyperdoc-scxml-system-loaded)
  (apply #'uiop:symbol-call :hyperdoc/scxml function arguments))

(defun scxml-validation-error-findings (findings)
  (remove-if-not (lambda (finding)
                   (eq :error
                       (call-hyperdoc-scxml
                        :scxml-validation-finding-severity-of
                        finding)))
                 findings))

(defun scxml-final-state= (expected final-state)
  (let ((state
          (cond
            ((stringp final-state) final-state)
            ((symbolp final-state) (string-downcase (symbol-name final-state)))
            (t (princ-to-string final-state)))))
    (string= (string-downcase expected)
             (string-downcase state))))

(defun run-scxml-expectation-with-events
    (scxml-path input-events semantic-facts
     &key expected-subject package-name function-name)
  (let* ((resolved-path (pathname scxml-path))
         (generated-package (or package-name
                                "HYPERDOC/SCXML/GENERATED/EXPECTATION"))
         (generated-function (or function-name
                                 "RUN-SCXML-EXPECTATION"))
         (chart (call-hyperdoc-scxml
                 :parse-scxml-file
                 resolved-path))
         (validation-findings (call-hyperdoc-scxml
                               :validate-scxml-chart
                               chart))
         (error-findings (scxml-validation-error-findings validation-findings)))
    (if error-findings
        (make-instance 'scxml-expectation-run
                       :scxml-path resolved-path
                       :expected-subject expected-subject
                       :input-events (copy-list input-events)
                       :semantic-facts (copy-tree semantic-facts)
                       :validation-findings validation-findings
                       :generated-package generated-package
                       :generated-function generated-function
                       :trace nil
                       :final-state nil
                       :done-p nil
                       :passed-p nil)
        (let* ((generated-run (call-hyperdoc-scxml
                               :compile-and-run-scxml-file-with-events
                               resolved-path
                               input-events
                               :package-name generated-package
                               :function-name generated-function))
               (trace (call-hyperdoc-scxml
                       :generated-scxml-run-trace-of
                       generated-run))
               (final-state (call-hyperdoc-scxml
                             :generated-scxml-run-final-state-of
                             generated-run))
               (done-p (call-hyperdoc-scxml
                        :generated-scxml-run-done-p
                        generated-run))
               (passed-p (and done-p
                              (scxml-final-state=
                               "passed"
                               final-state))))
          (make-instance 'scxml-expectation-run
                         :scxml-path resolved-path
                         :expected-subject expected-subject
                         :input-events (copy-list input-events)
                         :semantic-facts (copy-tree semantic-facts)
                         :validation-findings validation-findings
                         :generated-package generated-package
                         :generated-function generated-function
                         :trace trace
                         :final-state final-state
                         :done-p done-p
                         :passed-p passed-p)))))

(defun run-page-lookup-topic-repair-native-scxml (&optional issue)
  (let* ((scxml-path *page-lookup-topic-repair-stub-scxml*)
         (generated-package "HYPERDOC/SCXML/GENERATED/PAGE-LOOKUP-TOPIC-REPAIR")
         (generated-function "RUN-PAGE-LOOKUP-ISSUE-TOPIC-REPAIR")
         (chart (call-hyperdoc-scxml
                 :parse-scxml-file
                 scxml-path))
         (validation-findings (call-hyperdoc-scxml
                               :validate-scxml-chart
                               chart))
         (error-findings (scxml-validation-error-findings validation-findings)))
    (if error-findings
        (make-instance 'page-lookup-topic-repair-native-scxml-run
                       :issue issue
                       :scxml-path scxml-path
                       :generated-package generated-package
                       :generated-function generated-function
                       :trace nil
                       :final-state nil
                       :done-p nil
                       :validation-findings validation-findings)
        (let* ((generated-run (call-hyperdoc-scxml
                               :compile-and-run-scxml-file
                               scxml-path
                               :package-name generated-package
                               :function-name generated-function))
               (trace (call-hyperdoc-scxml
                       :generated-scxml-run-trace-of
                       generated-run))
               (final-state (call-hyperdoc-scxml
                             :generated-scxml-run-final-state-of
                             generated-run))
               (done-p (call-hyperdoc-scxml
                        :generated-scxml-run-done-p
                        generated-run)))
          (make-instance 'page-lookup-topic-repair-native-scxml-run
                         :issue issue
                         :scxml-path scxml-path
                         :generated-package generated-package
                         :generated-function generated-function
                         :trace trace
                         :final-state final-state
                         :done-p done-p
                         :validation-findings validation-findings)))))
