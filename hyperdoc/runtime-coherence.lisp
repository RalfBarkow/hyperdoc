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
         :status (if (eq (coherence-chunk-status-of base)
                         :optional-unavailable)
                     :optional-unavailable
                     :blocked)
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

(defun required-browser-inspection-support-chunk-p (chunk)
  (member (coherence-chunk-id-of chunk)
          '("clog-asdf-code-root"
            "clog-static-asset-root"
            "clog-moldable-inspector-system"
            "html-inspector-views-base-system")
          :test #'string=))

(defun degraded-optional-inspector-chunk-p (chunk)
  (and (eq (coherence-chunk-kind-of chunk)
           :optional-inspector-view)
       (member (coherence-chunk-status-of chunk)
               '(:optional-unavailable :blocked :failed :stale)
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

(defun make-inspector-runtime-coherence-report (&key
                                                  (title "Inspector runtime coherence report")
                                                  (observed-at (get-universal-time)))
  (let* ((clog-code-root (clog-asdf-code-root-chunk))
         (clog-static-root (clog-static-asset-root-chunk))
         (clog-inspector (clog-moldable-inspector-system-chunk))
         (html-base (html-inspector-base-system-chunk))
         (graphviz (s-graphviz-optional-capability-chunk))
         (html-standard
           (html-inspector-standard-view-chunk
            :s-graphviz-chunk graphviz))
         (html-standard-cache
           (html-inspector-standard-dependency-cache-chunk)))
    (make-runtime-coherence-report
     :title title
     :observed-at observed-at
     :chunks (list clog-code-root
                   clog-static-root
                   clog-inspector
                   html-base
                   html-standard
                   html-standard-cache
                   graphviz))))

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
