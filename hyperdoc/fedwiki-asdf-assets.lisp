;;;; HyperDoc-native writer for page-local FedWiki ASDF assets.

(in-package :hyperdoc)

(defparameter *fedwiki-page-assets-root*
  #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/")

(defclass page-asdf-asset-spec ()
  ((system-name :reader page-asdf-asset-spec-system-name :initarg :system-name)
   (page-slug :reader page-asdf-asset-spec-page-slug :initarg :page-slug)
   (page-title :reader page-asdf-asset-spec-page-title :initarg :page-title)
   (asset-root :reader page-asdf-asset-spec-asset-root :initarg :asset-root)
   (source-topic-id :reader page-asdf-asset-spec-source-topic-id
                    :initarg :source-topic-id)
   (files :reader page-asdf-asset-spec-files :initarg :files)
   (tests :reader page-asdf-asset-spec-tests :initarg :tests)
   (rendered-pages :reader page-asdf-asset-spec-rendered-pages
                   :initarg :rendered-pages)
   (zip-name :reader page-asdf-asset-spec-zip-name :initarg :zip-name)
   (package-name :reader page-asdf-asset-spec-package-name :initarg :package-name)
   (render-function :reader page-asdf-asset-spec-render-function
                    :initarg :render-function)
   (inspect-function :reader page-asdf-asset-spec-inspect-function
                     :initarg :inspect-function)
   (ensure-inspector-function
    :reader page-asdf-asset-spec-ensure-inspector-function
    :initarg :ensure-inspector-function)))

(defmethod print-object ((spec page-asdf-asset-spec) stream)
  (print-unreadable-object (spec stream :type t :identity nil)
    (format stream "~A -> ~A"
            (page-asdf-asset-spec-system-name spec)
            (page-asdf-asset-spec-page-slug spec))))

(defun page-asdf-normalize-name (name)
  (etypecase name
    (symbol (string-downcase (symbol-name name)))
    (string (string-downcase name))))

(defun page-asdf-normalize-package-name (name)
  (etypecase name
    (symbol (string-upcase (symbol-name name)))
    (string (string-upcase name))))

(defun fedwiki-page-assets-directory
    (page-slug &key (asset-root *fedwiki-page-assets-root*))
  (merge-pathnames
   (uiop:ensure-directory-pathname (page-asdf-normalize-name page-slug))
   (uiop:ensure-directory-pathname asset-root)))

(defun make-page-asdf-asset-spec
    (&key system-name page-slug page-title
       (asset-root *fedwiki-page-assets-root*)
       source-topic-id files tests rendered-pages zip-name package-name
       render-function inspect-function ensure-inspector-function)
  (let* ((system-name (page-asdf-normalize-name system-name))
         (page-slug (page-asdf-normalize-name (or page-slug system-name))))
    (make-instance
     'page-asdf-asset-spec
     :system-name system-name
     :page-slug page-slug
     :page-title page-title
     :asset-root (uiop:ensure-directory-pathname asset-root)
     :source-topic-id source-topic-id
     :files files
     :tests tests
     :rendered-pages rendered-pages
     :zip-name (or zip-name (format nil "~A-assets.zip" system-name))
     :package-name (page-asdf-normalize-package-name
                    (or package-name system-name))
     :render-function render-function
     :inspect-function inspect-function
     :ensure-inspector-function ensure-inspector-function)))

(defun page-asdf-asset-directory (spec)
  (fedwiki-page-assets-directory
   (page-asdf-asset-spec-page-slug spec)
   :asset-root (page-asdf-asset-spec-asset-root spec)))

(defun page-asdf-asset-asd-pathname (spec)
  (merge-pathnames
   (format nil "~A.asd" (page-asdf-asset-spec-system-name spec))
   (page-asdf-asset-directory spec)))

(defun page-asdf-template-pathname (relative-path)
  (asdf:system-relative-pathname
   :hyperdoc/fedwiki-asdf-assets
   (format nil "hyperdoc/fedwiki-asdf-assets/~A" relative-path)))

(defun page-asdf-file-path (file)
  (or (getf file :path)
      (error "Page ASDF asset file has no :PATH: ~S" file)))

(defun page-asdf-file-source (file)
  (getf file :source))

(defun page-asdf-file-content (file)
  (getf file :content))

(defun page-asdf-write-file (target file)
  (let* ((relative-path (page-asdf-file-path file))
         (pathname (merge-pathnames relative-path target))
         (source (page-asdf-file-source file)))
    (ensure-directories-exist pathname)
    (cond
      (source
       (uiop:copy-file source pathname))
      ((getf file :content)
       (with-open-file (stream pathname
                               :direction :output
                               :if-exists :supersede
                               :if-does-not-exist :create
                               :external-format :utf-8)
         (write-string (page-asdf-file-content file) stream)))
      (t
       (error "Page ASDF asset file has neither :SOURCE nor :CONTENT: ~S"
              file)))
    pathname))

(defun page-asdf-safe-clean-directory-p (spec directory)
  (let* ((root (namestring
                (uiop:ensure-directory-pathname
                 (page-asdf-asset-spec-asset-root spec))))
         (dir (namestring (uiop:ensure-directory-pathname directory))))
    (and (> (length (page-asdf-asset-spec-page-slug spec)) 0)
         (uiop:string-prefix-p root dir)
         (not (string= root dir)))))

(defun write-page-asdf-system (spec &key clean)
  (let ((target (page-asdf-asset-directory spec)))
    (when clean
      (uiop:delete-directory-tree
       target
       :validate (lambda (directory)
                   (page-asdf-safe-clean-directory-p spec directory))
       :if-does-not-exist :ignore))
    (ensure-directories-exist (merge-pathnames "src/.keep" target))
    (ensure-directories-exist (merge-pathnames "pages/.keep" target))
    (ensure-directories-exist (merge-pathnames "examples/.keep" target))
    (ensure-directories-exist (merge-pathnames "tests/.keep" target))
    (let ((written
            (mapcar (lambda (file)
                      (page-asdf-write-file target file))
                    (page-asdf-asset-spec-files spec))))
      (list :page-directory target
            :asd (page-asdf-asset-asd-pathname spec)
            :written written))))

(defun load-page-asdf-system (spec &key force)
  (let ((asd-path (page-asdf-asset-asd-pathname spec))
        (system-name (page-asdf-asset-spec-system-name spec)))
    (unless (uiop:file-exists-p asd-path)
      (error "Page-local ASDF file does not exist: ~A" asd-path))
    (when force
      (ignore-errors (asdf:clear-system system-name))
      (ignore-errors (asdf:clear-system (format nil "~A/test" system-name))))
    (asdf:load-asd asd-path :name system-name)
    (asdf:load-system system-name :force force)
    (asdf:find-system system-name)))

(defun test-page-asdf-system (spec)
  (let* ((system-name (page-asdf-asset-spec-system-name spec))
         (test-system (format nil "~A/test" system-name)))
    (asdf:load-asd (page-asdf-asset-asd-pathname spec) :name system-name)
    (if (page-asdf-asset-spec-tests spec)
        (progn
          (asdf:test-system test-system)
          (list :test-system test-system :status :passed))
        (list :test-system test-system :status :no-tests))))

(defun page-asdf-package-symbol (spec symbol-name)
  (let* ((package (find-package (page-asdf-asset-spec-package-name spec)))
         (symbol (and package
                      (find-symbol (string-upcase symbol-name) package))))
    (unless (and symbol (fboundp symbol))
      (error "No callable generated symbol ~A::~A is available."
             (page-asdf-asset-spec-package-name spec)
             symbol-name))
    symbol))

(defun page-asdf-call-generated (spec symbol-name &rest args)
  (apply (symbol-function (page-asdf-package-symbol spec symbol-name)) args))

(defun page-asdf-generated-diagnostic-status (spec object)
  (let ((package (find-package (page-asdf-asset-spec-package-name spec))))
    (when package
      (multiple-value-bind (symbol status)
          (find-symbol "MG-INSPECTOR-VIEWS-DIAGNOSTIC-STATUS" package)
        (when (and symbol (eq status :external) (fboundp symbol))
          (ignore-errors (funcall symbol object)))))))

(defun page-asdf-inspection-ready-p (spec result)
  (let ((ensure-result (getf result :ensure)))
    (or (member ensure-result '(t :ok :installed :already-installed))
        (member (page-asdf-generated-diagnostic-status spec ensure-result)
                '(:ok :installed :already-installed)))))

(defun inspect-page-asdf-system (spec)
  (let* ((ensure-function (page-asdf-asset-spec-ensure-inspector-function spec))
         (inspect-function (page-asdf-asset-spec-inspect-function spec))
         (ensure-result
           (when ensure-function
             (page-asdf-call-generated spec ensure-function)))
         (inspection-results
           (when inspect-function
             (mapcar (lambda (page)
                       (page-asdf-call-generated spec inspect-function page))
                     (page-asdf-asset-spec-rendered-pages spec)))))
    (list :ensure ensure-result
          :inspections inspection-results)))

(defun write-page-asdf-rendered-artifacts (spec)
  (let ((render-function (page-asdf-asset-spec-render-function spec)))
    (if render-function
        (page-asdf-call-generated spec render-function)
        nil)))

(defun page-asdf-string-suffix-p (suffix string)
  (let ((suffix-length (length suffix))
        (string-length (length string)))
    (and (<= suffix-length string-length)
         (string= suffix string
                  :start2 (- string-length suffix-length)))))

(defun page-asdf-directory-files-recursive (directory)
  (append (uiop:directory-files directory)
          (mapcan #'page-asdf-directory-files-recursive
                  (uiop:subdirectories directory))))

(defun page-asdf-zip-entry-allowed-p (spec relative-path)
  (let ((system-prefix (format nil "~A/"
                               (page-asdf-asset-spec-system-name spec))))
    (and (not (uiop:string-prefix-p system-prefix relative-path))
         (not (uiop:string-prefix-p ".cache/" relative-path))
         (not (uiop:string-prefix-p "cache/" relative-path))
         (not (search "/.cache/" relative-path :test #'char=))
         (not (search "__pycache__/" relative-path :test #'char=))
         (not (search "/cache/" relative-path :test #'char=))
         (not (string= ".DS_Store" relative-path))
         (not (page-asdf-string-suffix-p "/.DS_Store" relative-path))
         (not (page-asdf-string-suffix-p ".fasl" relative-path))
         (not (page-asdf-string-suffix-p ".zip" relative-path)))))

(defun page-asdf-zip-input-files (spec)
  (let ((directory (page-asdf-asset-directory spec)))
    (sort
     (loop for file in (page-asdf-directory-files-recursive directory)
           for relative = (enough-namestring file directory)
           when (page-asdf-zip-entry-allowed-p spec relative)
             collect relative)
     #'string<)))

(defun build-page-asdf-asset-zip (spec &key destination)
  (let* ((directory (page-asdf-asset-directory spec))
         (zip-path (or destination
                       (merge-pathnames
                        (page-asdf-asset-spec-zip-name spec)
                        directory)))
         (zip-path (merge-pathnames zip-path))
         (entries (page-asdf-zip-input-files spec)))
    (unless entries
      (error "No files are eligible for page ASDF asset ZIP: ~A" directory))
    (ensure-directories-exist zip-path)
    (when (uiop:file-exists-p zip-path)
      (delete-file zip-path))
    (uiop:run-program
     (append (list "zip" "-q" (namestring zip-path)) entries)
     :directory directory
     :output :string
     :error-output :string)
    (list :zip zip-path
          :source-directory directory
          :entries entries)))

(defun deploy-page-asdf-asset-zip (spec zip-path)
  (let ((directory (page-asdf-asset-directory spec)))
    (ensure-directories-exist (merge-pathnames "deploy.keep" directory))
    (uiop:run-program
     (list "unzip" "-o" (namestring zip-path) "-d" (namestring directory))
     :output :string
     :error-output :string)
    (list :deployed zip-path
          :page-directory directory)))

(defun page-asdf-asset-workflow
    (spec &key clean force test inspect zip)
  (let* ((write-report (write-page-asdf-system spec :clean clean))
         (load-report (load-page-asdf-system spec :force force))
         (test-report (when test
                        (test-page-asdf-system spec)))
         (inspect-report (when inspect
                           (inspect-page-asdf-system spec))))
    (when (and inspect
               (not (page-asdf-inspection-ready-p spec inspect-report)))
      (return-from page-asdf-asset-workflow
        (list :status :inspection-unavailable
              :write write-report
              :load load-report
              :test test-report
              :inspect inspect-report
              :rendered nil
              :zip nil)))
    (let* ((render-report (write-page-asdf-rendered-artifacts spec))
           (zip-report (when zip
                         (build-page-asdf-asset-zip spec))))
      (list :status :ok
            :write write-report
            :load load-report
            :test test-report
            :inspect inspect-report
            :rendered render-report
            :zip zip-report))))

(defun page-asdf-template-file (relative-path)
  (list :path relative-path
        :source (page-asdf-template-pathname
                 (format nil "metagraph/~A" relative-path))))

(defun make-metagraph-jsonld-fluree-asset-spec
    (&key (asset-root *fedwiki-page-assets-root*))
  (let ((system "metagraph-as-bipartite-graph-json-ld--fluree"))
    (make-page-asdf-asset-spec
     :system-name system
     :page-slug system
     :page-title "Metagraph as Bipartite Graph: JSON-LD + Fluree"
     :asset-root asset-root
     :source-topic-id 973197
     :files (cons
             (list :path "metagraph-as-bipartite-graph-json-ld--fluree.asd"
                   :source (page-asdf-template-pathname
                            "metagraph/metagraph-as-bipartite-graph-json-ld--fluree.asd.template"))
             (mapcar #'page-asdf-template-file
                     '("src/package.lisp"
                       "src/topicmaps.lisp"
                       "src/projections.lisp"
                       "src/install.lisp"
                       "pages/Metagraph as Bipartite Graph JSON-LD Fluree Topicmap View.html"
                       "examples/mrepl-session.lisp"
                       "tests/smoke.lisp"
                       "README.md"
                       "INSTALL-STEPS.md"
                       "MANIFEST.txt")))
     :tests '(:asdf-test-system)
     :rendered-pages '(:conversation-story :layer-contract :planning-example)
     :zip-name (format nil "~A-assets.zip" system)
     :package-name system
     :render-function "MG-WRITE-ALL-RENDERED-TOPICMAPS"
     :inspect-function "MG-INSPECT-RENDERED-TOPICMAP"
     :ensure-inspector-function "MG-ENSURE-INSPECTOR-VIEWS")))
