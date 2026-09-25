;;;; What turns a request into a plan, and what refuses to.

(defpackage #:dreyeck/gesture/operation-plan/tests
  (:use #:cl)
  (:local-nicknames (#:p #:dreyeck/gesture/operation-plan)
                    (#:r #:dreyeck/gesture/operation-request)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:a #:dreyeck/workflow/authoring)
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
    (assert (%refused-p
             (lambda ()
               (p:plan-operation-request
                (r:ensure-operation-request
                 (w:insert-executable-defexample-operation)
                 (%page "hyperdoc" "Support for tools")
                 (list :definition (find-symbol "MAKE-PLAYGROUND" "HYPERDOC")))
                :name (intern "PLAN-PROBE-EXAMPLE" "HYPERDOC")
                :body (list 't)))))
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
                             "dreyeck" "dreyeck/src/gesture-ordering-reading.lisp")
                            (hyperdoc::source-code-pathname (%page "hyperdoc" "Support for tools"))))
         (before (mapcar (lambda (path) (uiop:read-file-string path :external-format :utf-8))
                         authorities)))
    (let ((plan (test-the-running-example)))
      (test-arguments-specify-the-plan plan))
    (test-refusals)
    (test-the-catalog-cannot-reach-the-planner)
    (assert (every #'string= before
                   (mapcar (lambda (path) (uiop:read-file-string path :external-format :utf-8))
                           authorities)))
    (format t "~&OPERATION-PLAN-PASS: RACE-READING's request with a name and a ~
body plans one DEFEXAMPLE before %ENVELOPE, needs insertion, and reports ~
MOVEMENT-WINS-READING and DEADLINE-WINS-READING already calling it; other ~
arguments plan another form; another operation, a vanished definition, no ~
following keyed form and a stray name are refused by the planner, an ~
existing example by the insertion machinery; the Catalog's dependencies do ~
not reach the planner; both authorities are byte-identical.~%")
    t))
