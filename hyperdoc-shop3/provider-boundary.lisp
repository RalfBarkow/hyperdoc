;;;; Narrow ASDF source-registry boundary for the optional SHOP3 provider
;;
;;;; Copyright (c) 2026

(in-package #:hyperdoc/shop3-provider)

(defparameter *shop3-provider-system-names*
  '(:shop3 :fiveam-asdf :pddl-utils :hyperdoc/shop3))

(defun %directory-pathname (path)
  (uiop:ensure-directory-pathname path))

(defun %directory-name (path)
  (namestring (%directory-pathname path)))

(defun %path-contains-p (path needle)
  (search needle (%directory-name path) :test #'char-equal))

(defun %same-directory-p (left right)
  (string= (%directory-name left) (%directory-name right)))

(defun %string-suffix-p (suffix string)
  (let ((suffix-length (length suffix))
        (string-length (length string)))
    (and (<= suffix-length string-length)
         (string= suffix string :start2 (- string-length suffix-length)))))

(defun %default-shop3-provider-directories (hyperdoc-root shop3-root)
  (let ((shop3-root (%directory-pathname shop3-root)))
    (list (%directory-pathname hyperdoc-root)
          (merge-pathnames #P"shop3/" shop3-root)
          (merge-pathnames #P"jenkins/ext/pddl-tools/" shop3-root)
          (merge-pathnames #P"jenkins/ext/fiveam-asdf/" shop3-root)
          (merge-pathnames #P"jenkins/ext/random-state/" shop3-root)
          (merge-pathnames #P"jenkins/ext/documentation-utils/" shop3-root)
          (merge-pathnames #P"jenkins/ext/trivial-indent/" shop3-root)
          (merge-pathnames #P"jenkins/ext/trivial-garbage/" shop3-root)
          (merge-pathnames #P"jenkins/ext/iterate/" shop3-root))))

(defun %classify-shop3-provider-directory (directory shop3-root)
  (cond
    ((%same-directory-p directory shop3-root)
     :rejected-broad-shop3-root)
    ((%path-contains-p directory "/jenkins/ext/alexandria/")
     :rejected-vendored-alexandria)
    (t :selected)))

(defun %partition-shop3-provider-directories (directories shop3-root)
  (let ((selected '())
        (rejected '()))
    (dolist (directory directories)
      (let* ((pathname (%directory-pathname directory))
             (classification
              (%classify-shop3-provider-directory pathname shop3-root))
             (entry (list :directory (%directory-name pathname)
                          :classification classification)))
        (if (eq classification :selected)
            (push pathname selected)
            (push entry rejected))))
    (values (remove-duplicates (nreverse selected)
                               :test #'%same-directory-p)
            (nreverse rejected))))

(defun %source-registry-env-values ()
  (remove nil
          (list (uiop:getenv "CL_SOURCE_REGISTRY")
                (uiop:getenv "HYPERDOC_ASDF_TREES"))))

(defun %source-registry-entry-parts (entry)
  (let ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return) entry)))
    (unless (string= "" trimmed)
      (if (%string-suffix-p "//" trimmed)
          (values (subseq trimmed 0 (- (length trimmed) 2)) :tree)
          (values trimmed :directory)))))

(defun %safe-inherited-source-registry-entries (shop3-root)
  (let ((selected '())
        (rejected '()))
    (dolist (registry (%source-registry-env-values))
      (dolist (entry (uiop:split-string registry :separator ":"))
        (multiple-value-bind (path kind) (%source-registry-entry-parts entry)
          (when path
            (let* ((pathname (%directory-pathname path))
                   (classification
                     (%classify-shop3-provider-directory pathname shop3-root))
                   (report (list :directory (%directory-name pathname)
                                 :kind kind
                                 :source :environment
                                 :classification classification)))
              (if (eq classification :selected)
                  (push (list :directory (%directory-name pathname)
                              :kind kind
                              :source :environment)
                        selected)
                  (push report rejected)))))))
    (values (remove-duplicates (nreverse selected)
                               :test (lambda (left right)
                                       (and (eq (getf left :kind)
                                                (getf right :kind))
                                            (string= (getf left :directory)
                                                     (getf right :directory)))))
            (nreverse rejected))))

(defun %source-registry-form (directories inherited-entries)
  (append (list :source-registry)
          (mapcar (lambda (directory)
                    (list :directory directory))
                  directories)
          (mapcar (lambda (entry)
                    (list (getf entry :kind)
                          (getf entry :directory)))
                  inherited-entries)
          (list :ignore-inherited-configuration)))

(defun %find-system-report (name)
  (handler-case
      (let ((system (asdf:find-system name nil)))
        (if system
            (list :system name
                  :found t
                  :source-file
                  (let ((source-file (ignore-errors
                                       (asdf:system-source-file system))))
                    (and source-file (namestring source-file)))
                  :pathname
                  (let ((pathname (ignore-errors
                                    (asdf:component-pathname system))))
                    (and pathname (namestring pathname))))
            (list :system name :found nil)))
    (error (condition)
      (list :system name
            :found nil
            :condition-type (type-of condition)
            :condition-message (princ-to-string condition)))))

(defun %find-system-reports (names)
  (mapcar #'%find-system-report names))

(defun %alexandria-package-state ()
  (let* ((alexandria (find-package "ALEXANDRIA"))
         (versioned (find-package "ALEXANDRIA.1.0.0")))
    (list :alexandria-package-present (not (null alexandria))
          :alexandria-1.0.0-package-present (not (null versioned))
          :alexandria-1.0.0-is-alexandria-nickname
          (and alexandria versioned (eq alexandria versioned))
          :alexandria-package-nicknames
          (and alexandria (package-nicknames alexandria))
          :classification
          (cond
            ((and alexandria versioned (eq alexandria versioned))
             :alexandria-version-nickname-present)
            ((or alexandria versioned)
             :alexandria-package-state-present)
            (t
             :alexandria-package-state-absent)))))

(defun %environment-source-registry-state ()
  (let ((cl-source-registry (uiop:getenv "CL_SOURCE_REGISTRY"))
        (hyperdoc-asdf-trees (uiop:getenv "HYPERDOC_ASDF_TREES")))
    (list :cl-source-registry cl-source-registry
          :hyperdoc-asdf-trees hyperdoc-asdf-trees
          :mentions-broad-shop3-tree
          (or (and cl-source-registry
                   (search "/Users/rgb/workspace/shop3//"
                           cl-source-registry
                           :test #'char-equal))
              (and hyperdoc-asdf-trees
                   (search "/Users/rgb/workspace/shop3//"
                           hyperdoc-asdf-trees
                           :test #'char-equal)))
          :mentions-vendored-alexandria
          (or (and cl-source-registry
                   (search "/jenkins/ext/alexandria/"
                           cl-source-registry
                           :test #'char-equal))
              (and hyperdoc-asdf-trees
                   (search "/jenkins/ext/alexandria/"
                           hyperdoc-asdf-trees
                           :test #'char-equal))))))

(defun %vendored-alexandria-provider-found-p (system-reports)
  (some (lambda (report)
          (and (eq (getf report :system) :alexandria)
               (getf report :found)
               (let ((source-file (getf report :source-file)))
                 (and source-file
                      (search "/jenkins/ext/alexandria/"
                              source-file
                              :test #'char-equal)))))
        system-reports))

(defun %initialize-provider-output-translations (cache-directory)
  (let ((cache-directory (%directory-pathname cache-directory)))
    (ensure-directories-exist cache-directory)
    (asdf:initialize-output-translations
     (list :output-translations
           :ignore-inherited-configuration
           (list t (list cache-directory :implementation))))
    (list :classification :writable-fasl-cache
          :cache-directory (%directory-name cache-directory))))

(defun shop3-provider-boundary-report-selected-directories (report)
  (getf report :selected-directories))

(defun shop3-provider-boundary-report-rejected-directories (report)
  (getf report :rejected-directories))

(defun register-shop3-provider-source-registry
    (&key
       (hyperdoc-root #P"/Users/rgb/workspace/hyperdoc/")
       (shop3-root #P"/Users/rgb/workspace/shop3/")
       (output-cache (uiop:xdg-cache-home "common-lisp/asdf-fasl-cache/"))
       (initialize-output-translations t)
       additional-directories)
  "Install a narrow local ASDF source-registry for the optional SHOP3 provider.

The helper deliberately registers only exact ASDF directories. It rejects the
whole SHOP3 checkout tree and any local vendored Alexandria provider under
jenkins/ext/alexandria. It reports existing Alexandria package state but never
mutates packages or package nicknames. It also redirects compiled FASLs to a
writable cache so Nix-store dependency sources are never compiled in place.
Inherited source-registry configuration is ignored so a caller's broad SHOP3
tree does not re-enter the ASDF search path; safe dev-shell provider entries
are imported explicitly."
  (let* ((shop3-root (%directory-pathname shop3-root))
         (candidate-directories
          (append (%default-shop3-provider-directories hyperdoc-root shop3-root)
                  additional-directories)))
    (multiple-value-bind (selected-directories rejected-directories)
        (%partition-shop3-provider-directories candidate-directories shop3-root)
      (multiple-value-bind (safe-inherited-entries rejected-inherited-entries)
          (%safe-inherited-source-registry-entries shop3-root)
        (let* ((registry-form
                 (%source-registry-form selected-directories
                                        safe-inherited-entries))
               (environment-state (%environment-source-registry-state))
               (alexandria-before (%alexandria-package-state))
               (output-translation-state
                 (and initialize-output-translations
                      (%initialize-provider-output-translations output-cache))))
          (asdf:initialize-source-registry registry-form)
          (let* ((system-reports
                   (%find-system-reports
                    (append *shop3-provider-system-names* '(:alexandria))))
                 (vendored-alexandria-found
                   (%vendored-alexandria-provider-found-p system-reports))
                 (alexandria-after (%alexandria-package-state)))
            (list
             :kind :shop3-provider-boundary-report
             :selected-directories
             (mapcar #'%directory-name selected-directories)
             :selected-inherited-source-registry-entries safe-inherited-entries
             :rejected-directories
             (append rejected-directories rejected-inherited-entries)
             :source-registry-form registry-form
             :broad-shop3-root-tree-avoided
             (and (notany (lambda (directory)
                            (%same-directory-p directory shop3-root))
                          selected-directories)
                  (notany (lambda (entry)
                            (%same-directory-p
                             (getf entry :directory)
                             shop3-root))
                          safe-inherited-entries))
             :vendored-alexandria-provider-avoided
             (and (notany (lambda (directory)
                            (%path-contains-p directory
                                              "/jenkins/ext/alexandria/"))
                          selected-directories)
                  (notany (lambda (entry)
                            (%path-contains-p
                             (getf entry :directory)
                             "/jenkins/ext/alexandria/"))
                          safe-inherited-entries))
             :inherited-source-registry-ignored t
             :environment-source-registry environment-state
             :output-translations output-translation-state
             :existing-alexandria-package-state alexandria-before
             :alexandria-package-state-after alexandria-after
             :system-reports system-reports
             :classification
             (cond
               (vendored-alexandria-found
                :inherited-vendored-alexandria-provider-visible)
               ((or (getf environment-state :mentions-broad-shop3-tree)
                    (getf environment-state :mentions-vendored-alexandria)
                    rejected-inherited-entries)
                :narrow-shop3-provider-boundary-registered-with-ignored-environment-contaminants)
               ((getf alexandria-before
                      :alexandria-1.0.0-is-alexandria-nickname)
                :alexandria-version-nickname-present)
               (t
                :narrow-shop3-provider-boundary-registered)))))))))
