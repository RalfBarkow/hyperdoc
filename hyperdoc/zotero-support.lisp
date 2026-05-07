;;;; Optional Zotero runtime support boundary
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *zotero-backend-system-name* "hyperdoc/zotero")
(defparameter *zotero-inspector-system-name* "hyperdoc/inspector/zotero")
(defparameter *zotero-configuration-variable* "HYPERDOC_ENABLE_ZOTERO")
(defparameter *zotero-support-mode-override* :inherit)

(defclass zotero-backend-unavailable ()
  ((operation :reader zotero-backend-unavailable-operation-of
              :initarg :operation)
   (reason :reader zotero-backend-unavailable-reason-of
           :initarg :reason)
   (message :reader zotero-backend-unavailable-message-of
            :initarg :message)
   (configuration-variable
    :reader zotero-backend-unavailable-configuration-variable-of
    :initarg :configuration-variable
    :initform *zotero-configuration-variable*)
   (configuration-value
    :reader zotero-backend-unavailable-configuration-value-of
    :initarg :configuration-value
    :initform nil)
   (system-name :reader zotero-backend-unavailable-system-name-of
                :initarg :system-name
                :initform *zotero-backend-system-name*)
   (detail :reader zotero-backend-unavailable-detail-of
           :initarg :detail
           :initform nil)))

(defmethod print-object ((object zotero-backend-unavailable) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A (~A)"
            (zotero-backend-unavailable-operation-of object)
            (string-downcase
             (symbol-name (zotero-backend-unavailable-reason-of object))))))

(defun zotero-backend-unavailable-p (object)
  (typep object 'zotero-backend-unavailable))

(defun truthy-env-string-p (value)
  (member (string-downcase (or value ""))
          '("1" "true" "yes" "on")
          :test #'string=))

(defun falsy-env-string-p (value)
  (member (string-downcase (or value ""))
          '("0" "false" "no" "off")
          :test #'string=))

(defun configured-zotero-support-mode ()
  (let ((value (uiop:getenv *zotero-configuration-variable*)))
    (cond
      ((eq *zotero-support-mode-override* :enabled) :enabled)
      ((eq *zotero-support-mode-override* :disabled) :disabled)
      ((null value) :default)
      ((truthy-env-string-p value) :enabled)
      ((falsy-env-string-p value) :disabled)
      (t :disabled))))

(defun zotero-support-enabled-p ()
  (case (configured-zotero-support-mode)
    (:enabled t)
    (:disabled nil)
    (otherwise t)))

(defmacro with-zotero-support-mode ((mode) &body body)
  `(let ((*zotero-support-mode-override* ,mode))
     ,@body))

(defun zotero-disabled-message (operation)
  (format nil
          "Zotero support is disabled by configuration. ~A is unavailable until ~A=1."
          operation
          *zotero-configuration-variable*))

(defun zotero-load-failed-message (operation detail)
  (format nil
          "Zotero support is enabled, but ~A could not load ~A.~@[ ~A~]"
          operation
          *zotero-backend-system-name*
          detail))

(defun make-zotero-backend-unavailable (operation &key detail)
  (let ((enabled-p (zotero-support-enabled-p)))
    (make-instance
     'zotero-backend-unavailable
     :operation operation
     :reason (if enabled-p :load-failed :disabled-by-configuration)
     :message (if enabled-p
                  (zotero-load-failed-message operation detail)
                  (zotero-disabled-message operation))
     :configuration-value (uiop:getenv *zotero-configuration-variable*)
     :detail detail)))

(defun ensure-optional-zotero-system-loaded (&key (system-name *zotero-backend-system-name*)
                                               operation)
  (declare (ignore operation))
  (when (zotero-support-enabled-p)
    (handler-case
        (progn
          (asdf:load-system system-name)
          t)
      (error (condition)
        (values nil (princ-to-string condition))))))

(defun call-zotero-runtime-symbol (symbol-name operation arguments)
  (let* ((symbol (or (find-symbol symbol-name :hyperdoc)
                     (error "Missing HyperDoc symbol ~A for Zotero wrapper." symbol-name)))
         (self (and (fboundp symbol)
                    (symbol-function symbol))))
    (if (zotero-support-enabled-p)
        (multiple-value-bind (loaded-p detail)
            (ensure-optional-zotero-system-loaded :operation operation)
          (if loaded-p
              (let ((implementation (symbol-function symbol)))
                (if (eq implementation self)
                    (make-zotero-backend-unavailable operation
                                                     :detail "implementation remained unavailable after loading the Zotero system")
                    (apply implementation arguments)))
              (make-zotero-backend-unavailable operation :detail detail)))
        (make-zotero-backend-unavailable operation))))

(defmacro define-zotero-runtime-wrapper (name lambda-list operation)
  (let ((args (loop for item in lambda-list
                    unless (member item '(&optional &rest &key &allow-other-keys &aux))
                    collect (if (consp item) (first item) item))))
    `(defun ,name ,lambda-list
       (call-zotero-runtime-symbol ,(string name)
                                   ,operation
                                   (list ,@args)))))

(define-zotero-runtime-wrapper make-zotero-library-bridge
    (&key db-path storage-root note-roots sqlite-program)
  "create Zotero library bridge")

(define-zotero-runtime-wrapper make-default-zotero-library-bridge ()
  "open default Zotero library bridge")

(define-zotero-runtime-wrapper lookup-zotero-items-by-title
    (title &key bridge (match-mode :exact))
  "lookup Zotero items by title")

(define-zotero-runtime-wrapper lookup-zotero-item-by-id
    (item-id &key bridge)
  "lookup Zotero item by id")

(define-zotero-runtime-wrapper recent-zotero-changes
    (&key bridge limit since include-attachments?)
  "inspect recent Zotero changes")

(define-zotero-runtime-wrapper list-zotero-attachments-for-item
    (item-or-id &key bridge)
  "list Zotero attachments for item")

(define-zotero-runtime-wrapper resolve-zotero-stored-attachment-path
    (attachment &key bridge item-hit)
  "resolve Zotero stored attachment path")

(define-zotero-runtime-wrapper resolve-zotero-linked-attachment-path
    (attachment &key bridge item-hit)
  "resolve Zotero linked attachment path")

(define-zotero-runtime-wrapper resolve-zotero-attachment-path
    (bridge attachment &key item-hit)
  "resolve Zotero attachment path")

(define-zotero-runtime-wrapper resolve-zotero-title-to-candidate-pdf-reports
    (title &key bridge (match-mode :exact) note-search?)
  "resolve Zotero title to candidate PDF reports")

(define-zotero-runtime-wrapper resolve-zotero-title-to-local-pdf-report
    (title &key bridge (match-mode :exact) note-search?)
  "resolve Zotero title to local PDF report")

(define-zotero-runtime-wrapper make-zotero-live-demo-library ()
  "open Zotero live demo bridge")

(define-zotero-runtime-wrapper mind-and-mechanism-zotero-demo-title ()
  "read the Mind and Mechanism demo title")

(define-zotero-runtime-wrapper mind-and-mechanism-zotero-demo-item-id ()
  "read the Mind and Mechanism demo item id")

(define-zotero-runtime-wrapper mind-and-mechanism-zotero-demo-attachment-key ()
  "read the Mind and Mechanism demo attachment key")

(define-zotero-runtime-wrapper mind-and-mechanism-zotero-title-query ()
  "inspect the Mind and Mechanism Zotero title query")

(define-zotero-runtime-wrapper mind-and-mechanism-zotero-item-id-query ()
  "inspect the Mind and Mechanism Zotero item-id query")

(define-zotero-runtime-wrapper mind-and-mechanism-zotero-item-hit ()
  "inspect the Mind and Mechanism Zotero item hit")

(define-zotero-runtime-wrapper mind-and-mechanism-zotero-attachment-hit ()
  "inspect the Mind and Mechanism Zotero attachment hit")

(define-zotero-runtime-wrapper mind-and-mechanism-zotero-path-resolution-report ()
  "inspect the Mind and Mechanism Zotero path-resolution report")

(define-zotero-runtime-wrapper mind-and-mechanism-zotero-resolution-report ()
  "inspect the Mind and Mechanism Zotero title-resolution report")

(define-zotero-runtime-wrapper martinez-zotero-demo-title ()
  "read the Martínez demo title")

(define-zotero-runtime-wrapper martinez-zotero-demo-item-id ()
  "read the Martínez demo item id")

(define-zotero-runtime-wrapper martinez-zotero-paper-attachment-key ()
  "read the Martínez paper attachment key")

(define-zotero-runtime-wrapper martinez-zotero-supplement-attachment-key ()
  "read the Martínez supplement attachment key")

(define-zotero-runtime-wrapper martinez-zotero-title-query ()
  "inspect the Martínez Zotero title query")

(define-zotero-runtime-wrapper martinez-zotero-item-id-query ()
  "inspect the Martínez Zotero item-id query")

(define-zotero-runtime-wrapper martinez-zotero-item-hit ()
  "inspect the Martínez Zotero item hit")

(define-zotero-runtime-wrapper martinez-zotero-paper-attachment-hit ()
  "inspect the Martínez paper attachment hit")

(define-zotero-runtime-wrapper martinez-zotero-supplement-attachment-hit ()
  "inspect the Martínez supplement attachment hit")

(define-zotero-runtime-wrapper martinez-zotero-paper-path-resolution-report ()
  "inspect the Martínez paper path-resolution report")

(define-zotero-runtime-wrapper martinez-zotero-supplement-path-resolution-report ()
  "inspect the Martínez supplement path-resolution report")

(define-zotero-runtime-wrapper martinez-zotero-paper-resolution-report ()
  "inspect the Martínez paper resolution report")

(define-zotero-runtime-wrapper martinez-zotero-supplement-resolution-report ()
  "inspect the Martínez supplement resolution report")

(define-zotero-runtime-wrapper make-zotero-bibliography-source
    (&key bridge default-collection materialization-root)
  "create Zotero-backed bibliography source")

(define-zotero-runtime-wrapper make-default-bibliography-source ()
  "open default bibliography source")

(define-zotero-runtime-wrapper execute-topic-enrichment-query-plan
    (plan)
  "execute topic enrichment query plan")

(defun maybe-enable-zotero-runtime-support ()
  (cond
    ((not (zotero-support-enabled-p))
     (format t "~&[HYPERDOC/ZOTERO] disabled by ~A~%"
             *zotero-configuration-variable*)
     (make-zotero-backend-unavailable "runtime Zotero support"))
    (t
     (multiple-value-bind (loaded-p detail)
         (ensure-optional-zotero-system-loaded
          :system-name *zotero-inspector-system-name*
          :operation "runtime Zotero support")
       (if loaded-p
           (let ((source (make-default-bibliography-source)))
             (unless (zotero-backend-unavailable-p source)
               (ensure-bibliography-subcollections-hyperbook
                :source source
                :register? t))
             source)
           (let ((unavailable
                  (make-zotero-backend-unavailable
                   "runtime Zotero support"
                   :detail detail)))
             (format t "~&[HYPERDOC/ZOTERO] ~A~%"
                     (zotero-backend-unavailable-message-of unavailable))
             unavailable))))))

(defun maybe-register-zotero-startup-hook ()
  (when-let (package (find-package :hyperbook/server))
    (when-let (symbol (find-symbol "REGISTER-SERVER-STARTUP-HOOK" package))
      (when (fboundp symbol)
        (funcall symbol 'maybe-enable-zotero-runtime-support)))))

(eval-when (:load-toplevel :execute)
  (maybe-register-zotero-startup-hook))
