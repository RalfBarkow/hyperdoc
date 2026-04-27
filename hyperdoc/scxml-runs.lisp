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