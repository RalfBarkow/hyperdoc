(in-package #:dreyeck/lisp-image)

(defun hyperdoc-repository-root ()
  (uiop:pathname-directory-pathname
   (asdf:system-source-file
    (asdf:find-system "hyperdoc"))))

(defun run-git-observation (&rest arguments)
  (let ((root (hyperdoc-repository-root)))
    (multiple-value-bind (stdout stderr exit-code)
        (uiop:run-program
         (cons "git" arguments)
         :directory root
         :output :string
         :error-output :string
         :ignore-error-status t)
      (list :command (cons "git" arguments)
            :repository-root (namestring root)
            :exit-code exit-code
            :stdout stdout
            :stderr stderr))))

(hyperdoc:defexample lisp-image-repository-state-example
    "Observe the current repository, branch, HEAD, and working-tree state."
  (list
   :status
   (run-git-observation
    "status" "--short" "--branch")
   :head
   (run-git-observation
    "rev-parse" "HEAD")))

(hyperdoc:defexample lisp-image-hauptsache-diff-example
    "Compare the Lisp function and class HyperBook implementations on dreyeck.ch and hauptsache without loading either branch."
  (run-git-observation
   "diff"
   "dreyeck.ch..hauptsache"
   "--"
   "hyperbook-explorer/lisp-functions.lisp"
   "hyperbook-explorer/lisp-classes.lisp"))

(defun diff-signal-observation (name diff)
  (list :name name
        :present-p
        (not (null
              (search name diff :test #'char-equal)))))

(hyperdoc:defexample lisp-image-hauptsache-contract-example
    "Identify the inventory and browsing elements in the historical hauptsache implementation separately from its lookup hardening."
  (let* ((observation
           (run-git-observation
            "diff"
            "dreyeck.ch..hauptsache"
            "--"
            "hyperbook-explorer/lisp-functions.lisp"
            "hyperbook-explorer/lisp-classes.lisp"))
         (diff (getf observation :stdout))
         (inventory-signals
           '("package-qualified-symbol-name"
             "collect-lisp-function-pages"
             "collect-lisp-class-pages"
             "👀loaded-functions"
             "👀loaded-classes"))
         (lookup-signals
           '("make-lisp-function-lookup-issue"
             "make-lisp-class-lookup-issue"
             "lisp-function-definition"
             "lisp-class-definition"
             "fdefinition")))
    (list
     :inventory-and-browsing
     (mapcar
      (lambda (name)
        (diff-signal-observation name diff))
      inventory-signals)
     :lookup-hardening
     (mapcar
      (lambda (name)
        (diff-signal-observation name diff))
      lookup-signals))))

(hyperdoc:defexample current-lisp-hyperbooks-example
    "Inspect direct page lookup in the current Lisp functions and Lisp classes HyperBooks."
  (let ((functions
          (hyperbook:find-hyperbook
           "lisp-functions"
           :signal-error? t))
        (classes
          (hyperbook:find-hyperbook
           "lisp-classes"
           :signal-error? t)))
    (list
     :lisp-functions
     (list
      :hyperbook functions
      :known-page-id "COMMON-LISP:CAR"
      :known-page
      (hyperbook:find-page
       functions
       "COMMON-LISP:CAR"
       :signal-error? nil))
     :lisp-classes
     (list
      :hyperbook classes
      :known-page-id "COMMON-LISP:STANDARD-OBJECT"
      :known-page
      (hyperbook:find-page
       classes
       "COMMON-LISP:STANDARD-OBJECT"
       :signal-error? nil)))))

(defun view-titles-of (object)
  (mapcar #'html-inspector-views:view-title
          (html-inspector-views:all-views object)))

(hyperdoc:defexample current-lisp-hyperbook-views-example
    "Inspect the views currently provided by the Lisp functions and Lisp classes HyperBooks."
  (let* ((functions
           (hyperbook:find-hyperbook
            "lisp-functions"
            :signal-error? t))
         (classes
           (hyperbook:find-hyperbook
            "lisp-classes"
            :signal-error? t))
         (function-view-titles
           (view-titles-of functions))
         (class-view-titles
           (view-titles-of classes)))
    (list
     :lisp-functions
     (list
      :hyperbook functions
      :view-titles function-view-titles
      :loaded-functions-present-p
      (not
       (null
        (member "Loaded functions"
                function-view-titles
                :test #'string=))))
     :lisp-classes
     (list
      :hyperbook classes
      :view-titles class-view-titles
      :loaded-classes-present-p
      (not
       (null
        (member "Loaded classes"
                class-view-titles
                :test #'string=)))))))
