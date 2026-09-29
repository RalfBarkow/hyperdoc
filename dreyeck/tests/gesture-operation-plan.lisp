;;;; What turns a request into a plan, and what refuses to.

(defpackage #:dreyeck/gesture/operation-plan/tests
  (:use #:cl)
  (:local-nicknames (#:p #:dreyeck/gesture/operation-plan)
                    (#:r #:dreyeck/gesture/operation-request)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:a #:dreyeck/workflow/authoring)
                    (#:ex #:dreyeck/lisp-critic/examples)
                    (#:critic #:dreyeck/lisp-critic)
                    (#:er #:dreyeck/evaluation-record)
                    (#:views #:html-inspector-views))
  (:export #:run-operation-plan-tests))

(in-package #:dreyeck/gesture/operation-plan/tests)

(defun %page (book-id page-id)
  (let ((book (hyperbook:find-hyperbook book-id :signal-error? t)))
    (hyperdoc::ensure-pages-loaded book)
    (hyperbook:find-page book page-id :signal-error? t)))

(defun %ordering-page ()
  (%page "dreyeck/gesture/reading"
         "Reading the two continuations of one interaction."))

(defun %ordering (name) (find-symbol name "DREYECK/GESTURE/ORDERING"))

(defun %request ()
  "The request the code page's button makes for RACE-READING."
  (r:request-through-binding (r:inspector-binding) (%ordering-page)
                             (list :definition (%ordering "RACE-READING"))))

(defun %body ()
  (let ((*package* (find-package "DREYECK/GESTURE/ORDERING")))
    (list (read-from-string "(race-reading (t*::movement-wins-witness))"))))

(defun %refused-p (thunk &optional (type 'p:operation-plan-refused))
  (handler-case (progn (funcall thunk) nil)
    (error (condition) (typep condition type))))

(defun test-the-running-example ()
  (let* ((request (%request))
         (plan (p:plan-operation-request
                request :name (intern "RACE-READING-EXAMPLE" "DREYECK/GESTURE/ORDERING")
                        :body (%body)))
         (insertion (p:operation-plan-insertion plan)))
    (assert (eq request (p:operation-plan-request plan)))
    (assert (eq (w:insert-executable-defexample-operation)
                (r:operation-request-operation request)))
    (assert (equal (list :definition (%ordering "RACE-READING"))
                   (r:operation-request-form-key request)))
    (assert (equal (list (%ordering "MOVEMENT-WINS-READING")
                         (%ordering "DEADLINE-WINS-READING"))
                   (getf (p:operation-plan-observations plan) :examples-calling-target)))
    (assert (equal (list :definition (%ordering "%ENVELOPE"))
                   (a::insertion-plan-anchor-key insertion)))
    (assert (equal (list* 'hyperdoc:defexample
                          (%ordering "RACE-READING-EXAMPLE") (%body))
                   (a::insertion-plan-proposed insertion)))
    (assert (equal (list :example (%ordering "RACE-READING-EXAMPLE"))
                   (a::insertion-plan-key insertion)))
    (assert (eq :needs-insertion (a::insertion-plan-status insertion)))
    (assert (string= "dreyeck/gesture/reading" (a::insertion-plan-system insertion)))
    (assert (equal (truename (r:operation-request-path request))
                   (a::insertion-plan-path insertion)))
    ;; The view answers the questions, and says nothing ran.
    (let* ((view (find "Plan" (views:all-views plan)
                       :key #'views:view-title :test #'string=))
           (html (views:view-html view)))
      (dolist (needle '("operation/insert-executable-defexample" "RACE-READING-EXAMPLE"
                        "MOVEMENT-WINS-READING" "%ENVELOPE" "Executed"
                        "authorised" "attempted" "installed" "verified"))
        (assert (search needle html) () "The Plan view does not show ~A." needle)))
    plan))

(defun test-arguments-specify-the-plan (plan)
  "Same request, other arguments: another proposal."
  (let* ((other (p:plan-operation-request
                 (p:operation-plan-request plan)
                 :name (intern "RACE-READING-DEADLINE-EXAMPLE" "DREYECK/GESTURE/ORDERING")
                 :body (let ((*package* (find-package "DREYECK/GESTURE/ORDERING")))
                         (list (read-from-string
                                "(race-reading (t*::deadline-wins-witness))"))))))
    (assert (eq (p:operation-plan-request plan) (p:operation-plan-request other)))
    (assert (not (eq plan other)))
    (assert (not (equal (a::insertion-plan-proposed (p:operation-plan-insertion plan))
                        (a::insertion-plan-proposed (p:operation-plan-insertion other)))))))

(defparameter +last-keyed-definition-source+
  ";;;; Operation plan probe
(in-package :cl-user)

(defun plan-probe-earlier () 1)

(defun plan-probe-last () 2)

(pushnew :plan-probe-unkeyed *features*)
"
  "A code page whose last keyed top-level form is PLAN-PROBE-LAST. A form
follows it, but one without a structural key, so there is no insertion
anchor after it. PLAN-PROBE-EARLIER has one: PLAN-PROBE-LAST.")

(defun call-with-code-page-fixture (source function)
  "FUNCTION called with the one code page of a temporary system whose only
file holds SOURCE, and that file's path. The page is made by HyperDoc's own
constructor, so a request on it takes the production path. The system and
its directory are removed afterwards."
  (let* ((root (merge-pathnames (format nil "operation-plan-probe-~D-~D/"
                                        (get-universal-time) (random 100000))
                                (uiop:temporary-directory)))
         (asd (merge-pathnames "operation-plan-probe.asd" root))
         (path (merge-pathnames "code/probe.lisp" root)))
    (ensure-directories-exist path)
    (unwind-protect
         (progn
           (uiop:with-output-file (stream asd :external-format :utf-8)
             (write-string "(defsystem \"operation-plan-probe\"
  :components ((:module \"code\" :components ((:file \"probe\")))))
" stream))
           (uiop:with-output-file (stream path :external-format :utf-8)
             (write-string source stream))
           (asdf:load-asd asd)
           (let ((book (hyperdoc:make-hyperdoc :id "operation-plan-probe"
                                               :title "Operation plan probe"
                                               :asdf-system-name "operation-plan-probe"
                                               :subdirectory "code")))
             (funcall function (elt (hyperdoc::code-pages-of book) 0) path)))
      (ignore-errors (asdf:clear-system "operation-plan-probe"))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(defun test-no-keyed-form-after-the-definition ()
  "A definition with no keyed form after it: nothing to insert before. A
fixture owns that situation, so no evolving production file has to keep
it; the definition before it plans on the same page, so the refusal is
about the missing anchor and nothing else."
  (call-with-code-page-fixture
   +last-keyed-definition-source+
   (lambda (page path)
     (let ((before (uiop:read-file-string path :external-format :utf-8)))
       (flet ((plan (name)
                (p:plan-operation-request
                 (r:ensure-operation-request (w:insert-executable-defexample-operation) page
                                             (list :definition (intern name :cl-user)))
                 :name (intern (concatenate 'string name "-EXAMPLE") :cl-user)
                 :body (list 't))))
         (assert (equal (list :definition (intern "PLAN-PROBE-LAST" :cl-user))
                        (a::insertion-plan-anchor-key
                         (p:operation-plan-insertion (plan "PLAN-PROBE-EARLIER")))))
         (assert (%refused-p (lambda () (plan "PLAN-PROBE-LAST"))))
         (assert (search "no keyed top-level form follows"
                         (handler-case (progn (plan "PLAN-PROBE-LAST") "")
                           (p:operation-plan-refused (condition)
                             (p:operation-plan-refused-reason condition))))))
       (assert (string= before (uiop:read-file-string path :external-format :utf-8)))))))

(defun test-refusals ()
  (let* ((page (%ordering-page))
         (race (list :definition (%ordering "RACE-READING")))
         (name (intern "RACE-READING-EXAMPLE" "DREYECK/GESTURE/ORDERING")))
    ;; Another operation on the same definition is not this planner's.
    (assert (%refused-p
             (lambda ()
               (p:plan-operation-request
                (r:ensure-operation-request
                 (w::%make-operation-identity "operation/test-other" "Another operation")
                 page race)
                :name name :body (%body)))))
    ;; A request whose definition has gone from the authority. Made
    ;; directly, as a request from before the definition was removed.
    (assert (%refused-p
             (lambda ()
               (p:plan-operation-request
                (make-instance 'r:operation-request
                               :operation (w:insert-executable-defexample-operation)
                               :occurrence
                               (let ((observed (first (r:page-occurrences page))))
                                 (make-instance 'r:source-occurrence :page page
                                  :source (r:occurrence-source observed)
                                  :range (r:occurrence-range observed)
                                  :form-key (list :definition
                                                 (intern "NO-LONGER-HERE"
                                                         "DREYECK/GESTURE/ORDERING")))))
                :name name :body (%body)))))
    ;; A definition with no keyed form after it: nothing to insert before.
    (test-no-keyed-form-after-the-definition)
    ;; A name outside the definition's package is not how DEFEXAMPLE is used.
    (assert (%refused-p
             (lambda ()
               (p:plan-operation-request (%request)
                                         :name 'cl-user::stray-example
                                         :body (%body)))))
    ;; An example that already exists: the insertion machinery refuses,
    ;; not this planner.
    (assert (%refused-p
             (lambda ()
               (p:plan-operation-request (%request)
                                         :name (%ordering "MOVEMENT-WINS-READING")
                                         :body (%body)))
             'error))
    (assert (not (%refused-p
                  (lambda ()
                    (p:plan-operation-request (%request)
                                              :name (%ordering "MOVEMENT-WINS-READING")
                                              :body (%body))))))))

(defun %read (path) (uiop:read-file-string path :external-format :utf-8))

(defun test-execution-to-critique ()
  "RACE-READING's request, planned and executed on a copy of its code page.
Reading the installed page finds the new example; the Critic then judges that
occurrence. The inserted example, the critic evaluation, the critique and its
recommendation are four results, and none stands in for another."
  (call-with-code-page-fixture
   (%read (asdf:system-relative-pathname "dreyeck" "dreyeck/src/gesture-ordering-reading.lisp"))
   (lambda (page path)
     (let* ((before (%read path))
            (name (intern "MOVEMENT-WINS-MARKING-EXAMPLE" "DREYECK/GESTURE/ORDERING"))
            (body (let ((*package* (find-package "DREYECK/GESTURE/ORDERING")))
                    (list (read-from-string
                           "(equal :marking (getf (race-reading (t*::movement-wins-witness)) :mode))"))))
            (plan (p:plan-operation-request
                   (r:ensure-operation-request (w:insert-executable-defexample-operation) page
                                               (list :definition (%ordering "RACE-READING")))
                   :name name :body body))
            (environment (a:make-authoring-environment)))
       ;; Without the pinned authoring environment: refused, nothing written.
       (assert (%refused-p (lambda () (p:execute-operation-plan plan nil)) 'p:operation-execution-refused))
       (assert (string= before (%read path)))
       (let ((occurrence (p:execute-operation-plan plan environment))
             (after (%read path)))
         ;; The inserted example: what reading the installed page finds.
         (assert (typep occurrence 'r:source-occurrence))
         (assert (eq page (r:occurrence-page occurrence)))
         (assert (equal (list :example name) (r:occurrence-form-key occurrence)))
         (assert (not (string= before after)))
         (assert (string= after (r:occurrence-source occurrence)))
         (assert (eq :current (r:occurrence-status occurrence)))
         (assert (equal (list (list :example name) (r:occurrence-range occurrence))
                        (find (list :example name)
                              (mapcar (lambda (found) (list (r:occurrence-form-key found) (r:occurrence-range found)))
                                      (r:page-example-occurrences page))
                              :key #'first :test #'equal)))
         ;; Executed again, the plan no longer holds: nothing more is written.
         (assert (%refused-p (lambda () (p:execute-operation-plan plan environment))
                             'p:operation-execution-refused))
         (assert (string= after (%read path)))
         ;; A critic evaluation of that occurrence, by one real rule.
         (let* ((target (ex:critic-target-for-example occurrence))
                (contract (critic:lisp-critic-run-record-contract-of
                           (first (critic:target-runs-of (critic:car-cdr-critique-example)))))
                (record (critic:run-critic-rule contract "USE-EQL" target))
                (finding (first (critic:critiques-of record))))
           (assert (eq :completed (er:evaluation-status-of record)) ()
                   "Real Critic run failed: ~A" (er:evaluation-failure-of record))
           (assert (eq target (er:evaluation-input-of record)))
           ;; Its critique leads back to the inserted occurrence.
           (assert (equal (list finding) (er:evaluation-result-of record)))
           (assert (eq occurrence (ex:example-occurrence-of (critic:target-of finding))))
           (assert (eq 'equal (first (uiop:symbol-call :lisp-critic :critique-code
                                                       (critic:critique-evidence-of finding)))))
           ;; Its recommendation is text; nothing applies it.
           (assert (search "EQL" (critic:critique-explanation-of finding)))
           (assert (string= after (%read path)))
           ;; The example was never loaded, so it was never run.
           (assert (not (fboundp name)))
           record))))))

(defun %closure (name &optional seen)
  "Every system NAME depends on, by name, found without loading any."
  (let ((system (asdf:find-system name nil)))
    (if (or (null system) (member (asdf:component-name system) seen :test #'string=))
        seen
        (let ((seen (cons (asdf:component-name system) seen)))
          (dolist (dependency (asdf:system-depends-on system) seen)
            (let ((dependency-name
                    (cond ((stringp dependency) dependency)
                          ((symbolp dependency) (string-downcase dependency))
                          ((and (consp dependency) (eq :version (first dependency)))
                           (string-downcase (string (second dependency)))))))
              (when dependency-name
                (setf seen (%closure dependency-name seen)))))))))

(defun test-the-catalog-cannot-reach-the-planner ()
  (let ((closure (%closure "dreyeck/catalog")))
    (assert (member "dreyeck/gesture/operation-request" closure :test #'string=))
    (assert (not (member "dreyeck/gesture/operation-request/authoring" closure
                         :test #'string=)))
    (assert (not (member "dreyeck/workflow/authoring" closure :test #'string=)))))

(defun run-operation-plan-tests ()
  (let* ((authorities (list (asdf:system-relative-pathname
                             "dreyeck" "dreyeck/src/gesture-ordering-reading.lisp")))
         (before (mapcar (lambda (path) (uiop:read-file-string path :external-format :utf-8))
                         authorities)))
    (let ((plan (test-the-running-example)))
      (test-arguments-specify-the-plan plan))
    (test-refusals)
    (test-execution-to-critique)
    (test-the-catalog-cannot-reach-the-planner)
    (assert (every #'string= before
                   (mapcar (lambda (path) (uiop:read-file-string path :external-format :utf-8))
                           authorities)))
    (format t "~&OPERATION-PLAN-PASS: RACE-READING's request with a name and a ~
body plans one DEFEXAMPLE before %ENVELOPE, needs insertion, and reports ~
MOVEMENT-WINS-READING and DEADLINE-WINS-READING already calling it; other ~
arguments plan another form; another operation, a vanished definition, no ~
following keyed form (a fixture code page, whose earlier definition does ~
plan) and a stray name are refused by the planner, an existing example by ~
the insertion machinery; the Catalog's dependencies do not reach the ~
planner; the authority and the fixture are byte-identical. Executed on a ~
copy of the code page, the plan installs one example that reading the page ~
again finds, and USE-EQL judges that occurrence without the example being ~
run or its recommendation applied.~%")
    t))
