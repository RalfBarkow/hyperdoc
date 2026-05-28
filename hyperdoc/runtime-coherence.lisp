;;;; Runtime coherence chunks for dependency repair.

(in-package :hyperdoc)

(defparameter *coherence-chunk-statuses*
  '(:unknown
    :good
    :missing
    :stale
    :blocked
    :failed
    :optional-unavailable))

(defparameter *coherence-chunk-kinds*
  '(:asdf-code-root
    :static-asset-root
    :asdf-system
    :optional-inspector-view
    :browser-inspection-session
    :plan-result
    :projection))

(defclass coherence-chunk ()
  ((id
    :reader coherence-chunk-id-of
    :initarg :id)
   (title
    :reader coherence-chunk-title-of
    :initarg :title)
   (kind
    :reader coherence-chunk-kind-of
    :initarg :kind)
   (basis
    :accessor coherence-chunk-basis-of
    :initarg :basis
    :initform nil)
   (status
    :accessor coherence-chunk-status-of
    :initarg :status
    :initform :unknown)
   (value
    :accessor coherence-chunk-value-of
    :initarg :value
    :initform nil)
   (evidence
    :accessor coherence-chunk-evidence-of
    :initarg :evidence
    :initform nil)
   (last-error
    :accessor coherence-chunk-last-error-of
    :initarg :last-error
    :initform nil)
   (repair-options
    :accessor coherence-chunk-repair-options-of
    :initarg :repair-options
    :initform nil)
   (depends-on
    :accessor coherence-chunk-depends-on-of
    :initarg :depends-on
    :initform nil)))

(defclass runtime-coherence-report ()
  ((title
    :reader runtime-coherence-report-title-of
    :initarg :title)
   (observed-at
    :reader runtime-coherence-report-observed-at-of
    :initarg :observed-at)
   (chunks
    :reader runtime-coherence-report-chunks-of
    :initarg :chunks)
   (summary
    :reader runtime-coherence-report-summary-of
    :initarg :summary)
   (recommended-next-actions
    :reader runtime-coherence-report-recommended-next-actions-of
    :initarg :recommended-next-actions)))

(defun make-coherence-chunk (&key id
                                  title
                                  kind
                                  basis
                                  (status :unknown)
                                  value
                                  evidence
                                  last-error
                                  repair-options
                                  depends-on)
  (assert (member status *coherence-chunk-statuses*) (status)
          "Unknown coherence chunk status ~S." status)
  (assert (member kind *coherence-chunk-kinds*) (kind)
          "Unknown coherence chunk kind ~S." kind)
  (make-instance 'coherence-chunk
                 :id id
                 :title title
                 :kind kind
                 :basis basis
                 :status status
                 :value value
                 :evidence evidence
                 :last-error last-error
                 :repair-options repair-options
                 :depends-on depends-on))

(defun coherence-chunk-status-blocking-p (status)
  (member status '(:missing :stale :blocked :failed) :test #'eq))

(defun coherence-status-counts (chunks)
  (let ((counts (make-hash-table :test #'eq)))
    (dolist (chunk chunks)
      (incf (gethash (coherence-chunk-status-of chunk) counts 0)))
    (loop for status in *coherence-chunk-statuses*
          for count = (gethash status counts)
          when count
            collect (cons status count))))

(defun runtime-coherence-blocking-chunks (chunks)
  (remove-if-not
   (lambda (chunk)
     (coherence-chunk-status-blocking-p
      (coherence-chunk-status-of chunk)))
   chunks))

(defun runtime-coherence-default-summary (chunks)
  (let ((blocking (runtime-coherence-blocking-chunks chunks)))
    (list :total (length chunks)
          :by-status (coherence-status-counts chunks)
          :blocking-chunks (mapcar #'coherence-chunk-id-of blocking)
          :good-chunks (mapcar #'coherence-chunk-id-of
                               (remove :good chunks
                                       :key #'coherence-chunk-status-of
                                       :test-not #'eq)))))

(defun runtime-coherence-default-actions (chunks)
  (let ((blocking (runtime-coherence-blocking-chunks chunks))
        (optional-unavailable
          (remove :optional-unavailable chunks
                  :key #'coherence-chunk-status-of
                  :test-not #'eq)))
    (append
     (when blocking
       (list "Inspect blocked or failed chunks before re-deriving browser inspection state."))
     (when optional-unavailable
       (list "Treat optional inspector capabilities as degraded, not as plan-object failure."))
     (unless (or blocking optional-unavailable)
       (list "No repair action is indicated by this non-mutating coherence report.")))))

(defun condition-evidence (condition)
  (list :condition-type (type-of condition)
        :message (princ-to-string condition)))

(defun safe-find-asdf-system (system-name)
  (handler-case
      (let ((system (asdf:find-system system-name nil)))
        (values system nil))
    (condition (condition)
      (values nil condition))))

(defun safe-asdf-system-source-directory (system)
  (handler-case
      (values (and system
                   (asdf:system-source-directory system))
              nil)
    (condition (condition)
      (values nil condition))))

(defun maybe-directory-pathname (path)
  (when path
    (handler-case
        (uiop:ensure-directory-pathname (pathname path))
      (condition ()
        nil))))

(defun directory-exists-p (path)
  (and path
       (handler-case
           (probe-file (maybe-directory-pathname path))
         (condition ()
           nil))))

(defun path-contains-asd-p (path)
  (let ((directory (maybe-directory-pathname path)))
    (and directory
         (directory-exists-p directory)
         (handler-case
             (not (null (directory (merge-pathnames #P"*.asd" directory))))
           (condition ()
             nil)))))

(defun clog-required-static-asset-relative-pathnames ()
  '(#P"boot.html"
    #P"js/boot.js"
    #P"js/jquery.min.js"))

(defun clog-required-static-asset-pathnames (root)
  (mapcar (lambda (relative-path)
            (merge-pathnames relative-path
                             (uiop:ensure-directory-pathname root)))
          (clog-required-static-asset-relative-pathnames)))

(defun path-contains-required-clog-static-assets-p (path)
  (let ((directory (maybe-directory-pathname path)))
    (and directory
         (directory-exists-p directory)
         (every #'probe-file
                (clog-required-static-asset-pathnames directory)))))

(defun asdf-root-candidate-p (path)
  (path-contains-asd-p path))

(defun static-asset-root-candidate-p (path)
  (path-contains-required-clog-static-assets-p path))

(defun classify-clog-src (&optional (clog-src (uiop:getenv "CLOG_SRC")))
  (let* ((root (maybe-directory-pathname clog-src))
         (static-files (and root
                            (merge-pathnames #P"static-files/" root)))
         (source-directory (and root
                                (merge-pathnames #P"source/" root)))
         (classification
           (cond
             ((or (null clog-src)
                  (null root)
                  (not (directory-exists-p root)))
              :missing)
             ((asdf-root-candidate-p root)
              :asdf-root)
             ((static-asset-root-candidate-p root)
              :static-root)
             ((and (directory-exists-p source-directory)
                   (directory-exists-p static-files))
              :source-overlay)
             ((directory-exists-p static-files)
              :static-overlay)
             ((directory-exists-p source-directory)
              :source-overlay)
             (t
              :unknown))))
    (values classification
            (list :clog-src clog-src
                  :root root
                  :contains-asd (and root
                                     (path-contains-asd-p root))
                  :contains-required-static-assets
                  (and root
                       (path-contains-required-clog-static-assets-p root))
                  :static-files static-files
                  :static-files-contains-required-assets
                  (and static-files
                       (path-contains-required-clog-static-assets-p
                        static-files))
                  :source-directory source-directory
                  :source-directory-exists
                  (and source-directory
                       (directory-exists-p source-directory))))))

(defun loaded-function-symbol (package-designator symbol-name)
  (let ((package (find-package package-designator)))
    (when package
      (multiple-value-bind (symbol status)
          (find-symbol symbol-name package)
        (when (and status
                   (fboundp symbol))
          symbol)))))

(defun maybe-call-loaded-function (package-designator symbol-name &rest args)
  (let ((symbol (loaded-function-symbol package-designator symbol-name)))
    (when symbol
      (apply symbol args))))

(defun clog-src-static-files-root ()
  (when-let (clog-src (uiop:getenv "CLOG_SRC"))
    (let* ((root (maybe-directory-pathname clog-src))
           (candidate (and root
                           (merge-pathnames #P"static-files/" root))))
      (when (directory-exists-p candidate)
        candidate))))

(defun fallback-clog-static-files-root ()
  (multiple-value-bind (system condition)
      (safe-find-asdf-system :clog)
    (if system
        (handler-case
            (values
             (uiop:ensure-directory-pathname
              (asdf:system-relative-pathname :clog "static-files/"))
             condition)
          (condition (root-condition)
            (values nil root-condition)))
        (values nil condition))))

(defun resolved-clog-static-root-pathname ()
  (or (clog-src-static-files-root)
      (maybe-call-loaded-function :hyperbook/server
                                  "STATIC-ROOT-PATHNAME")
      (maybe-call-loaded-function :hyperdoc
                                  "CLOG-STATIC-ASSET-MOUNTED-ROOT-PATHNAME")
      (fallback-clog-static-files-root)))

(defun validate-clog-static-root-evidence (root)
  (let* ((directory (maybe-directory-pathname root))
         (asset-paths (and directory
                           (or (maybe-call-loaded-function
                                :hyperbook/server
                                "REQUIRED-STATIC-ASSET-PATHNAMES"
                                directory)
                               (clog-required-static-asset-pathnames
                                directory))))
         (asset-evidence
           (mapcar (lambda (path)
                     (list :path path
                           :present (and path
                                         (probe-file path))))
                   asset-paths))
         (missing-assets
           (remove-if (lambda (entry)
                        (getf entry :present))
                      asset-evidence)))
    (values (and directory
                 (null missing-assets))
            (list :root directory
                  :assets asset-evidence
                  :missing-assets missing-assets)
            missing-assets)))

(defun validate-clog-static-root-with-loaded-helper (root)
  (let ((validator (loaded-function-symbol :hyperbook/server
                                           "VALIDATE-STATIC-ROOT-PATHNAME")))
    (when validator
      (handler-case
          (values (funcall validator root) nil)
        (condition (condition)
          (values nil condition))))))

(defun clog-asdf-code-root-chunk ()
  (multiple-value-bind (system find-condition)
      (safe-find-asdf-system :clog)
    (multiple-value-bind (source-directory source-condition)
        (safe-asdf-system-source-directory system)
      (let ((condition (or find-condition source-condition)))
        (make-coherence-chunk
         :id "clog-asdf-code-root"
         :title "CLOG ASDF code root"
         :kind :asdf-code-root
         :status (cond
                   (condition :failed)
                   (source-directory :good)
                   (system :unknown)
                   (t :missing))
         :value source-directory
         :evidence (list (list :probe 'asdf:find-system
                               :system-name :clog
                               :system system
                               :found (not (null system)))
                         (list :probe 'asdf:system-source-directory
                               :source-directory source-directory)
                         (multiple-value-bind (classification evidence)
                             (classify-clog-src)
                           (list :clog-src-classification classification
                                 :evidence evidence)))
         :last-error condition
         :repair-options
         (unless source-directory
           '(:repair-asdf-source-registry)))))))

(defun clog-static-asset-root-chunk (&key root)
  (handler-case
      (let* ((selected-root (or root
                                (resolved-clog-static-root-pathname)))
             (helper-root nil)
             (helper-condition nil))
        (when selected-root
          (multiple-value-setq (helper-root helper-condition)
            (validate-clog-static-root-with-loaded-helper selected-root)))
        (multiple-value-bind (validp evidence missing-assets)
            (validate-clog-static-root-evidence selected-root)
          (make-coherence-chunk
           :id "clog-static-asset-root"
           :title "CLOG static asset root"
           :kind :static-asset-root
           :status (cond
                     ((null selected-root) :missing)
                     ((or helper-condition missing-assets) :missing)
                     (validp :good)
                     (t :unknown))
           :value selected-root
           :evidence (list (multiple-value-bind (classification
                                                  classification-evidence)
                               (classify-clog-src)
                             (list :clog-src-classification classification
                                   :evidence classification-evidence))
                           (list :selected-root selected-root
                                 :explicit-root root
                                 :helper-validation-root helper-root)
                           evidence)
           :last-error helper-condition
           :repair-options
           (unless validp
             '(:repair-clog-static-root
               :set-clog-src-to-overlay-with-static-files)))))
    (condition (condition)
      (make-coherence-chunk
       :id "clog-static-asset-root"
       :title "CLOG static asset root"
       :kind :static-asset-root
       :status :failed
       :last-error condition
       :evidence (list (condition-evidence condition))
       :repair-options
       '(:repair-clog-static-root
         :set-clog-src-to-overlay-with-static-files)))))

(defun make-runtime-coherence-report (&key (title "Runtime coherence report")
                                           (observed-at (get-universal-time))
                                           (chunks nil)
                                           summary
                                           recommended-next-actions)
  (make-instance 'runtime-coherence-report
                 :title title
                 :observed-at observed-at
                 :chunks chunks
                 :summary (or summary
                              (runtime-coherence-default-summary chunks))
                 :recommended-next-actions
                 (or recommended-next-actions
                     (runtime-coherence-default-actions chunks))))

(defun make-inspector-runtime-coherence-report (&key
                                                  (title "Inspector runtime coherence report")
                                                  (observed-at (get-universal-time)))
  (make-runtime-coherence-report
   :title title
   :observed-at observed-at
   :chunks (list (clog-asdf-code-root-chunk)
                 (clog-static-asset-root-chunk))))

(defun make-current-plan-browser-coherence-report (&key root-object
                                                        summary
                                                        checklist
                                                        projections
                                                        (title "Plan browser coherence report")
                                                        (observed-at (get-universal-time)))
  (declare (ignore checklist))
  (let ((chunks
          (remove
           nil
           (list
            (when root-object
              (make-coherence-chunk
               :id "current-plan-result"
               :title "Current plan result"
               :kind :plan-result
               :status :good
               :value root-object
               :evidence (list (list :object-type (type-of root-object)))))
            (when projections
              (make-coherence-chunk
               :id "current-plan-projections"
               :title "Current plan projections"
               :kind :projection
               :status :good
               :value projections
               :evidence (list (list :projection-count
                                     (length projections)))))))))
    (make-runtime-coherence-report
     :title title
     :observed-at observed-at
     :chunks chunks
     :summary (or summary
                  (runtime-coherence-default-summary chunks)))))
