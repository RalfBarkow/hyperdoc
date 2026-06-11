;;;; FedWiki page-attached ASDF capability relations.

(in-package :hyperdoc)

(defclass fedwiki-attached-asdf-capability-relation ()
  ((from-home
    :initarg :from-home
    :reader fedwiki-asdf-relation-from-home-of)
   (to-home
    :initarg :to-home
    :reader fedwiki-asdf-relation-to-home-of)
   (capability
    :initarg :capability
    :reader fedwiki-asdf-relation-capability-of)
   (entry-package-name
    :initarg :entry-package-name
    :reader fedwiki-asdf-relation-entry-package-name-of)
   (entry-symbol-name
    :initarg :entry-symbol-name
    :reader fedwiki-asdf-relation-entry-symbol-name-of)
   (reason
    :initarg :reason
    :initform nil
    :reader fedwiki-asdf-relation-reason-of)
   (load-policy
    :initarg :load-policy
    :initform :explicit
    :reader fedwiki-asdf-relation-load-policy-of)))

(defmethod print-object ((relation fedwiki-attached-asdf-capability-relation) stream)
  (print-unreadable-object (relation stream :type t :identity nil)
    (format stream "~A -> ~A ~A"
            (fedwiki-attached-asdf-system-slug
             (fedwiki-asdf-relation-from-home-of relation))
            (fedwiki-attached-asdf-system-slug
             (fedwiki-asdf-relation-to-home-of relation))
            (fedwiki-asdf-relation-capability-of relation))))

(defun make-fedwiki-attached-asdf-capability-relation
    (&key from-home to-home capability entry-package-name entry-symbol-name
       reason (load-policy :explicit))
  (make-instance
   'fedwiki-attached-asdf-capability-relation
   :from-home from-home
   :to-home to-home
   :capability capability
   :entry-package-name entry-package-name
   :entry-symbol-name entry-symbol-name
   :reason reason
   :load-policy load-policy))

(defun fedwiki-asdf-relation-entry-symbol (relation)
  (let ((package
          (find-package
           (fedwiki-asdf-relation-entry-package-name-of relation))))
    (when package
      (find-symbol
       (fedwiki-asdf-relation-entry-symbol-name-of relation)
       package))))

(defun fedwiki-asdf-relation-entry-function (relation)
  (let ((symbol (fedwiki-asdf-relation-entry-symbol relation)))
    (when (and symbol (fboundp symbol))
      (symbol-function symbol))))

(defun fedwiki-asdf-relation-provider-ready-p (relation)
  (not (null (fedwiki-asdf-relation-entry-function relation))))

(defun fedwiki-asdf-relation-state (relation)
  (let* ((from-home (fedwiki-asdf-relation-from-home-of relation))
         (to-home (fedwiki-asdf-relation-to-home-of relation))
         (entry-package-name
           (fedwiki-asdf-relation-entry-package-name-of relation))
         (entry-package (find-package entry-package-name))
         (entry-symbol-name
           (fedwiki-asdf-relation-entry-symbol-name-of relation))
         (entry-symbol
           (and entry-package
                (find-symbol entry-symbol-name entry-package))))
    (list
     :from-slug (fedwiki-attached-asdf-system-slug from-home)
     :to-slug (fedwiki-attached-asdf-system-slug to-home)
     :capability (fedwiki-asdf-relation-capability-of relation)
     :reason (fedwiki-asdf-relation-reason-of relation)
     :load-policy (fedwiki-asdf-relation-load-policy-of relation)
     :from-asset-root (fedwiki-page-asset-root from-home)
     :to-asset-root (fedwiki-page-asset-root to-home)
     :to-asdf-entrypoint (fedwiki-page-asdf-entrypoint to-home)
     :to-asdf-entrypoint-exists-p
     (uiop:file-exists-p (fedwiki-page-asdf-entrypoint to-home))
     :entry-package-name entry-package-name
     :entry-package-present-p (not (null entry-package))
     :entry-symbol-name entry-symbol-name
     :entry-symbol-present-p (not (null entry-symbol))
     :entry-symbol-fbound-p (and entry-symbol (fboundp entry-symbol))
     :provider-ready-p (fedwiki-asdf-relation-provider-ready-p relation))))

(defun fedwiki-asdf-relation-summary-lines (relation)
  (let ((state (fedwiki-asdf-relation-state relation)))
    (list
     (format nil "Relation: ~A -> ~A"
             (getf state :from-slug)
             (getf state :to-slug))
     (format nil "Capability: ~A" (getf state :capability))
     (format nil "Target ASDF entrypoint: ~A"
             (getf state :to-asdf-entrypoint))
     (format nil "Target entrypoint exists: ~A"
             (getf state :to-asdf-entrypoint-exists-p))
     (format nil "Provider package: ~A present: ~A"
             (getf state :entry-package-name)
             (getf state :entry-package-present-p))
     (format nil "Provider symbol: ~A present: ~A fbound: ~A"
             (getf state :entry-symbol-name)
             (getf state :entry-symbol-present-p)
             (getf state :entry-symbol-fbound-p))
     (format nil "Provider ready: ~A"
             (getf state :provider-ready-p)))))

(defun fedwiki-asdf-relation-load-provider (relation &key force)
  (let ((result
          (load-fedwiki-attached-asdf-system
           (fedwiki-asdf-relation-to-home-of relation)
           :force force)))
    (when (typep result 'fedwiki-asdf-system-lookup-failure)
      (error result))
    result))

(defun fedwiki-asdf-plist-key-present-p (plist key)
  (loop for (k v) on plist by #'cddr
        thereis (eq k key)))

(defun fedwiki-asdf-remove-plist-key (plist key)
  (loop for (k v) on plist by #'cddr
        unless (eq k key)
          append (list k v)))

(defun invoke-fedwiki-attached-asdf-capability (relation &rest args)
  "Invoke RELATION's provider capability.

By default, load the target page-attached ASDF provider first.

Pass :LOAD-PROVIDER NIL when the provider package and function are already
present in the running image. This is intentionally different from omitting
:LOAD-PROVIDER; NIL is an explicit operator decision."
  (let* ((load-provider
           (if (fedwiki-asdf-plist-key-present-p args :load-provider)
               (getf args :load-provider)
               t))
         (call-args
           (fedwiki-asdf-remove-plist-key args :load-provider)))
    (when load-provider
      (fedwiki-asdf-relation-load-provider relation))
    (let ((function (fedwiki-asdf-relation-entry-function relation)))
      (unless function
        (error "Provider function ~A::~A is not available for relation ~S."
               (fedwiki-asdf-relation-entry-package-name-of relation)
               (fedwiki-asdf-relation-entry-symbol-name-of relation)
               relation))
      (apply function call-args))))
