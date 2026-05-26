;;;; FedWiki page-attached ASDF system homes.

(in-package :hyperdoc)

(defparameter *default-fedwiki-site-root*
  #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/")

(defparameter *fedwiki-attached-asdf-system-reading-question-labels*
  '("How do I invoke response?"
    "What specifically can I do now?"
    "What is needed to do a specific function?"
    "What is that?"
    "Where is it?"
    "Does any part of the system do this?"
    "What part of the system knows about that?"
    "How did I get here? What has been happening?"
    "How can I get back?"
    "What is the current state of the system?"
    "Why did that happen?"
    "Why didn't that happen?"))

(defclass fedwiki-attached-asdf-system ()
  ((slug :accessor fedwiki-attached-asdf-system-slug :initarg :slug)
   (site-root :accessor fedwiki-attached-asdf-system-site-root
              :initarg :site-root)
   (system-name :accessor fedwiki-attached-asdf-system-system-name
                :initarg :system)
   (system-file :accessor fedwiki-attached-asdf-system-system-file
                :initarg :system-file)
   (test-system-name :accessor fedwiki-attached-asdf-system-test-system-name
                     :initarg :test-system
                     :initform nil)
   (package-name :accessor fedwiki-attached-asdf-system-package-name
                 :initarg :package-name)
   (compatibility-system-name
    :accessor fedwiki-attached-asdf-system-compatibility-system-name
    :initarg :compatibility-system
    :initform nil)
   (previous-object :accessor fedwiki-attached-asdf-system-previous-object
                    :initarg :previous-object
                    :initform nil)
   (lookup-trace :accessor %fedwiki-attached-asdf-system-lookup-trace
                 :initform nil)
   (last-lookup-failure
    :accessor %fedwiki-attached-asdf-system-last-lookup-failure
    :initform nil)))

(define-condition fedwiki-asdf-system-lookup-failure (lookup-failure)
  ((home :reader fedwiki-asdf-lookup-failure-home :initarg :home)
   (routes :reader fedwiki-asdf-lookup-failure-routes :initarg :routes)
   (condition :reader fedwiki-asdf-lookup-failure-condition
              :initarg :condition)
   (home-page :reader fedwiki-asdf-lookup-failure-home-page
              :initarg :home-page))
  (:report
   (lambda (condition stream)
     (format stream
             "Could not load FedWiki-attached ASDF system ~A from ~A."
             (fedwiki-attached-asdf-system-system-name
              (fedwiki-asdf-lookup-failure-home condition))
             (fedwiki-page-asdf-entrypoint
              (fedwiki-asdf-lookup-failure-home condition))))))

(defmethod print-object ((home fedwiki-attached-asdf-system) stream)
  (print-unreadable-object (home stream :type t :identity nil)
    (format stream "~A -> ~A"
            (fedwiki-attached-asdf-system-slug home)
            (fedwiki-attached-asdf-system-system-name home))))

(defun fedwiki-asdf-string-suffix-p (suffix string)
  (let ((suffix-length (length suffix))
        (string-length (length string)))
    (and (<= suffix-length string-length)
         (string= suffix string
                  :start2 (- string-length suffix-length)))))

(defun fedwiki-asdf-normalize-slug (slug)
  (etypecase slug
    (symbol (string-downcase (symbol-name slug)))
    (string (string-downcase slug))))

(defun fedwiki-asdf-system-name-string (name)
  (etypecase name
    (symbol (string-downcase (symbol-name name)))
    (string (string-downcase name))))

(defun fedwiki-asdf-system-keyword (name)
  (intern (string-upcase (fedwiki-asdf-system-name-string name)) :keyword))

(defun fedwiki-asdf-default-system-file (system)
  (let ((name (fedwiki-asdf-system-name-string system)))
    (subseq name 0 (or (position #\/ name) (length name)))))

(defun fedwiki-asdf-package-name-string (name)
  (let* ((system-name (fedwiki-asdf-system-name-string name))
         (base (subseq system-name 0 (or (position #\/ system-name)
                                         (length system-name)))))
    (string-upcase base)))

(defun fedwiki-asdf-system-file-namestring (system-file)
  (let ((name (etypecase system-file
                (symbol (fedwiki-asdf-system-name-string system-file))
                (string system-file)
                (pathname (file-namestring system-file)))))
    (if (fedwiki-asdf-string-suffix-p ".asd" name)
        name
        (format nil "~A.asd" name))))

(defun fedwiki-asdf-pathname-string (pathname)
  (and pathname (namestring pathname)))

(defun fedwiki-asdf-plist-value-string (value)
  (cond
    ((eq value t) "true")
    ((eq value nil) "false")
    ((pathnamep value) (namestring value))
    ((keywordp value) (format nil ":~A" (symbol-name value)))
    ((symbolp value) (format nil "~A" value))
    ((listp value) (format nil "~{~A~^, ~}" value))
    (t (format nil "~A" value))))

(defun fedwiki-asdf-format-command (form)
  (with-output-to-string (stream)
    (let ((*print-case* :downcase)
          (*print-pretty* nil))
      (prin1 form stream))))

(defgeneric fedwiki-page-asset-root (thing &key site-root))

(defmethod fedwiki-page-asset-root ((slug string) &key
                                    (site-root *default-fedwiki-site-root*))
  (merge-pathnames
   (format nil "assets/pages/~A/"
           (fedwiki-asdf-normalize-slug slug))
   (uiop:ensure-directory-pathname site-root)))

(defmethod fedwiki-page-asset-root ((slug symbol) &key
                                    (site-root *default-fedwiki-site-root*))
  (fedwiki-page-asset-root (fedwiki-asdf-normalize-slug slug)
                           :site-root site-root))

(defmethod fedwiki-page-asset-root ((home fedwiki-attached-asdf-system)
                                    &key site-root)
  (fedwiki-page-asset-root
   (fedwiki-attached-asdf-system-slug home)
   :site-root (or site-root
                  (fedwiki-attached-asdf-system-site-root home))))

(defgeneric fedwiki-page-asdf-entrypoint (thing &key site-root system-file))

(defmethod fedwiki-page-asdf-entrypoint ((slug string) &key
                                         (site-root *default-fedwiki-site-root*)
                                         (system-file slug))
  (merge-pathnames
   (fedwiki-asdf-system-file-namestring system-file)
   (fedwiki-page-asset-root slug :site-root site-root)))

(defmethod fedwiki-page-asdf-entrypoint ((slug symbol) &key
                                         (site-root *default-fedwiki-site-root*)
                                         (system-file slug))
  (fedwiki-page-asdf-entrypoint
   (fedwiki-asdf-normalize-slug slug)
   :site-root site-root
   :system-file system-file))

(defmethod fedwiki-page-asdf-entrypoint ((home fedwiki-attached-asdf-system)
                                         &key site-root system-file)
  (fedwiki-page-asdf-entrypoint
   (fedwiki-attached-asdf-system-slug home)
   :site-root (or site-root
                  (fedwiki-attached-asdf-system-site-root home))
   :system-file (or system-file
                    (fedwiki-attached-asdf-system-system-file home))))

(defun fedwiki-asdf-default-compatibility-system (system)
  (when (string= (fedwiki-asdf-system-name-string system) "kioskbeerli")
    :dreyeck/kioskbeerli))

(defun make-fedwiki-attached-asdf-system
    (&key slug
       (site-root *default-fedwiki-site-root*)
       system
       system-file
       test-system
       package-name
       compatibility-system
       previous-object)
  (let* ((system-name (or system
                          (error "Missing :SYSTEM for FedWiki-attached ASDF system.")))
         (system-file (or system-file
                          (fedwiki-asdf-default-system-file system-name))))
    (make-instance
     'fedwiki-attached-asdf-system
     :slug (fedwiki-asdf-normalize-slug
            (or slug (fedwiki-asdf-default-system-file system-name)))
     :site-root (uiop:ensure-directory-pathname site-root)
     :system (fedwiki-asdf-system-keyword system-name)
     :system-file system-file
     :test-system (and test-system
                       (fedwiki-asdf-system-keyword test-system))
     :package-name (fedwiki-asdf-package-name-string
                    (or package-name system-name))
     :compatibility-system
     (or compatibility-system
         (fedwiki-asdf-default-compatibility-system system-name))
     :previous-object previous-object)))

(defun fedwiki-asdf-system-name-registered-p (name)
  (member (fedwiki-asdf-system-name-string name)
          (asdf:registered-systems)
          :test #'string=))

(defun fedwiki-asdf-system-name-loaded-p (name)
  (member (fedwiki-asdf-system-name-string name)
          (asdf:already-loaded-systems)
          :test #'string=))

(defun fedwiki-asdf-resolved-system (name)
  (when (or (fedwiki-asdf-system-name-registered-p name)
            (fedwiki-asdf-system-name-loaded-p name))
    (ignore-errors (asdf:find-system name nil))))

(defun fedwiki-attached-asdf-system-source-directory (home)
  (or (ignore-errors
        (let ((system (fedwiki-asdf-resolved-system
                       (fedwiki-attached-asdf-system-system-name home))))
          (and system (asdf:system-source-directory system))))
      (when (uiop:file-exists-p (fedwiki-page-asdf-entrypoint home))
        (fedwiki-page-asset-root home))))

(defun fedwiki-attached-asdf-system-source-file (home)
  (or (ignore-errors
        (let ((system (fedwiki-asdf-resolved-system
                       (fedwiki-attached-asdf-system-system-name home))))
          (and system (asdf:system-source-file system))))
      (when (uiop:file-exists-p (fedwiki-page-asdf-entrypoint home))
        (fedwiki-page-asdf-entrypoint home))))

(defun fedwiki-attached-asdf-system-package-present-p (home)
  (not (null (find-package
              (fedwiki-attached-asdf-system-package-name home)))))

(defun fedwiki-attached-asdf-system-sqlite-status (home)
  (cond
    ((not (string= (fedwiki-attached-asdf-system-package-name home)
                   "KIOSKBEERLI"))
     :not-applicable)
    ((ignore-errors
       (uiop:run-program '("sqlite3" "--version")
                         :output :string
                         :error-output :string)
       t)
     :available)
    (t
     :missing)))

(defun fedwiki-attached-asdf-system-available-examples (home)
  (mapcar #'example-entry-title-of
          (discover-examples
           :system (fedwiki-asdf-system-name-string
                    (fedwiki-attached-asdf-system-system-name home)))))

(defun fedwiki-attached-asdf-system-available-tests (home)
  (let ((tests nil)
        (test-system (fedwiki-attached-asdf-system-test-system-name home)))
    (when test-system
      (push (format nil "ASDF test system ~A" test-system) tests)
      (push (format nil "(asdf:load-system ~S)"
                    test-system)
            tests))
    (when (string= (fedwiki-attached-asdf-system-package-name home)
                   "KIOSKBEERLI")
      (push "(kioskbeerli/tests:run-kioskbeerli-smoke-tests)" tests)
      (push "(uiop:symbol-call :kioskbeerli/tests :run-kioskbeerli-smoke-tests)"
            tests))
    (nreverse tests)))

(defun fedwiki-attached-asdf-system-state (home)
  (let* ((system-name (fedwiki-attached-asdf-system-system-name home))
         (test-system (fedwiki-attached-asdf-system-test-system-name home))
         (asset-root (fedwiki-page-asset-root home))
         (entrypoint (fedwiki-page-asdf-entrypoint home))
         (system (fedwiki-asdf-resolved-system system-name))
         (source-file (fedwiki-attached-asdf-system-source-file home))
         (source-directory
           (fedwiki-attached-asdf-system-source-directory home)))
    (list :page-identity (fedwiki-attached-asdf-system-slug home)
          :asset-root asset-root
          :asdf-entrypoint entrypoint
          :system system-name
          :test-system test-system
          :source-file source-file
          :source-directory source-directory
          :package-name (fedwiki-attached-asdf-system-package-name home)
          :loaded-p (not (null (fedwiki-asdf-system-name-loaded-p system-name)))
          :system-found-p (not (null system))
          :registered-p (not (null (fedwiki-asdf-system-name-registered-p
                                    system-name)))
          :test-system-found-p
          (and test-system
               (not (null (fedwiki-asdf-resolved-system test-system))))
          :asset-root-exists-p (not (null (uiop:directory-exists-p asset-root)))
          :asd-exists-p (not (null (uiop:file-exists-p entrypoint)))
          :package-present-p
          (fedwiki-attached-asdf-system-package-present-p home)
          :examples-count
          (length (fedwiki-attached-asdf-system-available-examples home))
          :tests-found-p
          (and test-system
               (or (not (null (fedwiki-asdf-resolved-system test-system)))
                   (not (null (uiop:directory-exists-p
                               (merge-pathnames "tests/" asset-root))))))
          :sqlite-status
          (fedwiki-attached-asdf-system-sqlite-status home))))

(defun fedwiki-attached-asdf-system-route-trace (home)
  (or (%fedwiki-attached-asdf-system-lookup-trace home)
      (let ((asset-root (fedwiki-page-asset-root home))
            (entrypoint (fedwiki-page-asdf-entrypoint home))
            (system (fedwiki-attached-asdf-system-system-name home)))
        (list
         (format nil "FedWiki page identity: ~A"
                 (fedwiki-attached-asdf-system-slug home))
         (format nil "Local page asset root: ~A" asset-root)
         (format nil "ASDF entrypoint pathname: ~A" entrypoint)
         (format nil "Load boundary: (asdf:load-asd #p~S :name ~S)"
                 (namestring entrypoint)
                 (fedwiki-asdf-system-name-string system))
         (format nil "ASDF system object: ~A" system)
         "Inspector object: fedwiki-attached-asdf-system home page"))))

(defun fedwiki-attached-asdf-system-available-actions (home)
  (let* ((system (fedwiki-attached-asdf-system-system-name home))
         (test-system (fedwiki-attached-asdf-system-test-system-name home))
         (entrypoint (fedwiki-page-asdf-entrypoint home)))
    (remove nil
            (list
             (format nil "(asdf:load-asd #p~S :name ~S)"
                     (namestring entrypoint)
                     (fedwiki-asdf-system-name-string system))
             (format nil "(hyperdoc:load-fedwiki-attached-asdf-system *)")
             (format nil "(asdf:load-system ~S)" system)
             (and test-system
                  (format nil "(asdf:load-system ~S)" test-system))
             "(clog-moldable-inspector:clog-inspect :object *)"
             "(hyperdoc/inspector:inspect-system-home-page *)"
             "Inspect Overview, Source, Examples, Tests, Files, Plan, and Dependencies views when present."
             (and (string= (fedwiki-attached-asdf-system-package-name home)
                           "KIOSKBEERLI")
                  "(uiop:symbol-call :kioskbeerli/tests :run-kioskbeerli-smoke-tests)")))))

(defun fedwiki-asdf-route-result-string (result condition)
  (cond
    (condition
     (with-output-to-string (stream)
       (princ condition stream)))
    (result
     (fedwiki-asdf-plist-value-string result))
    (t
     "")))

(defun fedwiki-asdf-workspace-asd-pathname (home)
  (or (ignore-errors
        (asdf:system-relative-pathname
         :hyperdoc
         (fedwiki-asdf-system-file-namestring
          (fedwiki-attached-asdf-system-system-file home))))
      (merge-pathnames
       (fedwiki-asdf-system-file-namestring
        (fedwiki-attached-asdf-system-system-file home))
       #P"/Users/rgb/workspace/hyperdoc/")))

(defun make-fedwiki-asdf-route
    (&key route label kind pathname system-name available-p recovery-action
       explanation tried-p result condition)
  (list :route route
        :label label
        :kind kind
        :pathname pathname
        :system-name system-name
        :exists-p (and pathname
                       (not (null (uiop:file-exists-p pathname))))
        :available-p available-p
        :recovery-action recovery-action
        :explanation explanation
        :tried-p tried-p
        :result result
        :condition condition
        :condition-message (fedwiki-asdf-route-result-string result condition)))

(defun fedwiki-attached-asdf-system-candidate-routes
    (home &key tried-route result condition)
  (let* ((system (fedwiki-attached-asdf-system-system-name home))
         (system-name (fedwiki-asdf-system-name-string system))
         (entrypoint (fedwiki-page-asdf-entrypoint home))
         (workspace-asd (fedwiki-asdf-workspace-asd-pathname home))
         (compatibility-system
           (fedwiki-attached-asdf-system-compatibility-system-name home)))
    (remove
     nil
     (list
      (make-fedwiki-asdf-route
       :route :fedwiki-asset
       :label "local FedWiki page asset .asd"
       :kind :pathname
       :pathname entrypoint
       :available-p (not (null (uiop:file-exists-p entrypoint)))
       :recovery-action
       (format nil "(asdf:load-asd #p~S :name ~S), then (asdf:load-system ~S)"
               (namestring entrypoint)
               system-name
               system)
       :explanation
       "Preferred SLY route: use the local file-backed asset attached to the FedWiki page identity."
       :tried-p (eq tried-route :fedwiki-asset)
       :result (and (eq tried-route :fedwiki-asset) result)
       :condition (and (eq tried-route :fedwiki-asset) condition))
      (make-fedwiki-asdf-route
       :route :workspace-source
       :label "workspace source .asd"
       :kind :pathname
       :pathname workspace-asd
       :available-p (not (null (uiop:file-exists-p workspace-asd)))
       :recovery-action
       (format nil "(asdf:load-asd #p~S :name ~S)"
               (namestring workspace-asd)
               system-name)
       :explanation
       "Fallback for repository-local development, not the page-attached route."
       :tried-p (eq tried-route :workspace-source)
       :result (and (eq tried-route :workspace-source) result)
       :condition (and (eq tried-route :workspace-source) condition))
      (when compatibility-system
        (make-fedwiki-asdf-route
         :route :compatibility-asdf-system
         :label "compatibility ASDF route"
         :kind :system
         :system-name compatibility-system
         :available-p (not (null (ignore-errors
                                   (asdf:find-system
                                    compatibility-system nil))))
         :recovery-action
         (format nil "(asdf:load-system ~S)" compatibility-system)
         :explanation
         "Compatibility alias for older dreyeck/kioskbeerli naming; not the page identity."
         :tried-p (eq tried-route :compatibility-asdf-system)
         :result (and (eq tried-route :compatibility-asdf-system) result)
         :condition (and (eq tried-route :compatibility-asdf-system)
                         condition)))))))

(defun fedwiki-attached-asdf-system-what-is-that (home)
  (let ((state (fedwiki-attached-asdf-system-state home)))
    (list
     (format nil "FedWiki page identity: ~A"
             (getf state :page-identity))
     (format nil "Asset root: ~A"
             (fedwiki-asdf-pathname-string (getf state :asset-root)))
     (format nil "ASDF entrypoint: ~A"
             (fedwiki-asdf-pathname-string (getf state :asdf-entrypoint)))
     (format nil "ASDF system: ~A" (getf state :system))
     (format nil "Package: ~A (~:[missing~;present~])"
             (getf state :package-name)
             (getf state :package-present-p))
     (format nil "Test system: ~A"
             (fedwiki-asdf-plist-value-string (getf state :test-system))))))

(defun fedwiki-attached-asdf-system-where-is-it (home)
  (let ((state (fedwiki-attached-asdf-system-state home)))
    (list
     (format nil "Site root: ~A"
             (fedwiki-attached-asdf-system-site-root home))
     (format nil "Asset root: ~A"
             (fedwiki-asdf-pathname-string (getf state :asset-root)))
     (format nil "ASDF entrypoint: ~A"
             (fedwiki-asdf-pathname-string (getf state :asdf-entrypoint)))
     (format nil "Source file: ~A"
             (fedwiki-asdf-pathname-string (getf state :source-file)))
     (format nil "Source directory: ~A"
             (fedwiki-asdf-pathname-string (getf state :source-directory))))))

(defun fedwiki-attached-asdf-system-current-state-lines (home)
  (let ((state (fedwiki-attached-asdf-system-state home)))
    (list
     (format nil "asset-root-exists-p: ~A"
             (getf state :asset-root-exists-p))
     (format nil "asd-exists-p: ~A" (getf state :asd-exists-p))
     (format nil "system-found-p: ~A" (getf state :system-found-p))
     (format nil "loaded-p: ~A" (getf state :loaded-p))
     (format nil "package-present-p: ~A" (getf state :package-present-p))
     (format nil "tests-found-p: ~A" (getf state :tests-found-p))
     (format nil "sqlite-status: ~A" (getf state :sqlite-status)))))

(defun fedwiki-attached-asdf-system-why-lines (home)
  (let ((state (fedwiki-attached-asdf-system-state home)))
    (cond
      ((getf state :loaded-p)
       (list "The system is loaded because ASDF has already completed a load operation for the named system."))
      ((getf state :asd-exists-p)
       (list "The local .asd exists, but the system has not been loaded through this home object yet."))
      (t
       (list "The local .asd is missing at the computed page asset path, so the page-attached route cannot load yet.")))))

(defun fedwiki-attached-asdf-system-why-not-lines (home)
  (let ((state (fedwiki-attached-asdf-system-state home)))
    (remove
     nil
     (list
      (unless (getf state :package-present-p)
        (format nil
                "Package ~A is absent because the ASDF system has not loaded or failed during load; reader forms such as kioskbeerli:... fail before evaluation when that package does not exist."
                (getf state :package-name)))
      (unless (getf state :tests-found-p)
        "Tests are not available as callable package functions until the test system has been loaded.")
      (unless (getf state :system-found-p)
        "ASDF does not yet know the system object until load-asd registers the exact page-local .asd or another source-registry route finds it.")))))

(defun fedwiki-attached-asdf-system-reading-questions (home)
  (let ((actions (fedwiki-attached-asdf-system-available-actions home)))
    (list
     (list :question "How do I invoke response?"
           :answer actions)
     (list :question "What specifically can I do now?"
           :answer '("Inspect Overview"
                     "Inspect Source"
                     "Inspect Examples"
                     "Inspect Tests"
                     "Inspect Files"
                     "Inspect Plan"
                     "Inspect Dependencies"
                     "Load tests"
                     "Run smoke tests"))
     (list :question "What is needed to do a specific function?"
           :answer '("The asset root must exist."
                     "The page-local .asd must exist."
                     "ASDF must load the .asd or know an equivalent source-registry route."
                     "The package must be created by loading the system before package-qualified calls are readable."
                     "sqlite3 is optional for SQLite-backed persistence."))
     (list :question "What is that?"
           :answer (fedwiki-attached-asdf-system-what-is-that home))
     (list :question "Where is it?"
           :answer (fedwiki-attached-asdf-system-where-is-it home))
     (list :question "Does any part of the system do this?"
           :answer '("hyperdoc:make-fedwiki-attached-asdf-system constructs the home object."
                     "hyperdoc:fedwiki-page-asset-root resolves the local asset root."
                     "hyperdoc:fedwiki-page-asdf-entrypoint resolves the exact .asd pathname."
                     "hyperdoc:load-fedwiki-attached-asdf-system loads the exact .asd."
                     "hyperdoc/inspector:inspect-system-home-page opens the inspector home surface."))
     (list :question "What part of the system knows about that?"
           :answer '("ASDF knows systems, components, source files, dependencies, and loaded state."
                     "The FedWiki asset materializer knows page-local asset paths."
                     "The inspector knows the Overview and lookup-failure views."
                     "The Kioskbeerli package knows dashboard, planner, trace, examples, tests, and optional SQLite APIs."))
     (list :question "How did I get here? What has been happening?"
           :answer (fedwiki-attached-asdf-system-route-trace home))
     (list :question "How can I get back?"
           :answer '("Reverse path: system object -> .asd source file -> asset root -> page identity."
                     "Use the Source file and Source directory rows to inspect the loaded entrypoint."
                     "Use the Page identity row to recover the FedWiki slug."
                     "Use the Previous object row when this home was opened from another inspected object."))
     (list :question "What is the current state of the system?"
           :answer (fedwiki-attached-asdf-system-current-state-lines home))
     (list :question "Why did that happen?"
           :answer (fedwiki-attached-asdf-system-why-lines home))
     (list :question "Why didn't that happen?"
           :answer (or (fedwiki-attached-asdf-system-why-not-lines home)
                       '("No derived failure is visible from the current home-page state."))))))

(defgeneric asdf-system-home-page-of (thing))

(defmethod asdf-system-home-page-of ((home fedwiki-attached-asdf-system))
  (let ((state (fedwiki-attached-asdf-system-state home)))
    (list :kind :fedwiki-attached-asdf-system-home-page
          :title "FedWiki-attached ASDF system home page"
          :object home
          :state state
          :actions (fedwiki-attached-asdf-system-available-actions home)
          :examples (fedwiki-attached-asdf-system-available-examples home)
          :tests (fedwiki-attached-asdf-system-available-tests home)
          :route-trace (fedwiki-attached-asdf-system-route-trace home)
          :candidate-routes
          (fedwiki-attached-asdf-system-candidate-routes home)
          :reading-questions
          (fedwiki-attached-asdf-system-reading-questions home))))

(defun fedwiki-attached-asdf-system-home-page-text (home)
  (let* ((page (asdf-system-home-page-of home))
         (state (getf page :state)))
    (with-output-to-string (stream)
      (format stream "FedWiki-attached ASDF system home page~%")
      (dolist (pair '(("Page identity" :page-identity)
                      ("Asset root" :asset-root)
                      ("ASDF entrypoint" :asdf-entrypoint)
                      ("System" :system)
                      ("Tests" :test-system)
                      ("Source file" :source-file)
                      ("Source directory" :source-directory)
                      ("Package" :package-name)
                      ("State" :loaded-p)))
        (format stream "~A: ~A~%"
                (first pair)
                (fedwiki-asdf-plist-value-string
                 (getf state (second pair)))))
      (format stream "~%Reading questions~%")
      (dolist (entry (getf page :reading-questions))
        (format stream "~A~%" (getf entry :question))
        (dolist (line (getf entry :answer))
          (format stream "- ~A~%" line))))))

(defun make-fedwiki-asdf-lookup-failure (home condition &key result)
  (let* ((routes
           (fedwiki-attached-asdf-system-candidate-routes
            home
            :tried-route :fedwiki-asset
            :result result
            :condition condition))
         (failure
           (make-condition
            'fedwiki-asdf-system-lookup-failure
            :home home
            :routes routes
            :condition condition
            :home-page (asdf-system-home-page-of home))))
    (setf (%fedwiki-attached-asdf-system-last-lookup-failure home)
          failure)
    failure))

(defun load-fedwiki-attached-asdf-system (home &key force)
  (let* ((entrypoint (fedwiki-page-asdf-entrypoint home))
         (system (fedwiki-attached-asdf-system-system-name home))
         (system-name (fedwiki-asdf-system-name-string system)))
    (handler-case
        (progn
          (unless (uiop:file-exists-p entrypoint)
            (error "FedWiki page-attached ASDF entrypoint does not exist: ~A"
                   entrypoint))
          (asdf:load-asd entrypoint :name system-name)
          (asdf:load-system system :force force)
          (let ((loaded (asdf:find-system system)))
            (setf (%fedwiki-attached-asdf-system-lookup-trace home)
                  (list
                   (format nil "FedWiki page identity: ~A"
                           (fedwiki-attached-asdf-system-slug home))
                   (format nil "Local page asset root: ~A"
                           (fedwiki-page-asset-root home))
                   (format nil "ASDF entrypoint pathname: ~A" entrypoint)
                   (format nil "Loaded with ASDF:LOAD-ASD name ~S"
                           system-name)
                   (format nil "ASDF system object: ~A"
                           (asdf:component-name loaded))
                   "Inspector object: fedwiki-attached-asdf-system home page")
                  (%fedwiki-attached-asdf-system-last-lookup-failure home)
                  nil)
            loaded))
      (error (condition)
        (make-fedwiki-asdf-lookup-failure home condition)))))

(defun fedwiki-asdf-lookup-failure-text (failure)
  (let* ((home (fedwiki-asdf-lookup-failure-home failure))
         (home-text (fedwiki-attached-asdf-system-home-page-text home)))
    (with-output-to-string (stream)
      (format stream "FedWiki ASDF lookup failure~%")
      (format stream "~A~%~%" failure)
      (format stream "Candidate routes~%")
      (dolist (route (fedwiki-asdf-lookup-failure-routes failure))
        (format stream "~A: ~A~%"
                (getf route :label)
                (or (fedwiki-asdf-pathname-string (getf route :pathname))
                    (getf route :system-name)))
        (format stream "  tried-p: ~A~%" (getf route :tried-p))
        (format stream "  available-p: ~A~%" (getf route :available-p))
        (format stream "  recovery: ~A~%" (getf route :recovery-action))
        (format stream "  explanation: ~A~%" (getf route :explanation))
        (when (getf route :condition-message)
          (format stream "  condition: ~A~%"
                  (getf route :condition-message))))
      (format stream "~%Package-reader consequence: reader forms such as kioskbeerli:... fail at read time if the system did not load and the package does not exist.~%~%")
      (write-string home-text stream))))

(defmethod asdf-system-home-page-of ((failure fedwiki-asdf-system-lookup-failure))
  (fedwiki-asdf-lookup-failure-home-page failure))
