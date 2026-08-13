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

(hyperdoc:defexample lisp-image-inventory-example
  "Construct a fresh dreyeck.ch-owned inventory of function-bound and class-bound symbols in the running Lisp image."
  (make-lisp-image-inventory))

(hyperdoc:defexample lisp-image-inventory-summary-example
  "Inspect the size and representative entries of a fresh running Lisp-image inventory."
  (let* ((inventory
           (make-lisp-image-inventory))
         (functions
           (lisp-image-function-entries inventory))
         (classes
           (lisp-image-class-entries inventory)))
    (list
     :inventory inventory
     :function-count
     (length functions)
     :class-count
     (length classes)
     :common-lisp-car
     (find-lisp-image-entry
      "COMMON-LISP:CAR"
      functions)
     :common-lisp-standard-object
     (find-lisp-image-entry
      "COMMON-LISP:STANDARD-OBJECT"
      classes))))

(defun observe-lisp-function-page-lookup (hyperbook page-id)
  (multiple-value-bind (symbol position)
      (read-from-string page-id)
    (declare (ignore position))
    (let ((entry
            (find-lisp-image-entry
             page-id
             (lisp-image-function-entries
              (make-lisp-image-inventory)))))
      (list
       :page-id page-id
       :symbol symbol
       :inventory-entry entry
       :fboundp (fboundp symbol)
       :macro-function (macro-function symbol)
       :special-operator-p (special-operator-p symbol)
       :page-lookup
       (handler-case
           (hyperbook:find-page
            hyperbook
            page-id
            :signal-error? t)
         (error (condition)
           (list
            :condition condition
            :condition-type (type-of condition)
            :message (princ-to-string condition))))))))

(hyperdoc:defexample lisp-function-inventory-transfer-example
  "Compare inventory membership with current Lisp-function HyperBook lookup for ordinary functions, macros, and special operators."
  (let ((hyperbook
          (hyperbook:find-hyperbook
           "lisp-functions"
           :signal-error? t)))
    (mapcar
     (lambda (page-id)
       (observe-lisp-function-page-lookup
        hyperbook
        page-id))
     '("COMMON-LISP:CAR"
       "COMMON-LISP:WHEN"
       "COMMON-LISP:IF"
       "COMMON-LISP:SETF"))))

(defun audit-inventory-page-transfer (hyperbook entries)
  (let ((success-count 0)
        (failure-count 0)
        (failure-page-ids nil))
    (dolist (entry entries)
      (let* ((page-id
               (lisp-image-entry-page-id entry))
             (page
               (handler-case
                   (hyperbook:find-page
                    hyperbook
                    page-id
                    :signal-error? nil)
                 (error ()
                   nil))))
        (if page
            (incf success-count)
            (progn
              (incf failure-count)
              (when (< (length failure-page-ids) 20)
                (push page-id failure-page-ids))))))
    (list
     :entry-count (length entries)
     :success-count success-count
     :failure-count failure-count
     :sample-failure-page-ids
     (nreverse failure-page-ids))))

(hyperdoc:defexample lisp-image-inventory-transfer-audit-example
  "Audit whether every current Lisp-image inventory entry can be represented by its existing HyperBook."
  (let* ((inventory
           (make-lisp-image-inventory))
         (functions
           (hyperbook:find-hyperbook
            "lisp-functions"
            :signal-error? t))
         (classes
           (hyperbook:find-hyperbook
            "lisp-classes"
            :signal-error? t)))
    (list
     :function-pages
     (audit-inventory-page-transfer
      functions
      (lisp-image-function-entries inventory))
     :class-pages
     (audit-inventory-page-transfer
      classes
      (lisp-image-class-entries inventory)))))

(defun read-page-id-observation (page-id)
  (handler-case
      (multiple-value-bind (object position)
          (read-from-string page-id)
        (list
         :object object
         :position position
         :length (length page-id)
         :complete-p (= position (length page-id))))
    (error (condition)
      (list
       :condition condition
       :condition-type (type-of condition)
       :message (princ-to-string condition)))))

(defun function-transfer-failure-entries ()
  (let* ((inventory
           (make-lisp-image-inventory))
         (hyperbook
           (hyperbook:find-hyperbook
            "lisp-functions"
            :signal-error? t)))
    (remove-if
     (lambda (entry)
       (handler-case
           (not
            (null
             (hyperbook:find-page
              hyperbook
              (lisp-image-entry-page-id entry)
              :signal-error? nil)))
         (error ()
           nil)))
     (lisp-image-function-entries inventory))))

(hyperdoc:defexample lisp-function-page-id-failures-example
  "Inspect any function inventory entries whose current package-qualified page identifiers do not round-trip through Lisp-function page lookup."
  (let ((failures
          (function-transfer-failure-entries)))
    (list
     :failure-count (length failures)
     :failures
     (mapcar
      (lambda (entry)
        (let ((symbol
                (lisp-image-entry-symbol entry))
              (page-id
                (lisp-image-entry-page-id entry)))
          (list
           :entry entry
           :page-id page-id
           :symbol symbol
           :symbol-name (symbol-name symbol)
           :reader-observation
           (read-page-id-observation page-id)
           :printed-symbol
           (let ((*package*
                   (find-package "DREYECK/LISP-IMAGE"))
                 (*print-escape* t))
             (prin1-to-string symbol)))))
      failures))))

(hyperdoc:defexample reader-safe-lisp-image-page-ids-example
  "Compare familiar and escaped package-qualified Lisp-image page identifiers and verify their reader round-trip."
  (let ((symbols
          (remove
           nil
           (list
            'car
            (find-symbol "#$-reader" "FSET")
            (find-symbol ")-COMPILER" "SB-FORMAT")
            (find-symbol
             "STRUCTURE-OBJECT class constructor"
             "SB-PCL")))))
    (mapcar
     (lambda (symbol)
       (multiple-value-bind (page-id status)
           (package-qualified-symbol-page-id symbol)
         (list
          :symbol symbol
          :symbol-name (symbol-name symbol)
          :status status
          :page-id page-id
          :round-trips-p
          (page-id-reads-as-symbol-p page-id symbol))))
     symbols)))
