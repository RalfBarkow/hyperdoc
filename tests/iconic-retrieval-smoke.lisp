;;;; Smoke tests for inspectable iconic retrieval objects
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-ICONIC-RETRIEVAL-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun iconic-retrieval-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun iconic-retrieval-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun iconic-retrieval-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message
           expected-type
           (type-of object))))

(defun iconic-retrieval-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun run-iconic-retrieval-constructor-smoke-test ()
  (dolist (symbol '(hyperdoc::make-world-state-proxy
                    hyperdoc::make-linguistic-retrieval-cue
                    hyperdoc::make-iconic-state-definition
                    hyperdoc::make-iconic-retrieval-route
                    hyperdoc::make-iconic-state-trajectory
                    hyperdoc::make-neural-state-machine-model-definition
                    hyperdoc::make-lexical-iconic-association-example
                    hyperdoc::make-case-role-iconic-trajectory-example
                    hyperdoc::make-iconic-route-language-example
                    hyperdoc::make-neural-state-machine-model-example
                    hyperdoc::grounded-iconic-state-p
                    hyperdoc::reentrant-iconic-state-p
                    hyperdoc::symbolic-and-grounded-dual-object-p
                    hyperdoc::iconic-retrieval-route-page-titles
                    hyperdoc::iconic-retrieval-summary-alist
                    hyperdoc::follow-route-retrieves-grounded-state-p
                    hyperdoc::acquire-iconic-representation
                    hyperdoc::associate-language-cue-with-iconic-state
                    hyperdoc::retrieve-iconic-state
                    hyperdoc::describe-case-role-trajectory
                    hyperdoc::describe-lexical-association-trajectory))
    (iconic-retrieval-assert-true
     (fboundp symbol)
     (format nil "Missing iconic retrieval function ~A" symbol))))

(defun run-iconic-retrieval-example-shape-smoke-test ()
  (let* ((route (hyperdoc::make-iconic-route-language-example))
         (lexical-example (hyperdoc::make-lexical-iconic-association-example))
         (case-example (hyperdoc::make-case-role-iconic-trajectory-example))
         (model (hyperdoc::make-neural-state-machine-model-example))
         (cue (hyperdoc::iconic-retrieval-route-cue-of route))
         (source-state (hyperdoc::iconic-retrieval-route-source-state-of route))
         (iconic-state (hyperdoc::iconic-retrieval-route-iconic-state-of route))
         (trajectory (hyperdoc::iconic-state-trajectory-of iconic-state))
         (summary (hyperdoc::iconic-retrieval-summary-alist route))
         (page-titles (hyperdoc::iconic-retrieval-route-page-titles route))
         (lexical-retrieved (hyperdoc::retrieve-iconic-state "cup" lexical-example))
         (case-description (hyperdoc::describe-case-role-trajectory case-example))
         (lexical-description
          (hyperdoc::describe-lexical-association-trajectory lexical-example)))
    (iconic-retrieval-assert-typep
     'hyperdoc::iconic-retrieval-route
     route
     "Route example must materialize as an iconic retrieval route")
    (iconic-retrieval-assert-typep
     'hyperdoc::multimodal-association-example
     lexical-example
     "Lexical example must materialize as a multimodal association example")
    (iconic-retrieval-assert-typep
     'hyperdoc::case-role-trajectory-example
     case-example
     "Case-role example must materialize as a case-role trajectory example")
    (iconic-retrieval-assert-typep
     'hyperdoc::linguistic-retrieval-cue
     cue
     "Route example must keep a symbolic cue object")
    (iconic-retrieval-assert-typep
     'hyperdoc::world-state-proxy
     source-state
     "Route example must keep a grounded world-state proxy")
    (iconic-retrieval-assert-typep
     'hyperdoc::iconic-state-definition
     iconic-state
     "Route example must keep an iconic state definition")
    (iconic-retrieval-assert-typep
     'hyperdoc::iconic-state-trajectory
     trajectory
     "Route example must keep a trajectory")
    (iconic-retrieval-assert-typep
     'hyperdoc::neural-state-machine-model-definition
     model
     "Model example must materialize as a neural-state-machine-model definition")
    (iconic-retrieval-assert-typep
     'hyperdoc::reentrant-iconic-state
     lexical-retrieved
     "Retrieving the lexical example through the written cue must reach a reentrant iconic state")
    (iconic-retrieval-assert-true
     (eq source-state (hyperdoc::iconic-state-world-state-proxy-of iconic-state))
     "Route example must keep the grounded source state distinct but linked to the iconic state")
    (iconic-retrieval-assert-true
     (hyperdoc::grounded-iconic-state-p iconic-state)
     "Iconic state example must report grounded state")
    (iconic-retrieval-assert-true
     (hyperdoc::symbolic-and-grounded-dual-object-p route)
     "Route example must keep symbolic and grounded readings linked")
    (iconic-retrieval-assert-true
     (hyperdoc::symbolic-and-grounded-dual-object-p model)
     "Model example must keep symbolic and grounded readings linked")
    (iconic-retrieval-assert-true
     (hyperdoc::reentrant-iconic-state-p lexical-example)
     "Lexical example must preserve the paper's reentrant-state pattern")
    (iconic-retrieval-assert-true
     (hyperdoc::follow-route-retrieves-grounded-state-p route)
     "Follow-route helper must report successful grounded retrieval for the example")
    (iconic-retrieval-assert-true
     (hyperdoc::follow-route-retrieves-grounded-state-p lexical-example)
     "Lexical example routes must retrieve grounded state")
    (iconic-retrieval-assert-true
     (hyperdoc::follow-route-retrieves-grounded-state-p case-example)
     "Case-role example routes must retrieve grounded state")
    (iconic-retrieval-assert-equal
     :symbolic-to-grounded
     (cdr (assoc :retrieval-mode summary))
     "Route summary must preserve the retrieval mode")
    (iconic-retrieval-assert-equal
     "Follow route"
     (cdr (assoc :follow-label summary))
     "Route summary must preserve the Touch-Fahrplan follow label")
    (dolist (page-title '("Iconic route language in HyperDoc"
                          "Focused semantic source stations"
                          "Symbols and semantics in Mind and Mechanism"
                          "Touch-Fahrplan view for Zotero topic enrichment"))
      (iconic-retrieval-assert-true
       (member page-title page-titles :test #'string=)
       (format nil "Route page titles must include ~A" page-title)))
    (iconic-retrieval-assert-true
     (equal '("k-a-p" "cup")
            (cdr (assoc :cue-texts lexical-description)))
     "Lexical description must preserve the phonemic and written cues")
    (iconic-retrieval-assert-true
     (cdr (assoc :reentrant-p lexical-description))
     "Lexical description must report a reentrant iconic state")
    (iconic-retrieval-assert-equal
     2
     (length (cdr (assoc :sentence-variants case-description)))
     "Case-role description must preserve the two sentence variants")
    (iconic-retrieval-assert-true
     (cdr (assoc :distinct-trajectory-p case-description))
     "Case-role description must report distinct trajectories")))

(defun run-iconic-retrieval-page-and-topic-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (dolist (entry '((hyperdoc::iconic-state-topic "Iconic state")
                   (hyperdoc::iconic-hypothesis-topic "Iconic hypothesis")
                   (hyperdoc::understanding-as-retrieval-topic
                    "Understanding as retrieval")
                   (hyperdoc::language-as-retrieval-vehicle-topic
                    "Language as retrieval vehicle")
                   (hyperdoc::neural-state-machine-model-topic
                    "Neural State Machine Model")
                   (hyperdoc::iconic-route-language-in-hyperdoc-topic
                    "Iconic route language in HyperDoc")
                   (hyperdoc::world-state-topic "World state")
                   (hyperdoc::world-state-proxy-topic "World-state proxy")
                   (hyperdoc::acquisition-of-iconic-representation-topic
                    "Acquisition of iconic representation")
                   (hyperdoc::linguistic-retrieval-cue-topic
                    "Linguistic retrieval cue")
                   (hyperdoc::iconic-retrieval-route-topic
                    "Iconic retrieval route")
                   (hyperdoc::iconic-state-trajectory-topic
                    "Iconic state trajectory")
                   (hyperdoc::reentrant-state-topic "Reentrant state")
                   (hyperdoc::early-processing-topic "Early processing")
                   (hyperdoc::grounded-symbolic-operation-topic
                    "Grounded symbolic operation")))
    (destructuring-bind (symbol title) entry
      (iconic-retrieval-assert-true
       (fboundp symbol)
       (format nil "Missing topic function ~A" symbol))
      (iconic-retrieval-assert-true
       (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
       (format nil "Missing topic page ~A" title))))
  (dolist (title '("Iconic route language in HyperDoc"
                   "Inspectable iconic retrieval objects"
                   "Focused semantic source stations"
                   "Symbols and semantics in Mind and Mechanism"
                   "Touch-Fahrplan view for Zotero topic enrichment"))
    (iconic-retrieval-assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc* title :signal-error? t)
     (format nil "Missing HyperDoc page ~A" title)))
  (let ((iconic-source
         (uiop:read-file-string
          (iconic-retrieval-relative-path
           "hyperdoc/Iconic route language in HyperDoc.html")))
        (operational-source
         (uiop:read-file-string
          (iconic-retrieval-relative-path
           "hyperdoc/Inspectable iconic retrieval objects.html")))
        (symbols-source
         (uiop:read-file-string
          (iconic-retrieval-relative-path
           "hyperdoc/Symbols and semantics in Mind and Mechanism.html"))))
    (dolist (substring '("(make-iconic-route-language-example)"
                         "(make-lexical-iconic-association-example)"
                         "(make-case-role-iconic-trajectory-example)"
                         "(make-neural-state-machine-model-example)"
                         "(iconic-retrieval-summary-alist (make-iconic-route-language-example))"))
      (iconic-retrieval-assert-true
       (search substring iconic-source :test #'char=)
       (format nil "Iconic route page must contain ~S" substring)))
    (dolist (substring '("(describe-lexical-association-trajectory (make-lexical-iconic-association-example))"
                         "(describe-case-role-trajectory (make-case-role-iconic-trajectory-example))"
                         "(retrieve-iconic-state \"cup\" (make-lexical-iconic-association-example))"))
      (iconic-retrieval-assert-true
       (search substring operational-source :test #'char=)
       (format nil "Operational iconic retrieval page must contain ~S" substring)))
    (dolist (substring '("Grounded symbolic operation"
                         "Inspectable iconic retrieval objects"))
      (iconic-retrieval-assert-true
       (search substring symbols-source :test #'char=)
       (format nil "Symbols page must contain ~S" substring)))))

(defun run-iconic-retrieval-smoke-tests ()
  (run-iconic-retrieval-constructor-smoke-test)
  (run-iconic-retrieval-example-shape-smoke-test)
  (run-iconic-retrieval-page-and-topic-smoke-test)
  (format t "~&Iconic retrieval smoke tests passed.~%")
  t)
