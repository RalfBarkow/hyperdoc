;;;; Generic page-as-ASDF-system reload boundaries.

(in-package :hyperdoc)

(defparameter *page-system-default-asdf-systems*
  '("hyperdoc/page/mobile-progressive-chrome"
    "hyperdoc/page/dm6-appembed-inline-proof"
    "fedwiki/page/wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc"
    "fedwiki/page/wiki.ralfbarkow.ch/shop3"))

(defun page-system-normalize-system-name (name)
  (etypecase name
    (symbol (string-downcase (symbol-name name)))
    (string (string-downcase name))))

(defun page-system-repo-pathname (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun page-system-read-file-string (pathname)
  (when (uiop:file-exists-p pathname)
    (with-open-file (stream pathname :direction :input :external-format :utf-8)
      (let ((string (make-string (file-length stream))))
        (read-sequence string stream)
        string))))

(defun page-system-count-substring (needle haystack)
  (loop with start = 0
        with count = 0
        for position = (and haystack
                            (search needle haystack :start2 start :test #'char-equal))
        while position
        do (setf start (+ position (length needle)))
        (incf count)
        finally (return count)))

(defclass page-runtime-provider ()
  ((provider-id :reader page-runtime-provider-id :initarg :provider-id)
   (provider-kind :reader page-runtime-provider-kind :initarg :provider-kind)
   (asdf-system-name :reader page-runtime-provider-asdf-system-name
                     :initarg :asdf-system-name)
   (ensure-function :reader page-runtime-provider-ensure-function
                    :initarg :ensure-function
                    :initform nil)
   (readiness-function :reader page-runtime-provider-readiness-function
                       :initarg :readiness-function
                       :initform nil)
   (display-notes :reader page-runtime-provider-display-notes
                  :initarg :display-notes
                  :initform nil)
   (source-repo :reader page-runtime-provider-source-repo
                :initarg :source-repo
                :initform nil)
   (upstream-url :reader page-runtime-provider-upstream-url
                 :initarg :upstream-url
                 :initform nil)
   (local-override-note :reader page-runtime-provider-local-override-note
                        :initarg :local-override-note
                        :initform nil)
   (license-note :reader page-runtime-provider-license-note
                 :initarg :license-note
                 :initform nil)))

(defmethod print-object ((provider page-runtime-provider) stream)
  (print-unreadable-object (provider stream :type t :identity nil)
    (format stream "~A" (page-runtime-provider-id provider))))

(defun make-page-runtime-provider
    (&key provider-id provider-kind asdf-system-name ensure-function
       readiness-function display-notes source-repo upstream-url
       local-override-note license-note)
  (make-instance 'page-runtime-provider
                 :provider-id provider-id
                 :provider-kind provider-kind
                 :asdf-system-name asdf-system-name
                 :ensure-function ensure-function
                 :readiness-function readiness-function
                 :display-notes display-notes
                 :source-repo source-repo
                 :upstream-url upstream-url
                 :local-override-note local-override-note
                 :license-note license-note))

(defun hyperdoc-runtime-provider ()
  (make-page-runtime-provider
   :provider-id "hyperdoc-runtime"
   :provider-kind :hyperdoc
   :asdf-system-name "hyperdoc"
   :ensure-function "asdf:load-system :hyperdoc"
   :readiness-function "hyperdoc:*hyperdoc* is registered"
   :display-notes "Provides HyperDoc page lookup, authored pages, and base render hooks."))

(defun hyperdoc-explorer-runtime-provider ()
  (make-page-runtime-provider
   :provider-id "hyperdoc-explorer-runtime"
   :provider-kind :hyperdoc-explorer
   :asdf-system-name "hyperdoc/explorer"
   :ensure-function "asdf:load-system :hyperdoc/explorer"
   :readiness-function "CLOG/html-inspector views are registered"
   :display-notes "Provides inspector and explorer views for HyperDoc pages and slice objects."))

(defun fedwiki-client-runtime-provider ()
  (make-page-runtime-provider
   :provider-id "fedwiki-client-runtime"
   :provider-kind :fedwiki-client
   :asdf-system-name "hyperbook/fedwiki"
   :ensure-function "asdf:load-system :hyperbook/fedwiki"
   :readiness-function "FedWiki HyperBook classes and story renderers are available"
   :display-notes "Provides FedWiki site/page objects and story rendering support."))

(defun fedwiki-materialization-runtime-provider ()
  (make-page-runtime-provider
   :provider-id "fedwiki-materialization-runtime"
   :provider-kind :fedwiki-materialization
   :asdf-system-name "hyperdoc/fedwiki"
   :ensure-function "asdf:load-system :hyperdoc/fedwiki"
   :readiness-function "Local twin/materialization planning helpers are available"
   :display-notes "Provides localhost FedWiki materialization metadata and dry-run helpers."))

(defparameter *shop3-asdf-system-name* "shop3")
(defparameter *shop3-upstream-url* "https://github.com/shop-planner/shop3")
(defparameter *shop3-flake-input* "github:shop-planner/shop3")

(defun shop3-source-root-pathname ()
  (or (when-let (root (uiop:getenv "SHOP3_SRC"))
        (uiop:ensure-directory-pathname root))
      (ignore-errors
        (uiop:pathname-parent-directory-pathname
         (asdf:system-source-directory *shop3-asdf-system-name*)))))

(defun ensure-shop3-runtime ()
  (asdf:load-system *shop3-asdf-system-name*)
  (asdf:find-system *shop3-asdf-system-name*))

(defun shop3-runtime-ready-p ()
  (and (ignore-errors
         (ensure-shop3-runtime)
         t)
       (find-package :shop3)
       (find-package :shop3-user)))

(defun shop3-runtime-provider ()
  (make-page-runtime-provider
   :provider-id "shop3-runtime-provider"
   :provider-kind :common-lisp-planner
   :asdf-system-name *shop3-asdf-system-name*
   :ensure-function "asdf:load-system :shop3"
   :readiness-function "ASDF resolves :shop3 and packages SHOP3/SHOP3-USER exist"
   :display-notes "Provides the SHOP3 HTN planner runtime for the FedWiki shop3 page."
   :source-repo *shop3-flake-input*
   :upstream-url *shop3-upstream-url*
   :local-override-note
   "nix develop --override-input shop3 path:/path/to/shop3"
   :license-note "MPL 1.1/GPL 2.0/LGPL 2.1; ASDF metadata says Mozilla Public License."))

(defun hyperdoc-shop3-planning-runtime-provider ()
  (make-page-runtime-provider
   :provider-id "hyperdoc-shop3-planning-runtime"
   :provider-kind :hyperdoc-shop3-planning-layer
   :asdf-system-name "hyperdoc/shop3"
   :ensure-function "asdf:load-system :hyperdoc/shop3"
   :readiness-function "HYPERDOC/SHOP3 package and plan-object helpers are available"
   :display-notes "Provides HyperDoc-facing SHOP3 plan objects and inspector views without running a planning problem on load."))

(defclass page-system ()
  ((page-system-id :reader page-system-id :initarg :page-system-id)
   (page-system-title :reader page-system-title :initarg :page-system-title)
   (page-system-kind :reader page-system-kind :initarg :page-system-kind)
   (page-system-asdf-system-name
    :reader page-system-asdf-system-name
    :initarg :page-system-asdf-system-name)
   (page-system-page-locator
    :reader page-system-page-locator
    :initarg :page-system-page-locator)
   (page-system-runtime-providers
    :reader page-system-runtime-providers
    :initarg :page-system-runtime-providers
    :initform nil)
   (page-system-runtime-entry-points
    :reader page-system-runtime-entry-points
    :initarg :page-system-runtime-entry-points
    :initform nil)
   (page-system-display-contract
    :reader page-system-display-contract
    :initarg :page-system-display-contract
    :initform nil)
   (page-system-inspection-entry-points
    :reader page-system-inspection-entry-points
    :initarg :page-system-inspection-entry-points
    :initform nil)
   (page-system-validation-entry-points
    :reader page-system-validation-entry-points
    :initarg :page-system-validation-entry-points
    :initform nil)
   (page-system-source-files
    :reader page-system-source-files
    :initarg :page-system-source-files
    :initform nil)
   (page-system-artifacts
    :reader page-system-artifacts
    :initarg :page-system-artifacts
    :initform nil)
   (page-system-display-check-function
    :reader page-system-display-check-function
    :initarg :page-system-display-check-function
    :initform nil)
   (page-system-description
    :reader page-system-description
    :initarg :page-system-description
    :initform nil)))

(defclass hyperdoc-page-system (page-system) ())
(defclass fedwiki-page-system (page-system) ())
(defclass external-page-system (page-system) ())

(defmethod print-object ((system page-system) stream)
  (print-unreadable-object (system stream :type t :identity nil)
    (format stream "~A" (page-system-asdf-system-name system))))

(defun make-page-system
    (class &key page-system-id page-system-title page-system-kind
             page-system-asdf-system-name page-system-page-locator
             page-system-runtime-providers page-system-runtime-entry-points
             page-system-display-contract page-system-inspection-entry-points
             page-system-validation-entry-points page-system-source-files
             page-system-artifacts page-system-display-check-function
             page-system-description)
  (make-instance class
                 :page-system-id page-system-id
                 :page-system-title page-system-title
                 :page-system-kind page-system-kind
                 :page-system-asdf-system-name
                 (page-system-normalize-system-name
                  page-system-asdf-system-name)
                 :page-system-page-locator page-system-page-locator
                 :page-system-runtime-providers page-system-runtime-providers
                 :page-system-runtime-entry-points
                 page-system-runtime-entry-points
                 :page-system-display-contract page-system-display-contract
                 :page-system-inspection-entry-points
                 page-system-inspection-entry-points
                 :page-system-validation-entry-points
                 page-system-validation-entry-points
                 :page-system-source-files page-system-source-files
                 :page-system-artifacts page-system-artifacts
                 :page-system-display-check-function
                 page-system-display-check-function
                 :page-system-description page-system-description))

(defgeneric page-system-runtime-systems (page-system))
(defgeneric ensure-page-system (page-system &key))
(defgeneric page-system-reload (page-system &key force))
(defgeneric page-system-display-ready-p (page-system))
(defgeneric page-system-inspection-targets (page-system))
(defgeneric page-system-validation-checks (page-system))
(defgeneric page-system-asdf-form (page-system))
(defgeneric materialize-page-system-asd (page-system &key pathname))
(defgeneric page-system-summary (page-system))
(defgeneric page-system-rendered-page (page-system &key signal-error?))
(defgeneric page-system-local-twin-pathname (page-system))

(defmethod page-system-runtime-systems ((system page-system))
  (remove-duplicates
   (mapcar #'page-runtime-provider-asdf-system-name
           (page-system-runtime-providers system))
   :test #'string=))

(defmethod ensure-page-system ((system page-system) &key)
  (register-page-system system))

(defmethod page-system-inspection-targets ((system page-system))
  (page-system-inspection-entry-points system))

(defmethod page-system-validation-checks ((system page-system))
  (page-system-validation-entry-points system))

(defmethod page-system-display-ready-p ((system page-system))
  (if (page-system-display-check-function system)
      (funcall (page-system-display-check-function system) system)
      (values t nil)))

(defclass page-system-reload-report ()
  ((page-system :reader page-system-reload-report-page-system
                :initarg :page-system)
   (asdf-system-name :reader page-system-reload-report-asdf-system-name
                     :initarg :asdf-system-name)
   (force :reader page-system-reload-report-force-p :initarg :force)
   (loaded-p :reader page-system-reload-report-loaded-p :initarg :loaded-p)
   (display-ready-p :reader page-system-reload-report-display-ready-p
                    :initarg :display-ready-p)
   (checked-at :reader page-system-reload-report-checked-at
               :initarg :checked-at)
   (warnings :reader page-system-reload-report-warnings
             :initarg :warnings
             :initform nil)))

(defmethod print-object ((report page-system-reload-report) stream)
  (print-unreadable-object (report stream :type t :identity nil)
    (format stream "~A loaded=~A ready=~A"
            (page-system-reload-report-asdf-system-name report)
            (page-system-reload-report-loaded-p report)
            (page-system-reload-report-display-ready-p report))))

(defvar *page-system-latest-reload-reports*
  (make-hash-table :test #'equal))

(defun page-system-latest-reload-report (system)
  (gethash (page-system-asdf-system-name system)
           *page-system-latest-reload-reports*))

(defmethod page-system-reload ((system page-system) &key (force t))
  (asdf:load-system (page-system-asdf-system-name system) :force force)
  (multiple-value-bind (ready warnings)
      (page-system-display-ready-p system)
    (let ((report
           (make-instance 'page-system-reload-report
                          :page-system system
                          :asdf-system-name
                          (page-system-asdf-system-name system)
                          :force force
                          :loaded-p t
                          :display-ready-p ready
                          :checked-at (get-universal-time)
                          :warnings warnings)))
      (setf (gethash (page-system-asdf-system-name system)
                     *page-system-latest-reload-reports*)
            report)
      report)))

(defmethod page-system-asdf-form ((system page-system))
  `(asdf:defsystem ,(intern (string-upcase (page-system-asdf-system-name system))
                            :keyword)
       :description ,(format nil "Page system for ~A" (page-system-title system))
       :depends-on ,(mapcar (lambda (system-name)
                              (intern (string-upcase system-name) :keyword))
                            (page-system-runtime-systems system))
       :serial t
       :components nil))

(defmethod materialize-page-system-asd ((system page-system) &key pathname)
  (let ((form (page-system-asdf-form system)))
    (when pathname
      (ensure-directories-exist pathname)
      (with-open-file (stream pathname
                              :direction :output
                              :if-exists :supersede
                              :if-does-not-exist :create
                              :external-format :utf-8)
        (prin1 form stream)
        (terpri stream)))
    form))

(defmethod page-system-summary ((system page-system))
  (list :id (page-system-id system)
        :title (page-system-title system)
        :kind (page-system-kind system)
        :asdf-system-name (page-system-asdf-system-name system)
        :page-locator (page-system-page-locator system)
        :runtime-systems (page-system-runtime-systems system)
        :display-contract (page-system-display-contract system)))

(defun page-system-locator-page-parts (locator)
  (cond
    ((uiop:string-prefix-p "hyperdoc:" locator)
     (values "hyperdoc"
             (subseq locator (length "hyperdoc:"))))
    ((uiop:string-prefix-p "fedwiki:" locator)
     (when-let (slash-position (position #\/ locator))
       (values (subseq locator 0 slash-position)
               (subseq locator (1+ slash-position)))))
    (t
     (when-let (slash-position (position #\/ locator))
       (values (subseq locator 0 slash-position)
               (subseq locator (1+ slash-position)))))))

(defun page-system-absolute-path-string-p (path)
  (and (stringp path)
       (plusp (length path))
       (char= (char path 0) #\/)))

(defun page-system-package-function (package-name symbol-name)
  (let* ((package (find-package package-name))
         (symbol (and package
                      (find-symbol symbol-name package))))
    (when (and symbol (fboundp symbol))
      (symbol-function symbol))))

(defun page-system-call-package-function (package-name symbol-name &rest args)
  (let ((function (page-system-package-function package-name symbol-name)))
    (unless function
      (error "No callable function ~A::~A is available."
             package-name
             symbol-name))
    (apply function args)))

(defun page-system-ensure-local-fedwiki-twin-page (hyperbook page-id pathname)
  "Register a localhost FedWiki twin as a real FedWiki page when it is not in the remote sitemap."
  (when (and hyperbook pathname (uiop:file-exists-p pathname))
    (let* ((pages (page-system-call-package-function
                   "HYPERBOOK/FEDWIKI"
                   "PAGES-OF"
                   hyperbook))
           (slugs (page-system-call-package-function
                   "HYPERBOOK/FEDWIKI"
                   "SLUGS-OF"
                   hyperbook))
           (json (page-system-call-package-function
                  "HYPERBOOK/FEDWIKI"
                  "READ-LOCALHOST-FEDWIKI-PAGE-JSON-FILE"
                  pathname))
           (title (gethash "title" json))
           (page (or (gethash page-id pages)
                     (page-system-call-package-function
                      "HYPERBOOK/FEDWIKI"
                      "MAKE-FEDWIKI-PAGE"
                      hyperbook
                      page-id
                      title))))
      (page-system-call-package-function
       "HYPERBOOK/FEDWIKI"
       "SET-PAGE-DATA"
       page
       json)
      (setf (gethash page-id pages) page
            (gethash page-id slugs) title)
      (when title
        (setf (gethash title slugs) page-id))
      page)))

(defmethod page-system-rendered-page ((system page-system)
                                      &key signal-error?)
  (multiple-value-bind (hyperbook-id page-id)
      (page-system-locator-page-parts (page-system-page-locator system))
    (when page-id
      (let ((hyperbook
             (cond
               ((string= hyperbook-id "hyperdoc")
                (or (hyperbook:find-hyperbook hyperbook-id)
                    *hyperdoc*))
               (t
                (hyperbook:find-hyperbook hyperbook-id
                                          :signal-error? signal-error?)))))
        (when hyperbook
          (hyperbook:find-page hyperbook
                               page-id
                               :signal-error? signal-error?))))))

(defmethod page-system-rendered-page ((system fedwiki-page-system)
                                      &key signal-error?)
  (multiple-value-bind (hyperbook-id page-id)
      (page-system-locator-page-parts (page-system-page-locator system))
    (when page-id
      (let ((hyperbook (hyperbook:find-hyperbook
                        hyperbook-id
                        :signal-error? signal-error?)))
        (when hyperbook
          (or (page-system-ensure-local-fedwiki-twin-page
               hyperbook
               page-id
               (page-system-local-twin-pathname system))
              (hyperbook:find-page hyperbook
                                   page-id
                                   :signal-error? nil)
              (when signal-error?
                (hyperbook:find-page hyperbook
                                     page-id
                                     :signal-error? signal-error?))))))))

(defmethod page-system-local-twin-pathname ((system page-system))
  (declare (ignore system))
  nil)

(defmethod page-system-local-twin-pathname ((system fedwiki-page-system))
  (loop for source in (page-system-source-files system)
        when (and (page-system-absolute-path-string-p source)
                  (search "/.wiki/" source :test #'char=)
                  (search "/pages/" source :test #'char=))
        do (return (pathname source))))

(defclass page-system-registry ()
  ((systems-by-asdf-name :reader page-system-registry-systems-by-asdf-name
                         :initform (make-hash-table :test #'equal))
   (systems-by-page-locator :reader page-system-registry-systems-by-page-locator
                            :initform (make-hash-table :test #'equal))))

(defvar *page-system-registry* (make-instance 'page-system-registry))
(defvar *page-system-registry-defaults-loaded-p* nil)

(defun page-system-registry-systems (&optional (registry *page-system-registry*))
  (loop for system being the hash-values of
        (page-system-registry-systems-by-asdf-name registry)
        collect system))

(defun register-page-system (system &optional (registry *page-system-registry*))
  (setf (gethash (page-system-asdf-system-name system)
                 (page-system-registry-systems-by-asdf-name registry))
        system)
  (setf (gethash (page-system-page-locator system)
                 (page-system-registry-systems-by-page-locator registry))
        system)
  system)

(defun ensure-default-page-systems-registered ()
  (unless *page-system-registry-defaults-loaded-p*
    (setf *page-system-registry-defaults-loaded-p* :loading)
    (dolist (system-name *page-system-default-asdf-systems*)
      (handler-case
          (asdf:load-system system-name)
        (error (condition)
          (warn "Could not load default page system ~A: ~A"
                system-name
                condition))))
    (setf *page-system-registry-defaults-loaded-p* t))
  *page-system-registry*)

(defun page-system-registry ()
  (ensure-default-page-systems-registered))

(defun find-page-system (identifier &key (by :asdf-system-name) signal-error?)
  (let ((registry (page-system-registry)))
    (or
     (ecase by
       (:asdf-system-name
        (gethash (page-system-normalize-system-name identifier)
                 (page-system-registry-systems-by-asdf-name registry)))
       (:page-locator
        (gethash identifier
                 (page-system-registry-systems-by-page-locator registry))))
     (when signal-error?
       (error "No page system found for ~S by ~S." identifier by)))))

(defmethod ensure-page-system ((identifier symbol) &key)
  (find-page-system identifier :signal-error? t))

(defmethod ensure-page-system ((identifier string) &key (by :asdf-system-name))
  (find-page-system identifier :by by :signal-error? t))

(defun page-system-source-file-exists-p (relative-path)
  (uiop:file-exists-p (page-system-repo-pathname relative-path)))

(defun page-system-all-source-files-exist-p (system)
  (every (lambda (path)
           (or (not (stringp path))
               (and (page-system-absolute-path-string-p path)
                    (uiop:file-exists-p path))
               (page-system-source-file-exists-p path)))
         (page-system-source-files system)))

(defun mobile-progressive-chrome-page-system-display-ready-p (system)
  (declare (ignore system))
  (let* ((path (page-system-repo-pathname
                "hyperdoc/Mobile progressive chrome in HyperDoc.html"))
         (source (page-system-read-file-string path))
         (missing nil))
    (dolist (needle '("Capabilities closed"
                      "Boundary-mounted handles"
                      "ASDF reload boundary"))
      (unless (and source (search needle source :test #'char=))
        (push (format nil "Missing page text: ~A" needle) missing)))
    (values (null missing) (nreverse missing))))

(defun dm6-appembed-inline-proof-page-system-display-ready-p (system)
  (declare (ignore system))
  (let* ((page-path
          (page-system-repo-pathname
           "hyperdoc/DM6 AppEmbed HyperDoc Inline Proof.html"))
         (source (page-system-read-file-string page-path))
         (stored-count (page-system-count-substring
                        "class=\"dm6-stored\""
                        source))
         (missing nil))
    (unless (= stored-count 1)
      (push (format nil "Expected exactly one script.dm6-stored, found ~D."
                    stored-count)
            missing))
    (dolist (relative-path '("assets/dm6-elm/app.js"
                             "assets/dm6-elm/hyperdoc-dm6-inline.js"
                             "assets/dm6-elm/hyperdoc-dm6-inline.css"))
      (unless (page-system-source-file-exists-p relative-path)
        (push (format nil "Missing AppEmbed asset: ~A" relative-path) missing)))
    (values (null missing) (nreverse missing))))

(defun fedwiki-mobile-progressive-chrome-page-system-display-ready-p (system)
  (declare (ignore system))
  (let* ((path #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/mobile-progressive-chrome-in-hyperdoc")
         (source (page-system-read-file-string path))
         (missing nil))
    (unless source
      (push "Localhost FedWiki twin file is missing." missing))
    (unless (and source
                 (search "\"title\": \"Mobile progressive chrome in HyperDoc\""
                         source
                         :test #'char=))
      (push "Localhost FedWiki twin does not expose the expected page title."
            missing))
    (values (null missing) (nreverse missing))))

(defun fedwiki-shop3-page-system-display-ready-p (system)
  (let* ((path #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/shop3")
         (source (page-system-read-file-string path))
         (missing nil))
    (unless source
      (push "Localhost FedWiki SHOP3 twin file is missing." missing))
    (unless (and source
                 (search "\"title\": \"SHOP3\"" source :test #'char=))
      (push "Localhost FedWiki SHOP3 twin does not expose the expected page title."
            missing))
    (unless (ignore-errors
              (page-system-rendered-page system :signal-error? t))
      (push "FedWiki rendered page object does not resolve." missing))
    (unless (ignore-errors
              (asdf:find-system *shop3-asdf-system-name* nil))
      (push "ASDF cannot find the SHOP3 planner system." missing))
    (unless (shop3-runtime-ready-p)
      (push "SHOP3 runtime did not load or expected packages are missing."
            missing))
    (unless (shop3-source-root-pathname)
      (push "SHOP3 source provenance is not inspectable." missing))
    (values (null missing) (nreverse missing))))

(defun make-mobile-progressive-chrome-page-system ()
  (make-page-system
   'hyperdoc-page-system
   :page-system-id "hyperdoc-page-mobile-progressive-chrome"
   :page-system-title "Mobile progressive chrome in HyperDoc"
   :page-system-kind :hyperdoc
   :page-system-asdf-system-name "hyperdoc/page/mobile-progressive-chrome"
   :page-system-page-locator "hyperdoc:Mobile progressive chrome in HyperDoc"
   :page-system-runtime-providers
   (list (hyperdoc-runtime-provider)
         (hyperdoc-explorer-runtime-provider)
         (make-page-runtime-provider
          :provider-id "mobile-progressive-chrome-feature-slice"
          :provider-kind :feature-slice
          :asdf-system-name "hyperdoc/mobile-progressive-chrome"
          :ensure-function "asdf:load-system :hyperdoc/mobile-progressive-chrome"
          :readiness-function "mobile-progressive-chrome-system-slice returns an inspectable object"
          :display-notes "Provides the feature-specific state, SCXML, plan, and validation helpers."))
   :page-system-runtime-entry-points
   '("(mobile-progressive-chrome-page)"
     "(mobile-progressive-chrome-system-slice)"
     "(mobile-progressive-chrome-state-model)")
   :page-system-display-contract
   '("Capabilities collapse behind )("
     "Inspector tabs collapse behind rotated )("
     "Boundary handles are mounted on .inspector-pane"
     "Collapsed chrome consumes no document vertical space"
     "Route capture starts only after explicit Connect / Lay route")
   :page-system-inspection-entry-points
   '("(find-page-system :hyperdoc/page/mobile-progressive-chrome)"
     "(mobile-progressive-chrome-system-slice)"
     "(mobile-progressive-chrome-scxml-artifact)"
     "(mobile-progressive-chrome-plan)")
   :page-system-validation-entry-points
   '("hyperdoc/tests:run-page-system-smoke-tests"
     "hyperdoc/tests:run-mobile-progressive-chrome-smoke-tests"
     "tests/playwright/mobile-progressive-chrome.spec.js")
   :page-system-source-files
   '("hyperdoc/Mobile progressive chrome in HyperDoc.html"
     "hyperdoc/mobile-progressive-chrome.lisp"
     "hyperdoc/mobile-progressive-chrome.scxml"
     "hyperdoc/dock.lisp"
     "hyperdoc/dom-annotations.lisp"
     "hyperdoc-explorer/dock.lisp"
     "hyperdoc-explorer/dom-annotations.lisp"
     "assets/hyperdoc/js/dom-annotation-connect.js"
     "assets/hyperdoc/css/dom-annotation-connect.css"
     "tests/mobile-progressive-chrome-smoke.lisp"
     "tests/playwright/mobile-progressive-chrome.spec.js")
   :page-system-artifacts
   '("Mobile progressive chrome SCXML"
     "Mobile progressive chrome plan"
     "Dock presentation state model")
   :page-system-display-check-function
   #'mobile-progressive-chrome-page-system-display-ready-p
   :page-system-description
   "Page-system reload boundary for the mobile progressive chrome documentation page."))

(defun make-dm6-appembed-inline-proof-page-system ()
  (make-page-system
   'hyperdoc-page-system
   :page-system-id "hyperdoc-page-dm6-appembed-inline-proof"
   :page-system-title "DM6 AppEmbed HyperDoc Inline Proof"
   :page-system-kind :hyperdoc
   :page-system-asdf-system-name "hyperdoc/page/dm6-appembed-inline-proof"
   :page-system-page-locator "hyperdoc:DM6 AppEmbed HyperDoc Inline Proof"
   :page-system-runtime-providers
   (list (hyperdoc-runtime-provider)
         (hyperdoc-explorer-runtime-provider))
   :page-system-runtime-entry-points
   '("(dm6-inline-proof-page-pathname)"
     "(dm6-page-topicmap-seed-report)"
     "(materialize-dm6-inline-proof-page-topicmap-seed!)")
   :page-system-display-contract
   '("Page contains exactly one generated script.dm6-stored"
     "Stored seed uses native AppEmbed model JSON"
     "AppEmbed assets are reachable from assets/dm6-elm"
     "Page renders in the HyperDoc inspector")
   :page-system-inspection-entry-points
   '("(find-page-system :hyperdoc/page/dm6-appembed-inline-proof)"
     "(dm6-page-topicmap-seed-report)")
   :page-system-validation-entry-points
   '("hyperdoc/tests:run-page-system-smoke-tests"
     "hyperdoc/tests:run-dm6-page-topicmap-smoke-tests")
   :page-system-source-files
   '("hyperdoc/DM6 AppEmbed HyperDoc Inline Proof.html"
     "hyperdoc/dm6-page-topicmap-api.lisp"
     "hyperdoc/dm6-page-topicmap.lisp"
     "assets/dm6-elm/app.js"
     "assets/dm6-elm/hyperdoc-dm6-inline.js"
     "assets/dm6-elm/hyperdoc-dm6-inline.css"
     "tests/dm6-page-topicmap-smoke.lisp")
   :page-system-artifacts
   '("DM6 page-local topicmap seed"
     "Generated script.dm6-stored")
   :page-system-display-check-function
   #'dm6-appembed-inline-proof-page-system-display-ready-p
   :page-system-description
   "Page-system reload boundary for the DM6 AppEmbed inline proof page."))

(defun make-fedwiki-mobile-progressive-chrome-page-system ()
  (make-page-system
   'fedwiki-page-system
   :page-system-id
   "fedwiki-page-wiki.ralfbarkow.ch-mobile-progressive-chrome-in-hyperdoc"
   :page-system-title "mobile-progressive-chrome-in-hyperdoc"
   :page-system-kind :fedwiki
   :page-system-asdf-system-name
   "fedwiki/page/wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc"
   :page-system-page-locator
   "fedwiki:wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc"
   :page-system-runtime-providers
   (list (hyperdoc-runtime-provider)
         (fedwiki-client-runtime-provider)
         (fedwiki-materialization-runtime-provider))
   :page-system-runtime-entry-points
   '("(hyperbook:find-hyperbook \"fedwiki:wiki.ralfbarkow.ch\")"
     "(plan-fedwiki-page-materialization \"mobile-progressive-chrome-in-hyperdoc\")")
   :page-system-display-contract
   '("Localhost FedWiki page JSON resolves without live network"
     "Story renderer runtime is provided by hyperbook/fedwiki"
     "Materialization metadata remains inspectable")
   :page-system-inspection-entry-points
   '("(find-page-system :fedwiki/page/wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc)"
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/mobile-progressive-chrome-in-hyperdoc")
   :page-system-validation-entry-points
   '("hyperdoc/tests:run-page-system-smoke-tests"
     "hyperdoc/tests:run-localhost-fedwiki-page-pipeline-smoke-tests"
     "hyperdoc/tests:run-fedwiki-materialization-smoke-tests")
   :page-system-source-files
   '("/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/mobile-progressive-chrome-in-hyperdoc"
     "hyperdoc/fedwiki-materialization.lisp"
     "hyperdoc/localhost-fedwiki-page-pipeline.lisp"
     "tests/fedwiki-materialization-smoke.lisp"
     "tests/localhost-fedwiki-page-pipeline-smoke.lisp")
   :page-system-artifacts
   '("localhost FedWiki twin"
     "FedWiki materialization plan")
   :page-system-display-check-function
   #'fedwiki-mobile-progressive-chrome-page-system-display-ready-p
   :page-system-description
   "Page-system reload boundary for the localhost FedWiki twin of the mobile progressive chrome documentation."))

(defun make-fedwiki-shop3-page-system ()
  (make-page-system
   'fedwiki-page-system
   :page-system-id "fedwiki-page-wiki.ralfbarkow.ch-shop3"
   :page-system-title "SHOP3"
   :page-system-kind :fedwiki
   :page-system-asdf-system-name
   "fedwiki/page/wiki.ralfbarkow.ch/shop3"
   :page-system-page-locator "fedwiki:wiki.ralfbarkow.ch/shop3"
   :page-system-runtime-providers
   (list (hyperdoc-runtime-provider)
         (fedwiki-client-runtime-provider)
         (fedwiki-materialization-runtime-provider)
         (shop3-runtime-provider)
         (hyperdoc-shop3-planning-runtime-provider))
   :page-system-runtime-entry-points
   '("(hyperbook:find-hyperbook \"fedwiki:wiki.ralfbarkow.ch\")"
     "(hyperbook:find-page * \"shop3\")"
     "(asdf:load-system :shop3)"
     "(asdf:load-system :hyperdoc/shop3)")
   :page-system-display-contract
   '("FedWiki page JSON resolves without live network"
     "Story renderer runtime is provided by hyperbook/fedwiki"
     "SHOP3 runtime is available through ASDF"
     "SHOP3 source provenance is inspectable"
     "Loading the page system does not run a planning problem automatically")
   :page-system-inspection-entry-points
   '("(find-page-system :fedwiki/page/wiki.ralfbarkow.ch/shop3)"
     "Open rendered page"
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/shop3"
     "(asdf:find-system :shop3)"
     "(ensure-shop3-runtime)"
     "(shop3-source-root-pathname)"
     "(shop3-runtime-provider)")
   :page-system-validation-entry-points
   '("hyperdoc/tests:run-page-system-smoke-tests"
     "hyperdoc/tests:run-shop3-page-system-smoke-tests"
     "asdf:load-system :fedwiki/page/wiki.ralfbarkow.ch/shop3"
     "asdf:load-system :shop3")
   :page-system-source-files
   '("/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/shop3"
     "hyperdoc/page-systems.lisp"
     "hyperdoc/page-systems/fedwiki-shop3.lisp"
     "fedwiki.asd"
     "hyperdoc-shop3/package.lisp"
     "hyperdoc-shop3/plan-objects.lisp"
     "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
     "hyperdoc-shop3/examples.lisp"
     "hyperdoc-shop3/views.lisp"
     "tests/page-system-smoke.lisp")
   :page-system-artifacts
   '("localhost FedWiki SHOP3 twin"
     "SHOP3 flake input"
     "SHOP3 runtime provider"
     "HyperDoc SHOP3 planning layer")
   :page-system-display-check-function
   #'fedwiki-shop3-page-system-display-ready-p
   :page-system-description
   "Page-system reload boundary for the localhost FedWiki SHOP3 page and the external SHOP3 HTN planner runtime."))

(eval-when (:load-toplevel :execute)
  (setf *topic-index-state* :stale))
