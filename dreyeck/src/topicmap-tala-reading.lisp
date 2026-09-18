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
                                (MAPCAR
                                        (LAMBDA (ENTRY)
                                                (LIST (GETF ENTRY :ID)
                                                      (TALA:TOPIC-ID-FROM-TALA-ID
                                                                                  (GETF
                                                                                        ENTRY
                                                                                        :D2-ID))))
                                        (TALA:TALA-INPUT-TOPICS INPUT)))))

(HYPERDOC:DEFEXAMPLE READING-DEPENDENCY (TALA:TALA-DEPENDENCY-STATUS))

(HYPERDOC:DEFEXAMPLE READING-LAYOUT-RESULT
                     (TALA:RUN-TALA (READING-LAYOUT-INPUT)))

(HYPERDOC:DEFEXAMPLE READING-GEOMETRY
                     (TALA:TALA-RENDERING-EVIDENCE (READING-LAYOUT-RESULT)))

(HYPERDOC:DEFEXAMPLE READING-INVARIANT-REPORT
                     (COMPARISON-INVARIANTS
                                            (REPOSITORY-LAYOUT-COMPARISON :SEED
                                                                          44)))

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
