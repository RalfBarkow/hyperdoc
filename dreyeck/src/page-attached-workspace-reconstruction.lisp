(in-package #:dreyeck/page-attached-system-projection)

;;;; Reconstructing a Workspace from a page's own ASDF definition.
;;;;
;;;; This function used to assert that the base projection held exactly
;;;; three topics and two associations, and the workspace projection four
;;;; and three. Those numbers were true of the definition it was first
;;;; written against, which defines a principal system and a test system.
;;;; They are not a contract: the projection holds one authority topic,
;;;; one topic per system the .asd defines, and one :DEFINES association
;;;; each, so the counts only say "this .asd defines two systems".
;;;;
;;;; They were not even a property of the file. SYSTEMS-DEFINED-BY-ASD
;;;; reads ASDF's registration table, so the counts move with whatever
;;;; happens to be registered in the image at the time.
;;;;
;;;; A real page-attached definition with a single system therefore could
;;;; not be reconstructed, although every step of the reconstruction
;;;; worked for it. What follows asserts what the later steps actually
;;;; need instead.

(defun %authority-id-for (asd)
  (format nil "asd:~A" (namestring asd)))

(defun %topics-of-type (projection type)
  (remove type (dreyeck/topicmap:topicmap-projection-topics-of projection)
          :key #'dreyeck/topicmap:topicmap-topic-type-of
          :test-not #'eq))

(defun %associations-of-type (projection type)
  (remove type (dreyeck/topicmap:topicmap-projection-associations-of projection)
          :key #'dreyeck/topicmap:topicmap-association-type-of
          :test-not #'eq))

(defun %topic-by-id (projection id)
  (find id (dreyeck/topicmap:topicmap-projection-topics-of projection)
        :key #'dreyeck/topicmap:topicmap-topic-id-of :test #'string=))

(defun execution-permitted-p ()
  "Whether this runtime may run code that arrived with a page.

Reuses the flag the playground already answers to rather than adding a
second switch: HYPERBOOK/SERVER::*SERVER-PARAMETERS* is NIL until a
server starts and then holds (pane-width development). A served runtime
started without development refuses; an image with no server — a
developer's, or a test's — allows.

Read softly on purpose. Nothing down here should depend on the HTTP
server; the question is only whether one is running.

The package name is load-bearing and was wrong once: looked up as
HYPERBOOK-SERVER, which does not exist, this returned NIL parameters
and so permitted everything, including on a production server. A test
that makes the package itself cannot catch that, so the tests bind the
real variable in the real package."
  (let* ((package (find-package :hyperbook/server))
         (symbol (and package (find-symbol "*SERVER-PARAMETERS*" package)))
         (parameters (and symbol (boundp symbol) (symbol-value symbol))))
    (if (null parameters)
        t
        (and (second parameters) t))))

(define-condition execution-not-permitted (error)
  ((operation :initarg :operation :reader execution-not-permitted-operation))
  (:report
   (lambda (condition stream)
     (format stream "~A is not permitted in this runtime: it would run code ~
that arrived with a page, and this server was started without development ~
mode."
             (execution-not-permitted-operation condition))))
  (:documentation
   "Refusal of an operation that would execute page-attached code.

Signalled by the operation, not by a view that offers it. Removing a
button removes one way of asking; anything reaching the function by
another route must meet the same answer."))

(defun page-attached-workspace-eligibility (system-designator)
  "Why SYSTEM-DESIGNATOR can or cannot become a Workspace, as a plist.

Separated from the reconstruction so that a caller can ask without
signalling, and so the reasons are inspectable rather than hidden in an
assertion failure."
  (handler-case
      (let* ((system (asdf/system:find-system system-designator))
             (asd (asdf/system:system-source-file system))
             ;; A system built into the image has no source file at all,
             ;; so nothing below it can be asked.
             (defined (and asd
                           (dreyeck/page-attached-asdf:systems-defined-by-asd
                            asd)))
             (page-attached
               (and asd (dreyeck/page-attached-asdf:page-attached-asd-p asd)))
             (principal-defined
               (and (member (asdf/component:component-name system) defined
                            :test #'string=)
                    t)))
        (list :system-designator system-designator
              :asd asd
              :page-attached-p page-attached
              :defined-systems defined
              :principal-system (asdf/component:component-name system)
              :principal-defined-by-its-asd-p principal-defined
              :eligible-p (and page-attached principal-defined t)
              :why (cond ((null asd) "the system has no source file")
                         ((not page-attached)
                          "the definition is not a page's own: it does not \
sit in a page's assets directory")
                         ((not principal-defined)
                          "the definition does not define this system")
                         (t nil))))
    (error (condition)
      (list :system-designator system-designator
            :eligible-p nil
            :why (format nil "~A" condition)))))

(defun reconstruct-page-attached-workspace (system-designator)
  ;; Guarded here rather than at each caller: LOOKUP-PATH on an offer
  ;; reaches this too, and so would anything else.
  (unless (execution-permitted-p)
    (error 'execution-not-permitted :operation "Workspace reconstruction"))
  (let* ((eligibility (page-attached-workspace-eligibility system-designator)))
    (assert (getf eligibility :eligible-p) ()
            "~A cannot be reconstructed as a page-attached workspace: ~A."
            system-designator (getf eligibility :why))
    (let* ((system (asdf/system:find-system system-designator))
           (system-name (asdf/component:component-name system))
           (asd (asdf/system:system-source-file system))
           (base-projection (page-attached-system-projection system-designator))
           (workspace-projection
             (dreyeck/topicmap::project-page-attached-workspace base-projection
                                                                system-name))
           (workspace
             (dreyeck/topicmap::make-topicmap-workspace-for-object
              workspace-projection))
           (materialized-projection
             (dreyeck/topicmap:topicmap-projection-of workspace))
           (current-topic
             (dreyeck/topicmap:topicmap-workspace-current-topic workspace))
           (authority-id (%authority-id-for asd))
           (system-id (format nil "asdf-system:~A" system-name))
           (workspace-id (format nil "workspace:~A" system-name)))
      ;; One definition speaks for this workspace, and it is the .asd.
      (assert (= 1 (length (%topics-of-type base-projection
                                            :page-attached-authority))))
      (assert (%topic-by-id base-projection authority-id))
      ;; The principal system is in the projection, related to that
      ;; definition. Sibling systems may be there too; how many there are
      ;; is a fact about the definition, not a condition on it.
      (assert (%topic-by-id base-projection system-id))
      (assert (= (length (dreyeck/topicmap:topicmap-projection-topics-of
                          base-projection))
                 (1+ (length (%associations-of-type base-projection :defines)))))
      (assert (find-if (lambda (association)
                         (and (string= authority-id
                                       (dreyeck/topicmap:topicmap-association-from-of
                                        association))
                              (string= system-id
                                       (dreyeck/topicmap:topicmap-association-to-of
                                        association))))
                       (%associations-of-type base-projection :defines)))
      ;; The workspace subject is derived from the principal system, so it
      ;; is the same on every run, and there is exactly one of it.
      (assert (= 1 (length (%associations-of-type workspace-projection
                                                  :workspace))))
      (assert (%topic-by-id workspace-projection workspace-id))
      ;; Reconstruction produced a workspace, materialization is a
      ;; separate projection, and the workspace stands at the definition.
      (assert workspace)
      (assert materialized-projection)
      (assert (not (eq workspace-projection materialized-projection)))
      (assert current-topic)
      (assert (string= authority-id
                       (dreyeck/topicmap:topicmap-topic-id-of current-topic)))
      (list :system-designator system-designator :asd asd :base-projection
            base-projection :workspace-projection workspace-projection
            :workspace workspace :materialized-projection
            materialized-projection :fresh-projection-p t :current-topic
            current-topic :current-topic-id
            (dreyeck/topicmap:topicmap-topic-id-of current-topic)
            :defined-systems (getf eligibility :defined-systems)
            :ready-for :fresh-image-runner))))
