;;;; Smoke test for executable DITA task objects.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-EXECUTABLE-DITA-TASKS-SMOKE-TEST"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun executable-dita-smoke-assert (condition message)
  (unless condition
    (error "~A" message)))

(defun executable-dita-smoke-assert-contains (needle haystack message)
  (unless (and haystack (search needle haystack :test #'char=))
    (error "~A -- missing substring: ~S" message needle)))

(defun executable-dita-smoke-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun executable-dita-smoke-default-db-path ()
  (hyperdoc:executable-dita-default-sqlite-path))

(defparameter *executable-dita-smoke-forbidden-systems*
  '("shop3"
    "kioskbeerli"
    "hyperdoc/shop3"
    "hyperdoc/kioskbeerli"))

(defun executable-dita-smoke-system-name (designator)
  (string-downcase
   (etypecase designator
     (string designator)
     (symbol (symbol-name designator)))))

(defun executable-dita-smoke-dependency-name (dependency)
  (cond
    ((and (consp dependency)
          (eq (first dependency) :version))
     (second dependency))
    ((and (consp dependency)
          (eq (first dependency) :feature))
     (third dependency))
    ((consp dependency)
     (first dependency))
    (t dependency)))

(defun executable-dita-smoke-system-dependency-closure (root)
  (let ((seen (make-hash-table :test #'equal))
        (result nil))
    (labels ((visit (designator)
               (let* ((name (executable-dita-smoke-system-name designator))
                      (system (ignore-errors
                                (asdf:find-system name nil))))
                 (unless (gethash name seen)
                   (setf (gethash name seen) t)
                   (push name result)
                   (when system
                     (dolist (dependency (asdf:system-depends-on system))
                       (let ((dependency-name
                               (executable-dita-smoke-dependency-name
                                dependency)))
                         (when dependency-name
                           (visit dependency-name)))))))))
      (visit root)
      (nreverse result))))

(defun executable-dita-smoke-loaded-system-names ()
  (sort
   (remove-duplicates
    (loop for system in (asdf:already-loaded-systems)
          for name = (or (ignore-errors (asdf:component-name system))
                         system)
          collect (executable-dita-smoke-system-name name))
    :test #'string=)
   #'string<))

(defun executable-dita-smoke-assert-no-forbidden-systems
    (system-names message)
  (let ((matched
          (remove-if-not
           (lambda (name)
             (member name
                     *executable-dita-smoke-forbidden-systems*
                     :test #'string=))
           system-names)))
    (when matched
      (error "~A -- forbidden systems present: ~S" message matched))))

(defun executable-dita-smoke-view (object title)
  (let ((view (find title
                    (html-inspector-views:all-views object)
                    :key #'html-inspector-views:view-title
                    :test #'string=)))
    (executable-dita-smoke-assert
     view
     (format nil "Expected inspector view ~S for ~S" title object))
    view))

(defun executable-dita-smoke-view-html (object title)
  (let* ((view (executable-dita-smoke-view object title))
         (html (html-inspector-views:view-html view)))
    (executable-dita-smoke-assert
     (and (stringp html)
          (plusp (length html)))
     (format nil "Inspector view ~S must render non-empty HTML" title))
    html))

(defun executable-dita-smoke-assert-view-titles (object titles)
  (dolist (title titles)
    (executable-dita-smoke-view object title)))

(defun executable-dita-smoke-candidates ()
  '((:id "candidate.inspect-sqlite-evidence"
     :title "Inspect persisted SQLite evidence"
     :cost 1
     :risk 0.1d0
     :expected-value 5
     :blocked-p nil)
    (:id "candidate.add-inspector-views"
     :title "Add inspector views for executable DITA tasks"
     :cost 3
     :risk 0.5d0
     :expected-value 9
     :selected-p t
     :blocked-p nil)
    (:id "candidate.enable-shop3-runtime"
     :title "Enable coherent SHOP3 planner execution"
     :cost 5
     :risk 1
     :expected-value 10
     :blocked-p nil)
    (:id "candidate.skip-guarded-operator-boundary"
     :title "Skip guarded operator boundary"
     :cost 1
     :risk 4
     :expected-value 20
     :blocked-p t)))

(defun executable-dita-smoke-assert-boundary ()
  (executable-dita-smoke-assert-no-forbidden-systems
   (executable-dita-smoke-system-dependency-closure
    :hyperdoc/executable-dita-tasks)
   "Executable DITA task system must not depend on SHOP3 or Kioskbeerli")
  (executable-dita-smoke-assert-no-forbidden-systems
   (executable-dita-smoke-loaded-system-names)
   "Executable DITA task smoke test must not load SHOP3 or Kioskbeerli"))

(defun executable-dita-smoke-selected-candidate-id (selection)
  (let ((candidate
          (hyperdoc:executable-dita-next-task-selection-selected-candidate
           selection)))
    (and candidate
         (hyperdoc:executable-dita-next-task-candidate-row-id candidate))))

(defun executable-dita-smoke-assert-inspector-views (task db-path)
  (let* ((task-id (hyperdoc:executable-dita-task-id task))
         (task-row
           (hyperdoc:read-executable-dita-task-row task-id :db-path db-path))
         (selection
           (hyperdoc:make-executable-dita-next-task-selection
            :task-id task-id
            :db-path db-path
            :include-blocked-p t))
         (summary-html
           (executable-dita-smoke-view-html task "Summary"))
         (sexp-html
           (executable-dita-smoke-view-html task "S-expression"))
         (dita-html
           (executable-dita-smoke-view-html task "DITA XML"))
         (hyperdoc-html
           (executable-dita-smoke-view-html task "HyperDoc HTML"))
         (scxml-html
           (executable-dita-smoke-view-html task "SCXML"))
         (sqlite-row-html
           (executable-dita-smoke-view-html task "SQLite row"))
         (next-tasks-html
           (executable-dita-smoke-view-html task "Next tasks"))
         (ranked-html
           (executable-dita-smoke-view-html selection "Ranked candidates"))
         (selection-html
           (executable-dita-smoke-view-html selection "Selection")))
    (executable-dita-smoke-assert
     task-row
     "Persisted SQLite task row object must be inspectable")
    (executable-dita-smoke-assert-view-titles
     task
     '("Summary"
       "S-expression"
       "DITA XML"
       "HyperDoc HTML"
       "SCXML"
       "SQLite row"
       "Next tasks"))
    (executable-dita-smoke-assert-view-titles
     task-row
     '("Summary"))
    (executable-dita-smoke-assert-view-titles
     selection
     '("Ranked candidates" "Selection"))
    (executable-dita-smoke-assert-contains
     "task.executable-dita-contract"
     summary-html
     "Summary view must render the task id")
    (executable-dita-smoke-assert-contains
     "executable-dita-task"
     sexp-html
     "S-expression view must render the canonical task object")
    (executable-dita-smoke-assert-contains
     "&lt;task"
     dita-html
     "DITA view must render escaped DITA XML")
    (executable-dita-smoke-assert-contains
     "&lt;in-package&gt;hyperdoc&lt;/in-package&gt;"
     hyperdoc-html
     "HyperDoc HTML view must render escaped HyperDoc markup")
    (executable-dita-smoke-assert-contains
     "&lt;scxml"
     scxml-html
     "SCXML view must render escaped SCXML XML")
    (executable-dita-smoke-assert-contains
     "SQLite task row"
     sqlite-row-html
     "Task SQLite-row view must link to the row object")
    (executable-dita-smoke-assert-contains
     "Executable DITA next-task selection"
     next-tasks-html
     "Task next-tasks view must link to the ranked selection object")
    (executable-dita-smoke-assert-contains
     "candidate.add-inspector-views"
     ranked-html
     "Ranked candidates view must include the selected implementation slice")
    (executable-dita-smoke-assert-contains
     "candidate.add-inspector-views"
     selection-html
     "Selection view must include the selected implementation slice")
    (executable-dita-smoke-assert-equal
     "candidate.add-inspector-views"
     (executable-dita-smoke-selected-candidate-id selection)
     "SQLite selected_p must point at the implemented inspector-view slice")))

(defun run-executable-dita-tasks-smoke-test
    (&key (db-path (executable-dita-smoke-default-db-path)))
  (executable-dita-smoke-assert-boundary)
  (let* ((task (hyperdoc:executable-dita-task-smoke-example))
         (sexp (hyperdoc:executable-dita-task->sexp task))
         (roundtrip (hyperdoc:sexp->executable-dita-task sexp))
         (dita (hyperdoc:executable-dita-task->dita roundtrip))
         (html (hyperdoc:executable-dita-task->hyperdoc-html roundtrip))
         (scxml (hyperdoc:executable-dita-task->scxml roundtrip)))
    (executable-dita-smoke-assert
     (equal (hyperdoc:executable-dita-task-id task)
            (hyperdoc:executable-dita-task-id roundtrip))
     "Executable DITA S-expression round trip must preserve task id")
    (executable-dita-smoke-assert-contains
     "<task"
     dita
     "DITA projection must contain a task element")
    (executable-dita-smoke-assert-contains
     "<in-package>hyperdoc</in-package>"
     html
     "HyperDoc HTML projection must carry the HyperDoc package marker")
    (executable-dita-smoke-assert-contains
     "<scxml"
     scxml
     "SCXML projection must contain an scxml element")
    (hyperdoc:persist-executable-dita-task task :db-path db-path)
    (let ((stored
            (hyperdoc:read-executable-dita-task
             (hyperdoc:executable-dita-task-id task)
             :db-path db-path)))
      (executable-dita-smoke-assert
       stored
       "Persisted executable DITA task must be readable from SQLite")
      (executable-dita-smoke-assert
       (equal (hyperdoc:executable-dita-task->sexp task)
              (hyperdoc:executable-dita-task->sexp stored))
       "SQLite round trip must preserve canonical task S-expression"))
    (dolist (candidate (executable-dita-smoke-candidates))
      (hyperdoc:store-executable-dita-next-task-candidate
       (hyperdoc:executable-dita-task-id task)
       candidate
       :db-path db-path))
    (executable-dita-smoke-assert-inspector-views task db-path)
    (let ((ranked
            (hyperdoc:select-executable-dita-next-task-candidates
             :task-id (hyperdoc:executable-dita-task-id task)
             :limit 1
             :db-path db-path))
          (selection
            (hyperdoc:make-executable-dita-next-task-selection
             :task-id (hyperdoc:executable-dita-task-id task)
             :db-path db-path
             :include-blocked-p t)))
      (executable-dita-smoke-assert
       ranked
       "At least one unblocked next-task candidate must be ranked")
      (executable-dita-smoke-assert
       (equal "candidate.inspect-sqlite-evidence"
              (getf (first ranked) :id))
       "Score ranking must keep the highest-scoring unblocked candidate visible")
      (executable-dita-smoke-assert-equal
       "candidate.add-inspector-views"
       (executable-dita-smoke-selected-candidate-id selection)
       "Selected candidate must be the inspector-view implementation slice")
      (format t "~&Executable DITA task smoke test passed.~%")
      (list :status :passed
            :db (namestring db-path)
            :task-id (hyperdoc:executable-dita-task-id task)
            :ranked (first ranked)
            :selected
            (executable-dita-smoke-selected-candidate-id selection)))))
