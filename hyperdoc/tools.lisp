;;;; Support for tools
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defclass tool-page (page)
  ((symbol :reader symbol-of :initarg :symbol)
   (package :reader package-of :initarg :package)
   (parts :accessor parts-of :initform nil)))

(defvar *tools* (make-hash-table :test #'eq))

(defun get-tool (name)
  (or (gethash name *tools*)
      (error "No tool named ~A" name)))

(defun make-tool (symbol id)
  (let ((tool (make-instance 'tool-page
                             :id id
                             :symbol symbol
                             :package *package*)))
    (setf (gethash symbol *tools*) tool)
    (push (cons :html (concatenate 'string "<h1>" id "</h1>"))
          (parts-of tool))
    tool))

(defvar *current-tool*)

(defmacro deftool (symbol title &body body)
  `(progn
     (defvar ,symbol)
     (let ((*current-tool* (make-tool ',symbol ,title)))
       (setf ,symbol *current-tool*)
       ,@body)))

(defun html-generator* (fn)
  (assert (typep *current-tool* 'tool-page))
  (push (cons :generator fn)
        (parts-of *current-tool*)))

(defmacro html-generator (&body body)
  `(html-generator* #'(lambda () ,@body)))

(defun html (s)
  (assert (typep *current-tool* 'tool-page))
  (push (cons :html s)
        (parts-of *current-tool*)))

(defun markdown (s)
  (assert (typep *current-tool* 'tool-page))
  (push (cons :markdown s)
        (parts-of *current-tool*)))

;;
;; Playgrounds as tool pages
;;

(defclass playground-page (page)
  ((initial-content :reader initial-content-of :initarg :initial-content)))

(defun make-playground (symbol id initial-content)
  (let ((page (make-instance symbol
                             :id id
                             :initial-content initial-content)))
    (setf (gethash symbol *tools*) page)
    page))

(defmacro defplayground (symbol title initial-content)
  `(progn (defclass ,symbol (playground-page) ())
          (make-playground ',symbol ,title ,initial-content)))

(defclass git-commit-target ()
  ((system :reader system-of :initarg :system :type asdf:system)
   (repo-root :reader repo-root-of :initarg :repo-root :type pathname)
   (repository-root-source :reader repository-root-source-of
                           :initarg :repository-root-source
                           :initform :system-source-default)
   (commit-hash :reader commit-hash-of :initarg :commit-hash :type string)))

(defclass canonical-route-discovery ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (page :reader page-of :initarg :page :type hb:page)
   (inspectable-object :reader inspectable-object-of
                       :initarg :inspectable-object
                       :initform nil)
   (inspectable-object-label :reader inspectable-object-label-of
                             :initarg :inspectable-object-label
                             :initform nil)
   (repository-root :reader repository-root-of
                    :initarg :repository-root
                    :initform nil)
   (repository-root-source :reader repository-root-source-of
                           :initarg :repository-root-source
                           :initform nil)
   (notes :reader notes-of
          :initarg :notes
          :initform nil)))

(defparameter *git-program* nil
  "Optional Git executable designator for HyperDoc Git-backed surfaces.
If NIL, HYPERDOC_GIT_PROGRAM is consulted and then PATH lookup for \"git\".")

(defparameter *git-repository-root* nil
  "Optional explicit Git repository root designator for HyperDoc Git-backed
surfaces. If NIL, HYPERDOC_GIT_REPOSITORY_ROOT is consulted before falling back
to repository discovery from the current process working directory and then the
loaded ASDF system.")

(defparameter +git-history-runtime-policy+
  "Git-backed history surfaces are supported in the dev shell and only in
deployed dreyeck runtimes that provide both a Git executable and usable
repository metadata for the HyperDoc tree. Built release images may contain
source snapshots without a live checkout or .git metadata; those runtimes
should render an inspectable unavailability surface instead of a raw
subprocess failure unless an explicit repository-root override points at a live
checkout or the runtime is intentionally launched from a working directory
inside a live checkout.")

(defun git-runtime-classification-label (classification)
  (ecase classification
    (:git-executable-unavailable
     "git-executable-unavailable")
    (:repository-metadata-unavailable
     "repository-metadata-unavailable")
    (:git-command-failed
     "git-command-failed")))

(defun git-runtime-condition-title (classification)
  (ecase classification
    (:git-executable-unavailable
     "Git executable unavailable in this runtime")
    (:repository-metadata-unavailable
     "Repository metadata unavailable in this runtime")
    (:git-command-failed
     "Git command failed in this runtime")))

(defun git-runtime-condition-summary (classification)
  (ecase classification
    (:git-executable-unavailable
     "Git-backed HyperDoc history surfaces cannot resolve a usable Git executable in the current runtime.")
    (:repository-metadata-unavailable
     "Git-backed HyperDoc history surfaces can find Git here, but the current runtime does not expose usable repository metadata for the requested command.")
    (:git-command-failed
     "Git-backed HyperDoc history surfaces found Git, but the requested command still failed for another reason.")))

(defun git-runtime-default-reason (classification)
  (ecase classification
    (:git-executable-unavailable
     "Git history unavailable: no usable Git executable is available in this runtime.")
    (:repository-metadata-unavailable
     "Git history unavailable: this runtime is not backed by usable repository metadata for the requested Git command.")
    (:git-command-failed
     "Git history unavailable: the requested Git command failed for a reason other than executable discovery or repository metadata availability.")))

(define-condition git-runtime-unavailable (error)
  ((id :reader id-of
       :initarg :id
       :initform "git-runtime-unavailable")
   (classification :reader classification-of
                   :initarg :classification
                   :initform :git-command-failed)
   (title :reader title-of
          :initarg :title
          :initform "Git unavailable in this runtime")
   (summary :reader summary-of
            :initarg :summary
            :initform "Git-backed HyperDoc history surfaces need a Git executable and a live repository checkout in the current runtime.")
   (operation :reader operation-of
              :initarg :operation
              :initform "git command")
   (command :reader command-of
            :initarg :command
            :initform nil)
   (exit-code :reader exit-code-of
              :initarg :exit-code
              :initform nil)
   (working-directory :reader working-directory-of
                      :initarg :working-directory
                      :initform nil)
   (repository-root :reader repository-root-of
                    :initarg :repository-root
                    :initform nil)
   (repository-root-source :reader repository-root-source-of
                           :initarg :repository-root-source
                           :initform nil)
   (requested-program :reader requested-program-of
                      :initarg :requested-program
                      :initform nil)
   (resolved-program :reader resolved-program-of
                     :initarg :resolved-program
                     :initform nil)
   (configuration-source :reader configuration-source-of
                         :initarg :configuration-source
                         :initform nil)
   (runtime-policy :reader runtime-policy-of
                   :initarg :runtime-policy
                   :initform +git-history-runtime-policy+)
   (reason :reader reason-of
           :initarg :reason
           :type string)
   (detail :reader detail-of
           :initarg :detail
           :initform nil)
   (guidance :reader guidance-of
             :initarg :guidance
             :initform nil)))

(defun full-git-commit-hash-p (string)
  (and (stringp string)
       (= 40 (length string))
       (every #'(lambda (char)
                  (not (null (digit-char-p char 16))))
              string)))

(defun trim-line-endings (string)
  (string-right-trim '(#\Newline #\Return) string))

(defun pathname-namestring-or-nil (pathname-designator)
  (when pathname-designator
    (namestring (pathname pathname-designator))))

(defun call-hyperbook-server-helper (name &rest arguments)
  (let* ((package (find-package :hyperbook/server))
         (symbol (and package
                      (find-symbol (string name) package))))
    (unless (and symbol
                 (fboundp symbol))
      (error "Route discovery helper ~A is unavailable until :hyperdoc/server is loaded."
             name))
    (apply (symbol-function symbol) arguments)))

(defun canonical-route-origin ()
  (call-hyperbook-server-helper 'canonical-route-origin))

(defun canonical-page-path (page)
  (call-hyperbook-server-helper 'canonical-page-path page))

(defun canonical-page-url (page)
  (call-hyperbook-server-helper 'canonical-page-url page))

(defun canonical-inspector-path (object)
  (call-hyperbook-server-helper 'canonical-inspector-path object))

(defun canonical-inspector-url (object)
  (call-hyperbook-server-helper 'canonical-inspector-url object))

(defun canonical-inspector-url-status (object)
  (if (canonical-inspector-path object)
      "Directly addressable through the runtime router."
      "No stable direct inspector URL is defined for this object type; reach it through a page or another inspectable surface."))

(defun configured-git-program ()
  (cond
    (*git-program*
     (values *git-program* :special-variable))
    ((uiop:getenv "HYPERDOC_GIT_PROGRAM")
     (values (uiop:getenv "HYPERDOC_GIT_PROGRAM")
             :environment))
    (t
     (values "git" :default-path))))

(defun configured-git-repository-root ()
  (cond
    (*git-repository-root*
     (values *git-repository-root* :special-variable))
    ((uiop:getenv "HYPERDOC_GIT_REPOSITORY_ROOT")
     (values (uiop:getenv "HYPERDOC_GIT_REPOSITORY_ROOT")
             :environment))
    (t
     (values nil nil))))

(defun git-explicit-repository-root-source-p (source)
  (member source '(:special-variable :environment) :test #'eq))

(defun git-repository-root-source-label (source)
  (case source
    ((nil)
     "n/a")
    (:special-variable
     "explicit override via hyperdoc::*git-repository-root*")
    (:environment
     "explicit override via HYPERDOC_GIT_REPOSITORY_ROOT")
    (:process-working-directory
     "inferred from the current process working directory")
    (:system-source-default
     "default root derived from the loaded ASDF system")
    (t
     (format nil "~A" source))))

(defun nix-store-pathname-p (pathname-designator)
  (and pathname-designator
       (uiop:string-prefix-p "/nix/store/"
                             (pathname-namestring-or-nil pathname-designator))))

(defun git-repository-root-origin-label (repository-root source)
  (cond
    ((git-explicit-repository-root-source-p source)
     "explicit override")
    ((eq source :process-working-directory)
     "workspace-rooted runtime")
    ((nix-store-pathname-p repository-root)
     "packaged runtime default")
    (repository-root
     "default live checkout")
    (t
     "unknown")))

(defun normalize-directory-pathname (pathname-designator)
  (uiop:ensure-directory-pathname (pathname pathname-designator)))

(defun current-process-working-directory ()
  (ignore-errors
    (normalize-directory-pathname (uiop:getcwd))))

(defun resolve-git-repository-root-override ()
  (multiple-value-bind (requested-root configuration-source)
      (configured-git-repository-root)
    (when requested-root
      (let* ((requested-string (etypecase requested-root
                                 (pathname
                                  (namestring requested-root))
                                 (string
                                  requested-root)))
             (requested-path (normalize-directory-pathname requested-string))
             (resolved-path (ignore-errors (probe-file requested-path))))
        (values requested-path
                (and resolved-path
                     (normalize-directory-pathname resolved-path))
                configuration-source
                requested-string)))))

(defun pathname-equal-p (left right)
  (and left
       right
       (equal (pathname-namestring-or-nil left)
              (pathname-namestring-or-nil right))))

(defun infer-git-repository-root-source (repository-root)
  (multiple-value-bind (_requested-root resolved-root source _requested-string)
      (resolve-git-repository-root-override)
    (declare (ignore _requested-root _requested-string))
    (let* ((process-root-info
            (handler-case
                (multiple-value-list
                 (process-working-directory-repository-root-info))
              (error ()
                nil)))
           (process-root (first process-root-info))
           (process-source (second process-root-info)))
      (cond
        ((and repository-root
              resolved-root
              (pathname-equal-p repository-root resolved-root))
         source)
        ((and repository-root
              process-root
              (pathname-equal-p repository-root process-root))
         process-source)
        (t
         :system-source-default)))))

(defun resolve-git-program ()
  (multiple-value-bind (requested-program configuration-source)
      (configured-git-program)
    (let* ((requested-string (etypecase requested-program
                               (pathname
                                (namestring requested-program))
                               (string
                                requested-program)))
           (resolved-program
            (if (and requested-string
                     (ignore-errors
                       (uiop:absolute-pathname-p (pathname requested-string))))
                (probe-file requested-string)
                requested-string)))
      (values resolved-program
              requested-string
              configuration-source))))

(defun git-repository-root-from-directory (directory &key repository-root-source)
  (let ((directory (normalize-directory-pathname directory)))
    (normalize-directory-pathname
     (pathname
      (git-command-output*
       directory
       '("rev-parse" "--show-toplevel")
       :operation "git rev-parse --show-toplevel"
       :repository-root-source repository-root-source)))))

(defun process-working-directory-repository-root-info ()
  (let ((working-directory (current-process-working-directory)))
    (when working-directory
      (handler-case
          (values
           (git-repository-root-from-directory
            working-directory
            :repository-root-source :process-working-directory)
           :process-working-directory)
        (git-runtime-unavailable (condition)
          (if (eq (classification-of condition)
                  :repository-metadata-unavailable)
              (values nil nil)
              (error condition)))))))

(defun git-runtime-guidance (&key classification working-directory repository-root
                               repository-root-source)
  (remove nil
          (list
           "Run HyperDoc inside `nix develop` when you want live Git-backed history surfaces."
           "Set `HYPERDOC_GIT_PROGRAM` or `hyperdoc::*git-program*` to an explicit Git executable path in runtimes that ship Git outside PATH."
           "Workspace-rooted runtimes such as `nix run .#default` can infer a live checkout from the current process working directory when that directory resolves inside a real Git repository."
           "Set `HYPERDOC_GIT_REPOSITORY_ROOT` or `hyperdoc::*git-repository-root*` to an explicit live checkout when you intentionally want a deployed runtime to use workspace-backed Git history surfaces."
           (and (eq classification :repository-metadata-unavailable)
                "Built release images may contain source snapshots without usable `.git` repository metadata. Git-backed history surfaces need a live checkout, worktree, or another runtime that exposes repository metadata to Git.")
           (and (eq classification :git-executable-unavailable)
                "This runtime still needs a usable Git executable. `HYPERDOC_GIT_PROGRAM` only solves executable discovery; it does not create repository metadata.")
           (and (git-explicit-repository-root-source-p repository-root-source)
                "Hosts like dreyeck.ch can intentionally point the deployed runtime at a real mutable checkout. This enables Git-backed history surfaces, but it also means the service observes whatever state is currently in that checkout.")
           (and (eq classification :git-command-failed)
                "Inspect the command, exit code, and working directory fields below to diagnose the Git invocation.")
           (and repository-root
                (format nil "The effective repository root for this runtime is `~A` (~A)."
                        (pathname-namestring-or-nil repository-root)
                        (git-repository-root-origin-label
                         repository-root
                         repository-root-source)))
           (and working-directory
                (format nil "The failing Git command was run with `-C ~A`."
                        (pathname-namestring-or-nil working-directory)))
           "Deployed dreyeck runtimes without repository metadata should render this inspectable unavailability surface instead of a raw subprocess error.")))

(defun git-command-program-string (resolved-program)
  (typecase resolved-program
    (pathname
     (namestring resolved-program))
    (string
     resolved-program)
    (t
     (princ-to-string resolved-program))))

(defun git-command-display-string (resolved-program directory args)
  (format nil "~{~A~^ ~}"
          (append (list (git-command-program-string resolved-program)
                        "-C"
                        (pathname-namestring-or-nil directory))
                  args)))

(defun git-string-contains-ci-p (needle haystack)
  (and haystack
       (not (null (search needle haystack :test #'char-equal)))))

(defun git-executable-launch-failure-p (detail)
  (and detail
       (or (git-string-contains-ci-p "couldn't execute" detail)
           (git-string-contains-ci-p "no such file" detail)
           (git-string-contains-ci-p "not found" detail)
           (git-string-contains-ci-p "permission denied" detail)
           (git-string-contains-ci-p "exec format error" detail))))

(defun git-repository-metadata-failure-p (&key operation detail exit-code)
  (or (git-string-contains-ci-p "not a git repository" detail)
      (git-string-contains-ci-p "outside repository" detail)
      (git-string-contains-ci-p "must be run in a work tree" detail)
      (and (eql exit-code 128)
           (string= operation "git rev-parse --show-toplevel"))))

(defun classify-git-runtime-failure (&key operation detail exit-code)
  (cond
    ((git-executable-launch-failure-p detail)
     :git-executable-unavailable)
    ((git-repository-metadata-failure-p
      :operation operation
      :detail detail
      :exit-code exit-code)
     :repository-metadata-unavailable)
    (t
     :git-command-failed)))

(defun signal-git-runtime-unavailable (&key operation repository-root reason detail
                                         requested-program resolved-program
                                         configuration-source classification
                                         command exit-code working-directory
                                         repository-root-source)
  (let* ((classification (or classification :git-command-failed))
         (working-directory (or working-directory repository-root))
         (repository-root-source
          (or repository-root-source
              (infer-git-repository-root-source repository-root)))
         (summary (git-runtime-condition-summary classification))
         (title (git-runtime-condition-title classification))
         (reason (or reason
                     (git-runtime-default-reason classification))))
    (error 'git-runtime-unavailable
           :classification classification
           :title title
           :summary summary
           :operation operation
           :command command
           :exit-code exit-code
           :working-directory working-directory
           :repository-root repository-root
           :repository-root-source repository-root-source
           :requested-program requested-program
           :resolved-program resolved-program
           :configuration-source configuration-source
           :reason reason
           :detail detail
           :guidance (git-runtime-guidance
                      :classification classification
                      :working-directory working-directory
                      :repository-root repository-root
                      :repository-root-source repository-root-source))))

(defun git-command-output* (directory args &key ignore-error-status operation
                                             repository-root-source)
  (multiple-value-bind (resolved-program requested-program configuration-source)
      (resolve-git-program)
    (let* ((resolved-program-string
            (and resolved-program
                 (git-command-program-string resolved-program)))
           (command
            (and resolved-program
                 (append (list resolved-program-string
                               "-C"
                               (pathname-namestring-or-nil directory))
                         args)))
           (command-display
            (and command
                 (format nil "~{~A~^ ~}" command))))
      (unless resolved-program
        (signal-git-runtime-unavailable
         :classification :git-executable-unavailable
         :operation (or operation "git command")
         :repository-root directory
         :working-directory directory
         :reason "Git history unavailable: no usable Git executable is configured for this runtime."
         :detail "Configure HYPERDOC_GIT_PROGRAM or hyperdoc::*git-program* if Git is not on PATH."
         :repository-root-source repository-root-source
         :requested-program requested-program
         :configuration-source configuration-source
         :command (git-command-display-string
                   (or requested-program "git")
                   directory
                   args)))
      (handler-case
          (multiple-value-bind (output error-output exit-code)
              (uiop:run-program
               command
               :output :string
               :error-output :output
               :ignore-error-status t)
            (declare (ignore error-output))
            (let ((output (trim-line-endings (or output ""))))
              (cond
                ((zerop exit-code)
                 output)
                ((and ignore-error-status
                      (eq (classify-git-runtime-failure
                           :operation (or operation "git command")
                           :detail output
                           :exit-code exit-code)
                          :git-command-failed))
                 output)
                (t
                 (let ((classification
                        (classify-git-runtime-failure
                         :operation (or operation "git command")
                         :detail output
                         :exit-code exit-code)))
                   (signal-git-runtime-unavailable
                    :classification classification
                    :operation (or operation "git command")
                    :repository-root directory
                    :working-directory directory
                    :detail output
                    :repository-root-source repository-root-source
                    :requested-program requested-program
                    :resolved-program resolved-program-string
                    :configuration-source configuration-source
                    :command command-display
                    :exit-code exit-code))))))
        (git-runtime-unavailable (condition)
          (error condition))
        (error (condition)
          (let* ((detail (princ-to-string condition))
                 (classification
                  (classify-git-runtime-failure
                   :operation (or operation "git command")
                   :detail detail)))
            (signal-git-runtime-unavailable
             :classification classification
             :operation (or operation "git command")
             :repository-root directory
             :working-directory directory
             :detail detail
             :repository-root-source repository-root-source
             :requested-program requested-program
             :resolved-program resolved-program-string
             :configuration-source configuration-source
             :command command-display)))))))

(defun system-repository-root-info (system)
  (multiple-value-bind (requested-root resolved-root source requested-string)
      (resolve-git-repository-root-override)
    (declare (ignore requested-string))
    (cond
      (requested-root
       (unless resolved-root
         (signal-git-runtime-unavailable
          :operation "git repository root override"
          :classification :repository-metadata-unavailable
          :repository-root requested-root
          :working-directory requested-root
          :repository-root-source source
          :reason "Git history unavailable: the explicit repository-root override does not resolve to an accessible checkout in this runtime."
          :detail "The HYPERDOC_GIT_REPOSITORY_ROOT override path does not exist or is not accessible."))
       (values resolved-root source))
      (t
       (multiple-value-bind (working-directory-root working-directory-source)
           (process-working-directory-repository-root-info)
         (when working-directory-root
           (return-from system-repository-root-info
             (values working-directory-root working-directory-source))))
       (let ((source-file (ignore-errors (asdf:system-source-file system))))
         (unless source-file
           (signal-git-runtime-unavailable
            :operation "git rev-parse --show-toplevel"
            :classification :repository-metadata-unavailable
            :repository-root-source :system-source-default
            :reason (format nil "ASDF system ~A has no source file for repository lookup."
                            (asdf:component-name system))
            :detail "A runtime without usable source or repository metadata cannot host Git-backed history surfaces."))
         (values
          (pathname
           (git-command-output*
            (uiop:pathname-directory-pathname source-file)
            '("rev-parse" "--show-toplevel")
            :operation "git rev-parse --show-toplevel"
            :repository-root-source :system-source-default))
          :system-source-default))))))

(defun system-repository-root (system)
  (nth-value 0 (system-repository-root-info system)))

(defun %system-git-commit-target (system-designator full-commit-hash)
  (let ((system (etypecase system-designator
                  (asdf:system
                   system-designator)
                  ((or string symbol)
                   (asdf:find-system system-designator)))))
    (unless (full-git-commit-hash-p full-commit-hash)
      (error "Expected a full 40-character Git commit hash, got ~S."
             full-commit-hash))
    (multiple-value-bind (repo-root repository-root-source)
        (system-repository-root-info system)
      (make-instance 'git-commit-target
                     :system system
                     :repo-root repo-root
                     :repository-root-source repository-root-source
                     :commit-hash (string-downcase full-commit-hash)))))

(defun call-with-git-runtime-boundary (thunk)
  (handler-case
      (funcall thunk)
    (git-runtime-unavailable (condition)
      condition)))

(defun system-git-commit-target (system-designator full-commit-hash)
  (call-with-git-runtime-boundary
   (lambda ()
     (%system-git-commit-target system-designator full-commit-hash))))

(defun git-command-output (repo-root &rest args)
  (git-command-output* repo-root args))

(defun git-command-output-ignore-status (repo-root &rest args)
  (git-command-output* repo-root args
                       :ignore-error-status t))

(defun git-commit-metadata (target)
  (let* ((output (git-command-output
                  (repo-root-of target)
                  "show" "--no-patch" "--date=iso-strict"
                  "--format=%H%n%an%n%ae%n%ad%n%s"
                  (commit-hash-of target)))
         (lines (uiop:split-string output :separator '(#\Newline))))
    (list (cons "Repository root" (namestring (repo-root-of target)))
          (cons "Repository root source"
                (git-repository-root-source-label
                 (repository-root-source-of target)))
          (cons "Repository root origin"
                (git-repository-root-origin-label
                 (repo-root-of target)
                 (repository-root-source-of target)))
          (cons "System" (asdf:component-name (system-of target)))
          (cons "Commit" (or (first lines) (commit-hash-of target)))
          (cons "Author" (or (second lines) ""))
          (cons "Email" (or (third lines) ""))
          (cons "Date" (or (fourth lines) ""))
          (cons "Subject" (or (fifth lines) "")))))
