;;;; Runtime coherence chunks for dependency repair.

(in-package :hyperdoc)

(defparameter *coherence-chunk-statuses*
  '(:unknown
    :ok
    :good
    :missing
    :missing-package
    :missing-generic-function
    :missing-null-method
    :packages-present-asdf-missing
    :base-system-missing
    :standard-system-missing
    :missing-html-inspector-views-src
    :missing-html-inspector-views-asd-env
    :missing-html-inspector-views-asd
    :asdf-subsystem-not-visible
    :dev-shell-asdf-system-not-visible
    :nix-derivation-mismatch
    :stale-sly-environment
    :stale
    :foreign-contaminant
    :planned
    :refused
    :degraded
    :blocked
    :failed-safe-call
    :failed
    :optional-unavailable))

(defparameter *coherence-chunk-kinds*
  '(:asdf-code-root
    :static-asset-root
    :asdf-system
    :optional-inspector-view
    :source-registry
    :coherence-gate
    :persistence
    :repair-plan
    :repair-action
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

(defclass runtime-coherence-repair-plan ()
  ((profile
    :reader runtime-coherence-repair-plan-profile-of
    :initarg :profile)
   (created-at
    :reader runtime-coherence-repair-plan-created-at-of
    :initarg :created-at)
   (initial-report
    :reader runtime-coherence-repair-plan-initial-report-of
    :initarg :initial-report
    :initform nil)
   (actions
    :reader runtime-coherence-repair-plan-actions-of
    :initarg :actions
    :initform nil)
   (final-report
    :reader runtime-coherence-repair-plan-final-report-of
    :initarg :final-report
    :initform nil)
   (repaired-p
    :reader runtime-coherence-repair-plan-repaired-p
    :initarg :repaired-p
    :initform nil)
   (summary
    :reader runtime-coherence-repair-plan-summary-of
    :initarg :summary
    :initform nil)))

(defun make-runtime-coherence-repair-plan
    (&key profile
          (created-at (get-universal-time))
          initial-report
          actions
          final-report
          repaired-p
          summary)
  (make-instance 'runtime-coherence-repair-plan
                 :profile profile
                 :created-at created-at
                 :initial-report initial-report
                 :actions actions
                 :final-report final-report
                 :repaired-p repaired-p
                 :summary (or summary
                              (list :profile profile
                                    :action-count (length actions)
                                    :repaired-p repaired-p
                                    :final-summary
                                    (and final-report
                                         (runtime-coherence-report-summary-of
                                          final-report))))))

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
  (member status
          '(:missing
            :missing-package
            :missing-generic-function
            :missing-null-method
            :packages-present-asdf-missing
            :base-system-missing
            :standard-system-missing
            :missing-html-inspector-views-src
            :missing-html-inspector-views-asd-env
            :missing-html-inspector-views-asd
            :asdf-subsystem-not-visible
            :dev-shell-asdf-system-not-visible
            :nix-derivation-mismatch
            :stale-sly-environment
            :stale
            :foreign-contaminant
            :refused
            :blocked
            :failed-safe-call
            :failed)
          :test #'eq))

(defgeneric derive (chunk &key &allow-other-keys)
  (:documentation "Derive CHUNK from its basis and return a coherence chunk."))

(defgeneric chunks-update (chunks &key &allow-other-keys)
  (:documentation "Derive a list of CHUNKS and return the updated chunks."))

(defgeneric coherence-report (object &key &allow-other-keys)
  (:documentation "Return a runtime coherence report for OBJECT or profile."))

(defmethod derive ((chunk coherence-chunk) &key &allow-other-keys)
  chunk)

(defmethod derive-date ((chunk coherence-chunk))
  (or (getf (coherence-chunk-value-of chunk) :observed-at)
      (getf (coherence-chunk-basis-of chunk) :observed-at)
      (get-universal-time)))

(defmethod chunk-up-to-date-p ((chunk coherence-chunk))
  (not (coherence-chunk-status-blocking-p
        (coherence-chunk-status-of chunk))))

(defmethod derive-date ((plan runtime-coherence-repair-plan))
  (runtime-coherence-repair-plan-created-at-of plan))

(defmethod chunks-update ((chunks list) &key &allow-other-keys)
  (mapcar #'derive chunks))

(defun runtime-coherence-operation-name (operation)
  (etypecase operation
    (symbol (string-downcase (symbol-name operation)))
    (string (string-downcase operation))))

(defmethod derive ((basis cons) &key &allow-other-keys)
  (let ((operation (runtime-coherence-operation-name (first basis))))
    (cond
      ((string= operation "expected-dev-shell-source-registry")
       (expected-dev-shell-source-registry))
      ((string= operation "current-image-source-registry")
       (current-image-source-registry))
      ((string= operation "source-registry-equivalent-to-dev-shell")
       (source-registry-equivalent-to-dev-shell))
      ((string= operation "foreign-asdf-source-contaminants")
       (foreign-asdf-source-contaminants))
      ((string= operation "asdf-visible")
       (asdf-visible (second basis)))
      ((string= operation "system-ready")
       (system-ready (second basis)))
      (t
       (make-coherence-chunk
        :id "unknown-runtime-coherence-deriver"
        :title "Unknown runtime coherence deriver"
        :kind :repair-action
        :status :blocked
        :basis basis
        :evidence
        (list (list :operation operation
                    :message
                    "No runtime coherence deriver is registered for this basis.")))))))

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
                               (remove-if-not
                                (lambda (chunk)
                                  (member (coherence-chunk-status-of chunk)
                                          '(:good :ok)
                                          :test #'eq))
                                chunks)))))

(defun runtime-coherence-default-actions (chunks)
  (let ((blocking (runtime-coherence-blocking-chunks chunks))
        (optional-unavailable
          (remove :optional-unavailable chunks
                  :key #'coherence-chunk-status-of
                  :test-not #'eq))
        (degraded
          (remove :degraded chunks
                  :key #'coherence-chunk-status-of
                  :test-not #'eq)))
    (append
     (when blocking
       (list "Inspect blocked or failed chunks before re-deriving browser inspection state."))
     (when (or optional-unavailable degraded)
       (list "Treat optional inspector capabilities as degraded, not as plan-object failure."))
     (unless (or blocking optional-unavailable degraded)
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

(defun safe-asdf-system-source-file (system)
  (handler-case
      (multiple-value-bind (symbol status)
          (find-symbol "SYSTEM-SOURCE-FILE" :asdf)
        (values (and system
                     status
                     (fboundp symbol)
                     (funcall symbol system))
                nil))
    (condition (condition)
      (values nil condition))))

(defun maybe-directory-pathname (path)
  (when path
    (handler-case
        (uiop:ensure-directory-pathname (pathname path))
      (condition ()
        nil))))

(defun pathname-exists-p (path)
  (and path
       (handler-case
           (probe-file (pathname path))
         (condition ()
           nil))))

(defun child-pathname (root relative-path)
  (let ((directory (maybe-directory-pathname root)))
    (and directory
         (merge-pathnames relative-path directory))))

(defun safe-namestring (path)
  (and path
       (handler-case
           (namestring (pathname path))
         (condition ()
           nil))))

(defun runtime-coherence-now-string (&optional (universal-time
                                                 (get-universal-time)))
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time universal-time 0)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ"
            year month day hour minute second)))

(defun runtime-coherence-print-value (value)
  (with-output-to-string (stream)
    (let ((*print-pretty* nil)
          (*print-circle* t)
          (*print-length* 80)
          (*print-level* 12))
      (prin1 value stream))))

(defun runtime-coherence-keyword-label (value)
  (cond
    ((null value) nil)
    ((keywordp value) (string-downcase (symbol-name value)))
    ((symbolp value) (string-downcase (symbol-name value)))
    (t (format nil "~A" value))))

(defun hyperdoc-repo-root-pathname ()
  (handler-case
      (uiop:ensure-directory-pathname
       (asdf:system-source-directory :hyperdoc))
    (condition ()
      (uiop:ensure-directory-pathname
       (truename *default-pathname-defaults*)))))

(defun pathname-prefix-p (prefix path)
  (let ((prefix-name (safe-namestring
                      (maybe-directory-pathname prefix)))
        (path-name (safe-namestring path)))
    (and prefix-name
         path-name
         (<= (length prefix-name) (length path-name))
         (string= prefix-name
                  (subseq path-name 0 (length prefix-name))))))

(defun source-path-authority (path &key
                                     (repo-root
                                      (hyperdoc-repo-root-pathname)))
  (let ((namestring (safe-namestring path)))
    (cond
      ((null namestring)
       :missing)
      ((pathname-prefix-p repo-root path)
       :repo)
      ((search "/nix/store/" namestring :test #'char=)
       :nix-store)
      ((or (search "/common-lisp/" namestring :test #'char=)
           (search "/quicklisp/" namestring :test #'char=)
           (search "/Downloads/" namestring :test #'char=))
       :foreign-contaminant)
      (t
       :unknown-host))))

(defun source-path-authority-accepted-p
    (authority &key (expected-authorities '(:repo :nix-store)))
  (member authority expected-authorities :test #'eq))

(defun cl-source-registry-entries
    (&optional (registry (uiop:getenv "CL_SOURCE_REGISTRY")))
  (remove-if
   (lambda (entry)
     (zerop (length entry)))
   (if registry
       (uiop:split-string registry :separator ":")
       nil)))

(defun cl-source-registry-entry-tree-p (entry)
  (let ((length (length entry)))
    (and (>= length 2)
         (char= (char entry (- length 1)) #\/)
         (char= (char entry (- length 2)) #\/))))

(defun cl-source-registry-entry-path-string (entry)
  (if (cl-source-registry-entry-tree-p entry)
      (subseq entry 0 (1- (length entry)))
      entry))

(defun cl-source-registry-entry-pathname (entry)
  (handler-case
      (uiop:ensure-directory-pathname
       (cl-source-registry-entry-path-string entry))
    (condition ()
      nil)))

(defun source-registry-tree-entry (pathname)
  (let ((namestring (safe-namestring
                     (maybe-directory-pathname pathname))))
    (and namestring
         (format nil "~A/" namestring))))

(defun source-registry-entry-normal-key (entry)
  (let ((pathname (cl-source-registry-entry-pathname entry)))
    (or (safe-namestring (and pathname
                              (maybe-directory-pathname pathname)))
        entry)))

(defun source-registry-entry-equivalent-p (left right)
  (string= (source-registry-entry-normal-key left)
           (source-registry-entry-normal-key right)))

(defun source-registry-entry-member-p (entry entries)
  (member entry entries :test #'source-registry-entry-equivalent-p))

(defun source-registry-set-difference (left right)
  (remove-if (lambda (entry)
               (source-registry-entry-member-p entry right))
             left))

(defun join-source-registry-entries (entries)
  (with-output-to-string (stream)
    (loop for entry in entries
          for firstp = t then nil
          do (progn
               (unless firstp
                 (write-char #\: stream))
               (write-string entry stream)))))

(defun accepted-source-registry-entries
    (&key (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
          (repo-root (hyperdoc-repo-root-pathname))
          (expected-authorities '(:repo :nix-store)))
  (remove-if-not
   (lambda (entry)
     (let* ((pathname (cl-source-registry-entry-pathname entry))
            (authority
              (source-path-authority pathname :repo-root repo-root)))
       (source-path-authority-accepted-p
        authority
        :expected-authorities expected-authorities)))
   (cl-source-registry-entries registry)))

(defun dev-shell-source-registry-entries
    (&key (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
          (hyperdoc-root (hyperdoc-repo-root-pathname)))
  (let* ((root (uiop:ensure-directory-pathname hyperdoc-root))
         (flake-deps (merge-pathnames #P".flake-deps/" root))
         (clog-src (uiop:getenv "CLOG_SRC"))
         (explicit
           (remove nil
                   (list (and clog-src
                              (source-registry-tree-entry clog-src))
                         (and (directory-exists-p flake-deps)
                              (source-registry-tree-entry flake-deps))
                         (source-registry-tree-entry root))))
         (accepted-current
           (accepted-source-registry-entries
            :registry registry
            :repo-root root)))
    (remove-duplicates
     (append explicit accepted-current)
     :test #'source-registry-entry-equivalent-p)))

(defun cl-source-registry-entry-evidence
    (entry &key (repo-root (hyperdoc-repo-root-pathname)))
  (let* ((pathname
           (handler-case
               (or (cl-source-registry-entry-pathname entry)
                   (pathname entry))
             (condition ()
               nil)))
         (authority
           (source-path-authority pathname :repo-root repo-root)))
    (list :entry entry
          :pathname pathname
          :exists (and pathname
                       (or (directory-exists-p pathname)
                           (pathname-exists-p pathname)))
          :authority authority
          :accepted (source-path-authority-accepted-p authority))))

(defun asdf-system-definition-filename (system-name)
  (let* ((downcase-name
           (string-downcase (string system-name)))
         (base-name
           (let ((slash (position #\/ downcase-name)))
             (if slash
                 (subseq downcase-name 0 slash)
                 downcase-name))))
    (format nil "~A.asd" base-name)))

(defun source-registry-search-roots
    (&key (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
          entries
          (repo-root (hyperdoc-repo-root-pathname)))
  (remove-duplicates
   (loop for entry in (or entries
                          (accepted-source-registry-entries
                           :registry registry
                           :repo-root repo-root))
         for pathname = (cl-source-registry-entry-pathname entry)
         when pathname
           collect pathname)
   :test #'equal))

(defun bounded-find-file-under-root
    (root filename &key (max-depth 2))
  (labels ((walk (directory depth)
             (let ((candidate (merge-pathnames filename directory)))
               (cond
                 ((pathname-exists-p candidate)
                  (list candidate))
                 ((<= depth 0)
                  nil)
                 (t
                  (handler-case
                      (loop for subdirectory in (uiop:subdirectories directory)
                            append (walk subdirectory (1- depth)))
                    (condition ()
                      nil)))))))
    (and (directory-exists-p root)
         (walk (uiop:ensure-directory-pathname root)
               max-depth))))

(defun asdf-definition-discovery
    (system-name &key
                   (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
                   entries
                   (repo-root (hyperdoc-repo-root-pathname))
                   (max-depth 2))
  (let* ((effective-entries
           (or entries
               (accepted-source-registry-entries
                :registry registry
                :repo-root repo-root)))
         (filename (asdf-system-definition-filename system-name))
         (roots
           (source-registry-search-roots
            :registry registry
            :entries effective-entries
            :repo-root repo-root))
         (lookup-records
           (loop for root in roots
                 for direct-path = (merge-pathnames filename root)
                 for found = (bounded-find-file-under-root
                              root
                              filename
                              :max-depth max-depth)
                 collect (list :source-registry-entry-root root
                               :expected-asd-path direct-path
                               :expected-asd-path-exists
                               (pathname-exists-p direct-path)
                               :found-asd-files found)))
         (candidates
           (remove-duplicates
            (loop for record in lookup-records
                  append (getf record :found-asd-files))
            :test #'equal)))
    (list :system-name system-name
          :expected-asd-filename filename
          :source-registry registry
          :source-registry-entries
          (mapcar (lambda (entry)
                    (cl-source-registry-entry-evidence
                     entry
                     :repo-root repo-root))
                  effective-entries)
          :search-roots roots
          :lookup-records lookup-records
          :candidate-asd-files candidates)))

(defun dev-shell-asdf-definition-discovery
    (system-name &key
                   registry
                   (repo-root (hyperdoc-repo-root-pathname))
                   (max-depth 3))
  (let* ((entries
           (dev-shell-source-registry-entries
            :registry registry
            :hyperdoc-root repo-root))
         (effective-registry
           (join-source-registry-entries entries)))
    (asdf-definition-discovery
     system-name
     :registry effective-registry
     :entries entries
     :repo-root repo-root
     :max-depth max-depth)))

(defun asdf-definition-candidates
    (system-name &key
                   (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
                   entries
                   (repo-root (hyperdoc-repo-root-pathname))
                   (max-depth 2))
  (getf (asdf-definition-discovery
         system-name
         :registry registry
         :entries entries
         :repo-root repo-root
         :max-depth max-depth)
        :candidate-asd-files))

(defun asdf-system-source-authority-evidence
    (system-name &key (repo-root (hyperdoc-repo-root-pathname))
                     (expected-authorities '(:repo :nix-store)))
  (multiple-value-bind (system find-condition)
      (safe-find-asdf-system system-name)
    (multiple-value-bind (source-file source-file-condition)
        (safe-asdf-system-source-file system)
      (multiple-value-bind (source-directory source-directory-condition)
          (safe-asdf-system-source-directory system)
        (let* ((source-path (or source-file source-directory))
               (authority
                 (source-path-authority source-path :repo-root repo-root))
               (accepted
                 (source-path-authority-accepted-p
                  authority
                  :expected-authorities expected-authorities)))
          (values
           (list :system-name system-name
                 :system system
                 :found (not (null system))
                 :source-file source-file
                 :source-directory source-directory
                 :source-authority authority
                 :source-authority-accepted accepted
                 :conditions
                 (remove
                  nil
                  (list (and find-condition
                             (list :probe 'asdf:find-system
                                   :condition
                                   (condition-evidence find-condition)))
                        (and source-file-condition
                             (list :probe 'asdf:system-source-file
                                   :condition
                                   (condition-evidence source-file-condition)))
                        (and source-directory-condition
                             (list :probe 'asdf:system-source-directory
                                   :condition
                                   (condition-evidence
                                    source-directory-condition))))))
           (or find-condition
               source-file-condition
               source-directory-condition)))))))

(defun set-process-environment-variable (name value)
  (handler-case
      #+sbcl
      (progn
        (require :sb-posix)
        (let ((package (find-package "SB-POSIX")))
          (if value
              (funcall (find-symbol "SETENV" package)
                       name
                       value
                       1)
              (funcall (find-symbol "UNSETENV" package)
                       name)))
        (values t nil))
      #-sbcl
      (values nil :unsupported-implementation)
    (condition (condition)
      (values nil condition))))

(defun environment-mutation-evidence (name value)
  (multiple-value-bind (success condition)
      (set-process-environment-variable name value)
    (list :env-var name
          :target-value value
          :set success
          :condition (and condition
                          (if (typep condition 'condition)
                              (condition-evidence condition)
                              condition)))))

(defun nix-store-path-p (path)
  (let ((namestring (safe-namestring path)))
    (and namestring
         (search "/nix/store/" namestring :test #'char=))))

(defun nix-store-derivation-key (path)
  (let* ((namestring (safe-namestring path))
         (prefix "/nix/store/")
         (start (and namestring
                     (search prefix namestring :test #'char=))))
    (when start
      (let* ((key-start (+ start (length prefix)))
             (key-end (position #\/ namestring :start key-start)))
        (subseq namestring key-start key-end)))))

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

(defun loaded-class-symbol (package-designator symbol-name)
  (let ((package (find-package package-designator)))
    (when package
      (multiple-value-bind (symbol status)
          (find-symbol symbol-name package)
        (when status
          symbol)))))

(defun loaded-class (package-designator symbol-name)
  (let ((symbol (loaded-class-symbol package-designator symbol-name)))
    (when symbol
      (handler-case
          (find-class symbol nil)
        (condition ()
          nil)))))

(defun generic-method-present-p (generic-function specializers)
  (handler-case
      (values (not (null (find-method generic-function nil specializers nil)))
              nil)
    (condition (condition)
      (values nil condition))))

(defun safe-call-loaded-function (package-designator symbol-name &rest args)
  (let ((symbol (loaded-function-symbol package-designator symbol-name)))
    (cond
      (symbol
       (handler-case
           (values (apply symbol args) nil t symbol)
         (condition (condition)
           (values nil condition t symbol))))
      (t
       (values nil nil nil nil)))))

(defun loaded-symbol-state (package-designator symbol-name)
  (let ((package (find-package package-designator)))
    (multiple-value-bind (symbol status)
        (if package
            (find-symbol symbol-name package)
            (values nil nil))
      (list :package-name package-designator
            :package package
            :package-present (not (null package))
            :symbol-name symbol-name
            :symbol symbol
            :symbol-status status
            :symbol-present (not (null status))
            :fbound (and symbol
                         (fboundp symbol))))))

(defun loaded-symbol-state-symbol (state)
  (getf state :symbol))

(defun loaded-symbol-state-fbound-p (state)
  (not (null (getf state :fbound))))

(defun html-inspector-standard-package-name ()
  "HTML-INSPECTOR-VIEWS/STANDARD")

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

(defun package-present-p (package-name)
  (not (null (find-package package-name))))

(defun asdf-system-probe-chunk (system-name
                                &key id
                                     title
                                     (kind :asdf-system)
                                     package-name
                                     optionalp
                                     depends-on
                                     extra-evidence)
  (multiple-value-bind (system condition)
      (safe-find-asdf-system system-name)
    (let* ((package-present (and package-name
                                 (package-present-p package-name)))
           (status
             (cond
               (condition
                (if optionalp :optional-unavailable :failed))
               (system
                :good)
               (optionalp
                :optional-unavailable)
               (t
                :missing))))
      (make-coherence-chunk
       :id id
       :title title
       :kind kind
       :status status
       :value system
       :evidence (append
                  (list (list :probe 'asdf:find-system
                              :system-name system-name
                              :system system
                              :found (not (null system)))
                        (list :probe 'find-package
                              :package-name package-name
                              :present package-present)
                        (list :load-probe-performed nil))
                  extra-evidence)
       :last-error condition
       :repair-options
       (when (and (not system)
                  (not optionalp))
         (list :repair-asdf-source-registry))
       :depends-on depends-on))))

(defun runtime-coherence-system-id (system-name suffix)
  (let ((base (string-downcase (string system-name))))
    (format nil "~A-~A"
            (with-output-to-string (stream)
              (loop for char across base
                    do (write-char (if (find char "/:"
                                             :test #'char=)
                                       #\-
                                       char)
                                   stream)))
            suffix)))

(defun expected-dev-shell-cl-source-registry-chunk
    (&key (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
          (repo-root (hyperdoc-repo-root-pathname)))
  (let* ((systems '(:hyperdoc :s-graphviz :clog-ace
                    :html-inspector-views/standard
                    :clog-moldable-inspector))
         (expected-entries
           (dev-shell-source-registry-entries
            :registry registry
            :hyperdoc-root repo-root))
         (system-evidence
           (mapcar (lambda (system-name)
                     (asdf-system-source-authority-evidence
                      system-name
                      :repo-root repo-root))
                   systems))
         (repo-root-exists-p (directory-exists-p repo-root))
         (nix-visible-p
           (some (lambda (entry)
                   (search "/nix/store/" entry :test #'char=))
                 (cl-source-registry-entries registry))))
    (make-coherence-chunk
     :id "expected-dev-shell-cl-source-registry"
     :title "Expected dev-shell CL_SOURCE_REGISTRY"
     :kind :source-registry
     :status (if repo-root-exists-p :good :failed)
     :value (list :repo-root repo-root
                  :expected-authorities '(:repo :nix-store)
                  :expected-cl-source-registry
                  (join-source-registry-entries expected-entries)
                  :expected-entries expected-entries
                  :nix-store-entry-visible nix-visible-p)
     :basis (list :profile :clog-moldable-inspector
                  :model :mcdermott-chunk-basis-derive)
     :evidence
     (list (list :repo-root repo-root
                 :repo-root-exists repo-root-exists-p)
           (list :expected-authorities '(:repo :nix-store))
           (list :current-cl-source-registry registry
                 :nix-store-entry-visible nix-visible-p)
           (list :expected-entries expected-entries)
           (list :selected-systems system-evidence))
     :repair-options
     (unless repo-root-exists-p
       '(:enter-hyperdoc-repo
       :re-enter-nix-develop)))))

(defun expected-dev-shell-source-registry (&key
                                             (registry
                                              (uiop:getenv
                                               "CL_SOURCE_REGISTRY"))
                                             (repo-root
                                              (hyperdoc-repo-root-pathname)))
  (expected-dev-shell-cl-source-registry-chunk
   :registry registry
   :repo-root repo-root))

(defun current-image-cl-source-registry-chunk
    (&key (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
          (repo-root (hyperdoc-repo-root-pathname)))
  (let* ((entries (cl-source-registry-entries registry))
         (entry-evidence
           (mapcar (lambda (entry)
                     (cl-source-registry-entry-evidence
                      entry
                      :repo-root repo-root))
                   entries)))
    (make-coherence-chunk
     :id "current-image-cl-source-registry"
     :title "Current image CL_SOURCE_REGISTRY"
     :kind :source-registry
     :status (if registry :good :unknown)
     :value (list :cl-source-registry registry
                  :entries entries)
     :basis (list :environment-variable "CL_SOURCE_REGISTRY")
     :evidence
     (list (list :env-var "CL_SOURCE_REGISTRY"
                 :value registry
                 :entry-count (length entries))
         (list :entries entry-evidence))
     :repair-options
     (unless registry
       '(:inspect-asdf-source-registry
         :re-enter-nix-develop)))))

(defun current-image-source-registry (&key
                                        (registry
                                         (uiop:getenv "CL_SOURCE_REGISTRY"))
                                        (repo-root
                                         (hyperdoc-repo-root-pathname)))
  (current-image-cl-source-registry-chunk
   :registry registry
   :repo-root repo-root))

(defun source-registry-equivalent-to-dev-shell
    (&key (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
          (repo-root (hyperdoc-repo-root-pathname)))
  (let* ((expected
           (dev-shell-source-registry-entries
            :registry registry
            :hyperdoc-root repo-root))
         (current
           (cl-source-registry-entries registry))
         (missing
           (source-registry-set-difference expected current))
         (extra
           (source-registry-set-difference current expected))
         (foreign-extra
           (remove-if-not
            (lambda (entry)
              (let ((evidence
                      (cl-source-registry-entry-evidence
                       entry
                       :repo-root repo-root)))
                (eq (getf evidence :authority)
                    :foreign-contaminant)))
            extra))
         (equivalent-p
           (and (null missing)
                (null extra))))
    (make-coherence-chunk
     :id "source-registry-equivalent-to-dev-shell"
     :title "Current source registry equivalent to dev shell"
     :kind :source-registry
     :status (cond
               (equivalent-p :good)
               (foreign-extra :foreign-contaminant)
               (registry :stale)
               (t :missing))
     :value (list :equivalent equivalent-p
                  :expected-entries expected
                  :current-entries current
                  :missing-entries missing
                  :extra-entries extra
                  :foreign-extra-entries foreign-extra)
     :basis (list :expected-dev-shell-source-registry expected
                  :current-image-source-registry current)
     :evidence
     (list (list :expected-entries expected)
           (list :current-entries current)
           (list :missing-entries missing)
           (list :extra-entries extra)
           (list :foreign-extra-entries foreign-extra)
           (list :message
                 "The attached image source registry must be equivalent to the repo/Nix dev-shell registry before guarded inspector loading."))
     :repair-options
     (unless equivalent-p
       '(:import-dev-shell-source-registry
         :quarantine-foreign-asdf-source-contaminants
         :clear-asdf-source-registry-cache)))))

(defun foreign-asdf-source-registry-contaminants-chunk
    (&key (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
          (repo-root (hyperdoc-repo-root-pathname))
          (system-names '(:s-graphviz
                          :clog-ace
                          :html-inspector-views/standard
                          :clog-moldable-inspector)))
  (let* ((entry-evidence
           (mapcar (lambda (entry)
                     (cl-source-registry-entry-evidence
                      entry
                      :repo-root repo-root))
                   (cl-source-registry-entries registry)))
         (system-evidence
           (mapcar (lambda (system-name)
                     (asdf-system-source-authority-evidence
                      system-name
                      :repo-root repo-root))
                   system-names))
         (foreign-entries
           (remove-if-not
            (lambda (entry)
              (eq (getf entry :authority) :foreign-contaminant))
            entry-evidence))
         (foreign-systems
           (remove-if-not
            (lambda (entry)
              (eq (getf entry :source-authority)
                  :foreign-contaminant))
            system-evidence))
         (foreign (append foreign-entries foreign-systems)))
    (make-coherence-chunk
     :id "foreign-asdf-source-registry-contaminants"
     :title "Foreign ASDF source-registry contaminants"
     :kind :source-registry
     :status (if foreign :foreign-contaminant :good)
     :value (list :foreign-count (length foreign)
                  :foreign foreign)
     :basis (list :current-cl-source-registry registry
                  :selected-system-names system-names
                  :expected-authorities '(:repo :nix-store))
     :evidence
     (list (list :registry-entries entry-evidence)
           (list :selected-systems system-evidence)
           (list :foreign-contaminants foreign)
           (list :message
                 "Foreign source roots such as ~/common-lisp, Quicklisp, or Downloads are not authoritative for the HyperDoc Nix/repo inspector profile."))
     :repair-options
     (when foreign
       '(:remove-foreign-source-registry-contaminant
         :derive-asdf-visibility-from-repo-nix-universe
         :re-enter-nix-develop)))))

(defun foreign-asdf-source-contaminants
    (&key (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
          (repo-root (hyperdoc-repo-root-pathname))
          (system-names '(:s-graphviz
                          :clog-ace
                          :html-inspector-views/standard
                          :clog-moldable-inspector)))
  (foreign-asdf-source-registry-contaminants-chunk
   :registry registry
   :repo-root repo-root
   :system-names system-names))

(defun asdf-system-visibility-chunk
    (system-name &key id
                      title
                      package-name
                      (requiredp t)
                      (expected-authorities '(:repo :nix-store))
                      (repo-root (hyperdoc-repo-root-pathname))
                      depends-on)
  (multiple-value-bind (source-evidence condition)
      (asdf-system-source-authority-evidence
       system-name
       :repo-root repo-root
       :expected-authorities expected-authorities)
    (let* ((foundp (getf source-evidence :found))
           (dev-shell-discovery
             (unless foundp
               (dev-shell-asdf-definition-discovery
                system-name
                :repo-root repo-root)))
           (dev-shell-candidates
             (getf dev-shell-discovery :candidate-asd-files))
           (authority (getf source-evidence :source-authority))
           (acceptedp
             (getf source-evidence :source-authority-accepted))
           (package-present
             (and package-name
                  (package-present-p package-name)))
           (status
             (cond
               ((not foundp)
                (cond
                  ((not requiredp)
                   :optional-unavailable)
                  (dev-shell-candidates
                   :asdf-subsystem-not-visible)
                  (t
                   :dev-shell-asdf-system-not-visible)))
               (condition
                :failed)
               ((not acceptedp)
                :foreign-contaminant)
               (t
                :good))))
      (make-coherence-chunk
       :id (or id
               (runtime-coherence-system-id system-name "asdf-visibility"))
       :title (or title
                  (format nil "~A ASDF visibility" system-name))
       :kind :asdf-system
       :status status
       :value (list :system-name system-name
                    :found foundp
                    :dev-shell-candidate-asd-files
                    dev-shell-candidates
                    :source-authority authority
                    :source-authority-accepted acceptedp
                    :package-present package-present)
       :basis (list :system-name system-name
                    :expected-authorities expected-authorities
                    :repo-root repo-root)
       :evidence
       (list (append (list :probe 'asdf:find-system)
                     source-evidence)
             (list :probe 'dev-shell-asdf-definition-discovery
                   :performed (not foundp)
                   :result dev-shell-discovery)
             (list :probe 'find-package
                   :package-name package-name
                   :present package-present)
             (list :ordinary-probe-mode :non-mutating
                   :load-system-called nil))
       :last-error condition
       :repair-options
       (unless (eq status :good)
         (case status
           (:foreign-contaminant
            '(:remove-foreign-source-registry-contaminant
              :rederive-asdf-system-from-repo-nix-universe))
           (:asdf-subsystem-not-visible
            '(:repair-asdf-source-registry
              :re-enter-nix-develop))
           (:dev-shell-asdf-system-not-visible
            '(:inspect-dev-shell-source-registry
              :verify-nix-dev-shell-contains-system
              :re-enter-nix-develop-as-fallback))
           (otherwise
            '(:inspect-asdf-visibility))))
       :depends-on depends-on))))

(defun asdf-visible (system-name &key id
                                   title
                                   package-name
                                   (requiredp t)
                                   (expected-authorities
                                    '(:repo :nix-store))
                                   (repo-root
                                    (hyperdoc-repo-root-pathname))
                                   depends-on)
  (asdf-system-visibility-chunk
   system-name
   :id id
   :title title
   :package-name (or package-name system-name)
   :requiredp requiredp
   :expected-authorities expected-authorities
   :repo-root repo-root
   :depends-on depends-on))

(defun attempt-load-asdf-system-chunk (system-name
                                       &key id
                                            title
                                            (kind :asdf-system)
                                            package-name
                                            optionalp
                                            depends-on)
  (handler-case
      (let ((loaded (asdf:load-system system-name)))
        (make-coherence-chunk
         :id (or id
                 (format nil "~(~A~)-asdf-system" system-name))
         :title (or title
                    (format nil "~A ASDF system" system-name))
         :kind kind
         :status (if loaded :good :unknown)
         :value (asdf:find-system system-name nil)
         :evidence (list (list :probe 'asdf:load-system
                               :system-name system-name
                               :loaded loaded)
                         (list :probe 'find-package
                               :package-name package-name
                               :present (and package-name
                                             (package-present-p package-name))))
         :depends-on depends-on))
    (condition (condition)
      (make-coherence-chunk
       :id (or id
               (format nil "~(~A~)-asdf-system" system-name))
       :title (or title
                  (format nil "~A ASDF system" system-name))
       :kind kind
       :status (if optionalp :optional-unavailable :failed)
       :last-error condition
       :evidence (list (condition-evidence condition)
                       (list :probe 'asdf:load-system
                             :system-name system-name
                             :loaded nil))
       :depends-on depends-on))))

(defun clog-moldable-inspector-system-chunk ()
  (asdf-system-probe-chunk
   :clog-moldable-inspector
   :id "clog-moldable-inspector-system"
   :title "CLOG moldable inspector ASDF system"
   :kind :asdf-system
   :package-name :clog-moldable-inspector
   :depends-on '("clog-asdf-code-root" "clog-static-asset-root")
   :extra-evidence
   (list (list :ordinary-probe-mode :non-mutating
               :load-system-called nil))))

(defun html-inspector-base-system-chunk ()
  (asdf-system-probe-chunk
   :html-inspector-views
   :id "html-inspector-views-base-system"
   :title "HTML inspector views base ASDF system"
   :kind :asdf-system
   :package-name :html-inspector-views
   :extra-evidence
   (list (list :ordinary-probe-mode :non-mutating
               :load-system-called nil))))

(defun html-inspector-views-repo-local-asd-pathname ()
  (handler-case
      (asdf:system-relative-pathname
       :hyperdoc
       "nix/vendor/html-inspector-views/html-inspector-views.asd")
    (condition ()
      nil)))

(defun html-inspector-views-asdf-system-evidence
    (package-name system-name)
  (let ((package (find-package package-name)))
    (multiple-value-bind (system find-condition)
        (safe-find-asdf-system system-name)
      (multiple-value-bind (source-file source-file-condition)
          (safe-asdf-system-source-file system)
        (multiple-value-bind (source-directory source-directory-condition)
            (safe-asdf-system-source-directory system)
          (values
           (list :package-name package-name
                 :package package
                 :package-present (not (null package))
                 :asdf-system-name system-name
                 :asdf-system system
                 :asdf-system-found (not (null system))
                 :asdf-system-source-file source-file
                 :asdf-system-source-directory source-directory
                 :conditions
                 (remove
                  nil
                  (list (and find-condition
                             (list :probe 'asdf:find-system
                                   :condition
                                   (condition-evidence find-condition)))
                        (and source-file-condition
                             (list :probe 'asdf:system-source-file
                                   :condition
                                   (condition-evidence source-file-condition)))
                        (and source-directory-condition
                             (list :probe 'asdf:system-source-directory
                                   :condition
                                   (condition-evidence
                                    source-directory-condition))))))
           (or find-condition
               source-file-condition
               source-directory-condition)))))))

(defun html-inspector-views-asdf-visibility-diagnoses
    (&key base-package-present-p
          standard-package-present-p
          base-system-found-p
          standard-system-found-p
          src-directory-exists-p
          expected-asd-exists-p
          explicit-asd-set-p
          explicit-asd-exists-p
          stale-src-relative-to-repo-p
          nix-derivation-mismatch-p)
  (remove
   nil
   (list
    (when (and (or base-package-present-p
                   standard-package-present-p)
               (or (not base-system-found-p)
                   (not standard-system-found-p)))
      :packages-present-asdf-missing)
    (when (not src-directory-exists-p)
      :missing-html-inspector-views-src)
    (when (not explicit-asd-set-p)
      :missing-html-inspector-views-asd-env)
    (when (not expected-asd-exists-p)
      :missing-html-inspector-views-asd)
    (when (and explicit-asd-set-p
               (not explicit-asd-exists-p))
      :missing-html-inspector-views-asd)
    (when stale-src-relative-to-repo-p
      :stale-sly-environment)
    (when nix-derivation-mismatch-p
      :nix-derivation-mismatch)
    (when (and (not base-system-found-p)
               (not standard-system-found-p))
      :asdf-subsystem-not-visible)
    (when (not base-system-found-p)
      :base-system-missing)
    (when (not standard-system-found-p)
      :standard-system-missing))))

(defun html-inspector-views-asdf-visibility-status (diagnoses)
  (cond
    ((null diagnoses)
     :ok)
    ((member :packages-present-asdf-missing diagnoses :test #'eq)
     :packages-present-asdf-missing)
    ((member :stale-sly-environment diagnoses :test #'eq)
     :stale-sly-environment)
    ((member :nix-derivation-mismatch diagnoses :test #'eq)
     :nix-derivation-mismatch)
    ((member :missing-html-inspector-views-src diagnoses :test #'eq)
     :missing-html-inspector-views-src)
    ((member :missing-html-inspector-views-asd-env diagnoses :test #'eq)
     :missing-html-inspector-views-asd-env)
    ((member :missing-html-inspector-views-asd diagnoses :test #'eq)
     :missing-html-inspector-views-asd)
    ((member :asdf-subsystem-not-visible diagnoses :test #'eq)
     :asdf-subsystem-not-visible)
    ((member :base-system-missing diagnoses :test #'eq)
     :base-system-missing)
    ((member :standard-system-missing diagnoses :test #'eq)
     :standard-system-missing)
    (t
     :blocked)))

(defun html-inspector-views-asdf-visibility-chunk
    (&key (base-package-name "HTML-INSPECTOR-VIEWS")
          (standard-package-name "HTML-INSPECTOR-VIEWS/STANDARD")
          (base-system-name :html-inspector-views)
          (standard-system-name :html-inspector-views/standard)
          (html-inspector-views-src (uiop:getenv "HTML_INSPECTOR_VIEWS_SRC"))
          (html-inspector-views-asd (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD"))
          (cl-source-registry (uiop:getenv "CL_SOURCE_REGISTRY")))
  (handler-case
      (multiple-value-bind (base-evidence base-condition)
          (html-inspector-views-asdf-system-evidence
           base-package-name
           base-system-name)
        (multiple-value-bind (standard-evidence standard-condition)
            (html-inspector-views-asdf-system-evidence
             standard-package-name
             standard-system-name)
          (let* ((src-directory
                   (maybe-directory-pathname html-inspector-views-src))
                 (src-directory-exists-p
                   (directory-exists-p src-directory))
                 (expected-asd
                   (child-pathname src-directory
                                   #P"html-inspector-views.asd"))
                 (expected-asd-exists-p
                   (pathname-exists-p expected-asd))
                 (explicit-asd-set-p
                   (not (null html-inspector-views-asd)))
                 (explicit-asd-path
                   (and explicit-asd-set-p
                        (pathname html-inspector-views-asd)))
                 (explicit-asd-exists-p
                   (and explicit-asd-set-p
                        (pathname-exists-p explicit-asd-path)))
                 (repo-local-asd
                   (html-inspector-views-repo-local-asd-pathname))
                 (repo-local-asd-exists-p
                   (pathname-exists-p repo-local-asd))
                 (src-stale-relative-to-repo-p
                   (and repo-local-asd-exists-p
                        html-inspector-views-src
                        (not expected-asd-exists-p)))
                 (src-derivation
                   (nix-store-derivation-key src-directory))
                 (explicit-asd-derivation
                   (nix-store-derivation-key explicit-asd-path))
                 (nix-derivation-mismatch-p
                   (and src-derivation
                        explicit-asd-derivation
                        (not (string= src-derivation
                                      explicit-asd-derivation))))
                 (diagnoses
                   (html-inspector-views-asdf-visibility-diagnoses
                    :base-package-present-p
                    (getf base-evidence :package-present)
                    :standard-package-present-p
                    (getf standard-evidence :package-present)
                    :base-system-found-p
                    (getf base-evidence :asdf-system-found)
                    :standard-system-found-p
                    (getf standard-evidence :asdf-system-found)
                    :src-directory-exists-p src-directory-exists-p
                    :expected-asd-exists-p expected-asd-exists-p
                    :explicit-asd-set-p explicit-asd-set-p
                    :explicit-asd-exists-p explicit-asd-exists-p
                    :stale-src-relative-to-repo-p
                    src-stale-relative-to-repo-p
                    :nix-derivation-mismatch-p
                    nix-derivation-mismatch-p))
                 (status
                   (html-inspector-views-asdf-visibility-status
                    diagnoses)))
            (make-coherence-chunk
             :id "html-inspector-views-asdf-visibility"
             :title "HTML inspector views ASDF visibility"
             :kind :asdf-system
             :status status
             :value (list :diagnoses diagnoses
                          :base-system-name base-system-name
                          :standard-system-name standard-system-name
                          :html-inspector-views-src
                          html-inspector-views-src
                          :html-inspector-views-asd
                          html-inspector-views-asd)
             :evidence
             (list
              (append (list :scope :base) base-evidence)
              (append (list :scope :standard) standard-evidence)
              (list :environment
                    :html-inspector-views-src html-inspector-views-src
                    :html-inspector-views-src-directory src-directory
                    :html-inspector-views-src-exists
                    src-directory-exists-p
                    :expected-asd expected-asd
                    :expected-asd-exists expected-asd-exists-p
                    :html-inspector-views-asd html-inspector-views-asd
                    :html-inspector-views-asd-set explicit-asd-set-p
                    :html-inspector-views-asd-exists
                    explicit-asd-exists-p
                    :cl-source-registry cl-source-registry
                    :repo-local-asd repo-local-asd
                    :repo-local-asd-exists repo-local-asd-exists-p
                    :src-stale-relative-to-repo
                    src-stale-relative-to-repo-p
                    :nix-derivation-mismatch
                    nix-derivation-mismatch-p)
              (list :diagnoses diagnoses))
             :last-error (or base-condition standard-condition)
             :repair-options
             (unless (eq status :ok)
               '(:re-enter-updated-nix-dev-shell
                 :repair-cl-source-registry
                 :bind-html-inspector-views-src-and-asd-to-current-derivation))
             :depends-on '("html-inspector-views-environment")))))
    (condition (condition)
      (make-coherence-chunk
       :id "html-inspector-views-asdf-visibility"
       :title "HTML inspector views ASDF visibility"
       :kind :asdf-system
       :status :blocked
       :value (list :diagnoses '(:blocked)
                    :html-inspector-views-src html-inspector-views-src
                    :html-inspector-views-asd html-inspector-views-asd)
       :evidence (list (condition-evidence condition))
       :last-error condition
       :repair-options
       '(:re-enter-updated-nix-dev-shell
         :repair-cl-source-registry
         :bind-html-inspector-views-src-and-asd-to-current-derivation)
       :depends-on '("html-inspector-views-environment")))))

(defun html-inspector-views-environment-advice-from-observation
    (src-directory-exists-p
     expected-asd-exists-p
     explicit-asd-set-p
     explicit-asd-exists-p
     base-system
     standard-system
     &key src-value
          explicit-asd-value)
  (cond
    ((not src-directory-exists-p)
     :missing-html-inspector-views-src)
    ((and (not expected-asd-exists-p)
          (or (and src-value
                   (search "/nix/store/" (namestring (pathname src-value))
                           :test #'char=))
              (and explicit-asd-value
                   (search "/nix/store/" (namestring (pathname explicit-asd-value))
                           :test #'char=))))
     :stale-sly-environment)
    ((not expected-asd-exists-p)
     :missing-html-inspector-views-asd)
    ((not explicit-asd-set-p)
     :missing-html-inspector-views-asd)
    ((and explicit-asd-set-p
          (not explicit-asd-exists-p))
     :missing-html-inspector-views-asd)
    ((or (not base-system)
         (not standard-system))
     :asdf-subsystem-not-visible)
    (t
     :ok)))

(defun status-for-html-inspector-views-environment-advice (advice)
  (ecase advice
    (:ok :good)
    (:missing-html-inspector-views-src :missing)
    ((:stale-sly-environment
      :missing-html-inspector-views-asd
      :asdf-subsystem-not-visible)
     :blocked)))

(defun html-inspector-views-environment-chunk
    (&key (html-inspector-views-src (uiop:getenv "HTML_INSPECTOR_VIEWS_SRC"))
          (html-inspector-views-asd (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD")))
  (handler-case
      (let* ((src-directory (maybe-directory-pathname html-inspector-views-src))
             (src-directory-exists-p (directory-exists-p src-directory))
             (expected-asd (child-pathname src-directory
                                           #P"html-inspector-views.asd"))
             (expected-asd-exists-p (pathname-exists-p expected-asd))
             (explicit-asd-set-p (not (null html-inspector-views-asd)))
             (explicit-asd-path (and html-inspector-views-asd
                                     (pathname html-inspector-views-asd)))
             (explicit-asd-exists-p
               (and explicit-asd-set-p
                    (pathname-exists-p explicit-asd-path)))
             (base-condition nil)
             (standard-condition nil))
        (multiple-value-bind (base-system base-error)
            (safe-find-asdf-system :html-inspector-views)
          (setf base-condition base-error)
          (multiple-value-bind (standard-system standard-error)
              (safe-find-asdf-system :html-inspector-views/standard)
            (setf standard-condition standard-error)
            (let* ((advice
                     (html-inspector-views-environment-advice-from-observation
                      src-directory-exists-p
                      expected-asd-exists-p
                      explicit-asd-set-p
                      explicit-asd-exists-p
                      base-system
                      standard-system
                      :src-value html-inspector-views-src
                      :explicit-asd-value html-inspector-views-asd))
                   (status
                     (status-for-html-inspector-views-environment-advice
                      advice)))
              (make-coherence-chunk
               :id "html-inspector-views-environment"
               :title "HTML inspector views environment"
               :kind :asdf-code-root
               :status status
               :value (list :repair-advice advice
                            :html-inspector-views-src html-inspector-views-src
                            :html-inspector-views-asd html-inspector-views-asd)
               :evidence
               (list
                (list :env-var "HTML_INSPECTOR_VIEWS_SRC"
                      :value html-inspector-views-src
                      :directory src-directory
                      :directory-exists src-directory-exists-p
                      :expected-asd expected-asd
                      :expected-asd-exists expected-asd-exists-p)
                (list :env-var "HTML_INSPECTOR_VIEWS_ASD"
                      :value html-inspector-views-asd
                      :set explicit-asd-set-p
                      :path explicit-asd-path
                      :exists explicit-asd-exists-p)
                (list :probe 'asdf:find-system
                      :system-name :html-inspector-views
                      :system base-system
                      :found (not (null base-system)))
                (list :probe 'asdf:find-system
                      :system-name :html-inspector-views/standard
                      :system standard-system
                      :found (not (null standard-system)))
                (list :repair-advice advice
                      :message
                      "This chunk checks process environment coherence for the HTML inspector views source derivation."))
               :last-error (or base-condition standard-condition)
               :repair-options
               (unless (eq advice :ok)
                 '(:re-enter-updated-nix-dev-shell
                   :bind-html-inspector-views-src-and-asd-to-current-derivation)))))))
    (condition (condition)
      (make-coherence-chunk
       :id "html-inspector-views-environment"
       :title "HTML inspector views environment"
       :kind :asdf-code-root
       :status :failed
       :value (list :repair-advice :stale-sly-environment
                    :html-inspector-views-src html-inspector-views-src
                    :html-inspector-views-asd html-inspector-views-asd)
       :evidence (list (condition-evidence condition))
       :last-error condition
       :repair-options
       '(:re-enter-updated-nix-dev-shell
         :bind-html-inspector-views-src-and-asd-to-current-derivation)))))

(defun html-inspector-views-environment-repair-advice
    (&key (html-inspector-views-src (uiop:getenv "HTML_INSPECTOR_VIEWS_SRC"))
          (html-inspector-views-asd (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD")))
  (handler-case
      (getf
       (coherence-chunk-value-of
        (html-inspector-views-environment-chunk
         :html-inspector-views-src html-inspector-views-src
         :html-inspector-views-asd html-inspector-views-asd))
       :repair-advice)
    (condition ()
      :stale-sly-environment)))

(defun html-inspector-views-environment-asdf-repair-chunk
    (&key (system-name :html-inspector-views)
          (standard-system-name :html-inspector-views/standard))
  (handler-case
      (let* ((before-src (uiop:getenv "HTML_INSPECTOR_VIEWS_SRC"))
             (before-asd (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD"))
             (base-condition nil)
             (source-file-condition nil)
             (source-directory-condition nil)
             (standard-condition nil))
        (multiple-value-bind (base-system base-error)
            (safe-find-asdf-system system-name)
          (setf base-condition base-error)
          (multiple-value-bind (source-file source-file-error)
              (safe-asdf-system-source-file base-system)
            (setf source-file-condition source-file-error)
            (multiple-value-bind (source-directory source-directory-error)
                (safe-asdf-system-source-directory base-system)
              (setf source-directory-condition source-directory-error)
              (multiple-value-bind (standard-system standard-error)
                  (safe-find-asdf-system standard-system-name)
                (setf standard-condition standard-error)
                (let* ((derived-source-file
                         (or source-file
                             (child-pathname source-directory
                                             #P"html-inspector-views.asd")))
                       (derived-source-directory
                         (or source-directory
                             (and derived-source-file
                                  (uiop:pathname-directory-pathname
                                   derived-source-file))))
                       (source-directory-exists-p
                         (directory-exists-p derived-source-directory))
                       (source-file-exists-p
                         (pathname-exists-p derived-source-file))
                       (target-src
                         (safe-namestring
                          (maybe-directory-pathname derived-source-directory)))
                       (target-asd
                         (safe-namestring derived-source-file))
                       (status
                         (cond
                           ((not base-system)
                            :asdf-subsystem-not-visible)
                           ((not source-directory-exists-p)
                            :missing-html-inspector-views-src)
                           ((not source-file-exists-p)
                            :missing-html-inspector-views-asd)
                           (t
                            :good)))
                       (mutation-evidence
                         (when (eq status :good)
                           (list
                            (environment-mutation-evidence
                             "HTML_INSPECTOR_VIEWS_SRC"
                             target-src)
                            (environment-mutation-evidence
                             "HTML_INSPECTOR_VIEWS_ASD"
                             target-asd))))
                       (mutation-success-p
                         (and mutation-evidence
                              (every (lambda (entry)
                                       (getf entry :set))
                                     mutation-evidence)))
                       (final-status
                         (if (and (eq status :good)
                                  (not mutation-success-p))
                             :failed
                             status)))
                  (make-coherence-chunk
                   :id "html-inspector-views-environment-asdf-repair"
                   :title "HTML inspector views environment repair from ASDF"
                   :kind :asdf-code-root
                   :status final-status
                   :value (list :before-html-inspector-views-src before-src
                                :before-html-inspector-views-asd before-asd
                                :target-html-inspector-views-src target-src
                                :target-html-inspector-views-asd target-asd
                                :base-system-found (not (null base-system))
                                :standard-system-found
                                (not (null standard-system)))
                   :evidence
                   (append
                    (list
                     (list :before
                           :html-inspector-views-src before-src
                           :html-inspector-views-asd before-asd)
                     (list :probe 'asdf:find-system
                           :system-name system-name
                           :system base-system
                           :found (not (null base-system)))
                     (list :probe 'asdf:find-system
                           :system-name standard-system-name
                           :system standard-system
                           :found (not (null standard-system)))
                     (list :source-file derived-source-file
                           :source-file-exists source-file-exists-p
                           :source-directory derived-source-directory
                           :source-directory-exists
                           source-directory-exists-p))
                    mutation-evidence
                    (list
                     (list :after
                           :html-inspector-views-src
                           (uiop:getenv "HTML_INSPECTOR_VIEWS_SRC")
                           :html-inspector-views-asd
                           (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD"))))
                   :last-error (or base-condition
                                   source-file-condition
                                   source-directory-condition
                                   standard-condition)
                   :repair-options
                   (unless (eq final-status :good)
                     '(:re-enter-updated-nix-dev-shell
                       :repair-cl-source-registry
                       :bind-html-inspector-views-src-and-asd-to-current-derivation))
                   :depends-on '("html-inspector-views-asdf-visibility"))))))))
    (condition (condition)
      (make-coherence-chunk
       :id "html-inspector-views-environment-asdf-repair"
       :title "HTML inspector views environment repair from ASDF"
       :kind :asdf-code-root
       :status :failed
       :value (list :before-html-inspector-views-src
                    (uiop:getenv "HTML_INSPECTOR_VIEWS_SRC")
                    :before-html-inspector-views-asd
                    (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD"))
       :evidence (list (condition-evidence condition))
       :last-error condition
       :repair-options
       '(:re-enter-updated-nix-dev-shell
         :repair-cl-source-registry
         :bind-html-inspector-views-src-and-asd-to-current-derivation)
       :depends-on '("html-inspector-views-asdf-visibility")))))

(defun repair-html-inspector-views-environment-from-asdf
    (&key (title "HTML inspector views environment repair from ASDF")
          (observed-at (get-universal-time))
          (system-name :html-inspector-views)
          (standard-system-name :html-inspector-views/standard))
  (let ((repair-chunk
          (html-inspector-views-environment-asdf-repair-chunk
           :system-name system-name
           :standard-system-name standard-system-name)))
    (make-runtime-coherence-report
     :title title
     :observed-at observed-at
     :chunks (list repair-chunk
                   (html-inspector-views-environment-chunk)
                   (html-inspector-views-asdf-visibility-chunk)))))

(defun s-graphviz-optional-capability-chunk (&key load-probe)
  (if load-probe
      (attempt-load-asdf-system-chunk
       :s-graphviz
       :id "s-graphviz-optional-capability"
       :title "s-graphviz optional capability"
       :kind :optional-inspector-view
       :package-name :s-graphviz
       :optionalp t)
      (asdf-system-probe-chunk
       :s-graphviz
       :id "s-graphviz-optional-capability"
       :title "s-graphviz optional capability"
       :kind :optional-inspector-view
       :package-name :s-graphviz
       :optionalp t
       :extra-evidence
       (list (list :ordinary-probe-mode :non-mutating
                   :load-system-called nil)))))

(defun html-inspector-standard-view-chunk (&key
                                             s-graphviz-chunk)
  (let* ((graphviz (or s-graphviz-chunk
                       (s-graphviz-optional-capability-chunk)))
         (base (asdf-system-probe-chunk
                :html-inspector-views/standard
                :id "html-inspector-views-standard-view"
                :title "HTML inspector standard views"
                :kind :optional-inspector-view
                :package-name :html-inspector-views/standard
                :optionalp t
                :depends-on '("html-inspector-views-base-system"
                              "s-graphviz-optional-capability")
                :extra-evidence
                (list (list :ordinary-probe-mode :non-mutating
                            :load-system-called nil)))))
    (if (member (coherence-chunk-status-of graphviz)
                '(:optional-unavailable :failed :blocked)
                :test #'eq)
        (make-coherence-chunk
         :id (coherence-chunk-id-of base)
         :title (coherence-chunk-title-of base)
         :kind (coherence-chunk-kind-of base)
         :status (if (eq (coherence-chunk-status-of base) :good)
                     :degraded
                     (coherence-chunk-status-of base))
         :value (coherence-chunk-value-of base)
         :evidence (append
                    (coherence-chunk-evidence-of base)
                    (list (list :optional-boundary
                                :s-graphviz
                                :optional-capability-status
                                (coherence-chunk-status-of graphviz)
                                :effect
                                "Graphviz-backed standard views are degraded without crashing the report.")))
         :last-error (or (coherence-chunk-last-error-of base)
                         (coherence-chunk-last-error-of graphviz))
         :repair-options '(:enable-graphviz-optional-capability)
         :depends-on (coherence-chunk-depends-on-of base))
        base)))

(defun html-inspector-views-live-method-chunk
    (&key (package-name (html-inspector-standard-package-name)))
  (handler-case
      (let* ((package (find-package package-name))
             (depends-on-state
               (loaded-symbol-state package-name "SYSTEM-DEPENDS-ON"))
             (dependencies-state
               (loaded-symbol-state package-name "SYSTEM-DEPENDENCIES"))
             (depends-on-symbol
               (loaded-symbol-state-symbol depends-on-state))
             (dependencies-symbol
               (loaded-symbol-state-symbol dependencies-state))
             (null-class (find-class 'null))
             (depends-on-null-method nil)
             (method-condition nil)
             (depends-on-result nil)
             (depends-on-condition nil)
             (depends-on-called nil)
             (dependencies-result nil)
             (dependencies-condition nil)
             (dependencies-called nil))
        (when (loaded-symbol-state-fbound-p depends-on-state)
          (multiple-value-setq (depends-on-null-method method-condition)
            (generic-method-present-p (symbol-function depends-on-symbol)
                                      (list null-class)))
          (multiple-value-setq (depends-on-result depends-on-condition
                                                  depends-on-called)
            (safe-call-loaded-function package-name
                                       "SYSTEM-DEPENDS-ON"
                                       nil)))
        (when (loaded-symbol-state-fbound-p dependencies-state)
          (multiple-value-setq (dependencies-result dependencies-condition
                                                    dependencies-called)
            (safe-call-loaded-function package-name
                                       "SYSTEM-DEPENDENCIES"
                                       nil)))
        (let* ((condition (or method-condition
                              depends-on-condition
                              dependencies-condition))
               (status
                 (cond
                   ((null package)
                    :missing-package)
                   ((or (not (loaded-symbol-state-fbound-p depends-on-state))
                        (not (loaded-symbol-state-fbound-p dependencies-state))
                        method-condition)
                    :missing-generic-function)
                   ((not depends-on-null-method)
                    :missing-null-method)
                   (condition
                    :failed-safe-call)
                   (t
                    :good))))
          (make-coherence-chunk
           :id "html-inspector-views-standard-live-methods"
           :title "HTML inspector standard live methods"
           :kind :optional-inspector-view
           :status status
           :value (list :package package
                        :system-depends-on depends-on-symbol
                        :system-dependencies dependencies-symbol
                        :null-method-present depends-on-null-method)
           :evidence
           (list
            (list :probe 'find-package
                  :package-name package-name
                  :present (not (null package)))
            (list :probe 'find-symbol
                  :symbol "SYSTEM-DEPENDS-ON"
                  :present (getf depends-on-state :symbol-present)
                  :fbound (loaded-symbol-state-fbound-p depends-on-state)
                  :symbol-status (getf depends-on-state :symbol-status))
            (list :probe 'find-symbol
                  :symbol "SYSTEM-DEPENDENCIES"
                  :present (getf dependencies-state :symbol-present)
                  :fbound (loaded-symbol-state-fbound-p dependencies-state)
                  :symbol-status (getf dependencies-state :symbol-status))
            (list :probe 'find-method
                  :generic-function 'system-depends-on
                  :specializers '(null)
                  :present depends-on-null-method
                  :condition (and method-condition
                                  (condition-evidence method-condition)))
            (list :probe 'safe-call
                  :form '(system-depends-on nil)
                  :performed depends-on-called
                  :result depends-on-result
                  :condition (and depends-on-condition
                                  (condition-evidence depends-on-condition)))
            (list :probe 'safe-call
                  :form '(system-dependencies nil)
                  :performed dependencies-called
                  :result dependencies-result
                  :condition (and dependencies-condition
                                  (condition-evidence dependencies-condition))))
           :last-error condition
           :repair-options
           (when (member status
                         '(:missing-null-method :failed-safe-call)
                         :test #'eq)
             '(:repair-html-inspector-views-standard-live-methods))
           :depends-on '("html-inspector-views-standard-view"))))
    (condition (condition)
      (make-coherence-chunk
       :id "html-inspector-views-standard-live-methods"
       :title "HTML inspector standard live methods"
       :kind :optional-inspector-view
       :status :failed-safe-call
       :evidence (list (condition-evidence condition))
       :last-error condition
       :repair-options '(:repair-html-inspector-views-standard-live-methods)
       :depends-on '("html-inspector-views-standard-view")))))

(defun html-inspector-standard-dependency-cache-chunk ()
  (let* ((package-name :html-inspector-views/standard)
         (package (find-package package-name))
         (depends-on-symbol
           (loaded-function-symbol package-name "SYSTEM-DEPENDS-ON"))
         (dependencies-symbol
           (loaded-function-symbol package-name "SYSTEM-DEPENDENCIES"))
         (precompute-layers-symbol
           (loaded-function-symbol package-name "PRECOMPUTE-LAYERS"))
         (missing-component-class
           (loaded-class package-name "MISSING-COMPONENT"))
         (null-class (find-class 'null))
         (depends-on-null-method nil)
         (method-condition nil)
         (depends-on-result nil)
         (depends-on-condition nil)
         (dependencies-result nil)
         (dependencies-condition nil)
         (depends-on-called nil)
         (dependencies-called nil))
    (when depends-on-symbol
      (multiple-value-setq (depends-on-null-method method-condition)
        (generic-method-present-p (symbol-function depends-on-symbol)
                                  (list null-class)))
      (multiple-value-setq (depends-on-result depends-on-condition
                                              depends-on-called)
        (safe-call-loaded-function package-name "SYSTEM-DEPENDS-ON" nil)))
    (when dependencies-symbol
      (multiple-value-setq (dependencies-result dependencies-condition
                                                dependencies-called)
        (safe-call-loaded-function package-name "SYSTEM-DEPENDENCIES" nil)))
    (let* ((condition (or method-condition
                          depends-on-condition
                          dependencies-condition))
           (status
             (cond
               ((null package)
                :good)
               (condition
                :failed)
               ((not depends-on-symbol)
                :stale)
               ((not dependencies-symbol)
                :stale)
               ((not depends-on-null-method)
                :stale)
               ((not missing-component-class)
                :stale)
               (t
                :good))))
      (make-coherence-chunk
       :id "html-inspector-views-standard-dependency-cache"
       :title "HTML inspector standard dependency cache"
       :kind :optional-inspector-view
       :status status
       :value (list :package package
                    :system-depends-on depends-on-symbol
                    :system-dependencies dependencies-symbol
                    :precompute-layers precompute-layers-symbol
                    :missing-component-class missing-component-class)
       :evidence
       (list (list :probe 'find-package
                   :package-name package-name
                   :present (not (null package)))
             (list :probe 'find-symbol
                   :system-depends-on-present (not (null depends-on-symbol))
                   :system-dependencies-present (not (null dependencies-symbol))
                   :precompute-layers-present (not (null precompute-layers-symbol))
                   :missing-component-class-present
                   (not (null missing-component-class)))
             (list :probe 'find-method
                   :generic-function 'system-depends-on
                   :specializers '(null)
                   :present depends-on-null-method)
             (list :probe 'safe-call
                   :form '(system-depends-on nil)
                   :performed depends-on-called
                   :result depends-on-result)
             (list :probe 'safe-call
                   :form '(system-dependencies nil)
                   :performed dependencies-called
                   :result dependencies-result)
             (if package
                 (list :message
                       "Loaded standard inspector dependency precompute is nil-safe when this chunk is :good.")
                 (list :message
                       "Standard inspector package is not loaded, so no running-image dependency cache is active.")))
       :last-error condition
       :repair-options
       (when (member status '(:stale :failed) :test #'eq)
         '(:reload-html-inspector-views-standard-source
           :recompute-html-inspector-dependency-cache))
       :depends-on '("html-inspector-views-standard-view")))))

(defun clog-moldable-inspector-profile-visibility-chunks ()
  (list
   (asdf-system-visibility-chunk
    :s-graphviz
    :id "s-graphviz-asdf-visibility"
    :title "s-graphviz ASDF visibility"
    :package-name :s-graphviz
    :requiredp t
    :depends-on '("expected-dev-shell-cl-source-registry"
                  "current-image-cl-source-registry"
                  "source-registry-equivalent-to-dev-shell"
                  "foreign-asdf-source-registry-contaminants"))
   (asdf-system-visibility-chunk
    :clog-ace
    :id "clog-ace-asdf-visibility"
    :title "CLOG ACE ASDF visibility"
    :package-name :clog-ace
    :requiredp t
    :depends-on '("expected-dev-shell-cl-source-registry"
                  "current-image-cl-source-registry"
                  "source-registry-equivalent-to-dev-shell"
                  "foreign-asdf-source-registry-contaminants"))
   (asdf-system-visibility-chunk
    :html-inspector-views/standard
    :id "html-inspector-views-standard-asdf-visibility"
    :title "HTML inspector standard ASDF visibility"
    :package-name :html-inspector-views/standard
    :requiredp t
    :depends-on '("html-inspector-views-environment"
                  "html-inspector-views-asdf-visibility"
                  "source-registry-equivalent-to-dev-shell"
                  "foreign-asdf-source-registry-contaminants"))
   (asdf-system-visibility-chunk
    :clog-moldable-inspector
    :id "clog-moldable-inspector-asdf-visibility"
    :title "CLOG moldable inspector ASDF visibility"
    :package-name :clog-moldable-inspector
    :requiredp t
    :depends-on '("clog-asdf-code-root"
                  "clog-static-asset-root"
                  "s-graphviz-asdf-visibility"
                  "clog-ace-asdf-visibility"
                  "html-inspector-views-standard-asdf-visibility"))))

(defun clog-moldable-inspector-readiness-required-chunk-p (chunk)
  (member (coherence-chunk-id-of chunk)
          '("expected-dev-shell-cl-source-registry"
            "source-registry-equivalent-to-dev-shell"
            "foreign-asdf-source-registry-contaminants"
            "clog-asdf-code-root"
            "clog-static-asset-root"
            "s-graphviz-asdf-visibility"
            "clog-ace-asdf-visibility"
            "html-inspector-views-standard-asdf-visibility"
            "clog-moldable-inspector-asdf-visibility"
            "clog-moldable-inspector-system"
            "html-inspector-views-standard-live-methods"
            "html-inspector-views-standard-dependency-cache")
          :test #'string=))

(defun clog-moldable-inspector-readiness-chunk (chunks)
  (let* ((required-blocking
           (remove-if-not
            (lambda (chunk)
              (and (clog-moldable-inspector-readiness-required-chunk-p chunk)
                   (coherence-chunk-status-blocking-p
                    (coherence-chunk-status-of chunk))))
            chunks))
         (degraded
           (remove-if-not
            (lambda (chunk)
              (member (coherence-chunk-status-of chunk)
                      '(:degraded :optional-unavailable)
                      :test #'eq))
            chunks)))
    (make-coherence-chunk
     :id "clog-moldable-inspector-readiness"
     :title "CLOG moldable inspector readiness"
     :kind :coherence-gate
     :status (cond
               (required-blocking :blocked)
               (degraded :degraded)
               (t :good))
     :basis (list :profile :clog-moldable-inspector
                  :required-chunks
                  (mapcar #'coherence-chunk-id-of
                          (remove-if-not
                           #'clog-moldable-inspector-readiness-required-chunk-p
                           chunks)))
     :value (list :blocking-chunks
                  (mapcar #'coherence-chunk-id-of required-blocking)
                  :degraded-chunks
                  (mapcar #'coherence-chunk-id-of degraded))
     :evidence
     (list
      (list :blocking-runtime-support-chunks
            (mapcar (lambda (chunk)
                      (list :id (coherence-chunk-id-of chunk)
                            :status (coherence-chunk-status-of chunk)))
                    required-blocking))
      (list :degraded-runtime-support-chunks
            (mapcar (lambda (chunk)
                      (list :id (coherence-chunk-id-of chunk)
                            :status (coherence-chunk-status-of chunk)))
                    degraded))
      (if required-blocking
          (list :message
                "Refuse to load CLOG moldable inspector until required ASDF visibility and source-registry chunks are coherent.")
          (list :message
                "CLOG moldable inspector load is coherent enough for the guarded profile.")))
     :repair-options
     (when required-blocking
       '(:inspect-source-registry-diff
         :remove-foreign-asdf-contaminants
         :repair-asdf-visibility
         :re-enter-nix-develop-as-fallback))
     :depends-on (mapcar #'coherence-chunk-id-of chunks))))

(defun system-ready (system-name &key chunks)
  (case system-name
    (:clog-moldable-inspector
     (clog-moldable-inspector-readiness-chunk
      (or chunks
          (let ((profile-chunks
                  (make-clog-moldable-inspector-profile-chunks)))
            (remove "clog-moldable-inspector-readiness"
                    profile-chunks
                    :key #'coherence-chunk-id-of
                    :test #'string=)))))
    (otherwise
     (make-coherence-chunk
      :id (runtime-coherence-system-id system-name "readiness")
      :title (format nil "~A readiness" system-name)
      :kind :coherence-gate
      :status :blocked
      :basis (list :system-name system-name)
      :evidence
      (list (list :message
                  "No running-image coherence readiness profile is registered for this system."))
      :repair-options '(:define-coherence-profile)))))

(defun make-clog-moldable-inspector-profile-chunks ()
  (let* ((expected-registry
           (expected-dev-shell-cl-source-registry-chunk))
         (current-registry
           (current-image-cl-source-registry-chunk))
         (source-registry-equivalence
           (source-registry-equivalent-to-dev-shell))
         (foreign-contaminants
           (foreign-asdf-source-registry-contaminants-chunk))
         (clog-code-root
           (clog-asdf-code-root-chunk))
         (clog-static-root
           (clog-static-asset-root-chunk))
         (html-environment
           (html-inspector-views-environment-chunk))
         (html-asdf-visibility
           (html-inspector-views-asdf-visibility-chunk))
         (profile-visibility
           (clog-moldable-inspector-profile-visibility-chunks))
         (clog-inspector
           (clog-moldable-inspector-system-chunk))
         (html-standard-live-methods
           (html-inspector-views-live-method-chunk))
         (html-standard-cache
           (html-inspector-standard-dependency-cache-chunk))
         (chunks
           (append (list expected-registry
                         current-registry
                         source-registry-equivalence
                         foreign-contaminants
                         clog-code-root
                         clog-static-root
                         html-environment
                         html-asdf-visibility)
                   profile-visibility
                   (list clog-inspector
                         html-standard-live-methods
                         html-standard-cache))))
    (append chunks
            (list (clog-moldable-inspector-readiness-chunk chunks)))))

(defun make-clog-moldable-inspector-coherence-report
    (&key (title "CLOG moldable inspector running-image coherence report")
          (observed-at (get-universal-time)))
  (let ((chunks (make-clog-moldable-inspector-profile-chunks)))
    (make-runtime-coherence-report
     :title title
     :observed-at observed-at
     :chunks chunks)))

(defun required-browser-inspection-support-chunk-p (chunk)
  (member (coherence-chunk-id-of chunk)
          '("clog-asdf-code-root"
            "clog-static-asset-root"
            "clog-moldable-inspector-system"
            "html-inspector-views-environment"
            "html-inspector-views-asdf-visibility"
            "html-inspector-views-base-system")
          :test #'string=))

(defun degraded-optional-inspector-chunk-p (chunk)
  (and (eq (coherence-chunk-kind-of chunk)
           :optional-inspector-view)
       (member (coherence-chunk-status-of chunk)
               '(:degraded :optional-unavailable :blocked :failed :stale)
               :test #'eq)))

(defun browser-inspection-session-chunk (&key root-object
                                              summary
                                              checklist
                                              projections
                                              support-chunks)
  (let* ((required-blocking
           (remove-if-not
            (lambda (chunk)
              (and (required-browser-inspection-support-chunk-p chunk)
                   (coherence-chunk-status-blocking-p
                    (coherence-chunk-status-of chunk))))
            support-chunks))
         (optional-degraded
           (remove-if-not #'degraded-optional-inspector-chunk-p
                          support-chunks))
         (root-good (not (null root-object))))
    (make-coherence-chunk
     :id "browser-inspection-session"
     :title "Browser inspection session"
     :kind :browser-inspection-session
     :basis root-object
     :status (cond
               (required-blocking :blocked)
               (root-good :good)
               (t :unknown))
     :value (list :root-object root-object
                  :summary summary
                  :checklist checklist
                  :projections projections)
     :evidence (list
                (list :root-object-present root-good
                      :root-object-type (and root-object
                                             (type-of root-object)))
                (list :blocking-runtime-support-chunks
                      (mapcar #'coherence-chunk-id-of
                              required-blocking))
                (list :optional-degraded-chunks
                      (mapcar #'coherence-chunk-id-of
                              optional-degraded))
                (if required-blocking
                    (list :message
                          "Object state is preserved, but browser inspection is blocked by runtime support chunks."
                          :plan-object-status
                          (if root-good :good :unknown))
                    (list :message
                          "No required browser-inspection support chunk is blocking this non-mutating report."
                          :plan-object-status
                          (if root-good :good :unknown))))
     :repair-options
     (when required-blocking
       '(:inspect-blocking-runtime-support-chunks))
     :depends-on (mapcar #'coherence-chunk-id-of support-chunks))))

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

(defmethod derive-date ((report runtime-coherence-report))
  (runtime-coherence-report-observed-at-of report))

(defmethod coherence-report ((report runtime-coherence-report)
                             &key &allow-other-keys)
  report)

(defmethod coherence-report ((profile (eql :clog-moldable-inspector))
                             &key (title "CLOG moldable inspector running-image coherence report")
                                  (observed-at (get-universal-time))
                                  &allow-other-keys)
  (make-clog-moldable-inspector-coherence-report
   :title title
   :observed-at observed-at))

(defmethod coherence-report ((object t)
                             &key (profile :clog-moldable-inspector)
                                  &allow-other-keys)
  (declare (ignore object))
  (coherence-report profile))

(defun default-runtime-coherence-sqlite-path ()
  (handler-case
      (asdf:system-relative-pathname
       :hyperdoc
       "var/runtime-coherence.sqlite")
    (condition ()
      (merge-pathnames #P"var/runtime-coherence.sqlite"
                       (uiop:ensure-directory-pathname
                        *default-pathname-defaults*)))))

(defun runtime-coherence-sqlite-available-p
    (&key (sqlite-program "sqlite3"))
  (and sqlite-program
       (not (string= sqlite-program ""))
       (handler-case
           (multiple-value-bind (output error-output exit-code)
               (uiop:run-program (list sqlite-program "--version")
                                 :output :string
                                 :error-output :string
                                 :ignore-error-status t)
             (declare (ignore output error-output))
             (zerop exit-code))
         (condition ()
           nil))))

(defun runtime-coherence-sqlite-string-literal (value)
  (if (null value)
      "NULL"
      (format nil "'~A'"
              (with-output-to-string (stream)
                (loop for char across (format nil "~A" value)
                      do (if (char= char #\')
                             (write-string "''" stream)
                             (write-char char stream)))))))

(defun runtime-coherence-sqlite-run
    (sql &key (db-path (default-runtime-coherence-sqlite-path))
              (sqlite-program "sqlite3")
              json-p)
  (let* ((pathname (etypecase db-path
                     (pathname db-path)
                     (string (pathname db-path))))
         (parent (uiop:pathname-directory-pathname pathname)))
    (cond
      ((not (runtime-coherence-sqlite-available-p
             :sqlite-program sqlite-program))
       (values nil :backend-unavailable
               (format nil "sqlite3 is unavailable: ~A" sqlite-program)))
      (t
       (ensure-directories-exist parent)
       (handler-case
           (multiple-value-bind (output error-output exit-code)
               (uiop:run-program
                (append (list sqlite-program)
                        (when json-p (list "-json"))
                        (list (namestring pathname) sql))
                :output :string
                :error-output :output
                :ignore-error-status t)
             (declare (ignore error-output))
             (if (zerop exit-code)
                 (values output :ok nil)
                 (values output :error
                         (format nil "sqlite3 exited with code ~D: ~A"
                                 exit-code
                                 output))))
         (condition (condition)
           (values nil :error (princ-to-string condition))))))))

(defun runtime-coherence-sqlite-schema-sql ()
  "CREATE TABLE IF NOT EXISTS runtime_coherence_events(
    event_id integer primary key autoincrement,
    timestamp text not null,
    report_title text,
    chunk_id text not null,
    status text not null,
    kind text,
    basis text,
    evidence text,
    repair_action text,
    condition_class text,
    condition_message text
  );

  CREATE INDEX IF NOT EXISTS runtime_coherence_events_chunk_idx
    ON runtime_coherence_events(chunk_id);

  CREATE INDEX IF NOT EXISTS runtime_coherence_events_status_idx
    ON runtime_coherence_events(status);")

(defun ensure-runtime-coherence-sqlite-schema
    (&key (db-path (default-runtime-coherence-sqlite-path))
          (sqlite-program "sqlite3"))
  (multiple-value-bind (output status detail)
      (runtime-coherence-sqlite-run
       (runtime-coherence-sqlite-schema-sql)
       :db-path db-path
       :sqlite-program sqlite-program)
    (declare (ignore output))
    (values (eq status :ok) status detail)))

(defun coherence-condition-class-name (condition)
  (and condition
       (typep condition 'condition)
       (format nil "~A" (type-of condition))))

(defun coherence-condition-message (condition)
  (and condition
       (if (typep condition 'condition)
           (princ-to-string condition)
           (format nil "~A" condition))))

(defun persist-runtime-coherence-event
    (chunk &key report-title
                repair-action
                (timestamp (runtime-coherence-now-string))
                (db-path (default-runtime-coherence-sqlite-path))
                (sqlite-program "sqlite3"))
  (multiple-value-bind (schema-ready-p schema-status schema-detail)
      (ensure-runtime-coherence-sqlite-schema
       :db-path db-path
       :sqlite-program sqlite-program)
    (if (not schema-ready-p)
        (values nil schema-status schema-detail)
        (let* ((condition (coherence-chunk-last-error-of chunk))
               (sql
                 (format nil
                         "INSERT INTO runtime_coherence_events
                          (timestamp, report_title, chunk_id, status, kind,
                           basis, evidence, repair_action, condition_class,
                           condition_message)
                          VALUES(~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A);"
                         (runtime-coherence-sqlite-string-literal timestamp)
                         (runtime-coherence-sqlite-string-literal report-title)
                         (runtime-coherence-sqlite-string-literal
                          (coherence-chunk-id-of chunk))
                         (runtime-coherence-sqlite-string-literal
                          (runtime-coherence-keyword-label
                           (coherence-chunk-status-of chunk)))
                         (runtime-coherence-sqlite-string-literal
                          (runtime-coherence-keyword-label
                           (coherence-chunk-kind-of chunk)))
                         (runtime-coherence-sqlite-string-literal
                          (runtime-coherence-print-value
                           (coherence-chunk-basis-of chunk)))
                         (runtime-coherence-sqlite-string-literal
                          (runtime-coherence-print-value
                           (coherence-chunk-evidence-of chunk)))
                         (runtime-coherence-sqlite-string-literal
                          (or repair-action
                              (runtime-coherence-print-value
                               (coherence-chunk-repair-options-of chunk))))
                         (runtime-coherence-sqlite-string-literal
                          (coherence-condition-class-name condition))
                         (runtime-coherence-sqlite-string-literal
                          (coherence-condition-message condition)))))
          (runtime-coherence-sqlite-run
           sql
           :db-path db-path
           :sqlite-program sqlite-program)))))

(defun persist-runtime-coherence-report
    (report &key repair-action
                 (db-path (default-runtime-coherence-sqlite-path))
                 (sqlite-program "sqlite3"))
  (let ((results nil))
    (dolist (chunk (runtime-coherence-report-chunks-of report))
      (multiple-value-bind (output status detail)
          (persist-runtime-coherence-event
           chunk
           :report-title (runtime-coherence-report-title-of report)
           :repair-action repair-action
           :db-path db-path
           :sqlite-program sqlite-program)
        (push (list :chunk-id (coherence-chunk-id-of chunk)
                    :status status
                    :detail detail
                    :output output)
              results)))
    (nreverse results)))

(defun runtime-coherence-current-chunk-map (report)
  (mapcar (lambda (chunk)
            (cons (coherence-chunk-id-of chunk) chunk))
          (runtime-coherence-report-chunks-of report)))

(defun runtime-coherence-stale-chunks (report)
  (remove-if-not
   (lambda (chunk)
     (or (coherence-chunk-status-blocking-p
          (coherence-chunk-status-of chunk))
         (member (coherence-chunk-status-of chunk)
                 '(:degraded :optional-unavailable)
                 :test #'eq)))
   (runtime-coherence-report-chunks-of report)))

(defun runtime-coherence-selected-asdf-source-files
    (&optional (system-names '(:s-graphviz
                               :clog-ace
                               :html-inspector-views/standard
                               :clog-moldable-inspector)))
  (mapcar (lambda (system-name)
            (let ((evidence
                    (asdf-system-source-authority-evidence system-name)))
              (list :system-name system-name
                    :found (getf evidence :found)
                    :source-file (getf evidence :source-file)
                    :source-directory (getf evidence :source-directory)
                    :source-authority
                    (getf evidence :source-authority))))
          system-names))

(defun runtime-coherence-source-registry-diff (report)
  (let ((current
          (find "current-image-cl-source-registry"
                (runtime-coherence-report-chunks-of report)
                :key #'coherence-chunk-id-of
                :test #'string=))
        (foreign
          (find "foreign-asdf-source-registry-contaminants"
                (runtime-coherence-report-chunks-of report)
                :key #'coherence-chunk-id-of
                :test #'string=)))
    (list :current-cl-source-registry
          (and current
               (getf (coherence-chunk-value-of current)
                     :cl-source-registry))
          :entries
          (and current
               (getf (coherence-chunk-value-of current)
                     :entries))
          :foreign-contaminants
          (and foreign
               (getf (coherence-chunk-value-of foreign)
                     :foreign)))))

(defun runtime-coherence-restart-repair-recommendation (report)
  (let ((blocking (runtime-coherence-blocking-chunks
                   (runtime-coherence-report-chunks-of report))))
    (cond
      ((null blocking)
       :ok)
      ((some (lambda (chunk)
               (eq (coherence-chunk-status-of chunk)
                   :foreign-contaminant))
             blocking)
       :repair-source-registry-before-restart)
      ((some (lambda (chunk)
               (eq (coherence-chunk-status-of chunk)
                   :asdf-subsystem-not-visible))
             blocking)
       :derive-asdf-visibility-or-re-enter-dev-shell)
      (t
       :inspect-blocking-chunks))))

(defun runtime-coherence-find-chunk (id report-or-chunks)
  (find id
        (etypecase report-or-chunks
          (runtime-coherence-report
           (runtime-coherence-report-chunks-of report-or-chunks))
          (list report-or-chunks))
        :key #'coherence-chunk-id-of
        :test #'string=))

(defun source-registry-forms-from-entries (entries)
  (append
   (list :source-registry)
   (loop for entry in entries
         for pathname = (cl-source-registry-entry-pathname entry)
         when pathname
           collect (list :tree pathname))
   (list :ignore-inherited-configuration)))

(defun initialize-asdf-source-registry-from-entries (entries)
  (handler-case
      (progn
        (asdf:initialize-source-registry
         (source-registry-forms-from-entries entries))
        (values t nil))
    (condition (condition)
      (values nil condition))))

(defun runtime-coherence-repair-action-chunk
    (&key id title
          (status :unknown)
          basis
          value
          evidence
          last-error
          repair-options
          depends-on)
  (make-coherence-chunk
   :id id
   :title title
   :kind :repair-action
   :status status
   :basis basis
   :value value
   :evidence evidence
   :last-error last-error
   :repair-options repair-options
   :depends-on depends-on))

(defun import-dev-shell-source-registry
    (hyperdoc-root attached-image
     &key (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
          (mutate t))
  (let* ((entries
           (dev-shell-source-registry-entries
            :registry registry
            :hyperdoc-root hyperdoc-root))
         (source-registry
           (join-source-registry-entries entries))
         (env-evidence nil)
         (initialize-success nil)
         (initialize-condition nil))
    (cond
      ((null entries)
       (runtime-coherence-repair-action-chunk
        :id "import-dev-shell-source-registry"
        :title "Import dev-shell source registry"
        :status :blocked
        :basis (list :hyperdoc-root hyperdoc-root
                     :attached-image attached-image)
        :value (list :imported nil)
        :evidence
        (list (list :message
                    "Could not derive a non-empty repo/Nix source registry to import."))
        :repair-options '(:re-enter-nix-develop-as-fallback)))
      ((not mutate)
       (runtime-coherence-repair-action-chunk
        :id "import-dev-shell-source-registry"
        :title "Import dev-shell source registry"
        :status :planned
        :basis (list :hyperdoc-root hyperdoc-root
                     :attached-image attached-image)
        :value (list :imported nil
                     :planned-cl-source-registry source-registry
                     :entries entries)
        :evidence
        (list (list :mutation-performed nil)
              (list :planned-cl-source-registry source-registry))))
      (t
       (setf env-evidence
             (environment-mutation-evidence
              "CL_SOURCE_REGISTRY"
              source-registry))
       (multiple-value-setq (initialize-success initialize-condition)
         (initialize-asdf-source-registry-from-entries entries))
       (runtime-coherence-repair-action-chunk
        :id "import-dev-shell-source-registry"
        :title "Import dev-shell source registry"
        :status (if (and (getf env-evidence :set)
                         initialize-success)
                    :good
                    :failed)
        :basis (list :hyperdoc-root hyperdoc-root
                     :attached-image attached-image)
        :value (list :imported (and (getf env-evidence :set)
                                    initialize-success)
                     :cl-source-registry source-registry
                     :entries entries)
        :evidence
        (list (list :env-mutation env-evidence)
              (list :asdf-initialize-source-registry
                    :success initialize-success
                    :condition (and initialize-condition
                                    (condition-evidence
                                     initialize-condition))))
        :last-error (or (getf env-evidence :condition)
                        initialize-condition)
        :repair-options
        (unless (and (getf env-evidence :set)
                     initialize-success)
          '(:inspect-process-environment
            :re-enter-nix-develop-as-fallback)))))))

(defun clear-asdf-source-registry-cache
    (attached-image &key (mutate t))
  (let* ((package (find-package "ASDF"))
         (symbol (and package
                      (find-symbol "CLEAR-SOURCE-REGISTRY" package)))
         (fbound (and symbol
                      (fboundp symbol)))
         (condition nil)
         (called nil))
    (cond
      ((not mutate)
       (runtime-coherence-repair-action-chunk
        :id "clear-asdf-source-registry-cache"
        :title "Clear ASDF source-registry cache"
        :status :planned
        :basis (list :attached-image attached-image)
        :value (list :called nil
                     :function-present fbound)
        :evidence (list (list :mutation-performed nil
                              :function-present fbound))))
      ((not fbound)
       (runtime-coherence-repair-action-chunk
        :id "clear-asdf-source-registry-cache"
        :title "Clear ASDF source-registry cache"
        :status :blocked
        :basis (list :attached-image attached-image)
        :value (list :called nil
                     :function-present nil)
        :evidence
        (list (list :package-present (not (null package))
                    :symbol symbol
                    :fbound fbound
                    :message
                    "ASDF does not expose CLEAR-SOURCE-REGISTRY in this image."))
        :repair-options '(:initialize-source-registry-explicitly)))
      (t
       (handler-case
           (progn
             (funcall (symbol-function symbol))
             (setf called t))
         (condition (caught)
           (setf condition caught)))
       (runtime-coherence-repair-action-chunk
        :id "clear-asdf-source-registry-cache"
        :title "Clear ASDF source-registry cache"
        :status (if (and called (null condition))
                    :good
                    :failed)
        :basis (list :attached-image attached-image)
        :value (list :called called
                     :function-present fbound)
        :evidence
        (list (list :function symbol
                    :called called
                    :condition (and condition
                                    (condition-evidence condition))))
        :last-error condition
        :repair-options
        (when condition
          '(:initialize-source-registry-explicitly)))))))

(defun quarantine-foreign-asdf-source-contaminants
    (attached-image &key
                      (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
                      (repo-root (hyperdoc-repo-root-pathname))
                      (mutate t)
                      (initialize-asdf t))
  (let* ((entries (cl-source-registry-entries registry))
         (entry-evidence
           (mapcar (lambda (entry)
                     (cl-source-registry-entry-evidence
                      entry
                      :repo-root repo-root))
                   entries))
         (foreign
           (remove-if-not
            (lambda (entry)
              (eq (getf entry :authority)
                  :foreign-contaminant))
            entry-evidence))
         (kept
           (loop for entry in entries
                 for evidence in entry-evidence
                 unless (eq (getf evidence :authority)
                            :foreign-contaminant)
                   collect entry))
         (sanitized (join-source-registry-entries kept))
         (env-evidence nil)
         (initialize-success nil)
         (initialize-condition nil))
    (cond
      ((null foreign)
       (runtime-coherence-repair-action-chunk
        :id "quarantine-foreign-asdf-source-contaminants"
        :title "Quarantine foreign ASDF source contaminants"
        :status :good
        :basis (list :attached-image attached-image
                     :repo-root repo-root)
        :value (list :foreign-count 0
                     :cl-source-registry registry)
        :evidence (list (list :foreign-contaminants nil
                              :message
                              "No foreign source-registry contaminants were present."))))
      ((not mutate)
       (runtime-coherence-repair-action-chunk
        :id "quarantine-foreign-asdf-source-contaminants"
        :title "Quarantine foreign ASDF source contaminants"
        :status :planned
        :basis (list :attached-image attached-image
                     :repo-root repo-root)
        :value (list :foreign-count (length foreign)
                     :sanitized-cl-source-registry sanitized)
        :evidence
        (list (list :mutation-performed nil)
              (list :foreign-contaminants foreign)
              (list :kept-entries kept))))
      (t
       (setf env-evidence
             (environment-mutation-evidence
              "CL_SOURCE_REGISTRY"
              sanitized))
       (when initialize-asdf
         (multiple-value-setq (initialize-success initialize-condition)
           (initialize-asdf-source-registry-from-entries kept)))
       (runtime-coherence-repair-action-chunk
        :id "quarantine-foreign-asdf-source-contaminants"
        :title "Quarantine foreign ASDF source contaminants"
        :status (if (and (getf env-evidence :set)
                         (or (not initialize-asdf)
                             initialize-success))
                    :good
                    :failed)
        :basis (list :attached-image attached-image
                     :repo-root repo-root)
        :value (list :foreign-count (length foreign)
                     :sanitized-cl-source-registry sanitized
                     :foreign-contaminants foreign)
        :evidence
        (list (list :foreign-contaminants foreign)
              (list :kept-entries kept)
              (list :env-mutation env-evidence)
              (list :asdf-initialize-source-registry
                    :attempted initialize-asdf
                    :success initialize-success
                    :condition (and initialize-condition
                                    (condition-evidence
                                     initialize-condition))))
        :last-error (or (getf env-evidence :condition)
                        initialize-condition)
        :repair-options
        (unless (and (getf env-evidence :set)
                     (or (not initialize-asdf)
                         initialize-success))
          '(:import-dev-shell-source-registry
            :re-enter-nix-develop-as-fallback)))))))

(defun asdf-load-asd-attempt-record
    (asd-path &key (mutate t) phase)
  (let ((exists (pathname-exists-p asd-path))
        (error-condition nil)
        (observed-conditions nil)
        (loaded nil)
        (called nil))
    (when (and mutate exists)
      (setf called t)
      (handler-bind
          ((condition
             (lambda (caught)
               (push caught observed-conditions))))
        (handler-case
            (progn
              (asdf:load-asd asd-path)
              (setf loaded t))
          (error (caught)
            (setf error-condition caught)))))
    (values
     (list :asd-path asd-path
           :phase phase
           :exists exists
           :load-asd-called called
           :load-asd-succeeded loaded
           :conditions
           (mapcar #'condition-evidence
                   (nreverse observed-conditions))
           :condition (and error-condition
                           (condition-evidence error-condition)))
     error-condition)))

(defun asdf-load-asd-attempt-records
    (asd-paths &key (mutate t) stop-after-success)
  (let ((records nil)
        (conditions nil)
        (loaded nil))
    (dolist (asd-path asd-paths)
      (if (and stop-after-success loaded)
          (push (list :asd-path asd-path
                      :exists (pathname-exists-p asd-path)
                      :load-asd-called nil
                      :load-asd-succeeded nil
                      :skipped-after-success t)
                records)
          (multiple-value-bind (record condition)
              (asdf-load-asd-attempt-record
               asd-path
               :mutate mutate)
            (when condition
              (push condition conditions))
            (when (getf record :load-asd-succeeded)
              (setf loaded t))
            (push record records))))
    (values (nreverse records)
            loaded
            (nreverse conditions))))

(defun pathname-parent-directory (pathname)
  (and pathname
       (handler-case
           (uiop:pathname-directory-pathname pathname)
         (condition ()
           nil))))

(defun reload-selected-asd-definitions
    (attached-image systems &key
                              (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
                              (repo-root (hyperdoc-repo-root-pathname))
                              (mutate t)
                              (max-depth 2))
  (let ((records nil)
        (conditions nil))
    (dolist (system systems)
      (let* ((before (asdf-system-source-authority-evidence
                      system
                      :repo-root repo-root))
             (already-found (getf before :found))
             (discovery
               (asdf-definition-discovery
                system
                :registry registry
                :repo-root repo-root
                :max-depth max-depth))
             (candidates
               (unless already-found
                 (getf discovery :candidate-asd-files)))
             (attempt-records nil)
             (loaded nil)
             (load-conditions nil))
        (unless already-found
          (multiple-value-setq
              (attempt-records loaded load-conditions)
            (asdf-load-asd-attempt-records
             candidates
             :mutate mutate
             :stop-after-success t))
          (setf conditions (append load-conditions conditions)))
        (push (list :system-name system
                    :expected-asd-filename
                    (getf discovery :expected-asd-filename)
                    :current-image-lookup before
                    :already-found already-found
                    :definition-discovery discovery
                    :candidate-asd-files candidates
                    :mutation-performed (and mutate
                                             (not already-found)
                                             (not (null candidates)))
                    :load-asd-attempts attempt-records
                    :load-asd-called
                    (some (lambda (record)
                            (getf record :load-asd-called))
                          attempt-records)
                    :loaded loaded
                    :conditions (mapcar #'condition-evidence
                                        load-conditions))
              records)))
    (let* ((ordered-records (nreverse records))
           (missing-candidates
             (remove-if (lambda (record)
                          (or (getf record :already-found)
                              (getf record :candidate-asd-files)))
                        ordered-records))
           (loaded-or-already
             (every (lambda (record)
                      (or (getf record :already-found)
                          (getf record :loaded)))
                    ordered-records))
           (status
             (cond
               ((not mutate) :planned)
               ((and conditions
                     (not loaded-or-already))
                :failed)
               (missing-candidates :blocked)
               (loaded-or-already :good)
               (t :stale))))
      (runtime-coherence-repair-action-chunk
       :id "reload-selected-asd-definitions"
       :title "Reload selected ASD definitions"
       :status status
       :basis (list :attached-image attached-image
                    :systems systems
                    :source-registry registry
                    :repo-root repo-root)
       :value (list :systems systems
                    :records ordered-records
                    :missing-candidates missing-candidates)
       :evidence
       (list (list :records ordered-records)
             (list :load-system-called nil)
             (list :message
                   "This repair action reloads selected .asd definitions only; it does not call ASDF:LOAD-SYSTEM."))
       :last-error (first conditions)
       :repair-options
       (when (or conditions missing-candidates)
         '(:import-dev-shell-source-registry
           :inspect-selected-asdf-source-files
           :re-enter-nix-develop-as-fallback))))))

(defun runtime-coherence-system-repair-action-id (prefix system-name)
  (format nil "~A-~A"
          prefix
          (with-output-to-string (stream)
            (loop for char across (string-downcase (string system-name))
                  do (write-char (if (find char "/:"
                                           :test #'char=)
                                     #\-
                                     char)
                                 stream)))))

(defun asdf-find-system-probe-record
    (system-name &key (repo-root (hyperdoc-repo-root-pathname)))
  (multiple-value-bind (evidence condition)
      (asdf-system-source-authority-evidence
       system-name
       :repo-root repo-root)
    (append evidence
            (list :condition (and condition
                                  (condition-evidence condition))))))

(defun asdf-central-registry-matching-entries
    (&optional (needles '("graphviz" "s-graphviz")))
  (loop for entry in asdf:*central-registry*
        for namestring = (safe-namestring entry)
        when (and namestring
                  (some (lambda (needle)
                          (search needle namestring
                                  :test #'char-equal))
                        needles))
          collect (list :entry entry
                        :namestring namestring
                        :exists (or (directory-exists-p entry)
                                    (pathname-exists-p entry)))))

(defun push-asd-parent-into-central-registry
    (asd-path &key (mutate t))
  (let ((parent (pathname-parent-directory asd-path)))
    (cond
      ((not parent)
       (list :asd-path asd-path
             :parent-directory nil
             :pushed nil
             :condition
             (list :message "Could not derive an ASD parent directory.")))
      ((not mutate)
       (list :asd-path asd-path
             :parent-directory parent
             :pushed nil
             :planned t
             :already-present
             (member parent asdf:*central-registry* :test #'equal)))
      (t
       (let ((already-present
               (member parent asdf:*central-registry* :test #'equal)))
         (unless already-present
           (push parent asdf:*central-registry*))
         (list :asd-path asd-path
               :parent-directory parent
               :pushed (not already-present)
               :already-present already-present
               :central-registry-size
               (length asdf:*central-registry*)))))))

(defun clear-asdf-system-cache-record
    (system-name &key (mutate t))
  (let* ((package (find-package "ASDF"))
         (symbol (and package
                      (find-symbol "CLEAR-SYSTEM" package)))
         (fbound (and symbol
                      (fboundp symbol)))
         (condition nil)
         (called nil))
    (when (and mutate fbound)
      (handler-case
          (progn
            (funcall (symbol-function symbol) system-name)
            (setf called t))
        (condition (caught)
          (setf condition caught))))
    (values
     (list :system-name system-name
           :function-present fbound
           :called called
           :planned (and (not mutate) fbound)
           :condition (and condition
                           (condition-evidence condition)))
     condition)))

(defun derive-asdf-system-visibility
    (attached-image system-name &key
                                (registry (uiop:getenv "CL_SOURCE_REGISTRY"))
                                (repo-root (hyperdoc-repo-root-pathname))
                                (mutate t))
  (let* ((current-registry registry)
         (dev-shell-discovery
           (dev-shell-asdf-definition-discovery
            system-name
            :registry current-registry
            :repo-root repo-root))
         (imported-dev-shell-registry
           (getf dev-shell-discovery :source-registry))
         (dev-shell-candidates
           (getf dev-shell-discovery :candidate-asd-files))
         (before-lookup
           (asdf-find-system-probe-record
            system-name
            :repo-root repo-root))
         (central-registry-before
           (asdf-central-registry-matching-entries))
         (load-attempts nil)
         (central-registry-actions nil)
         (clear-cache-records nil)
         (clear-cache-conditions nil)
         (load-conditions nil))
    (unless (getf before-lookup :found)
      (dolist (candidate dev-shell-candidates)
        (multiple-value-bind (attempt condition)
            (asdf-load-asd-attempt-record
             candidate
             :mutate mutate
             :phase :before-cache-clear)
          (push attempt load-attempts)
          (when condition
            (push condition load-conditions)))
        (push (push-asd-parent-into-central-registry
               candidate
               :mutate mutate)
              central-registry-actions)
        (multiple-value-bind (clear-record clear-condition)
            (clear-asdf-system-cache-record
             system-name
             :mutate mutate)
          (push clear-record clear-cache-records)
          (when clear-condition
            (push clear-condition clear-cache-conditions)))
        (when (and mutate
                   (not (getf (asdf-find-system-probe-record
                               system-name
                               :repo-root repo-root)
                              :found)))
          (multiple-value-bind (attempt condition)
              (asdf-load-asd-attempt-record
               candidate
               :mutate mutate
               :phase :after-cache-clear)
            (push attempt load-attempts)
            (when condition
              (push condition load-conditions))))
        (when (and mutate
                   (getf (asdf-find-system-probe-record
                          system-name
                          :repo-root repo-root)
                         :found))
          (return))))
    (let* ((after-lookup
             (asdf-find-system-probe-record
              system-name
              :repo-root repo-root))
           (visibility
             (asdf-visible system-name
                           :repo-root repo-root
                           :requiredp t))
           (central-registry-after
             (asdf-central-registry-matching-entries))
           (status
             (cond
               ((getf after-lookup :found)
                :good)
               ((not dev-shell-candidates)
                :dev-shell-asdf-system-not-visible)
               ((not mutate)
                :planned)
               ((or load-conditions clear-cache-conditions)
                :failed)
               (t
                (coherence-chunk-status-of visibility)))))
    (runtime-coherence-repair-action-chunk
     :id (runtime-coherence-system-repair-action-id
          "derive-asdf-system-visibility"
          system-name)
     :title (format nil "Derive ASDF visibility for ~A" system-name)
     :status status
     :basis (list :attached-image attached-image
                  :system-name system-name
                  :current-cl-source-registry current-registry
                  :imported-dev-shell-cl-source-registry
                  imported-dev-shell-registry)
     :value (list :system-name system-name
                  :current-image-found-before
                  (getf before-lookup :found)
                  :current-image-found-after
                  (getf after-lookup :found)
                  :dev-shell-candidate-asd-files
                  dev-shell-candidates
                  :visibility-status
                  (coherence-chunk-status-of visibility))
     :evidence
     (list (list :current-image-asdf-find-system-before
                 before-lookup)
           (list :dev-shell-discovery-result
                 dev-shell-discovery)
           (list :current-cl-source-registry
                 current-registry)
           (list :imported-dev-shell-cl-source-registry
                 imported-dev-shell-registry)
           (list :central-registry-before-graphviz-entries
                 central-registry-before)
           (list :direct-asd-load-attempts
                 (nreverse load-attempts))
           (list :central-registry-actions
                 (nreverse central-registry-actions))
           (list :clear-asdf-system-cache
                 (nreverse clear-cache-records))
           (list :current-image-asdf-find-system-after
                 after-lookup)
           (list :central-registry-after-graphviz-entries
                 central-registry-after)
           (list :asdf-visibility
                 :status (coherence-chunk-status-of visibility)
                 :value (coherence-chunk-value-of visibility)
                 :evidence (coherence-chunk-evidence-of visibility)))
     :last-error (or (first load-conditions)
                     (first clear-cache-conditions)
                     (coherence-chunk-last-error-of visibility))
     :repair-options
     (unless (eq status :good)
       (case status
         (:dev-shell-asdf-system-not-visible
          '(:inspect-dev-shell-source-registry
            :verify-nix-dev-shell-contains-system
            :re-enter-nix-develop-as-fallback))
         (otherwise
          '(:inspect-asdf-definition-candidates
            :import-dev-shell-source-registry
            :re-enter-nix-develop-as-fallback))))))))

(defun ensure-running-image-coherent
    (&key (profile :clog-moldable-inspector)
          (persist-events t)
          (db-path (default-runtime-coherence-sqlite-path))
          (sqlite-program "sqlite3"))
  (let ((report (coherence-report profile)))
    (when persist-events
      (persist-runtime-coherence-report
       report
       :repair-action "ensure-running-image-coherent"
       :db-path db-path
       :sqlite-program sqlite-program))
    report))

(defun runtime-coherence-report-with-extra-chunk (report chunk)
  (let ((chunks (append (runtime-coherence-report-chunks-of report)
                        (list chunk))))
    (make-runtime-coherence-report
     :title (runtime-coherence-report-title-of report)
     :observed-at (runtime-coherence-report-observed-at-of report)
     :chunks chunks
     :summary (runtime-coherence-default-summary chunks))))

(defun runtime-coherence-report-repaired-p (report)
  (null (runtime-coherence-blocking-chunks
         (runtime-coherence-report-chunks-of report))))

(defun runtime-coherence-persist-action-chunk
    (chunk action-name &key
                  (db-path (default-runtime-coherence-sqlite-path))
                  (sqlite-program "sqlite3"))
  (persist-runtime-coherence-event
   chunk
   :report-title "Running image coherence repair"
   :repair-action action-name
   :db-path db-path
   :sqlite-program sqlite-program))

(defun repair-running-image-coherence
    (&key (profile :clog-moldable-inspector)
          (hyperdoc-root (hyperdoc-repo-root-pathname))
          (attached-image :current)
          (systems '(:s-graphviz
                     :clog-ace
                     :html-inspector-views/standard
                     :clog-moldable-inspector))
          (mutate t)
          (persist-events t)
          (db-path (default-runtime-coherence-sqlite-path))
          (sqlite-program "sqlite3"))
  "Derive or plan repairs for PROFILE in the current running Lisp image.

This function does not call ASDF:LOAD-SYSTEM.  Mutating steps are explicit
repair actions on the attached image: source-registry import/quarantine,
ASDF source-registry cache clearing, and selected ASD definition reload."
  (let ((initial-report
          (ensure-running-image-coherent
           :profile profile
           :persist-events persist-events
           :db-path db-path
           :sqlite-program sqlite-program))
        (actions nil))
    (labels ((record (chunk action-name)
               (push chunk actions)
               (when persist-events
                 (runtime-coherence-persist-action-chunk
                  chunk
                  action-name
                  :db-path db-path
                  :sqlite-program sqlite-program))
               chunk))
      (record
       (quarantine-foreign-asdf-source-contaminants
        attached-image
        :repo-root hyperdoc-root
        :mutate mutate)
       "quarantine-foreign-asdf-source-contaminants")
      (record
       (import-dev-shell-source-registry
        hyperdoc-root
        attached-image
        :mutate mutate)
       "import-dev-shell-source-registry")
      (record
       (clear-asdf-source-registry-cache
        attached-image
        :mutate mutate)
       "clear-asdf-source-registry-cache")
      (record
       (reload-selected-asd-definitions
        attached-image
        systems
        :repo-root hyperdoc-root
        :mutate mutate)
       "reload-selected-asd-definitions")
      (dolist (system '(:s-graphviz :clog-ace))
        (record
         (derive-asdf-system-visibility
          attached-image
          system
          :repo-root hyperdoc-root
          :mutate mutate)
         (format nil "derive-asdf-system-visibility ~A" system)))
      (let* ((final-report
               (ensure-running-image-coherent
                :profile profile
                :persist-events persist-events
                :db-path db-path
                :sqlite-program sqlite-program))
             (repaired-p
               (runtime-coherence-report-repaired-p final-report))
             (ordered-actions (nreverse actions))
             (plan
               (make-runtime-coherence-repair-plan
                :profile profile
                :initial-report initial-report
                :actions ordered-actions
                :final-report final-report
                :repaired-p repaired-p
                :summary (list :profile profile
                               :mutated mutate
                               :repaired-p repaired-p
                               :actions
                               (mapcar
                                (lambda (chunk)
                                  (list :id (coherence-chunk-id-of chunk)
                                        :status
                                        (coherence-chunk-status-of chunk)))
                                ordered-actions)
                               :final-summary
                               (runtime-coherence-report-summary-of
                                final-report)))))
        (values repaired-p
                final-report
                plan)))))

(defun explain-asdf-visibility
    (system-name &key
                   (profile :clog-moldable-inspector)
                   (hyperdoc-root (hyperdoc-repo-root-pathname))
                   (attached-image :current)
                   (mutate nil)
                   (persist-events nil)
                   (db-path (default-runtime-coherence-sqlite-path))
                   (sqlite-program "sqlite3"))
  "Return an inspectable report explaining ASDF visibility for SYSTEM-NAME.

By default this is diagnostic-only.  It records the current image lookup,
repo/Nix dev-shell discovery, source-registry differences, direct ASD repair
attempts, and condition trail without calling ASDF:LOAD-SYSTEM."
  (let* ((expected
           (expected-dev-shell-source-registry
            :repo-root hyperdoc-root))
         (current
           (current-image-source-registry))
         (equivalence
           (source-registry-equivalent-to-dev-shell
            :repo-root hyperdoc-root))
         (foreign
           (foreign-asdf-source-contaminants
            :repo-root hyperdoc-root))
         (visibility
           (asdf-visible system-name
                         :repo-root hyperdoc-root
                         :requiredp t))
         (derivation
           (derive-asdf-system-visibility
            attached-image
            system-name
            :repo-root hyperdoc-root
            :mutate mutate))
         (chunks
           (list expected
                 current
                 equivalence
                 foreign
                 visibility
                 derivation))
         (report
           (make-runtime-coherence-report
            :title (format nil "~A ASDF visibility explanation"
                           system-name)
            :chunks chunks
            :summary
            (append (runtime-coherence-default-summary chunks)
                    (list :profile profile
                          :system-name system-name
                          :mutated mutate
                          :attempted-repair-action
                          (coherence-chunk-id-of derivation))))))
    (when persist-events
      (persist-runtime-coherence-report
       report
       :repair-action "explain-asdf-visibility"
       :db-path db-path
       :sqlite-program sqlite-program))
    report))

(defun load-coherent-system
    (system-name &key (profile system-name)
                      force
                      (persist-events t)
                      (db-path (default-runtime-coherence-sqlite-path))
                      (sqlite-program "sqlite3"))
  (let* ((report (ensure-running-image-coherent
                  :profile profile
                  :persist-events persist-events
                  :db-path db-path
                  :sqlite-program sqlite-program))
         (blocking (runtime-coherence-blocking-chunks
                    (runtime-coherence-report-chunks-of report))))
    (cond
      ((and blocking
            (not force))
       (let* ((gate
                (make-coherence-chunk
                 :id "load-coherent-system-gate"
                 :title "Coherent ASDF load gate"
                 :kind :coherence-gate
                 :status :refused
                 :basis (list :system-name system-name
                              :profile profile)
                 :value (list :load-system-called nil
                              :blocking-chunks
                              (mapcar #'coherence-chunk-id-of blocking))
                 :evidence
                 (list
                  (list :system-name system-name
                        :profile profile
                        :load-system-called nil)
                  (list :blocking-chunks
                        (mapcar (lambda (chunk)
                                  (list :id (coherence-chunk-id-of chunk)
                                        :status
                                        (coherence-chunk-status-of chunk)))
                                blocking))
                  (list :message
                        "ASDF load was refused because the running image has incoherent profile chunks."))
                 :repair-options
                 '(:inspect-blocking-chunks
                   :repair-asdf-visibility
                   :remove-foreign-source-registry-contaminants)))
              (refused-report
                (runtime-coherence-report-with-extra-chunk report gate)))
         (when persist-events
           (persist-runtime-coherence-report
            refused-report
            :repair-action "load-coherent-system-refused"
            :db-path db-path
            :sqlite-program sqlite-program))
         (values nil refused-report)))
      (t
       (handler-case
           (let* ((loaded (asdf:load-system system-name))
                  (gate
                    (make-coherence-chunk
                     :id "load-coherent-system-gate"
                     :title "Coherent ASDF load gate"
                     :kind :coherence-gate
                     :status (if loaded :good :unknown)
                     :basis (list :system-name system-name
                                  :profile profile
                                  :force force)
                     :value (list :load-system-called t
                                  :loaded loaded)
                     :evidence
                     (list (list :system-name system-name
                                 :profile profile
                                 :load-system-called t
                                 :loaded loaded)))))
             (let ((loaded-report
                     (runtime-coherence-report-with-extra-chunk
                      report
                      gate)))
               (when persist-events
                 (persist-runtime-coherence-report
                  loaded-report
                  :repair-action "load-coherent-system-loaded"
                  :db-path db-path
                  :sqlite-program sqlite-program))
               (values loaded loaded-report)))
         (condition (condition)
           (let* ((gate
                    (make-coherence-chunk
                     :id "load-coherent-system-gate"
                     :title "Coherent ASDF load gate"
                     :kind :coherence-gate
                     :status :failed
                     :basis (list :system-name system-name
                                  :profile profile
                                  :force force)
                     :value (list :load-system-called t
                                  :loaded nil)
                     :evidence
                     (list (list :system-name system-name
                                 :profile profile
                                 :load-system-called t
                                 :loaded nil)
                           (condition-evidence condition))
                     :last-error condition
                     :repair-options
                     '(:inspect-asdf-load-condition
                       :repair-running-image-coherence)))
                  (failed-report
                    (runtime-coherence-report-with-extra-chunk
                     report
                     gate)))
             (when persist-events
               (persist-runtime-coherence-report
                failed-report
                :repair-action "load-coherent-system-failed"
                :db-path db-path
                :sqlite-program sqlite-program))
             (values nil failed-report))))))))

(defun make-html-inspector-views-environment-coherence-report
    (&key (title "HTML inspector views environment coherence report")
          (observed-at (get-universal-time))
          (html-inspector-views-src (uiop:getenv "HTML_INSPECTOR_VIEWS_SRC"))
          (html-inspector-views-asd (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD")))
  (let ((chunk
          (html-inspector-views-environment-chunk
           :html-inspector-views-src html-inspector-views-src
           :html-inspector-views-asd html-inspector-views-asd)))
    (make-runtime-coherence-report
     :title title
     :observed-at observed-at
     :chunks (list chunk))))

(defun make-html-inspector-views-asdf-visibility-coherence-report
    (&key (title "HTML inspector views ASDF visibility coherence report")
          (observed-at (get-universal-time))
          (base-package-name "HTML-INSPECTOR-VIEWS")
          (standard-package-name "HTML-INSPECTOR-VIEWS/STANDARD")
          (base-system-name :html-inspector-views)
          (standard-system-name :html-inspector-views/standard)
          (html-inspector-views-src (uiop:getenv "HTML_INSPECTOR_VIEWS_SRC"))
          (html-inspector-views-asd (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD"))
          (cl-source-registry (uiop:getenv "CL_SOURCE_REGISTRY")))
  (make-runtime-coherence-report
   :title title
   :observed-at observed-at
   :chunks
   (list
    (html-inspector-views-asdf-visibility-chunk
     :base-package-name base-package-name
     :standard-package-name standard-package-name
     :base-system-name base-system-name
     :standard-system-name standard-system-name
     :html-inspector-views-src html-inspector-views-src
     :html-inspector-views-asd html-inspector-views-asd
     :cl-source-registry cl-source-registry))))

(defun make-html-inspector-views-live-method-coherence-report
    (&key (title "HTML inspector views live method coherence report")
          (observed-at (get-universal-time))
          (package-name (html-inspector-standard-package-name)))
  (make-runtime-coherence-report
   :title title
   :observed-at observed-at
   :chunks (list (html-inspector-views-live-method-chunk
                  :package-name package-name))))

(defun html-inspector-views-live-method-safe-call-evidence (chunk form)
  (find form
        (coherence-chunk-evidence-of chunk)
        :key (lambda (entry)
               (and (listp entry)
                    (getf entry :form)))
        :test #'equal))

(defun html-inspector-views-live-method-repair-chunk
    (&key (package-name (html-inspector-standard-package-name)))
  (handler-case
      (let* ((before (html-inspector-views-live-method-chunk
                      :package-name package-name))
             (before-status (coherence-chunk-status-of before))
             (before-value (coherence-chunk-value-of before))
             (depends-on-symbol (getf before-value :system-depends-on))
             (null-method-before (getf before-value :null-method-present))
             (installed nil)
             (install-condition nil)
             (repair-attempted nil))
        (cond
          ((member before-status
                   '(:missing-package :missing-generic-function)
                   :test #'eq)
           nil)
          ((not null-method-before)
           (setf repair-attempted t)
           (handler-case
               (progn
                 (eval
                  `(defmethod ,depends-on-symbol ((system null))
                     nil))
                 (setf installed t))
             (condition (condition)
               (setf install-condition condition)))))
        (let* ((after (html-inspector-views-live-method-chunk
                       :package-name package-name))
               (status
                 (cond
                   (install-condition
                    :failed-safe-call)
                   ((member before-status
                            '(:missing-package :missing-generic-function)
                            :test #'eq)
                    before-status)
                   (t
                    (coherence-chunk-status-of after)))))
          (make-coherence-chunk
           :id "html-inspector-views-standard-live-methods-repair"
           :title "HTML inspector standard live method repair"
           :kind :optional-inspector-view
           :status status
           :value (list :package-name package-name
                        :before-status before-status
                        :after-status (coherence-chunk-status-of after)
                        :system-depends-on depends-on-symbol
                        :null-method-present-before null-method-before
                        :null-method-installed installed
                        :null-method-present-after
                        (getf (coherence-chunk-value-of after)
                              :null-method-present))
           :evidence
           (list
            (list :phase :before
                  :package-present
                  (not (null (getf before-value :package)))
                  :generic-function-present
                  (not (null depends-on-symbol))
                  :null-method-present null-method-before
                  :status before-status)
            (list :phase :repair
                  :attempted repair-attempted
                  :null-method-installed installed
                  :condition (and install-condition
                                  (condition-evidence install-condition)))
            (list :phase :after
                  :package-present
                  (not (null (getf (coherence-chunk-value-of after)
                                   :package)))
                  :generic-function-present
                  (not (null (getf (coherence-chunk-value-of after)
                                   :system-depends-on)))
                  :null-method-present
                  (getf (coherence-chunk-value-of after)
                        :null-method-present)
                  :status (coherence-chunk-status-of after)
                  :system-depends-on-call
                  (html-inspector-views-live-method-safe-call-evidence
                   after
                   '(system-depends-on nil))
                  :system-dependencies-call
                  (html-inspector-views-live-method-safe-call-evidence
                   after
                   '(system-dependencies nil))))
           :last-error (or install-condition
                           (coherence-chunk-last-error-of after)
                           (coherence-chunk-last-error-of before))
           :repair-options
           (when (member status
                         '(:missing-null-method :failed-safe-call)
                         :test #'eq)
             '(:repair-html-inspector-views-standard-live-methods))
           :depends-on '("html-inspector-views-standard-live-methods"))))
    (condition (condition)
      (make-coherence-chunk
       :id "html-inspector-views-standard-live-methods-repair"
       :title "HTML inspector standard live method repair"
       :kind :optional-inspector-view
       :status :failed-safe-call
       :evidence (list (condition-evidence condition))
       :last-error condition
       :repair-options '(:repair-html-inspector-views-standard-live-methods)
       :depends-on '("html-inspector-views-standard-live-methods")))))

(defun repair-html-inspector-views-standard-live-methods
    (&key (title "HTML inspector views live method repair report")
          (observed-at (get-universal-time))
          (package-name (html-inspector-standard-package-name)))
  (make-runtime-coherence-report
   :title title
   :observed-at observed-at
   :chunks (list (html-inspector-views-live-method-repair-chunk
                  :package-name package-name))))

(defun make-inspector-runtime-coherence-report (&key
                                                  (title "Inspector runtime coherence report")
                                                  (observed-at (get-universal-time)))
  (let* ((expected-registry
           (expected-dev-shell-cl-source-registry-chunk))
         (current-registry
           (current-image-cl-source-registry-chunk))
         (source-registry-equivalence
           (source-registry-equivalent-to-dev-shell))
         (foreign-contaminants
           (foreign-asdf-source-registry-contaminants-chunk))
         (clog-code-root (clog-asdf-code-root-chunk))
         (clog-static-root (clog-static-asset-root-chunk))
         (clog-inspector (clog-moldable-inspector-system-chunk))
         (html-environment
           (html-inspector-views-environment-chunk))
         (html-asdf-visibility
           (html-inspector-views-asdf-visibility-chunk))
         (html-base (html-inspector-base-system-chunk))
         (graphviz (s-graphviz-optional-capability-chunk))
         (html-standard
           (html-inspector-standard-view-chunk
            :s-graphviz-chunk graphviz))
         (html-standard-live-methods
           (html-inspector-views-live-method-chunk))
         (html-standard-cache
           (html-inspector-standard-dependency-cache-chunk))
         (profile-visibility
           (clog-moldable-inspector-profile-visibility-chunks))
         (without-readiness
           (append (list expected-registry
                         current-registry
                         source-registry-equivalence
                         foreign-contaminants
                         clog-code-root
                         clog-static-root
                         clog-inspector
                         html-environment
                         html-asdf-visibility
                         html-base
                         html-standard
                         html-standard-live-methods
                         html-standard-cache
                         graphviz)
                   profile-visibility))
         (readiness
           (clog-moldable-inspector-readiness-chunk without-readiness)))
    (make-runtime-coherence-report
     :title title
     :observed-at observed-at
     :chunks (append without-readiness
                     (list readiness)))))

(defun make-current-plan-browser-coherence-report (&key root-object
                                                        summary
                                                        checklist
                                                        projections
                                                        (title "Plan browser coherence report")
                                                        (observed-at (get-universal-time)))
  (let* ((support-report (make-inspector-runtime-coherence-report))
         (support-chunks
           (runtime-coherence-report-chunks-of support-report))
         (plan-chunks
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
                :evidence (list (list :object-type (type-of root-object))
                                (list :summary summary)
                                (list :checklist checklist))))
             (when projections
               (make-coherence-chunk
                :id "current-plan-projections"
                :title "Current plan projections"
                :kind :projection
                :status :good
                :value projections
                :evidence (list (list :projection-count
                                      (length projections))))))))
         (session-chunk
           (browser-inspection-session-chunk
            :root-object root-object
            :summary summary
            :checklist checklist
            :projections projections
            :support-chunks support-chunks))
         (chunks (append plan-chunks
                         support-chunks
                         (list session-chunk))))
    (make-runtime-coherence-report
     :title title
     :observed-at observed-at
     :chunks chunks
     :summary (runtime-coherence-default-summary chunks))))
