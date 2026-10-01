;;;; Executable TALA reading examples
(IN-PACKAGE :DREYECK/INSPECTOR/TOPICMAP/TALA)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Reading TALA as a Layout Layer"))

(HYPERDOC:DEFEXAMPLE READING-WORKSPACE
                     (TM::MAKE-TOPICMAP-WORKSPACE-FOR-OBJECT
                                                             (DREYECK/GIT:MAKE-CURRENT-GIT-REPOSITORY-CHECKOUT)))

(HYPERDOC:DEFEXAMPLE READING-PROJECTION
                     (TM:TOPICMAP-PROJECTION-OF (READING-WORKSPACE)))

(HYPERDOC:DEFEXAMPLE READING-TOPIC-IDENTITIES
                     (MAPCAR (FUNCTION TM:TOPICMAP-TOPIC-ID-OF)
                             (TM:TOPICMAP-PROJECTION-TOPICS-OF
                                                               (READING-PROJECTION))))

(HYPERDOC:DEFEXAMPLE READING-ASSOCIATION-ENDPOINTS
                     (MAPCAR
                             (LAMBDA (ASSOCIATION)
                                     (LIST :ID
                                           (TM:TOPICMAP-ASSOCIATION-ID-OF
                                                                          ASSOCIATION)
                                           :FROM
                                           (TM:TOPICMAP-ASSOCIATION-FROM-OF
                                                                            ASSOCIATION)
                                           :TO
                                           (TM:TOPICMAP-ASSOCIATION-TO-OF
                                                                          ASSOCIATION)))
                             (TM:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
                                                                     (READING-PROJECTION))))

(HYPERDOC:DEFEXAMPLE READING-LAYOUT-INPUT
                     (TALA:PROJECTION-TALA-INPUT (READING-PROJECTION) :SEED 44))

(HYPERDOC:DEFEXAMPLE READING-ID-MAPPING
                     (LET ((INPUT (READING-LAYOUT-INPUT)))
                          (LIST :TOPICS (TALA:TALA-INPUT-TOPICS INPUT)
                                :ASSOCIATIONS
                                (TALA:TALA-INPUT-ASSOCIATIONS INPUT)
                                :ROUNDTRIPS
                                ;; The key leads back to the Topic by being
                                ;; looked up in the projection that assigned
                                ;; it, not by being decoded. A key is local
                                ;; to this diagram; the Topic is not.
                                (MAPCAR
                                        (LAMBDA (ENTRY)
                                                (LIST (GETF ENTRY :ID)
                                                      (TALA:TALA-INPUT-TOPIC-ID
                                                                                INPUT
                                                                                (GETF
                                                                                      ENTRY
                                                                                      :D2-ID))))
                                        (TALA:TALA-INPUT-TOPICS INPUT)))))

(HYPERDOC:DEFEXAMPLE READING-DEPENDENCY (TALA:TALA-DEPENDENCY-STATUS))

(HYPERDOC:DEFEXAMPLE READING-LAYOUT-RESULT
  (let ((dependency (tala:tala-dependency-status)))
    (if (eq :available (getf dependency :status))
        (tala:run-tala (reading-layout-input)) dependency)))

(HYPERDOC:DEFEXAMPLE READING-GEOMETRY
  (let ((result (reading-layout-result)))
    (if (typep result 'tala:tala-rendering)
        (tala:tala-rendering-evidence result) result)))

(HYPERDOC:DEFEXAMPLE READING-INVARIANT-REPORT
  (let ((result (repository-layout-comparison :seed 44)))
    (if (typep result 'tala-comparison) (comparison-invariants result) result)))

(HYPERDOC:DEFEXAMPLE READING-COMPARISON (REPOSITORY-LAYOUT-COMPARISON :SEED 44))

(HYPERDOC:DEFEXAMPLE READING-SOURCE-WORKSPACE
                     (LET
                          ((PROJECTION
                                       (TM::PROJECT-PAGE-ATTACHED-ASD
                                                                      (ASDF/SYSTEM:SYSTEM-SOURCE-FILE
                                                                                                      (ASDF/SYSTEM:FIND-SYSTEM
                                                                                                                               "dreyeck/topicmap/tala"))
                                                                      (MAPCAR
                                                                              (LAMBDA
                                                                                      (NAME)
                                                                                      (CONS
                                                                                            NAME
                                                                                            (ASDF/SYSTEM:FIND-SYSTEM
                                                                                                                     NAME)))
                                                                              (QUOTE
                                                                                     ("dreyeck/topicmap/tala"
                                                                                      "dreyeck/inspector/topicmap/tala"
                                                                                      "dreyeck/topicmap/tala/reading"
                                                                                      "dreyeck/topicmap/tala/reading/tests"))))))
                          (TM:MAKE-TOPICMAP-WORKSPACE PROJECTION
                                                      (TM:TOPICMAP-TOPIC-ID-OF
                                                                               (FIRST
                                                                                      (TM:TOPICMAP-PROJECTION-TOPICS-OF
                                                                                                                        PROJECTION))))))

(DREYECK/HYPERDOC:DEFHYPERDOC *TALA-READING* :TITLE
                              "Reading TALA as a Layout Layer" :ID
                              "dreyeck/topicmap/tala/reading" :ASDF-SYSTEM-NAME
                              "dreyeck/topicmap/tala/reading" :SUBDIRECTORY
                              "dreyeck/pages/topicmap-tala" :CODE-SUBDIRECTORY
                              "dreyeck/src" :MAIN-PAGE-ID
                              "Reading TALA as a Layout Layer")

;; The existing source renderer supplies the play thunk. This more-specific
;; presentation adapter leaves other examples and any authority-policy thunk
;; untouched, and binds only these layout examples to the existing TALA probe.
(defmethod html-inspector-views/standard:render-toplevel-cst :around
    ((head (eql 'hyperdoc:defexample)) (cst concrete-syntax-tree:cons-cst) source position)
  (let ((name (concrete-syntax-tree:raw (concrete-syntax-tree:second cst))))
    (if (not (member name '(reading-layout-result reading-geometry
                           reading-invariant-report reading-comparison authored-d2-example)))
        (call-next-method)
        (let ((dependency (tala:tala-dependency-status)))
          (if (not (eq :available (getf dependency :status)))
              (progn
                (views:object-ref dependency :display
                                  (format nil "TALA ~A (inspect capability)"
                                          (string-downcase (symbol-name (getf dependency :status)))))
                ;; DEFEXAMPLE's normal primary rendering is RENDER-CST. Keep
                ;; its persisted source and object references, without play.
                (html-inspector-views/standard::render-cst cst source position))
              (let* ((before (copy-list (views::accumulator-references views::*view-accumulator*)))
                     (end (call-next-method)))
                ;; Preserve the upstream/authority-policy action itself; wrap
                ;; only its evaluation so disappearing/failed tools remain
                ;; inspectable instead of escaping the CLOG event thread.
                (dolist (reference (set-difference
                                    (views::accumulator-references views::*view-accumulator*)
                                    before :test #'eq))
                  (when (typep (cdr reference) 'views:thunk)
                    (let ((original (cdr reference)))
                      (setf (cdr reference)
                            (views:thunk
                              (handler-case
                                  (let ((current (tala:tala-dependency-status)))
                                    (if (eq :available (getf current :status))
                                        (views:eval-thunk original) current))
                                (error (condition) condition)))))))
                end))))))
