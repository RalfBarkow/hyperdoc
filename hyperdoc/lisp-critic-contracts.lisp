;;;; Source-station-backed LISP-CRITIC execution contract.
;;
;; This slice defines the invocation boundary only.  It does not vendor,
;; copy, parse, normalize, or suppress LISP-CRITIC findings.

(in-package :hyperdoc)

(defclass lisp-critic-source-station ()
  ((id :initarg :id :reader lisp-critic-source-station-id-of)
   (title :initarg :title :reader lisp-critic-source-station-title-of)
   (site :initarg :site :reader lisp-critic-source-station-site-of)
   (page :initarg :page :reader lisp-critic-source-station-page-of)
   (asset-root :initarg :asset-root
               :reader lisp-critic-source-station-asset-root-of)
   (wrapper-system :initarg :wrapper-system
                   :reader lisp-critic-source-station-wrapper-system-of)
   (wrapper-package :initarg :wrapper-package
                    :reader lisp-critic-source-station-wrapper-package-of)
   (wrapper-loader-symbol
    :initarg :wrapper-loader-symbol
    :reader lisp-critic-source-station-wrapper-loader-symbol-of)
   (wrapper-entrypoint-symbol
    :initarg :wrapper-entrypoint-symbol
    :reader lisp-critic-source-station-wrapper-entrypoint-symbol-of)
   (upstream-system :initarg :upstream-system
                    :reader lisp-critic-source-station-upstream-system-of)
   (upstream-package :initarg :upstream-package
                     :reader lisp-critic-source-station-upstream-package-of)
   (upstream-file-entrypoint-symbol
    :initarg :upstream-file-entrypoint-symbol
    :reader lisp-critic-source-station-upstream-file-entrypoint-symbol-of)
   (provenance :initarg :provenance
               :reader lisp-critic-source-station-provenance-of)))

(defclass lisp-critic-contract ()
  ((id :initarg :id :reader lisp-critic-contract-id-of)
   (title :initarg :title :reader lisp-critic-contract-title-of)
   (source-station :initarg :source-station
                   :reader lisp-critic-contract-source-station-of)
   (input-policy :initarg :input-policy
                 :reader lisp-critic-contract-input-policy-of)
   (invocation-policy :initarg :invocation-policy
                      :reader lisp-critic-contract-invocation-policy-of)
   (output-policy :initarg :output-policy
                  :reader lisp-critic-contract-output-policy-of)
   (availability-policy :initarg :availability-policy
                        :reader lisp-critic-contract-availability-policy-of)
   (failure-policy :initarg :failure-policy
                   :reader lisp-critic-contract-failure-policy-of)
   (review-contract-role :initarg :review-contract-role
                         :reader lisp-critic-contract-review-contract-role-of)))

(defclass lisp-critic-run-record ()
  ((id :initarg :id :reader lisp-critic-run-record-id-of)
   (contract :initarg :contract :reader lisp-critic-run-record-contract-of)
   (target-paths :initarg :target-paths
                 :reader lisp-critic-run-record-target-paths)
   (status :initarg :status :reader lisp-critic-run-record-status)
   (started-at :initarg :started-at
               :reader lisp-critic-run-record-started-at-of)
   (finished-at :initarg :finished-at
                :reader lisp-critic-run-record-finished-at-of)
   (raw-output :initarg :raw-output
               :reader lisp-critic-run-record-raw-output)
   (error-output :initarg :error-output
                 :reader lisp-critic-run-record-error-output-of)
   (condition-summary :initarg :condition-summary
                      :reader lisp-critic-run-record-condition-summary-of)
   (invocation-form :initarg :invocation-form
                    :reader lisp-critic-run-record-invocation-form-of)
   (notes :initarg :notes :reader lisp-critic-run-record-notes-of)))

(defmethod print-object ((object lisp-critic-source-station) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (lisp-critic-source-station-id-of object))))

(defmethod print-object ((object lisp-critic-contract) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (lisp-critic-contract-id-of object))))

(defmethod print-object ((object lisp-critic-run-record) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A: ~A"
            (lisp-critic-run-record-id-of object)
            (lisp-critic-run-record-status object))))

(defmethod id-of ((source-station lisp-critic-source-station))
  (lisp-critic-source-station-id-of source-station))

(defmethod title-of ((source-station lisp-critic-source-station))
  (lisp-critic-source-station-title-of source-station))

(defmethod summary-of ((source-station lisp-critic-source-station))
  (format nil "FedWiki source station ~A/~A at ~A."
          (lisp-critic-source-station-site-of source-station)
          (lisp-critic-source-station-page-of source-station)
          (lisp-critic-source-station-asset-root-of source-station)))

(defmethod id-of ((contract lisp-critic-contract))
  (lisp-critic-contract-id-of contract))

(defmethod title-of ((contract lisp-critic-contract))
  (lisp-critic-contract-title-of contract))

(defmethod summary-of ((contract lisp-critic-contract))
  (format nil "LISP-CRITIC contract using ~A; output policy ~A."
          (title-of (lisp-critic-contract-source-station-of contract))
          (lisp-critic-contract-output-policy-of contract)))

(defmethod id-of ((record lisp-critic-run-record))
  (lisp-critic-run-record-id-of record))

(defmethod title-of ((record lisp-critic-run-record))
  (format nil "LISP-CRITIC run ~A"
          (lisp-critic-run-record-id-of record)))

(defmethod summary-of ((record lisp-critic-run-record))
  (format nil "LISP-CRITIC run over ~D target~:P finished with status ~A."
          (length (lisp-critic-run-record-target-paths record))
          (lisp-critic-run-record-status record)))

(defparameter *default-lisp-critic-source-station*
  (make-instance
   'lisp-critic-source-station
   :id "fedwiki-lisp-critic-source-station"
   :title "FedWiki LISP-CRITIC source station"
   :site "wiki.ralfbarkow.ch"
   :page "a-critic-for-lisp"
   :asset-root *lisp-critic-fedwiki-asset-root*
   :wrapper-system :a-critic-for-lisp
   :wrapper-package "A-CRITIC-FOR-LISP"
   :wrapper-loader-symbol :load-lisp-critic
   :wrapper-entrypoint-symbol :critique-if-available
   :upstream-system :lisp-critic
   :upstream-package "LISP-CRITIC"
   :upstream-file-entrypoint-symbol :critique-file
   :provenance
   '((:fedwiki-asset
      :site "wiki.ralfbarkow.ch"
     :page "a-critic-for-lisp"
     :asset-root "~/.wiki/wiki.ralfbarkow.ch/assets/pages/a-critic-for-lisp/")
     (:manual-review
      :observed-wrapper-api
      ("a-critic-for-lisp:load-lisp-critic"
       "a-critic-for-lisp:critique-if-available")
      :observed-upstream-api
      ("lisp-critic:critique"
       "lisp-critic:critique-file"
       "lisp-critic:critique-definition")))))

(defparameter *default-lisp-critic-contract*
  (make-instance
   'lisp-critic-contract
   :id "lisp-critic-source-station-contract"
   :title "LISP-CRITIC source-station critic contract"
   :source-station *default-lisp-critic-source-station*
   :input-policy
   '(:lisp-source-files
     :paths-are-repo-relative-or-absolute
     :no-html-or-mixed-content-by-default)
   :invocation-policy
   '(:prefer-wrapper-system
     :load-wrapper-with-asdf
     :call-wrapper-loader
     :invoke-upstream-file-entrypoint
     :capture-text-output)
   :output-policy
   '(:raw-output-only
     :no-finding-normalization-in-this-slice
     :no-suppression-or-waiver-policy-in-this-slice)
   :availability-policy
   '(:asset-root-is-optional
     :missing-asset-produces-run-record
     :ci-must-not-require-local-fedwiki-checkout)
   :failure-policy
   '(:capture-load-conditions
     :capture-invocation-conditions
     :return-run-record-by-default)
   :review-contract-role
   '(:critic-engine
     :source-station-backed
     :raw-evidence-producer)))

(defun default-lisp-critic-source-station ()
  *default-lisp-critic-source-station*)

(defun default-lisp-critic-contract ()
  *default-lisp-critic-contract*)

(defun %lisp-critic-symbol-name (symbol-designator)
  (etypecase symbol-designator
    (symbol (symbol-name symbol-designator))
    (string symbol-designator)))

(defun %lisp-critic-home-relative-pathname (path)
  (let ((prefix "~/"))
    (if (and (>= (length path) (length prefix))
             (string= prefix path :end2 (length prefix)))
        (merge-pathnames (subseq path (length prefix))
                         (user-homedir-pathname))
        (parse-namestring path))))

(defun %lisp-critic-source-station-asset-pathname (source-station)
  (%lisp-critic-home-relative-pathname
   (lisp-critic-source-station-asset-root-of source-station)))

(defun lisp-critic-source-station-present-p
    (&optional (source-station (default-lisp-critic-source-station)))
  (not (null (probe-file
              (%lisp-critic-source-station-asset-pathname source-station)))))

(defun %lisp-critic-condition-summary (condition)
  (with-output-to-string (stream)
    (format stream "~A: ~A" (type-of condition) condition)))

(defun %lisp-critic-run-id ()
  (format nil "lisp-critic-run-~D" (get-universal-time)))

(defun %make-lisp-critic-run-record
    (&key contract target-paths status started-at finished-at raw-output
          error-output condition-summary invocation-form notes)
  (make-instance
   'lisp-critic-run-record
   :id (%lisp-critic-run-id)
   :contract contract
   :target-paths target-paths
   :status status
   :started-at started-at
   :finished-at finished-at
   :raw-output (or raw-output "")
   :error-output (or error-output "")
   :condition-summary condition-summary
   :invocation-form invocation-form
   :notes notes))

(defun %lisp-critic-normalize-target-pathname (path)
  (etypecase path
    (pathname
     (if (uiop:absolute-pathname-p path)
         path
         (asdf:system-relative-pathname :hyperdoc path)))
    (string
     (let ((pathname (parse-namestring path)))
       (if (uiop:absolute-pathname-p pathname)
           pathname
           (asdf:system-relative-pathname :hyperdoc path))))))

(defun %lisp-critic-target-path-namestrings (target-paths)
  (mapcar (lambda (path)
            (namestring (%lisp-critic-normalize-target-pathname path)))
          target-paths))

(defun %lisp-critic-find-function (package-name symbol-designator)
  (let* ((package (find-package package-name))
         (symbol (and package
                      (find-symbol (%lisp-critic-symbol-name
                                    symbol-designator)
                                   package))))
    (and symbol (fboundp symbol) (symbol-function symbol))))

(defun %load-lisp-critic-source-station (source-station)
  (let ((asset-root (%lisp-critic-source-station-asset-pathname
                     source-station)))
    (let ((asdf:*central-registry*
            (cons asset-root asdf:*central-registry*)))
      (asdf:load-system
       (lisp-critic-source-station-wrapper-system-of source-station))
      (let ((loader (%lisp-critic-find-function
                     (lisp-critic-source-station-wrapper-package-of
                      source-station)
                     (lisp-critic-source-station-wrapper-loader-symbol-of
                      source-station))))
        (unless loader
          (error "Wrapper loader ~A::~A is unavailable."
                 (lisp-critic-source-station-wrapper-package-of
                  source-station)
                 (lisp-critic-source-station-wrapper-loader-symbol-of
                  source-station)))
        (funcall loader)))))

(defun %lisp-critic-file-entrypoint (source-station)
  (%lisp-critic-find-function
   (lisp-critic-source-station-upstream-package-of source-station)
   (lisp-critic-source-station-upstream-file-entrypoint-symbol-of
    source-station)))

(defun lisp-critic-contract-available-p
    (&optional (contract (default-lisp-critic-contract)))
  (let ((source-station (lisp-critic-contract-source-station-of contract)))
    (and (lisp-critic-source-station-present-p source-station)
         (handler-case
             (progn
               (%load-lisp-critic-source-station source-station)
               (not (null (%lisp-critic-file-entrypoint source-station))))
           (error () nil)))))

(defun %lisp-critic-asset-missing-record (contract target-paths started-at)
  (let ((source-station (lisp-critic-contract-source-station-of contract)))
    (%make-lisp-critic-run-record
     :contract contract
     :target-paths (%lisp-critic-target-path-namestrings target-paths)
     :status :asset-missing
     :started-at started-at
     :finished-at (get-universal-time)
     :condition-summary
     (format nil "LISP-CRITIC source station asset root is absent: ~A"
             (lisp-critic-source-station-asset-root-of source-station))
     :invocation-form
     `(:not-run
       :reason :asset-missing
       :asset-root ,(lisp-critic-source-station-asset-root-of source-station))
     :notes '(:graceful-absence :no-ci-dependency))))

(defun %lisp-critic-condition-record
    (contract target-paths status condition started-at invocation-form
     &optional error-output)
  (%make-lisp-critic-run-record
   :contract contract
   :target-paths (%lisp-critic-target-path-namestrings target-paths)
   :status status
   :started-at started-at
   :finished-at (get-universal-time)
   :error-output (or error-output (%lisp-critic-condition-summary condition))
   :condition-summary (%lisp-critic-condition-summary condition)
   :invocation-form invocation-form
   :notes '(:condition-captured :raw-run-record-only)))

(defun run-lisp-critic-contract
    (&optional
       (contract (default-lisp-critic-contract))
       (target-paths nil)
     &rest options)
  "Run LISP-CRITIC for TARGET-PATHS under CONTRACT and return a run record.

The returned record preserves raw textual output and boundary evidence.  It
does not normalize findings.  By default, missing source stations and runtime
conditions are captured as run records instead of being signaled."
  (let* ((signal-error? (getf options :signal-error?))
         (started-at (get-universal-time))
         (source-station (lisp-critic-contract-source-station-of contract))
         (normalized-paths (%lisp-critic-target-path-namestrings target-paths)))
    (unless (lisp-critic-source-station-present-p source-station)
      (return-from run-lisp-critic-contract
        (%lisp-critic-asset-missing-record
         contract target-paths started-at)))
    (handler-case
        (progn
          (%load-lisp-critic-source-station source-station)
          (let ((entrypoint (%lisp-critic-file-entrypoint source-station)))
            (unless entrypoint
              (return-from run-lisp-critic-contract
                (%make-lisp-critic-run-record
                 :contract contract
                 :target-paths normalized-paths
                 :status :critic-unavailable
                 :started-at started-at
                 :finished-at (get-universal-time)
                 :condition-summary
                 (format nil
                         "Upstream file critique entrypoint ~A::~A is unavailable."
                         (lisp-critic-source-station-upstream-package-of
                          source-station)
                         (lisp-critic-source-station-upstream-file-entrypoint-symbol-of
                          source-station))
                 :invocation-form
                 `(:find-function
                   ,(lisp-critic-source-station-upstream-package-of
                     source-station)
                   ,(lisp-critic-source-station-upstream-file-entrypoint-symbol-of
                     source-station))
                 :notes '(:critic-unavailable
                          :raw-run-record-only))))
            (let ((invocation-form
                    `(:function "lisp-critic:critique-file"
                      :target-paths ,normalized-paths
                      :output :captured-string)))
              (handler-case
                  (let ((error-stream (make-string-output-stream)))
                    (let ((raw-output
                            (with-output-to-string (stream)
                              (let ((*error-output* error-stream))
                                (dolist (path normalized-paths)
                                  (funcall entrypoint path stream))))))
                      (%make-lisp-critic-run-record
                       :contract contract
                       :target-paths normalized-paths
                       :status :completed
                       :started-at started-at
                       :finished-at (get-universal-time)
                       :raw-output raw-output
                       :error-output
                       (get-output-stream-string error-stream)
                       :invocation-form invocation-form
                       :notes '(:raw-output-only
                                :finding-normalization-deferred))))
                (error (condition)
                  (when signal-error?
                    (error condition))
                  (%lisp-critic-condition-record
                   contract target-paths :failed condition started-at
                   invocation-form))))))
      (error (condition)
        (when signal-error?
          (error condition))
        (%lisp-critic-condition-record
         contract target-paths :load-failed condition started-at
         `(:load-wrapper-system
           ,(lisp-critic-source-station-wrapper-system-of source-station)))))))
