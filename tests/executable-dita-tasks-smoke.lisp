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

(defun executable-dita-smoke-default-db-path ()
  (hyperdoc:executable-dita-default-sqlite-path))

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

(defun run-executable-dita-tasks-smoke-test
    (&key (db-path (executable-dita-smoke-default-db-path)))
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
    (let ((selected
            (hyperdoc:select-executable-dita-next-task-candidates
             :task-id (hyperdoc:executable-dita-task-id task)
             :limit 1
             :mark-selected-p t
             :db-path db-path)))
      (executable-dita-smoke-assert
       selected
       "At least one unblocked next-task candidate must be selected")
      (executable-dita-smoke-assert
       (equal "candidate.inspect-sqlite-evidence"
              (getf (first selected) :id))
       "Ranking must select the highest-scoring unblocked next-task candidate")
      (format t "~&Executable DITA task smoke test passed.~%")
      (list :status :passed
            :db (namestring db-path)
            :task-id (hyperdoc:executable-dita-task-id task)
            :selected (first selected)))))
