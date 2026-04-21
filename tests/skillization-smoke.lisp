;;;; Focused smoke tests for skillization docs, topics, and definition objects
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-SKILLIZATION-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun skillization-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun skillization-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun skillization-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message
           expected-type
           (type-of object))))

(defun read-skillization-page (namestring)
  (uiop:read-file-string
   (asdf:system-relative-pathname :hyperdoc namestring)))

(defun skillization-page-pathname (namestring)
  (asdf:system-relative-pathname :hyperdoc namestring))

(defun normalize-skillization-whitespace (string)
  (with-output-to-string (stream)
    (loop with pending-space = nil
          with wrote-char = nil
          for char across string
          do (if (find char '(#\Space #\Tab #\Newline #\Return))
                 (setf pending-space t)
                 (progn
                   (when pending-space
                     (when wrote-char
                       (write-char #\Space stream))
                     (setf pending-space nil))
                   (write-char char stream)
                   (setf wrote-char t))))))

(defun skillization-page-contains-all-p (page-source needles)
  (let ((normalized (normalize-skillization-whitespace page-source)))
    (every (lambda (needle)
             (search (normalize-skillization-whitespace needle)
                     normalized
                     :test #'char=))
           needles)))

(defun run-skillization-topic-factory-smoke-test ()
  (dolist (spec '((hyperdoc::skillization-topic . "Skillization")
                  (hyperdoc::skill-pattern-topic . "Skill pattern")
                  (hyperdoc::conceptual-center-topic . "Conceptual center")
                  (hyperdoc::discoverability-propagation-topic
                   . "Discoverability propagation")
                  (hyperdoc::docs-only-propagation-slice-topic
                   . "Docs-only propagation slice")
                  (hyperdoc::architectural-drift-topic
                   . "Architectural drift")))
    (let ((symbol (car spec))
          (title (cdr spec)))
      (skillization-assert-true
       (fboundp symbol)
       (format nil "Missing topic factory ~A" symbol))
      (skillization-assert-true
       (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
       (format nil "Missing Topics HyperBook page ~A" title)))))

(defun run-skillization-page-smoke-test ()
  (dolist (page-spec '(("Skillization in HyperDoc"
                        . "hyperdoc/Skillization in HyperDoc.html")
                       ("Operational definition: skill pattern, conceptual center, discoverability propagation"
                        . "hyperdoc/Operational definition: skill pattern, conceptual center, discoverability propagation.html")
                       ("Conceptual center in HyperDoc"
                        . "hyperdoc/Conceptual center in HyperDoc.html")
                       ("Discoverability propagation in HyperDoc"
                        . "hyperdoc/Discoverability propagation in HyperDoc.html")))
    (let* ((page-title (car page-spec))
           (page-namestring (cdr page-spec))
           (page-pathname (skillization-page-pathname page-namestring))
           (page-source (read-skillization-page page-namestring)))
      (skillization-assert-true
       (probe-file page-pathname)
       (format nil "Missing authored HyperDoc page file ~A" page-namestring))
      (skillization-assert-true
       (skillization-page-contains-all-p
        page-source
        (list (format nil "<h1>~A</h1>" page-title)))
       (format nil "Authored HyperDoc page ~A must keep its expected title." page-title))))
  (skillization-assert-true
   (skillization-page-contains-all-p
    (read-skillization-page "hyperdoc/Skillization in HyperDoc.html")
    '("(make-route-language-skill-pattern-definition)"
      "Skillization loop"))
   "Skillization in HyperDoc must expose the worked example object and distinguish the skillization loop.")
  (skillization-assert-true
   (skillization-page-contains-all-p
    (read-skillization-page
     "hyperdoc/Operational definition: skill pattern, conceptual center, discoverability propagation.html")
    '("skill pattern"
      "conceptual center"
      "discoverability propagation"
      "docs-only propagation slice"
      "architectural drift"))
   "Operational definition page must define the vocabulary explicitly."))

(defun run-skill-pattern-definition-smoke-test ()
  (let* ((pattern (hyperdoc::make-route-language-skill-pattern-definition))
         (steps (hyperdoc::skill-pattern-steps-of pattern))
         (first-step (first steps))
         (second-step (second steps))
         (page-titles (hyperdoc::skill-pattern-page-titles pattern)))
    (skillization-assert-typep
     'hyperdoc::skill-pattern-definition
     pattern
     "Worked example must materialize as a skill-pattern-definition.")
    (skillization-assert-equal
     "Iconic route language in HyperDoc"
     (hyperdoc::skill-pattern-concept-page-of pattern)
     "Worked example must keep the conceptual center page title.")
    (skillization-assert-true
     (hyperdoc::docs-only-skill-pattern-p pattern)
     "Worked example must be classified as docs-only.")
    (skillization-assert-true
     (hyperdoc::skill-pattern-has-topic-growth-p pattern)
     "Worked example must record that the conceptual-center slice allowed topic growth.")
    (skillization-assert-true
     (= 2 (length steps))
     "Worked example must keep the two-step pattern.")
    (skillization-assert-typep
     'hyperdoc::conceptual-center-step
     first-step
     "First step must be the conceptual-center step.")
    (skillization-assert-true
     (hyperdoc::skill-pattern-step-topic-growth-allowed-p-of first-step)
     "Conceptual-center step must allow topic growth when needed.")
    (skillization-assert-typep
     'hyperdoc::discoverability-propagation-step
     second-step
     "Second step must be the discoverability-propagation step.")
    (skillization-assert-true
     (hyperdoc::discoverability-only-step-p second-step)
     "Second step must remain the discoverability-only step.")
    (dolist (page-title '("Iconic route language in HyperDoc"
                          "Dock capabilities in HyperDoc"
                          "Dock presentation state model"))
      (skillization-assert-true
       (member page-title page-titles :test #'string=)
       (format nil "Worked example page titles must include ~A." page-title)))))

(defun run-skillization-smoke-tests ()
  (run-skillization-topic-factory-smoke-test)
  (run-skillization-page-smoke-test)
  (run-skill-pattern-definition-smoke-test)
  (format t "~&Skillization smoke tests passed.~%")
  t)
