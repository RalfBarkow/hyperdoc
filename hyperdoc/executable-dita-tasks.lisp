;;;; Executable DITA task objects and projections for HyperDoc.
;;;;
;;;; The canonical object is an S-expression.  DITA XML, HyperDoc HTML, SCXML,
;;;; and SQLite rows are projections from that object.

(in-package :hyperdoc)

(define-condition executable-dita-sqlite-unavailable (error)
  ((program :reader executable-dita-sqlite-unavailable-program-of
            :initarg :program)
   (detail :reader executable-dita-sqlite-unavailable-detail-of
           :initarg :detail))
  (:report (lambda (condition stream)
             (format stream
                     "Executable DITA SQLite support is unavailable through ~S: ~A"
                     (executable-dita-sqlite-unavailable-program-of condition)
                     (executable-dita-sqlite-unavailable-detail-of condition)))))

(defclass executable-dita-task ()
  ((id :initarg :id :reader executable-dita-task-id)
   (title :initarg :title :reader executable-dita-task-title)
   (summary :initarg :summary :reader executable-dita-task-summary)
   (context :initarg :context :reader executable-dita-task-context
            :initform nil)
   (pddl :initarg :pddl :reader executable-dita-task-pddl
         :initform nil)
   (scxml :initarg :scxml :reader executable-dita-task-scxml
          :initform nil)
   (operators :initarg :operators :reader executable-dita-task-operators
              :initform nil)
   (preconditions :initarg :preconditions
                  :reader executable-dita-task-preconditions
                  :initform nil)
   (postconditions :initarg :postconditions
                   :reader executable-dita-task-postconditions
                   :initform nil)
   (failure-modes :initarg :failure-modes
                  :reader executable-dita-task-failure-modes
                  :initform nil)))

(defmethod print-object ((task executable-dita-task) stream)
  (print-unreadable-object (task stream :type t :identity nil)
    (format stream "~A" (executable-dita-task-id task))))

(defmethod id-of ((task executable-dita-task))
  (executable-dita-task-id task))

(defmethod title-of ((task executable-dita-task))
  (executable-dita-task-title task))

(defmethod summary-of ((task executable-dita-task))
  (executable-dita-task-summary task))

(defclass executable-dita-sqlite-task-row ()
  ((id :initarg :id :reader executable-dita-sqlite-task-row-id)
   (title :initarg :title :reader executable-dita-sqlite-task-row-title)
   (status :initarg :status :reader executable-dita-sqlite-task-row-status)
   (created-at :initarg :created-at
               :reader executable-dita-sqlite-task-row-created-at)
   (sexp-size :initarg :sexp-size
              :reader executable-dita-sqlite-task-row-sexp-size)
   (dita-size :initarg :dita-size
              :reader executable-dita-sqlite-task-row-dita-size)
   (hyperdoc-html-size
    :initarg :hyperdoc-html-size
    :reader executable-dita-sqlite-task-row-hyperdoc-html-size)
   (scxml-size :initarg :scxml-size
               :reader executable-dita-sqlite-task-row-scxml-size)
   (task :initarg :task :reader executable-dita-sqlite-task-row-task)))

(defclass executable-dita-next-task-candidate-row ()
  ((id :initarg :id :reader executable-dita-next-task-candidate-row-id)
   (task-id :initarg :task-id
            :reader executable-dita-next-task-candidate-row-task-id)
   (candidate :initarg :candidate
              :reader executable-dita-next-task-candidate-row-candidate)
   (cost :initarg :cost
         :reader executable-dita-next-task-candidate-row-cost)
   (risk :initarg :risk
         :reader executable-dita-next-task-candidate-row-risk)
   (expected-value
    :initarg :expected-value
    :reader executable-dita-next-task-candidate-row-expected-value)
   (blocked-p :initarg :blocked-p
              :reader executable-dita-next-task-candidate-row-blocked-p)
   (selected-p :initarg :selected-p
               :reader executable-dita-next-task-candidate-row-selected-p)
   (score :initarg :score
          :reader executable-dita-next-task-candidate-row-score)))

(defclass executable-dita-next-task-selection ()
  ((task-id :initarg :task-id
            :reader executable-dita-next-task-selection-task-id)
   (db-path :initarg :db-path
            :reader executable-dita-next-task-selection-db-path)
   (candidates :initarg :candidates
               :reader executable-dita-next-task-selection-candidates)
   (selected-candidate
    :initarg :selected-candidate
    :reader executable-dita-next-task-selection-selected-candidate)
   (include-blocked-p
    :initarg :include-blocked-p
    :reader executable-dita-next-task-selection-include-blocked-p)))

(defmethod print-object ((row executable-dita-sqlite-task-row) stream)
  (print-unreadable-object (row stream :type t :identity nil)
    (format stream "~A ~A"
            (executable-dita-sqlite-task-row-id row)
            (executable-dita-sqlite-task-row-status row))))

(defmethod print-object ((row executable-dita-next-task-candidate-row) stream)
  (print-unreadable-object (row stream :type t :identity nil)
    (format stream "~A score=~,2F~:[~; selected~]~:[~; blocked~]"
            (executable-dita-next-task-candidate-row-id row)
            (or (executable-dita-next-task-candidate-row-score row) 0.0d0)
            (executable-dita-next-task-candidate-row-selected-p row)
            (executable-dita-next-task-candidate-row-blocked-p row))))

(defmethod print-object ((selection executable-dita-next-task-selection) stream)
  (print-unreadable-object (selection stream :type t :identity nil)
    (format stream "~A selected=~A"
            (executable-dita-next-task-selection-task-id selection)
            (and (executable-dita-next-task-selection-selected-candidate
                  selection)
                 (executable-dita-next-task-candidate-row-id
                  (executable-dita-next-task-selection-selected-candidate
                   selection))))))

(defun make-executable-dita-task
    (&key id title summary context pddl scxml operators preconditions
       postconditions failure-modes)
  (unless (and id title summary)
    (error "Executable DITA tasks require :ID, :TITLE, and :SUMMARY."))
  (make-instance
   'executable-dita-task
   :id id
   :title title
   :summary summary
   :context context
   :pddl pddl
   :scxml (or scxml (executable-dita-default-scxml-contract))
   :operators operators
   :preconditions preconditions
   :postconditions postconditions
   :failure-modes failure-modes))

(defun executable-dita-task->sexp (task)
  `(:executable-dita-task
    (:id ,(executable-dita-task-id task))
    (:title ,(executable-dita-task-title task))
    (:summary ,(executable-dita-task-summary task))
    (:context ,(executable-dita-task-context task))
    (:pddl ,(executable-dita-task-pddl task))
    (:scxml ,(executable-dita-task-scxml task))
    (:preconditions ,(executable-dita-task-preconditions task))
    (:operators ,(executable-dita-task-operators task))
    (:postconditions ,(executable-dita-task-postconditions task))
    (:failure-modes ,(executable-dita-task-failure-modes task))))

(defun executable-dita-entry-value (key entries)
  (second (assoc key entries)))

(defun sexp->executable-dita-task (sexp)
  (unless (and (consp sexp)
               (eq (first sexp) :executable-dita-task))
    (error "Not an executable DITA task S-expression: ~S" sexp))
  (let ((entries (rest sexp)))
    (make-executable-dita-task
     :id (executable-dita-entry-value :id entries)
     :title (executable-dita-entry-value :title entries)
     :summary (executable-dita-entry-value :summary entries)
     :context (executable-dita-entry-value :context entries)
     :pddl (executable-dita-entry-value :pddl entries)
     :scxml (executable-dita-entry-value :scxml entries)
     :operators (executable-dita-entry-value :operators entries)
     :preconditions (executable-dita-entry-value :preconditions entries)
     :postconditions (executable-dita-entry-value :postconditions entries)
     :failure-modes (executable-dita-entry-value :failure-modes entries))))

(defun executable-dita-xml-escape (value)
  (let ((text (format nil "~A" value)))
    (with-output-to-string (stream)
      (loop for char across text
            do (write-string
                (case char
                  (#\< "&lt;")
                  (#\> "&gt;")
                  (#\& "&amp;")
                  (#\" "&quot;")
                  (t (string char)))
                stream)))))

(defun executable-dita-sexp-string (value)
  (with-output-to-string (stream)
    (let ((*print-pretty* nil)
          (*print-circle* t))
      (prin1 value stream))))

(defun executable-dita-html-codeblock (stream title value)
  (format stream "  <section>~%    <title>~A</title>~%    <codeblock>~A</codeblock>~%  </section>~%"
          (executable-dita-xml-escape title)
          (executable-dita-xml-escape
           (executable-dita-sexp-string value))))

(defun executable-dita-html-list (stream element-name title items)
  (format stream "    <~A>~%      <p>~A</p>~%      <ul>~%"
          element-name
          (executable-dita-xml-escape title))
  (dolist (item items)
    (format stream "        <li><codeph>~A</codeph></li>~%"
            (executable-dita-xml-escape
             (executable-dita-sexp-string item))))
  (format stream "      </ul>~%    </~A>~%" element-name))

(defun executable-dita-task->dita (task)
  (with-output-to-string (stream)
    (format stream "<?xml version=\"1.0\" encoding=\"UTF-8\"?>~%")
    (format stream "<!DOCTYPE task PUBLIC \"-//OASIS//DTD DITA Task//EN\" \"task.dtd\">~%")
    (format stream "<task id=\"~A\">~%"
            (executable-dita-xml-escape (executable-dita-task-id task)))
    (format stream "  <title>~A</title>~%"
            (executable-dita-xml-escape (executable-dita-task-title task)))
    (format stream "  <shortdesc>~A</shortdesc>~%"
            (executable-dita-xml-escape (executable-dita-task-summary task)))
    (format stream "  <prolog>~%    <metadata>~%      <keywords>~%")
    (dolist (keyword '("HyperDoc" "Executable DITA" "S-expression" "PDDL" "SCXML" "SQLite"))
      (format stream "        <keyword>~A</keyword>~%"
              (executable-dita-xml-escape keyword)))
    (format stream "      </keywords>~%    </metadata>~%  </prolog>~%")
    (format stream "  <taskbody>~%")
    (format stream "    <context>~%      <p>~A</p>~%      <codeblock>~A</codeblock>~%    </context>~%"
            "The canonical S-expression task object is the source of truth."
            (executable-dita-xml-escape
             (executable-dita-sexp-string
              (executable-dita-task->sexp task))))
    (when (executable-dita-task-preconditions task)
      (executable-dita-html-list
       stream
       "prereq"
       "Preconditions"
       (executable-dita-task-preconditions task)))
    (when (executable-dita-task-operators task)
      (format stream "    <steps>~%")
      (dolist (operator (executable-dita-task-operators task))
        (format stream "      <step id=\"~A\">~%        <cmd>~A</cmd>~%      </step>~%"
                (executable-dita-xml-escape
                 (string-downcase
                  (format nil "~A" (or (getf operator :id) "operator"))))
                (executable-dita-xml-escape
                 (executable-dita-sexp-string operator))))
      (format stream "    </steps>~%"))
    (when (executable-dita-task-postconditions task)
      (executable-dita-html-list
       stream
       "result"
       "Postconditions"
       (executable-dita-task-postconditions task)))
    (executable-dita-html-codeblock stream "PDDL/SHOP3 data"
                                    (executable-dita-task-pddl task))
    (executable-dita-html-codeblock stream "SCXML contract data"
                                    (executable-dita-task-scxml task))
    (when (executable-dita-task-failure-modes task)
      (executable-dita-html-codeblock stream "Failure modes"
                                      (executable-dita-task-failure-modes task)))
    (format stream "  </taskbody>~%</task>~%")))

(defun executable-dita-task->hyperdoc-html (task)
  (with-output-to-string (stream)
    (format stream "<h1>~A</h1>~%~%<in-package>hyperdoc</in-package>~%~%"
            (executable-dita-xml-escape (executable-dita-task-title task)))
    (format stream "<p>~A</p>~%~%"
            (executable-dita-xml-escape (executable-dita-task-summary task)))
    (format stream "<h2>Inspectable objects</h2>~%~%")
    (format stream "<ul>~%")
    (format stream "  <li><a expr=\"(executable-dita-task-smoke-example)\"><tt>executable-dita-task-smoke-example</tt></a></li>~%")
    (format stream "  <li><a expr=\"(executable-dita-task->sexp (executable-dita-task-smoke-example))\"><tt>canonical S-expression</tt></a></li>~%")
    (format stream "  <li><a expr=\"(executable-dita-default-pddl-domain)\"><tt>executable-dita-default-pddl-domain</tt></a></li>~%")
    (format stream "  <li><a expr=\"(executable-dita-default-scxml-contract)\"><tt>executable-dita-default-scxml-contract</tt></a></li>~%")
    (format stream "</ul>~%~%")
    (format stream "<h2>Canonical task object</h2>~%~%<pre>~A</pre>~%~%"
            (executable-dita-xml-escape
             (executable-dita-sexp-string
              (executable-dita-task->sexp task))))
    (format stream "<h2>Source of truth</h2>~%~%")
    (format stream "<p>The canonical S-expression task object is authoritative. DITA XML, HyperDoc HTML, SCXML XML, and SQLite rows are projections.</p>~%~%")
    (format stream "<h2>Planning boundary</h2>~%~%")
    (format stream "<p>PDDL and SHOP3-shaped fields are stored as data in this slice. Planner execution belongs to a later runtime-coherence slice.</p>~%~%")
    (format stream "<h2>Safe execution boundary</h2>~%~%")
    (format stream "<p>Operator execution is guarded. The safe default is print and inspect; mutation requires an explicit execution guard.</p>~%~%")
    (format stream "<h2>SQLite evidence boundary</h2>~%~%")
    (format stream "<p>Task evidence is persisted under <tt>~A</tt>.</p>~%~%"
            (executable-dita-xml-escape
             (namestring (executable-dita-default-sqlite-path))))
    (format stream "<h2>Goldberg questions</h2>~%~%")
    (format stream "<ol>~%")
    (dolist (qa
              '(("What is the program about?"
                 "It represents executable DITA tasks as canonical S-expressions with projections.")
                ("What are the main objects?"
                 "Executable task, PDDL plan lookup, SCXML contract, operator, precondition, postcondition, failure mode, SQLite record.")
                ("What is the stable identity?"
                 "The :id field in the canonical S-expression task object.")
                ("What changes over time?"
                 "Status, evidence, next-task candidates, projection files, and implementation commits.")
                ("What is the source of truth?"
                 "The canonical S-expression task object, with SQLite as durable store.")
                ("What is only a projection?"
                 "DITA XML, HyperDoc HTML, SCXML XML, and rendered pages.")
                ("What is the safe default?"
                 "Print and inspect. Do not mutate unless explicitly guarded.")
                ("What is the planning boundary?"
                 "PDDL and SHOP3 fields are data in this slice; actual SHOP3 execution is later.")
                ("What is the execution boundary?"
                 "SCXML classifies state transitions; it does not run arbitrary shell commands.")
                ("What is the evidence boundary?"
                 "Completion requires persisted SQLite rows, emitted projections, and smoke-test output.")
                ("What should Codex not do?"
                 "Do not use Quicklisp, do not load full :kioskbeerli, do not require :shop3 for smoke tests, and do not write implementation files under /Users/rgb/workspace/hauptsache.")
                ("What is the next useful inspection?"
                 "Inspect the task object, its projections, the SQLite row, and the ranked next-task candidates.")))
      (format stream "  <li><b>~A</b> ~A</li>~%"
              (executable-dita-xml-escape (first qa))
              (executable-dita-xml-escape (second qa))))
    (format stream "</ol>~%~%")
    (format stream "<h2>Boundary</h2>~%~%")
    (format stream "<p>This narrow slice uses SBCL, ASDF, UIOP, and the sqlite3 command-line program. It does not require Quicklisp, SHOP3, or Kioskbeerli.</p>~%")))

(defun executable-dita-scxml-transitions (scxml)
  (or (getf scxml :transitions)
      (getf (executable-dita-default-scxml-contract) :transitions)))

(defun executable-dita-scxml-final-states (scxml)
  (or (getf scxml :final-states)
      (getf (executable-dita-default-scxml-contract) :final-states)))

(defun executable-dita-task->scxml (task)
  (let* ((scxml (or (executable-dita-task-scxml task)
                    (executable-dita-default-scxml-contract)))
         (initial (or (getf scxml :initial) "specified"))
         (states (or (getf scxml :states)
                     (getf (executable-dita-default-scxml-contract) :states)))
         (final-states (executable-dita-scxml-final-states scxml))
         (transitions (executable-dita-scxml-transitions scxml)))
    (with-output-to-string (stream)
      (format stream "<?xml version=\"1.0\" encoding=\"UTF-8\"?>~%")
      (format stream "<scxml xmlns=\"http://www.w3.org/2005/07/scxml\" version=\"1.0\" initial=\"~A\" name=\"~A\">~%"
              (executable-dita-xml-escape initial)
              (executable-dita-xml-escape (executable-dita-task-id task)))
      (format stream "  <datamodel>~%")
      (format stream "    <data id=\"taskId\" expr=\"'~A'\"/>~%"
              (executable-dita-xml-escape (executable-dita-task-id task)))
      (format stream "    <data id=\"pddlTask\" expr=\"'~A'\"/>~%"
              (executable-dita-xml-escape
               (executable-dita-sexp-string
                (executable-dita-task-pddl task))))
      (format stream "  </datamodel>~%")
      (dolist (state states)
        (unless (member state final-states :test #'string=)
          (format stream "  <state id=\"~A\">~%"
                  (executable-dita-xml-escape state))
          (dolist (transition transitions)
            (when (string= state (getf transition :state))
              (format stream "    <transition event=\"~A\" target=\"~A\"/>~%"
                      (executable-dita-xml-escape (getf transition :event))
                      (executable-dita-xml-escape (getf transition :target)))))
          (format stream "  </state>~%")))
      (dolist (state final-states)
        (format stream "  <final id=\"~A\"/>~%"
                (executable-dita-xml-escape state)))
      (format stream "</scxml>~%"))))

(defun executable-dita-sqlite-blank-string-p (value)
  (or (null value)
      (and (stringp value)
           (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return)
                                       value))))))

(defun executable-dita-sqlite-string-literal (value)
  (if (null value)
      "NULL"
      (format nil "'~A'"
              (with-output-to-string (stream)
                (loop for char across (format nil "~A" value)
                      do (if (char= char #\')
                             (write-string "''" stream)
                             (write-char char stream)))))))

(defun executable-dita-sqlite-number-literal (value)
  (if value
      (format nil "~F" (coerce value 'double-float))
      "NULL"))

(defun executable-dita-sqlite-available-p (&key (sqlite-program "sqlite3"))
  (and (not (executable-dita-sqlite-blank-string-p sqlite-program))
       (handler-case
           (multiple-value-bind (output error-output exit-code)
               (uiop:run-program (list sqlite-program "--version")
                                 :output :string
                                 :error-output :string
                                 :ignore-error-status t)
             (declare (ignore output error-output))
             (zerop exit-code))
         (error () nil))))

(defun executable-dita-ensure-sqlite-available (sqlite-program)
  (unless (executable-dita-sqlite-available-p
           :sqlite-program sqlite-program)
    (error 'executable-dita-sqlite-unavailable
           :program sqlite-program
           :detail "The sqlite3 command is not present or did not run successfully."))
  t)

(defun executable-dita-sqlite-run
    (db-path sql &key (sqlite-program "sqlite3") no-header-p)
  (executable-dita-ensure-sqlite-available sqlite-program)
  (let ((parent (and db-path (uiop:pathname-directory-pathname db-path))))
    (when parent
      (ensure-directories-exist parent)))
  (let ((command (append (list sqlite-program "-batch")
                         (when no-header-p
                           (list "-noheader" "-separator" (string #\Tab)))
                         (list (namestring db-path) sql))))
    (multiple-value-bind (output error-output exit-code)
        (uiop:run-program command
                          :output :string
                          :error-output :output
                          :ignore-error-status t)
      (declare (ignore error-output))
      (unless (zerop exit-code)
        (error "Executable DITA sqlite3 exited with code ~D: ~A"
               exit-code
               output))
      output)))

(defun executable-dita-sqlite-exec
    (db-path sql &key (sqlite-program "sqlite3"))
  (executable-dita-sqlite-run db-path sql :sqlite-program sqlite-program)
  db-path)

(defun executable-dita-sqlite-query-lines
    (db-path sql &key (sqlite-program "sqlite3"))
  (remove-if #'executable-dita-sqlite-blank-string-p
             (uiop:split-string
              (executable-dita-sqlite-run db-path
                                          sql
                                          :sqlite-program sqlite-program
                                          :no-header-p t)
              :separator '(#\Newline #\Return))))

(defun executable-dita-sqlite-schema-sql ()
  "CREATE TABLE IF NOT EXISTS executable_dita_tasks(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  sexp TEXT NOT NULL,
  dita_xml TEXT,
  hyperdoc_html TEXT,
  scxml TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS executable_dita_next_task_candidates(
  id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL,
  candidate_sexp TEXT NOT NULL,
  cost REAL,
  risk REAL,
  expected_value REAL,
  blocked_p INTEGER NOT NULL DEFAULT 0,
  selected_p INTEGER NOT NULL DEFAULT 0
);")

(defun ensure-executable-dita-sqlite-schema
    (&key (db-path (executable-dita-default-sqlite-path))
       (sqlite-program "sqlite3"))
  (executable-dita-sqlite-exec
   db-path
   (executable-dita-sqlite-schema-sql)
   :sqlite-program sqlite-program)
  db-path)

(defun executable-dita-now-string ()
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time (get-universal-time) 0)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ"
            year month day hour minute second)))

(defun persist-executable-dita-task
    (task &key (db-path (executable-dita-default-sqlite-path))
       (sqlite-program "sqlite3") (status "active"))
  (ensure-executable-dita-sqlite-schema
   :db-path db-path
   :sqlite-program sqlite-program)
  (let* ((sexp (executable-dita-sexp-string
                (executable-dita-task->sexp task)))
         (dita (executable-dita-task->dita task))
         (html (executable-dita-task->hyperdoc-html task))
         (scxml (executable-dita-task->scxml task))
         (sql
           (format nil
                   "INSERT OR REPLACE INTO executable_dita_tasks(id, title, sexp, dita_xml, hyperdoc_html, scxml, status, created_at)
                    VALUES(~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A);"
                   (executable-dita-sqlite-string-literal
                    (executable-dita-task-id task))
                   (executable-dita-sqlite-string-literal
                    (executable-dita-task-title task))
                   (executable-dita-sqlite-string-literal sexp)
                   (executable-dita-sqlite-string-literal dita)
                   (executable-dita-sqlite-string-literal html)
                   (executable-dita-sqlite-string-literal scxml)
                   (executable-dita-sqlite-string-literal status)
                   (executable-dita-sqlite-string-literal
                    (executable-dita-now-string)))))
    (executable-dita-sqlite-exec db-path sql :sqlite-program sqlite-program)
    (list :status :persisted
          :db (namestring db-path)
          :task-id (executable-dita-task-id task))))

(defun read-executable-dita-task
    (task-id &key (db-path (executable-dita-default-sqlite-path))
       (sqlite-program "sqlite3"))
  (ensure-executable-dita-sqlite-schema
   :db-path db-path
   :sqlite-program sqlite-program)
  (let* ((sql
           (format nil
                   "SELECT sexp FROM executable_dita_tasks WHERE id = ~A LIMIT 1;"
                   (executable-dita-sqlite-string-literal task-id)))
         (lines
           (executable-dita-sqlite-query-lines
            db-path
            sql
            :sqlite-program sqlite-program)))
    (when lines
      (sexp->executable-dita-task
       (read-from-string (first lines))))))

(defun store-executable-dita-next-task-candidate
    (task-id candidate &key id cost risk expected-value blocked-p selected-p
       (db-path (executable-dita-default-sqlite-path))
       (sqlite-program "sqlite3"))
  (ensure-executable-dita-sqlite-schema
   :db-path db-path
   :sqlite-program sqlite-program)
  (let* ((candidate-id (or id (getf candidate :id)))
         (candidate-cost (or cost (getf candidate :cost)))
         (candidate-risk (or risk (getf candidate :risk)))
         (candidate-expected-value
           (or expected-value (getf candidate :expected-value)))
         (candidate-blocked-p (or blocked-p (getf candidate :blocked-p)))
         (candidate-selected-p (or selected-p (getf candidate :selected-p)))
         (sexp (executable-dita-sexp-string candidate)))
    (unless candidate-id
      (error "Next-task candidates require an id."))
    (executable-dita-sqlite-exec
     db-path
     (format nil
             "INSERT OR REPLACE INTO executable_dita_next_task_candidates(
                id, task_id, candidate_sexp, cost, risk, expected_value, blocked_p, selected_p)
              VALUES(~A, ~A, ~A, ~A, ~A, ~A, ~D, ~D);"
             (executable-dita-sqlite-string-literal candidate-id)
             (executable-dita-sqlite-string-literal task-id)
             (executable-dita-sqlite-string-literal sexp)
             (executable-dita-sqlite-number-literal candidate-cost)
             (executable-dita-sqlite-number-literal candidate-risk)
             (executable-dita-sqlite-number-literal candidate-expected-value)
             (if candidate-blocked-p 1 0)
             (if candidate-selected-p 1 0))
     :sqlite-program sqlite-program)
    (list :status :stored
          :id candidate-id
          :task-id task-id
          :score (executable-dita-next-task-score
                  :cost candidate-cost
                  :risk candidate-risk
                  :expected-value candidate-expected-value))))

(defun executable-dita-parse-candidate-line (line)
  (let* ((fields (uiop:split-string line :separator (list #\Tab)))
         (id (first fields))
         (task-id (second fields))
         (candidate (read-from-string (third fields)))
         (cost (read-from-string (fourth fields)))
         (risk (read-from-string (fifth fields)))
         (expected-value (read-from-string (sixth fields)))
         (blocked-p (not (zerop (parse-integer (seventh fields)))))
         (selected-p (not (zerop (parse-integer (eighth fields)))))
         (score (read-from-string (ninth fields))))
    (list :id id
          :task-id task-id
          :candidate candidate
          :cost cost
          :risk risk
          :expected-value expected-value
          :blocked-p blocked-p
          :selected-p selected-p
          :score score)))

(defun executable-dita-candidate-row-from-plist (plist)
  (make-instance
   'executable-dita-next-task-candidate-row
   :id (getf plist :id)
   :task-id (getf plist :task-id)
   :candidate (getf plist :candidate)
   :cost (getf plist :cost)
   :risk (getf plist :risk)
   :expected-value (getf plist :expected-value)
   :blocked-p (getf plist :blocked-p)
   :selected-p (getf plist :selected-p)
   :score (getf plist :score)))

(defun executable-dita-mark-selected-candidate
    (db-path task-id candidate-id sqlite-program)
  (executable-dita-sqlite-exec
   db-path
   (format nil
           "UPDATE executable_dita_next_task_candidates
            SET selected_p = CASE WHEN id = ~A THEN 1 ELSE 0 END
            WHERE task_id = ~A;"
           (executable-dita-sqlite-string-literal candidate-id)
           (executable-dita-sqlite-string-literal task-id))
   :sqlite-program sqlite-program))

(defun select-executable-dita-next-task-candidates
    (&key task-id (limit 1) include-blocked-p mark-selected-p
       (db-path (executable-dita-default-sqlite-path))
       (sqlite-program "sqlite3"))
  (ensure-executable-dita-sqlite-schema
   :db-path db-path
   :sqlite-program sqlite-program)
  (let* ((where
           (with-output-to-string (stream)
             (write-string "WHERE 1 = 1" stream)
             (when task-id
               (format stream " AND task_id = ~A"
                       (executable-dita-sqlite-string-literal task-id)))
             (unless include-blocked-p
               (write-string " AND blocked_p = 0" stream))))
         (sql
           (format nil
                   "SELECT id, task_id, candidate_sexp, cost, risk, expected_value, blocked_p, selected_p,
                           ((COALESCE(expected_value, 0) / CASE WHEN COALESCE(cost, 0) > 1 THEN cost ELSE 1 END) - COALESCE(risk, 0)) AS score
                    FROM executable_dita_next_task_candidates
                    ~A
                    ORDER BY score DESC, id ASC
                    LIMIT ~D;"
                   where
                   limit))
         (rows
           (mapcar #'executable-dita-parse-candidate-line
                   (executable-dita-sqlite-query-lines
                    db-path
                    sql
                    :sqlite-program sqlite-program))))
    (when (and mark-selected-p rows)
      (executable-dita-mark-selected-candidate
       db-path
       (getf (first rows) :task-id)
       (getf (first rows) :id)
       sqlite-program)
      (setf (getf (first rows) :selected-p) t))
    rows))

(defun select-executable-dita-next-task-candidate-rows
    (&key task-id (limit 10) include-blocked-p
       (db-path (executable-dita-default-sqlite-path))
       (sqlite-program "sqlite3"))
  (mapcar #'executable-dita-candidate-row-from-plist
          (select-executable-dita-next-task-candidates
           :task-id task-id
           :limit limit
           :include-blocked-p include-blocked-p
           :db-path db-path
           :sqlite-program sqlite-program)))

(defun make-executable-dita-next-task-selection
    (&key task-id (limit 10) include-blocked-p
       (db-path (executable-dita-default-sqlite-path))
       (sqlite-program "sqlite3"))
  (let* ((candidates
           (select-executable-dita-next-task-candidate-rows
            :task-id task-id
            :limit limit
            :include-blocked-p include-blocked-p
            :db-path db-path
            :sqlite-program sqlite-program))
         (selected
           (or (find-if #'executable-dita-next-task-candidate-row-selected-p
                        candidates)
               (find-if-not #'executable-dita-next-task-candidate-row-blocked-p
                            candidates))))
    (make-instance
     'executable-dita-next-task-selection
     :task-id task-id
     :db-path db-path
     :candidates candidates
     :selected-candidate selected
     :include-blocked-p include-blocked-p)))

(defun executable-dita-parse-task-row-line (line task)
  (destructuring-bind (id title status created-at sexp-size dita-size
                          hyperdoc-html-size scxml-size)
      (uiop:split-string line :separator (list #\Tab))
    (make-instance
     'executable-dita-sqlite-task-row
     :id id
     :title title
     :status status
     :created-at created-at
     :sexp-size (parse-integer sexp-size)
     :dita-size (parse-integer dita-size)
     :hyperdoc-html-size (parse-integer hyperdoc-html-size)
     :scxml-size (parse-integer scxml-size)
     :task task)))

(defun read-executable-dita-task-row
    (task-id &key (db-path (executable-dita-default-sqlite-path))
       (sqlite-program "sqlite3"))
  (ensure-executable-dita-sqlite-schema
   :db-path db-path
   :sqlite-program sqlite-program)
  (let* ((task (read-executable-dita-task
                task-id
                :db-path db-path
                :sqlite-program sqlite-program))
         (sql
           (format nil
                   "SELECT id, title, status, created_at,
                           coalesce(length(sexp), 0),
                           coalesce(length(dita_xml), 0),
                           coalesce(length(hyperdoc_html), 0),
                           coalesce(length(scxml), 0)
                    FROM executable_dita_tasks
                    WHERE id = ~A
                    LIMIT 1;"
                   (executable-dita-sqlite-string-literal task-id)))
         (lines
           (executable-dita-sqlite-query-lines
            db-path
            sql
            :sqlite-program sqlite-program)))
    (and task
         lines
         (executable-dita-parse-task-row-line (first lines) task))))

(defun executable-dita-task-smoke-example ()
  (make-executable-dita-task
   :id "task.executable-dita-contract"
   :title "Implement Executable DITA task objects"
   :summary "Represent DITA-like task topics as canonical S-expression task objects with DITA, HyperDoc, SCXML, and SQLite projections."
   :context
   '((:hyperdoc-root "/Users/rgb/workspace/hyperdoc")
     (:branch "hauptsache")
     (:db "/Users/rgb/workspace/hyperdoc/var/shared-sexpression-plans.sqlite")
     (:topic-page "/Users/rgb/workspace/hyperdoc/hyperdoc/Executable DITA as shared S-expression task contract.html"))
   :pddl
   `(:task "(implement-executable-dita-task-contract hyperdoc executable-dita-tasks shared-sexpression-plans.sqlite)"
     :domain "hyperdoc-maintenance"
     :objective :minimize-cost
     :domain-data ,(executable-dita-default-pddl-domain))
   :scxml (executable-dita-default-scxml-contract)
   :preconditions
   '((:id "repo-visible"
      :check "(probe-file #p\"/Users/rgb/workspace/hyperdoc/hyperdoc.asd\")")
     (:id "sqlite-cli-visible"
      :check "sqlite3 --version"))
   :operators
   '((:id :initialize-db :kind :lisp :safe-default :print-only)
     (:id :store-prompt :kind :lisp :safe-default :print-only)
     (:id :select-next-task :kind :lisp :safe-default :print-only)
     (:id :run-smoke-test :kind :shell :safe-default :print-only))
   :postconditions
   '((:id "schema-created" :evidence "sqlite .schema output")
     (:id "prompt-stored" :evidence "read-executable-dita-task returns original task")
     (:id "best-task-selected" :evidence "ranked next task output"))
   :failure-modes
   '((:id "ql-package-reference"
      :repair "Remove QL package symbols from readable source.")
     (:id "planner-runtime-missing"
      :repair "Keep SHOP3 plan lookup as data until runtime is coherent.")
     (:id "mutation-without-guard"
      :repair "Require explicit :execute t or guarded operator.")
     (:id "wrong-project-root"
      :repair "Use /Users/rgb/workspace/hyperdoc as repository root; do not use /Users/rgb/workspace/hauptsache."))))
