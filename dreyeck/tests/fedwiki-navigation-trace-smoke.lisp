;;;; Tests for source-backed FedWiki navigation traces.

(defpackage #:dreyeck/fedwiki-navigation/tests
  (:use #:cl)
  (:export #:run-fedwiki-navigation-trace-tests))

(in-package #:dreyeck/fedwiki-navigation/tests)

(defun run-fedwiki-navigation-trace-tests ()
  (run-defexample-component-ownership-test)
  (dreyeck/fedwiki-navigation/prototype:navigation-transcript-smoke-test)
  
(defun require-test (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun top-level-defexample-names (component)
  (let ((end-of-file (gensym "END-OF-FILE"))
        (defexample-symbol
          (or (find-symbol "DEFEXAMPLE" "HYPERDOC")
              (error "HYPERDOC:DEFEXAMPLE is unavailable."))))
    (with-open-file
        (stream
         (asdf:component-pathname component)
         :direction :input)
      (loop
        for form =
          (let ((*read-eval* nil))
            (read stream nil end-of-file))
        until (eq form end-of-file)
        when
          (and
           (consp form)
           (eq (first form) defexample-symbol)
           (symbolp (second form)))
          collect
            (symbol-name (second form))))))

(defun run-defexample-component-ownership-test ()
  (let* ((target
           "FEDWIKI-JAVA-NAVIGATION-TRACE-EXAMPLE")
         (trace-system
           (asdf:find-system
            "dreyeck/fedwiki-navigation"))
         (views-system
           (asdf:find-system
            "dreyeck/inspector/fedwiki-navigation"))
         (trace-component
           (or
            (asdf:find-component
             trace-system
             "navigation-trace")
            (error
             "Component navigation-trace was not found.")))
         (views-component
           (or
            (asdf:find-component
             views-system
             "navigation-trace-views")
            (error
             "Component navigation-trace-views was not found.")))
         (trace-examples
           (top-level-defexample-names trace-component))
         (views-examples
           (top-level-defexample-names views-component))
         (target-count
           (count
            target
            (append trace-examples views-examples)
            :test #'string=))
         (dependencies
           (asdf:system-depends-on trace-system)))
    (require-test
     (some
      (lambda (dependency)
        (and
         (or (stringp dependency)
             (symbolp dependency))
         (string-equal
          (string dependency)
          "hyperdoc")))
      dependencies)
     "Owning system lacks direct HYPERDOC dependency: ~S."
     dependencies)
    (require-test
     (= target-count 1)
     "Expected exactly one ~A; found ~D."
     target target-count)
    (require-test
     (member target trace-examples :test #'string=)
     "~A is not owned by navigation-trace: ~S."
     target trace-examples)
    (require-test
     (not
      (member target views-examples :test #'string=))
     "~A is still owned by navigation-trace-views: ~S."
     target views-examples)
    t))

(defun trace-view-titles (object)
  (mapcar #'html-inspector-views:view-title
          (html-inspector-views:all-views object)))

(defun source-reference-record (reference)
  (let* ((component
           (dreyeck/fedwiki-navigation/prototype:navigation-source-reference-component
            reference))
         (source
           (dreyeck/fedwiki-navigation/prototype:navigation-source-reference-source-file
            reference))
         (pathname
           (dreyeck/fedwiki-navigation/prototype:navigation-source-file-pathname-of
            source))
         (dreyeck-root
           (merge-pathnames
            #P"dreyeck/src/"
            (uiop:pathname-directory-pathname
             (asdf:system-source-file
              (asdf:find-system :dreyeck/fedwiki-navigation)))))
         (producer
           (dreyeck/fedwiki-navigation/prototype:navigation-source-reference-producer-symbol-of
            reference)))
    (require-test (fboundp producer)
                  "Producer ~S is not function-bound." producer)
    (require-test (typep component 'asdf:cl-source-file)
                  "Source component ~S is not a Lisp component." component)
    (require-test (probe-file pathname)
                  "Source pathname ~A does not exist." pathname)
    (require-test (uiop:subpathp pathname dreyeck-root)
                  "Source pathname ~A is outside ~A." pathname dreyeck-root)
    (require-test
     (search (symbol-name producer)
             (dreyeck/fedwiki-navigation/prototype:navigation-source-file-contents
              source)
             :test #'char-equal)
     "Source ~A does not contain producer name ~S."
     pathname producer)
    (list producer
          (asdf:component-name
           (dreyeck/fedwiki-navigation/prototype:navigation-source-reference-system
            reference))
          (asdf:component-name component)
          (dreyeck/fedwiki-navigation/prototype:navigation-source-file-relative-pathname-of
           source))))

(defun run-trace-shape-test ()
  (let* ((trace
           (dreyeck/fedwiki-navigation/prototype:make-fedwiki-java-navigation-trace))
         (steps
           (dreyeck/fedwiki-navigation/prototype:navigation-trace-steps-of
            trace)))
    (require-test (= 7 (length steps))
                  "Trace has ~D steps instead of seven." (length steps))
    (require-test
     (equal
      '("case find pages we share"
        "find share"
        "next"
        "link"
        "find 2020"
        "link"
        "test experience")
      (dreyeck/fedwiki-navigation/prototype:navigation-trace-commands-of
       trace))
     "Trace commands differ: ~S"
     (dreyeck/fedwiki-navigation/prototype:navigation-trace-commands-of
      trace))
    (require-test
     (eq :passed
         (dreyeck/fedwiki-navigation/prototype:navigation-trace-result-of
          trace))
     "Trace result is not :PASSED.")
    (require-test
     (string=
      "dojo-practices-2020"
      (dreyeck/fedwiki-navigation/prototype:navigation-position-current-page-slug-of
       (dreyeck/fedwiki-navigation/prototype:navigation-trace-final-session-of
        trace)))
     "Trace did not finish on dojo-practices-2020.")
    (let ((link-steps (list (fourth steps) (sixth steps))))
      (require-test
       (equal
        '("dojo-practice-yearbooks" "dojo-practices-2020")
        (mapcar
         (lambda (step)
           (dreyeck/fedwiki-navigation/prototype:navigation-link-observation-link-slug-of
            (dreyeck/fedwiki-navigation/prototype:navigation-step-link-observation-of
             step)))
         link-steps))
       "Link observations differ."))
    (require-test
     (dreyeck/fedwiki-navigation/prototype:navigation-test-outcome-passed-p
      (dreyeck/fedwiki-navigation/prototype:navigation-step-outcome-of
       (seventh steps)))
     "The final TEST EXPERIENCE command did not pass.")
    (loop
      for previous in steps
      for next in (rest steps)
      do
         (require-test
          (equalp
           (dreyeck/fedwiki-navigation/prototype:navigation-step-after-of
            previous)
           (dreyeck/fedwiki-navigation/prototype:navigation-step-before-of
            next))
          "Step ~D AFTER does not match the following BEFORE."
          (dreyeck/fedwiki-navigation/prototype:navigation-step-number-of
           previous)))
    trace))

(defun run-snapshot-non-aliasing-test ()
  (let* ((session
           (dreyeck/fedwiki-navigation/prototype:make-navigation-fixture))
         (snapshot
           (dreyeck/fedwiki-navigation/prototype::navigation-position-from-session
            session))
         (item-id
           (dreyeck/fedwiki-navigation/prototype:navigation-position-current-item-id-of
            snapshot))
         (lineup
           (copy-list
            (dreyeck/fedwiki-navigation/prototype::navigation-position-lineup-slugs
             snapshot))))
    (dreyeck/fedwiki-navigation/prototype::move-next session)
    (dreyeck/fedwiki-navigation/prototype::move-next session)
    (dreyeck/fedwiki-navigation/prototype::follow-link session)
    (require-test
     (and
      (string= item-id
               (dreyeck/fedwiki-navigation/prototype:navigation-position-current-item-id-of
                snapshot))
      (equal lineup
             (dreyeck/fedwiki-navigation/prototype::navigation-position-lineup-slugs
              snapshot)))
     "Snapshot changed after mutating its source session."))
  t)

(defun run-source-relation-test (trace)
  (dolist (step
            (dreyeck/fedwiki-navigation/prototype:navigation-trace-steps-of
             trace))
    (source-reference-record
     (dreyeck/fedwiki-navigation/prototype:navigation-step-implementation-of
      step))
    (source-reference-record
     (dreyeck/fedwiki-navigation/prototype:navigation-step-dispatcher-implementation-of
      step)))
  t)

(defun run-inspector-view-test (trace)
  (let* ((step
           (fourth
            (dreyeck/fedwiki-navigation/prototype:navigation-trace-steps-of
             trace)))
         (reference
           (dreyeck/fedwiki-navigation/prototype:navigation-step-implementation-of
            step))
         (source
           (dreyeck/fedwiki-navigation/prototype:navigation-source-reference-source-file
            reference)))
    (dolist (title '("Trace" "Steps"))
      (require-test (member title (trace-view-titles trace) :test #'string=)
                    "Trace lacks view ~S." title))
    (dolist (title '("Before" "Command" "After"
                     "Explanation" "Implementation"))
      (require-test (member title (trace-view-titles step) :test #'string=)
                    "Step lacks view ~S." title))
    (dolist (title '("Implementation" "Source"))
      (require-test
       (member title (trace-view-titles reference) :test #'string=)
       "Source reference lacks view ~S." title))
    (dolist (title '("Source" "Contents"))
      (require-test (member title (trace-view-titles source) :test #'string=)
                    "Source file lacks view ~S." title)))
  t)

(defun run-fedwiki-navigation-trace-tests ()
  (dreyeck/fedwiki-navigation/prototype:navigation-transcript-smoke-test)
  (require-test
   (typep
    (dreyeck/fedwiki-navigation/prototype:fedwiki-java-navigation-trace-example)
    'dreyeck/fedwiki-navigation/prototype:navigation-trace)
   "The executable HyperDoc example did not return a navigation trace.")
  (let ((trace (run-trace-shape-test)))
    (run-snapshot-non-aliasing-test)
    (run-source-relation-test trace)
    (run-inspector-view-test trace))
  t)
