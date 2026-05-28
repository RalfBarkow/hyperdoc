;;;; Smoke tests for runtime coherence chunks.

(in-package :hyperdoc/tests)

(defun rc-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun rc-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S"
           message expected actual)))

(defun rc-find-chunk (id chunks)
  (find id chunks
        :key #'hyperdoc:coherence-chunk-id-of
        :test #'string=))

(defun rc-system-dependency-names (system-name)
  (mapcar (lambda (dependency)
            (string-downcase
             (etypecase dependency
               (symbol (symbol-name dependency))
               (string dependency))))
          (asdf:system-depends-on
           (asdf:find-system system-name))))

(defun rc-runtime-layer-does-not-depend-on-inspector-smoke-test ()
  (let ((dependencies (rc-system-dependency-names :hyperdoc)))
    (rc-assert-true
     (not (member "hyperdoc/inspector" dependencies :test #'string=))
     ":hyperdoc must not depend on :hyperdoc/inspector for runtime coherence")
    (rc-assert-true
     (not (member "hyperdoc/shop3" dependencies :test #'string=))
     ":hyperdoc must not depend on :hyperdoc/shop3 for runtime coherence"))
  (let ((report (hyperdoc:make-inspector-runtime-coherence-report)))
    (rc-assert-true
     (typep report 'hyperdoc:runtime-coherence-report)
     "Inspector runtime coherence report must be a plain report object"))
  t)

(defun rc-report-contains-runtime-support-chunks-smoke-test ()
  (let* ((report (hyperdoc:make-inspector-runtime-coherence-report))
         (chunks (hyperdoc:runtime-coherence-report-chunks-of report)))
    (dolist (id '("clog-asdf-code-root"
                  "clog-static-asset-root"
                  "clog-moldable-inspector-system"
                  "html-inspector-views-base-system"
                  "html-inspector-views-standard-view"
                  "html-inspector-views-standard-live-methods"
                  "html-inspector-views-standard-dependency-cache"
                  "s-graphviz-optional-capability"))
      (rc-assert-true
       (rc-find-chunk id chunks)
       (format nil "Report must include chunk ~A" id))))
  t)

(defun rc-loaded-symbol (package-designator symbol-name)
  (let ((package (find-package package-designator)))
    (when package
      (multiple-value-bind (symbol status)
          (find-symbol symbol-name package)
        (when (and status
                   (fboundp symbol))
          symbol)))))

(defun rc-required-loaded-symbol (package-designator symbol-name)
  (or (rc-loaded-symbol package-designator symbol-name)
      (error "Expected loaded symbol ~A::~A"
             package-designator
             symbol-name)))

(defun rc-make-temp-directory (label)
  (let ((directory
          (merge-pathnames
           (format nil "hyperdoc-runtime-coherence-~A-~A/"
                   label
                   (get-universal-time))
           (uiop:temporary-directory))))
    (ensure-directories-exist (merge-pathnames #P".keep" directory))
    directory))

(defun rc-temp-package-name (label)
  (format nil "HYPERDOC-RUNTIME-COHERENCE-~A-~A"
          label
          (gensym)))

(defun rc-delete-package-if-present (package-name)
  (let ((package (find-package package-name)))
    (when package
      (delete-package package))))

(defun rc-with-live-method-fixture (thunk)
  (let* ((package-name (rc-temp-package-name "LIVE-METHODS"))
         (package (make-package package-name :use '(:cl)))
         (depends-on (intern "SYSTEM-DEPENDS-ON" package))
         (dependencies (intern "SYSTEM-DEPENDENCIES" package)))
    (unwind-protect
         (progn
           (eval `(defgeneric ,depends-on (system)))
           (eval `(defmethod ,depends-on ((system string))
                    nil))
           (eval `(defun ,dependencies (system)
                    (loop for dependency in (,depends-on system)
                          collect dependency)))
           (funcall thunk package-name depends-on dependencies))
      (rc-delete-package-if-present package-name))))

(defun rc-classify-clog-src-no-asd-smoke-test ()
  (let ((directory (rc-make-temp-directory "no-asd")))
    (unwind-protect
         (multiple-value-bind (classification evidence)
             (hyperdoc:classify-clog-src directory)
           (declare (ignore evidence))
           (rc-assert-true
            (not (eq classification :asdf-root))
            "A path with no .asd file must not classify as :asdf-root"))
      (uiop:delete-directory-tree directory
                                  :validate t
                                  :if-does-not-exist :ignore)))
  t)

(defun rc-with-asdf-find-system-override (override thunk)
  (let ((original (symbol-function 'asdf:find-system)))
    (unwind-protect
         (progn
           (setf (symbol-function 'asdf:find-system)
                 (lambda (&rest args)
                   (multiple-value-bind (handledp value)
                       (apply override args)
                     (if handledp
                         value
                         (apply original args)))))
           (funcall thunk))
      (setf (symbol-function 'asdf:find-system) original))))

(defun rc-graphviz-missing-degrades-smoke-test ()
  (rc-with-asdf-find-system-override
   (lambda (system-name &rest args)
     (declare (ignore args))
     (when (string= (string-downcase (string system-name))
                    "s-graphviz")
       (values t nil)))
   (lambda ()
     (let* ((graphviz
              (hyperdoc:s-graphviz-optional-capability-chunk))
            (standard
              (hyperdoc:html-inspector-standard-view-chunk
               :s-graphviz-chunk graphviz)))
       (rc-assert-equal
        :optional-unavailable
        (hyperdoc:coherence-chunk-status-of graphviz)
        "Missing s-graphviz must become an optional chunk status")
       (rc-assert-true
        (member (hyperdoc:coherence-chunk-status-of standard)
                '(:blocked :optional-unavailable)
                :test #'eq)
        "Standard view chunk must record Graphviz degradation, not signal"))))
  t)

(defun rc-html-inspector-standard-dependency-cache-smoke-test ()
  (let* ((package-name :html-inspector-views/standard)
         (package (find-package package-name))
         (depends-on (rc-required-loaded-symbol package-name
                                                "SYSTEM-DEPENDS-ON"))
         (dependencies (rc-required-loaded-symbol package-name
                                                  "SYSTEM-DEPENDENCIES"))
         (find-system (rc-required-loaded-symbol package-name
                                                 "FIND-SYSTEM"))
         (missing-reason (rc-required-loaded-symbol package-name
                                                    "MISSING-COMPONENT-REASON"))
         (missing-class (find-class
                         (find-symbol "MISSING-COMPONENT" package)
                         nil))
         (chunk (hyperdoc:html-inspector-standard-dependency-cache-chunk))
         (missing (funcall find-system
                           "hyperdoc-runtime-coherence-missing-smoke/system")))
    (rc-assert-true package
                    "html-inspector-views/standard must be loaded in this smoke")
    (rc-assert-equal nil
                     (funcall depends-on nil)
                     "SYSTEM-DEPENDS-ON on NIL must be nil-safe")
    (rc-assert-equal nil
                     (funcall dependencies nil)
                     "SYSTEM-DEPENDENCIES on NIL must be nil-safe")
    (rc-assert-true
     (and missing-class
          (typep missing missing-class))
     "Missing ASDF systems must degrade into MISSING-COMPONENT records")
    (rc-assert-equal :missing
                     (funcall missing-reason missing)
                     "Missing ASDF systems must record a missing-component reason")
    (rc-assert-equal
     :good
     (hyperdoc:coherence-chunk-status-of chunk)
     "Loaded standard dependency cache must report nil-safe coherence")
    (rc-assert-true
     (some (lambda (entry)
             (and (listp entry)
                  (eq (getf entry :probe) 'find-method)
                  (getf entry :present)))
           (hyperdoc:coherence-chunk-evidence-of chunk))
     "Dependency cache chunk must record the null SYSTEM-DEPENDS-ON method"))
  t)

(defun rc-live-method-report-missing-package-smoke-test ()
  (let* ((package-name (rc-temp-package-name "MISSING-PACKAGE"))
         (report (hyperdoc:make-html-inspector-views-live-method-coherence-report
                  :package-name package-name))
         (chunk (first (hyperdoc:runtime-coherence-report-chunks-of report))))
    (rc-assert-equal
     :missing-package
     (hyperdoc:coherence-chunk-status-of chunk)
     "Live method report must degrade when the standard package is absent"))
  t)

(defun rc-live-method-repair-missing-package-smoke-test ()
  (let* ((package-name (rc-temp-package-name "MISSING-REPAIR-PACKAGE"))
         (report (hyperdoc:repair-html-inspector-views-standard-live-methods
                  :package-name package-name))
         (chunk (first (hyperdoc:runtime-coherence-report-chunks-of report))))
    (rc-assert-equal
     :missing-package
     (hyperdoc:coherence-chunk-status-of chunk)
     "Live method repair must not signal when the standard package is absent"))
  t)

(defun rc-live-method-report-missing-null-method-smoke-test ()
  (rc-with-live-method-fixture
   (lambda (package-name depends-on dependencies)
     (declare (ignore depends-on dependencies))
     (let* ((report
              (hyperdoc:make-html-inspector-views-live-method-coherence-report
               :package-name package-name))
            (chunk
              (first (hyperdoc:runtime-coherence-report-chunks-of report))))
       (rc-assert-equal
        :missing-null-method
        (hyperdoc:coherence-chunk-status-of chunk)
        "A present generic without a NULL method must report :missing-null-method")
       (rc-assert-true
        (some (lambda (entry)
                (and (listp entry)
                     (eq (getf entry :probe) 'find-method)
                     (not (getf entry :present))))
              (hyperdoc:coherence-chunk-evidence-of chunk))
        "The missing NULL method must be recorded as chunk evidence"))))
  t)

(defun rc-live-method-repair-installs-null-method-smoke-test ()
  (rc-with-live-method-fixture
   (lambda (package-name depends-on dependencies)
     (let* ((report
              (hyperdoc:repair-html-inspector-views-standard-live-methods
               :package-name package-name))
            (chunk
              (first (hyperdoc:runtime-coherence-report-chunks-of report)))
            (after
              (find :after
                    (hyperdoc:coherence-chunk-evidence-of chunk)
                    :key (lambda (entry)
                           (and (listp entry)
                                (getf entry :phase))))))
       (rc-assert-equal
        :good
        (hyperdoc:coherence-chunk-status-of chunk)
        "Live method repair must produce a good chunk after installing the NULL method")
       (rc-assert-true
        (getf (hyperdoc:coherence-chunk-value-of chunk)
              :null-method-installed)
        "Repair evidence must record that the NULL method was installed")
       (rc-assert-equal
        nil
        (funcall depends-on nil)
        "SYSTEM-DEPENDS-ON on NIL must return NIL after repair")
       (rc-assert-equal
        nil
        (funcall dependencies nil)
        "SYSTEM-DEPENDENCIES on NIL must return NIL after repair")
       (rc-assert-true
        (and after
             (getf after :system-depends-on-call)
             (getf after :system-dependencies-call))
        "Repair evidence must include successful post-repair safe-call records"))))
  t)

(defun rc-html-inspector-views-environment-missing-asd-smoke-test ()
  (let ((directory (rc-make-temp-directory "html-inspector-src-no-asd")))
    (unwind-protect
         (let* ((report
                  (hyperdoc:make-html-inspector-views-environment-coherence-report
                   :html-inspector-views-src directory
                   :html-inspector-views-asd nil))
                (chunks (hyperdoc:runtime-coherence-report-chunks-of report))
                (chunk (rc-find-chunk "html-inspector-views-environment"
                                      chunks))
                (advice
                  (hyperdoc:html-inspector-views-environment-repair-advice
                   :html-inspector-views-src directory
                   :html-inspector-views-asd nil)))
           (rc-assert-true
            chunk
            "HTML inspector environment report must include its environment chunk")
           (rc-assert-true
            (member (hyperdoc:coherence-chunk-status-of chunk)
                    '(:blocked :failed)
                    :test #'eq)
            "A source directory without html-inspector-views.asd must degrade into a chunk status")
           (rc-assert-equal
            :missing-html-inspector-views-asd
            (getf (hyperdoc:coherence-chunk-value-of chunk)
                  :repair-advice)
            "Missing html-inspector-views.asd must be recorded as repair advice")
           (rc-assert-equal
            :missing-html-inspector-views-asd
            advice
            "Repair advice function must return a non-signaling keyword diagnosis")
           (rc-assert-true
            (some (lambda (entry)
                    (and (listp entry)
                         (string= (getf entry :env-var)
                                  "HTML_INSPECTOR_VIEWS_SRC")
                         (getf entry :directory-exists)
                         (not (getf entry :expected-asd-exists))))
                  (hyperdoc:coherence-chunk-evidence-of chunk))
            "Missing html-inspector-views.asd must be visible in chunk evidence"))
      (uiop:delete-directory-tree directory
                                  :validate t
                                  :if-does-not-exist :ignore)))
  t)

(defun rc-static-root-missing-assets-degrades-smoke-test ()
  (let ((directory (rc-make-temp-directory "missing-static-assets")))
    (unwind-protect
         (let ((chunk (hyperdoc:clog-static-asset-root-chunk
                       :root directory)))
           (rc-assert-equal
            :missing
            (hyperdoc:coherence-chunk-status-of chunk)
            "A static root with missing assets must become :missing")
           (rc-assert-true
            (some (lambda (entry)
                    (and (listp entry)
                         (getf entry :missing-assets)))
                  (hyperdoc:coherence-chunk-evidence-of chunk))
            "Missing static assets must be recorded as chunk evidence"))
      (uiop:delete-directory-tree directory
                                  :validate t
                                  :if-does-not-exist :ignore)))
  t)

(defun rc-report-construction-does-not-load-systems-smoke-test ()
  (let ((original (symbol-function 'asdf:load-system))
        (calls nil))
    (unwind-protect
         (progn
           (setf (symbol-function 'asdf:load-system)
                 (lambda (system-name &rest args)
                   (declare (ignore args))
                   (push system-name calls)
                   (error "Report construction attempted to load ~S"
                          system-name)))
           (hyperdoc:make-inspector-runtime-coherence-report)
           (hyperdoc:make-current-plan-browser-coherence-report
            :root-object '(:synthetic-plan-result)
            :summary '(:synthetic-summary)
            :checklist '(:synthetic-checklist))
           (rc-assert-true
            (null calls)
            "Runtime coherence report construction must not call ASDF:LOAD-SYSTEM"))
      (setf (symbol-function 'asdf:load-system) original)))
  t)

(defun rc-current-plan-browser-report-smoke-test ()
  (let* ((report
           (hyperdoc:make-current-plan-browser-coherence-report
            :root-object '(:synthetic-plan-result)
            :summary '(:synthetic-summary)
            :checklist '(:synthetic-checklist)
            :projections '(:summary :checklist)))
         (chunks (hyperdoc:runtime-coherence-report-chunks-of report))
         (plan (rc-find-chunk "current-plan-result" chunks))
         (session (rc-find-chunk "browser-inspection-session" chunks)))
    (rc-assert-true plan
                    "Current plan browser report must keep the plan object chunk")
    (rc-assert-equal :good
                     (hyperdoc:coherence-chunk-status-of plan)
                     "Synthetic plan object must remain good")
    (rc-assert-true session
                    "Current plan browser report must include a session chunk")
    (rc-assert-true
     (member (hyperdoc:coherence-chunk-status-of session)
             '(:good :blocked)
             :test #'eq)
     "Browser session chunk must summarize support status without losing the plan"))
  t)

(defun run-runtime-coherence-smoke-tests ()
  (rc-runtime-layer-does-not-depend-on-inspector-smoke-test)
  (rc-report-contains-runtime-support-chunks-smoke-test)
  (rc-classify-clog-src-no-asd-smoke-test)
  (rc-graphviz-missing-degrades-smoke-test)
  (rc-html-inspector-standard-dependency-cache-smoke-test)
  (rc-live-method-report-missing-package-smoke-test)
  (rc-live-method-repair-missing-package-smoke-test)
  (rc-live-method-report-missing-null-method-smoke-test)
  (rc-live-method-repair-installs-null-method-smoke-test)
  (rc-html-inspector-views-environment-missing-asd-smoke-test)
  (rc-static-root-missing-assets-degrades-smoke-test)
  (rc-report-construction-does-not-load-systems-smoke-test)
  (rc-current-plan-browser-report-smoke-test)
  (format t "~&Runtime coherence smoke tests passed.~%")
  t)
