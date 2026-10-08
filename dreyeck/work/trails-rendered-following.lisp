;;;; Tracing One Recorded Trail

(IN-PACKAGE #:DREYECK/WORK/TRAILS-RENDERED-READING)

(HYPERDOC:SEE
              (HYPERDOC:PAGE "Trails Rendered public reproduction" :HYPERBOOK
                             "dreyeck/work/reading"))

(HYPERDOC:SEE
              (HYPERDOC:PAGE "Following One Recorded Trail" :HYPERBOOK
                             "dreyeck/work/reading"))

(DEFCLASS TRAIL-SOURCE-FRAGMENT NIL
          ((METADATA :INITARG :METADATA :READER FRAGMENT-METADATA)
           (TEXT :INITARG :TEXT :READER FRAGMENT-TEXT)
           (REVISION-FILE :INITARG :REVISION-FILE :READER
            FRAGMENT-REVISION-FILE)))

(DEFCLASS TRAIL-FOLLOWING NIL
          ((CONTEXT :INITARG :CONTEXT :READER FOLLOWING-CONTEXT)
           (PAGE :INITARG :PAGE :READER FOLLOWING-PAGE)
           (RAW :INITARG :RAW :READER FOLLOWING-RAW)
           (STATE :INITARG :STATE :READER FOLLOWING-STATE)
           (BATCH :INITARG :BATCH :READER FOLLOWING-BATCH)
           (BEAM :INITARG :BEAM :READER FOLLOWING-BEAM)
           (RENDER :INITARG :RENDER :READER FOLLOWING-RENDER)
           (RESULT :INITARG :RESULT :READER FOLLOWING-RESULT)
           (HOVER :INITARG :HOVER :READER FOLLOWING-HOVER)
           (MANIFEST :INITARG :MANIFEST :READER FOLLOWING-MANIFEST)
           (WITNESS :INITARG :WITNESS :READER FOLLOWING-WITNESS)
           (SOURCES :INITARG :SOURCES :READER FOLLOWING-SOURCES)
           (TRAILS :INITFORM NIL :ACCESSOR FOLLOWING-TRAILS)
           (BASE-PROJECTION :INITARG :BASE-PROJECTION :READER
                            FOLLOWING-BASE-PROJECTION)))

(DEFCLASS SELECTED-TRAIL NIL
          ((FOLLOWING :INITARG :FOLLOWING :READER TRAIL-FOLLOWING-OF)
           (PARAGRAPH :INITARG :PARAGRAPH :READER TRAIL-PARAGRAPH)
           (INDEX :INITARG :INDEX :READER TRAIL-INDEX)
           (RELATIONS :INITARG :RELATIONS :READER TRAIL-RELATIONS)
           (ASPECT :INITARG :ASPECT :READER TRAIL-ASPECT)
           (BEAM-ASPECT :INITARG :BEAM-ASPECT :READER TRAIL-BEAM-ASPECT)))

(DEFUN FOLLOWING-PATH (NAME)
  (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME "dreyeck/work/reading" NAME))

(DEFUN VERIFIED-TRAIL-ARTIFACT (RECORD &KEY JSON)
  (LET ((FILE (FOLLOWING-PATH (GETHASH "file" RECORD))))
    (UNLESS
        (EQUAL (GETHASH "sha256" RECORD)
               (IRONCLAD:BYTE-ARRAY-TO-HEX-STRING
                (IRONCLAD:DIGEST-FILE :SHA256 FILE)))
      (ERROR "Retained trail artifact digest mismatch: ~A" FILE))
    (IF JSON
        (READ-OBSERVATION (GETHASH "file" RECORD))
        (UIOP/STREAM:READ-FILE-STRING FILE))))

(DEFUN TRAIL-SOURCE-FRAGMENT (RECORD)
  (LET* ((REVISION
          (DREYECK/GIT:MAKE-GIT-REVISION-REFERENCE :AUTHORITY
                                                   (GETHASH "authority" RECORD)
                                                   :OID
                                                   (GETHASH "revision" RECORD)
                                                   :ROLE
                                                   "retained-trails-source"
                                                   :WEB-URL
                                                   (FORMAT NIL "~A/commit/~A"
                                                           (GETHASH "authority"
                                                                    RECORD)
                                                           (GETHASH "revision"
                                                                    RECORD))))
         (FILE
          (DREYECK/GIT:ENSURE-GIT-EVIDENCE-FILE REVISION
                                                (GETHASH "path" RECORD)))
         (FRAGMENT
          (MAKE-INSTANCE 'TRAIL-SOURCE-FRAGMENT :METADATA RECORD :TEXT
                         (VERIFIED-TRAIL-ARTIFACT RECORD) :REVISION-FILE FILE)))
    (DREYECK/GIT:ADD-GIT-EVIDENCE-LOCATION FILE FRAGMENT)
    FRAGMENT))

(DEFUN MAKE-TRAIL-FOLLOWING (CONTEXT)
       "Reuse historical page/state objects and recorded payloads; no execution, layout or navigation."
       (LET*
             ((MANIFEST
                        (READ-OBSERVATION
                                          "dreyeck/work/trails-rendered-following-provenance.json"))
              (EVIDENCE (CONTEXT-PAGE CONTEXT "ward-trails"))
              (RAW (GETHASH "raw" EVIDENCE))
              (SOURCE (GETHASH "source" MANIFEST))
              (FILES (GETHASH "files" MANIFEST))
              (BATCH (SOLO-BATCH))
              (BEAM (SOLO-BEAM))
              (ASPECTS (GETHASH "aspects" (AREF (GETHASH "sources" BATCH) 0)))
              (STATE (CONTEXT-CURRENT-STATE CONTEXT))
              (FOLLOWING
                         (MAKE-INSTANCE (QUOTE TRAIL-FOLLOWING) :CONTEXT
                                        CONTEXT :PAGE
                                        (CONTEXT-PAGE-OBJECT CONTEXT EVIDENCE)
                                        :RAW RAW :STATE STATE :BATCH BATCH
                                        :BEAM BEAM :RESULT (PUBLIC-RESULT)
                                        :HOVER (HOVERBOLD-OBSERVATION)
                                        :MANIFEST MANIFEST :RENDER
                                        (GETHASH "render"
                                                 (VERIFIED-TRAIL-ARTIFACT
                                                                          (GETHASH
                                                                                   "render"
                                                                                   FILES)
                                                                          :JSON
                                                                          T))
                                        :WITNESS
                                        (VERIFIED-TRAIL-ARTIFACT
                                                                 (GETHASH
                                                                          "witness"
                                                                          FILES)
                                                                 :JSON T)
                                        :SOURCES
                                        (MAPCAR
                                                (LAMBDA (KEY)
                                                        (TRAIL-SOURCE-FRAGMENT
                                                                               (GETHASH
                                                                                        KEY
                                                                                        FILES)))
                                                (QUOTE
                                                       ("mech-source"
                                                        "solo-source")))
                                        :BASE-PROJECTION
                                        (CONTEXT-PROJECTION CONTEXT))))
             (ASSERT
                     (DREYECK/WORK/READING::%JSON-EQUAL RAW
                                                        (VERIFIED-TRAIL-ARTIFACT
                                                                                 SOURCE
                                                                                 :JSON
                                                                                 T)))
             (SETF (FOLLOWING-TRAILS FOLLOWING)
                   (LOOP FOR ID ACROSS (GETHASH "paragraphs" SOURCE) FOR INDEX
                         FROM 0 FOR PARAGRAPH =
                         (FIND ID (GETHASH "story" RAW) :KEY
                               (LAMBDA (ITEM) (GETHASH "id" ITEM)) :TEST
                               (FUNCTION EQUAL))
                         DO (ASSERT PARAGRAPH) COLLECT
                         (MAKE-INSTANCE (QUOTE SELECTED-TRAIL) :FOLLOWING
                                        FOLLOWING :PARAGRAPH PARAGRAPH :INDEX
                                        INDEX :RELATIONS
                                        (COERCE
                                                (REMOVE-IF-NOT
                                                               (LAMBDA
                                                                       (RELATION)
                                                                       (AND
                                                                            (EQUAL
                                                                                   ID
                                                                                   (GETHASH
                                                                                            "item"
                                                                                            RELATION))
                                                                            (UIOP/UTILITY:STRING-PREFIX-P
                                                                                                          "trail:"
                                                                                                          (GETHASH
                                                                                                                   "id"
                                                                                                                   RELATION))))
                                                               (GETF STATE
                                                                     :RELATIONS))
                                                (QUOTE VECTOR))
                                        :ASPECT (AREF ASPECTS INDEX)
                                        :BEAM-ASPECT (AREF BEAM INDEX))))
             FOLLOWING))

(HYPERDOC:DEFEXAMPLE TRAIL-FOLLOWING
  "Follow the two selected source paragraphs through existing recorded objects.
The original page/site and historical native page are distinguished; graph node
IDs are scoped to their aspect. No JavaScript execution or layout occurs here."
  (MAKE-TRAIL-FOLLOWING (FEDERATED-CONTEXT)))

(DEFUN TRAIL-CORRESPONDENCE (TRAIL)
       "Falsifiable value/order correspondence, never identity inferred from titles."
       (LET*
             ((NAMES
                     (CONTEXT-WIKI-TARGETS
                                           (GETHASH "text"
                                                    (TRAIL-PARAGRAPH TRAIL))))
              (GRAPH (GETHASH "graph" (TRAIL-ASPECT TRAIL)))
              (NODES (GETHASH "nodes" GRAPH))
              (RELS (GETHASH "rels" GRAPH))
              (VALUES-MATCH
                            (AND
                                 (EQUAL NAMES
                                        (MAP (QUOTE LIST)
                                             (LAMBDA (NODE)
                                                     (SUBSTITUTE (CHAR " " 0)
                                                                 #\Newline
                                                                 (GETHASH
                                                                          "name"
                                                                          (GETHASH
                                                                                   "props"
                                                                                   NODE))))
                                             NODES))
                                 (= (1- (LENGTH NAMES)) (LENGTH RELS)
                                    (LENGTH (TRAIL-RELATIONS TRAIL)))
                                 (LOOP FOR REL ACROSS RELS FOR INDEX FROM 0
                                       ALWAYS
                                       (AND
                                            (EQUAL "Trail"
                                                   (GETHASH "type" REL))
                                            (= INDEX (GETHASH "from" REL))
                                            (= (1+ INDEX) (GETHASH "to" REL))
                                            (LET
                                                 ((SOURCE-REL
                                                              (AREF
                                                                    (TRAIL-RELATIONS
                                                                                     TRAIL)
                                                                    INDEX)))
                                                 (AND
                                                      (EQUAL
                                                             (GETHASH "kind"
                                                                      SOURCE-REL)
                                                             (GETHASH "type"
                                                                      REL))
                                                      (EQUAL
                                                             (GETHASH "from"
                                                                      SOURCE-REL)
                                                             (CONCATENATE
                                                                          (QUOTE
                                                                                 STRING)
                                                                          "concept:"
                                                                          (NTH
                                                                               INDEX
                                                                               NAMES)))
                                                      (EQUAL
                                                             (GETHASH "to"
                                                                      SOURCE-REL)
                                                             (CONCATENATE
                                                                          (QUOTE
                                                                                 STRING)
                                                                          "concept:"
                                                                          (NTH
                                                                               (1+
                                                                                   INDEX)
                                                                               NAMES))))))))))
             (LIST :STATUS :DERIVED :SOURCE-PARAGRAPH (TRAIL-PARAGRAPH TRAIL)
                   :TARGETS NAMES :SOURCE-RELATIONS (TRAIL-RELATIONS TRAIL)
                   :GRAPH GRAPH :MATCHES VALUES-MATCH :IDENTITY-PRESERVED NIL
                   :BASIS
                   "Paragraph item ID and position; source order, names and directed endpoints agree. These origin IDs are absent from captured graph records.")))

(DEFUN FOLLOWING-BOUNDARY (FOLLOWING)
       (LIST :STATUS :OBSERVED :LIMITS
             (GETHASH "limits" (FOLLOWING-MANIFEST FOLLOWING))
             :RUNTIME-ALIAS-CHECKS
             (GETF (GETHASH :BEAM-CAPTURE (SOLO-BATCH-PROVENANCE))
                   :RUNTIME-REFERENCE-CHECKS)
             :HYPERDOC-ALIASES
             "Independent JSON snapshots: batch and beam aspect/node objects are not EQ."
             :SNAPSHOT-TO-SVG
             "Derived correspondence to recorded title/label fields. Complete original SVG outerHTML and per-source-item identifiers were not retained."
             :HYPOTHESIZED NIL :UNVERIFIED (PUBLIC-SOURCE-BOUNDARY)
             :CAPTURE-SEPARATION
             "The retained batch was captured at 08:41; the beam and its paired input at 09:07 on 2026-10-04. Cross-capture value correspondence is derived, not an observed alias between these HyperDoc records."))

(DEFUN EXECUTE-TRAIL-WITNESS NIL
       "Explicit Inspector operation: execute retained source on disposable inputs in a fresh Node VM.
The historical imported graph.js dependency and Graphviz rendering are not replayed."
       (LET
            ((ROOT
                   (ASDF/SYSTEM:SYSTEM-SOURCE-DIRECTORY
                                                        "dreyeck/work/reading")))
            (MULTIPLE-VALUE-BIND (OUTPUT STDERR EXIT-CODE)
                                 (UIOP/RUN-PROGRAM:RUN-PROGRAM
                                                               (LIST "env" "-u"
                                                                     "DYLD_LIBRARY_PATH"
                                                                     "-u"
                                                                     "DYLD_FALLBACK_LIBRARY_PATH"
                                                                     "-u"
                                                                     "LD_LIBRARY_PATH"
                                                                     "node"
                                                                     (NAMESTRING
                                                                                 (FOLLOWING-PATH
                                                                                                 "dreyeck/work/trails-rendered-witness.mjs"))
                                                                     (NAMESTRING
                                                                                 ROOT))
                                                               :OUTPUT :STRING
                                                               :ERROR-OUTPUT
                                                               :STRING
                                                               :IGNORE-ERROR-STATUS
                                                               T)
                                 (UNLESS (ZEROP EXIT-CODE)
                                         (ERROR
                                                "Controlled trail witness failed (exit ~D): ~A"
                                                EXIT-CODE STDERR))
                                 (WITH-INPUT-FROM-STRING (INPUT OUTPUT)
                                                         (SHASHT:READ-JSON*
                                                                            :STREAM
                                                                            INPUT
                                                                            :SINGLE-VALUE
                                                                            T
                                                                            :OBJECT-FORMAT
                                                                            :HASH-TABLE
                                                                            :HASH-TABLE-TEST
                                                                            (QUOTE
                                                                                   EQUAL)
                                                                            :ARRAY-FORMAT
                                                                            :VECTOR
                                                                            :TRUE-VALUE
                                                                            :TRUE
                                                                            :FALSE-VALUE
                                                                            :FALSE
                                                                            :NULL-VALUE
                                                                            :NULL)))))

(HYPERDOC:DEFEXAMPLE TRAIL-COMPOSITION-WITNESS
  "Explicitly rerun the retained functions with controlled Graph substitution and name/type controls.
This is fresh execution, separate from the historical Wiki/Solo captures."
  (EXECUTE-TRAIL-WITNESS))

(DEFUN TRAIL-LEARNING-PROJECTION (FOLLOWING)
       "Extend the same context graph with a provenance path; all object slots hold represented values."
       (LET*
             ((CONTEXT (FOLLOWING-CONTEXT FOLLOWING))
              (BASE (FOLLOWING-BASE-PROJECTION FOLLOWING))
              (TOPICS
                      (COPY-LIST
                                 (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-TOPICS-OF
                                                                                 BASE)))
              (ASSOCIATIONS
                            (MAPCAR
                                    (LAMBDA (A)
                                            (DREYECK/TOPICMAP:MAKE-TOPICMAP-ASSOCIATION
                                                                                        :ID
                                                                                        (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-ID-OF
                                                                                                                                     A)
                                                                                        :TYPE
                                                                                        (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF
                                                                                                                                       A)
                                                                                        :FROM
                                                                                        (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF
                                                                                                                                       A)
                                                                                        :TO
                                                                                        (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TO-OF
                                                                                                                                     A)
                                                                                        :PROPERTIES
                                                                                        (LIST*
                                                                                               :WARRANT
                                                                                               :DERIVED
                                                                                               (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-PROPERTIES-OF
                                                                                                                                                    A))))
                                    (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
                                                                                          BASE)))
              (WARD
                    (CONTEXT-PAGE-ID
                                     (PAGE-EVIDENCE
                                                    (FOLLOWING-PAGE
                                                                    FOLLOWING)))))
             (LABELS
                     ((TOPIC (ID LABEL OBJECT) (ASSERT OBJECT)
                             (PUSH
                                   (DREYECK/TOPICMAP:MAKE-TOPICMAP-TOPIC :ID ID
                                                                         :TYPE
                                                                         :TRAIL-EVIDENCE
                                                                         :LABEL
                                                                         LABEL
                                                                         :OBJECT
                                                                         OBJECT)
                                   TOPICS))
                      (EDGE (FROM TO TYPE WARRANT BASIS &OPTIONAL IDENTITY)
                            (PUSH
                                  (DREYECK/TOPICMAP:MAKE-TOPICMAP-ASSOCIATION
                                                                              :ID
                                                                              (FORMAT
                                                                                      NIL
                                                                                      "learning:~A:~A:~A"
                                                                                      FROM
                                                                                      TYPE
                                                                                      TO)
                                                                              :TYPE
                                                                              TYPE
                                                                              :FROM
                                                                              FROM
                                                                              :TO
                                                                              TO
                                                                              :PROPERTIES
                                                                              (LIST
                                                                                    :FOLLOWING
                                                                                    FOLLOWING
                                                                                    :WARRANT
                                                                                    WARRANT
                                                                                    :BASIS
                                                                                    BASIS
                                                                                    :IDENTITY
                                                                                    IDENTITY))
                                  ASSOCIATIONS)))
                     (TOPIC "learning:source" "Retained Ward source JSON"
                            (FOLLOWING-RAW FOLLOWING))
                     (TOPIC "learning:batch" "Recorded SOLO batch"
                            (FOLLOWING-BATCH FOLLOWING))
                     (TOPIC "learning:beam" "Recorded Solo beam"
                            (FOLLOWING-BEAM FOLLOWING))
                     (TOPIC "learning:witness" "Controlled composite witness"
                            (FOLLOWING-WITNESS FOLLOWING))
                     (TOPIC "learning:composite"
                            "Recorded composite graph fields"
                            (GETHASH "graph" (FOLLOWING-RENDER FOLLOWING)))
                     (PROGN
                            (TOPIC "learning:result"
                                   "Recorded SVG titles and labels"
                                   (FOLLOWING-RENDER FOLLOWING))
                            (TOPIC "learning:svg-node:2"
                                   "Recorded SVG node table / title 2"
                                   (FIND "2"
                                         (GETHASH "svgNodes"
                                                  (FOLLOWING-RENDER FOLLOWING))
                                         :KEY
                                         (LAMBDA (NODE) (GETHASH "title" NODE))
                                         :TEST (FUNCTION EQUAL)))
                            (EDGE "learning:result" "learning:svg-node:2"
                                  "contains recorded SVG node entry" :OBSERVED
                                  (FOLLOWING-RENDER FOLLOWING) :EQ))
                     (TOPIC "learning:boundary" "Exact unverified boundaries"
                            (FOLLOWING-BOUNDARY FOLLOWING))
                     (EDGE "learning:source" WARD "historical representation"
                           :DERIVED (PAGE-EVENT (FOLLOWING-PAGE FOLLOWING))
                           :RECONSTRUCTED)
                     (EDGE "learning:batch" "learning:beam"
                           "label/flatten value correspondence" :DERIVED
                           (SOLO-BATCH-PROVENANCE) :DIFFERENT-CAPTURES)
                     (EDGE "learning:beam" "learning:witness"
                           "replay on disposable copies" :DERIVED
                           (FOLLOWING-WITNESS FOLLOWING) :RECONSTRUCTED)
                     (EDGE "learning:beam" "learning:composite"
                           "cross-capture composition correspondence" :DERIVED
                           (LIST :WITNESS (FOLLOWING-WITNESS FOLLOWING)
                                 :CAPTURE (SOLO-BATCH-PROVENANCE))
                           :DIFFERENT-CAPTURES)
                     (EDGE "learning:composite" "learning:result"
                           "recorded graph to SVG fields" :OBSERVED
                           (FOLLOWING-RENDER FOLLOWING) :RECORDED-FIELDS-ONLY)
                     (EDGE "learning:result" "learning:boundary"
                           "retention boundary" :OBSERVED
                           (FOLLOWING-MANIFEST FOLLOWING))
                     (LOOP FOR SOURCE IN (FOLLOWING-SOURCES FOLLOWING) FOR KEY
                           IN (QUOTE ("mech" "solo")) DO
                           (TOPIC (FORMAT NIL "learning:code:~A" KEY)
                                  (FORMAT NIL "Retained ~A source" KEY) SOURCE)
                           (EDGE (FORMAT NIL "learning:code:~A" KEY)
                                 (IF (EQUAL KEY "mech") "learning:batch"
                                     "learning:composite")
                                 "source warrant" :OBSERVED SOURCE))
                     (LOOP FOR TRAIL IN (FOLLOWING-TRAILS FOLLOWING) FOR INDEX
                           = (TRAIL-INDEX TRAIL) FOR PREFIX =
                           (FORMAT NIL "learning:trail:~D" INDEX) FOR ITEM-ID =
                           (GETHASH "id" (TRAIL-PARAGRAPH TRAIL)) FOR
                           PARAGRAPH-ID =
                           (CONCATENATE (QUOTE STRING) PREFIX ":paragraph") FOR
                           PARSED-ID =
                           (CONCATENATE (QUOTE STRING) PREFIX ":parsed") FOR
                           ASPECT-ID =
                           (CONCATENATE (QUOTE STRING) PREFIX ":aspect") FOR
                           GRAPH-ID =
                           (CONCATENATE (QUOTE STRING) PREFIX ":graph") FOR
                           BEAM-ID =
                           (CONCATENATE (QUOTE STRING) PREFIX ":beam-aspect")
                           FOR GRAPH = (GETHASH "graph" (TRAIL-ASPECT TRAIL))
                           DO
                           (TOPIC PARAGRAPH-ID
                                  (FORMAT NIL "Source paragraph ~A" ITEM-ID)
                                  (TRAIL-PARAGRAPH TRAIL))
                           (TOPIC PARSED-ID
                                  (FORMAT NIL "Parsed trail ~D" (1+ INDEX))
                                  TRAIL)
                           (TOPIC ASPECT-ID
                                  (GETHASH "name" (TRAIL-ASPECT TRAIL))
                                  (TRAIL-ASPECT TRAIL))
                           (TOPIC GRAPH-ID
                                  (FORMAT NIL "Aspect-scoped graph ~D" INDEX)
                                  GRAPH)
                           (TOPIC BEAM-ID (FORMAT NIL "Beam aspect ~D" INDEX)
                                  (TRAIL-BEAM-ASPECT TRAIL))
                           (EDGE "learning:source" PARAGRAPH-ID
                                 "contains source item" :OBSERVED
                                 (TRAIL-PARAGRAPH TRAIL) :EQ)
                           (EDGE PARAGRAPH-ID PARSED-ID "parse selected links"
                                 :DERIVED (TRAIL-CORRESPONDENCE TRAIL)
                                 :REPRESENTATION)
                           (EDGE PARSED-ID ASPECT-ID
                                 "ordered value correspondence" :DERIVED
                                 (TRAIL-CORRESPONDENCE TRAIL) :NOT-EQ)
                           (EDGE ASPECT-ID GRAPH-ID "contains graph" :OBSERVED
                                 GRAPH :EQ)
                           (EDGE "learning:batch" ASPECT-ID "contains aspect"
                                 :OBSERVED (TRAIL-ASPECT TRAIL) :EQ)
                           (EDGE "learning:beam" BEAM-ID "contains aspect"
                                 :OBSERVED (TRAIL-BEAM-ASPECT TRAIL) :EQ)
                           (EDGE ASPECT-ID BEAM-ID
                                 "snapshot value correspondence" :DERIVED
                                 (SOLO-BATCH-PROVENANCE) :NOT-EQ)
                           (LOOP FOR RELATION ACROSS (TRAIL-RELATIONS TRAIL)
                                 FOR RI FROM 0 FOR ID =
                                 (FORMAT NIL "~A:source-relation:~D" PREFIX RI)
                                 DO
                                 (TOPIC ID
                                        (FORMAT NIL "Derived source hop ~D" RI)
                                        RELATION)
                                 (PROGN
                                        (EDGE PARSED-ID ID
                                              "derives directed relation"
                                              :DERIVED (TRAIL-PARAGRAPH TRAIL))
                                        (EDGE ID GRAPH-ID
                                              "corresponds to captured hop"
                                              :DERIVED
                                              (LIST :SOURCE-RELATION RELATION
                                                    :CAPTURED-RELATION
                                                    (AREF
                                                          (GETHASH "rels"
                                                                   GRAPH)
                                                          RI)
                                                    :COMPARISON
                                                    (TRAIL-CORRESPONDENCE
                                                                          TRAIL))
                                              :NOT-EQ)))
                           (LOOP FOR NODE ACROSS (GETHASH "nodes" GRAPH) FOR NI
                                 FROM 0 DO
                                 (TOPIC (FORMAT NIL "~A:node:~D" PREFIX NI)
                                        (FORMAT NIL "aspect ~D / node ~D: ~A"
                                                INDEX NI
                                                (GETHASH "name"
                                                         (GETHASH "props"
                                                                  NODE)))
                                        NODE)
                                 (EDGE GRAPH-ID
                                       (FORMAT NIL "~A:node:~D" PREFIX NI)
                                       "contains node" :OBSERVED NODE :EQ))
                           (LOOP FOR REL ACROSS (GETHASH "rels" GRAPH) FOR RI
                                 FROM 0 DO
                                 (EDGE
                                       (FORMAT NIL "~A:node:~D" PREFIX
                                               (GETHASH "from" REL))
                                       (FORMAT NIL "~A:node:~D" PREFIX
                                               (GETHASH "to" REL))
                                       "Trail" :OBSERVED REL :ASPECT-SCOPED))
                           (EDGE (FORMAT NIL "~A:node:2" PREFIX)
                                 "learning:svg-node:2"
                                 "type/name correspondence to SVG title 2"
                                 :DERIVED (FOLLOWING-WITNESS FOLLOWING)
                                 :NOT-EQ))
                     (DREYECK/TOPICMAP:MAKE-TOPICMAP-PROJECTION :SOURCE
                                                                FOLLOWING
                                                                :TOPICS
                                                                (NREVERSE
                                                                          TOPICS)
                                                                :ASSOCIATIONS
                                                                (NREVERSE
                                                                          ASSOCIATIONS)))))

(DEFMETHOD DREYECK/TOPICMAP:TOPICMAP-PROJECTION-OF
           ((FOLLOWING TRAIL-FOLLOWING))
  (TRAIL-LEARNING-PROJECTION FOLLOWING))

(DEFUN TRAIL-WORKSPACE (FOLLOWING)
  "Explicitly reproject the existing context editing session; retain Point and domain values."
  (LET ((WORKSPACE (CONTEXT-CURRENT-WORKSPACE (FOLLOWING-CONTEXT FOLLOWING))))
    (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-REPROJECT WORKSPACE
                                                   (TRAIL-LEARNING-PROJECTION
                                                    FOLLOWING))
    WORKSPACE))

(DEFUN TRAIL-READING-LINK ()
  (HTML-INSPECTOR-VIEWS:OBJECT-REF
   (HYPERBOOK:FIND-PAGE "dreyeck/work/reading" "Following One Recorded Trail"
                        :SIGNAL-ERROR? T)
   :DISPLAY "Return to Following One Recorded Trail"))

(HTML-INSPECTOR-VIEWS:DEFVIEW TRAIL-FOLLOWING-OVERVIEW
                              (FOLLOWING TRAIL-FOLLOWING)
                              (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE
                                                              "Follow the trail"
                                                              :PRIORITY 0
                                                              (HTML-INSPECTOR-VIEWS:HTML
                                                                (:P
                                                                 (TRAIL-READING-LINK))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (FOLLOWING-PAGE
                                                                   FOLLOWING)
                                                                  :DISPLAY
                                                                  "Native historical Ward page"))
                                                                (:P
                                                                 "Original live Wiki navigation: "
                                                                 (RENDER-CONTEXT-PAGE-LINK
                                                                  (PAGE-EVIDENCE
                                                                   (FOLLOWING-PAGE
                                                                    FOLLOWING))))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (FOLLOWING-RAW
                                                                   FOLLOWING)
                                                                  :DISPLAY
                                                                  "Retained original JSON"))
                                                                (:UL
                                                                 (DOLIST
                                                                     (TRAIL
                                                                      (FOLLOWING-TRAILS
                                                                       FOLLOWING))
                                                                   (HTML-INSPECTOR-VIEWS:HTML
                                                                     (:LI
                                                                      (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                       TRAIL
                                                                       :DISPLAY
                                                                       (GETHASH
                                                                        "text"
                                                                        (TRAIL-PARAGRAPH
                                                                         TRAIL)))))))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (FOLLOWING-BATCH
                                                                   FOLLOWING)
                                                                  :DISPLAY
                                                                  "Recorded batch")
                                                                 " · "
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (FOLLOWING-BEAM
                                                                   FOLLOWING)
                                                                  :DISPLAY
                                                                  "Recorded beam")
                                                                 " · "
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (FOLLOWING-RENDER
                                                                   FOLLOWING)
                                                                  :DISPLAY
                                                                  "Recorded rendered fields"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (FOLLOWING-WITNESS
                                                                   FOLLOWING)
                                                                  :DISPLAY
                                                                  "Saved controlled witness")
                                                                 " · "
                                                                 (:SPAN :CLASS
                                                                  "inspector-inspect"
                                                                  :ID
                                                                  (HTML-INSPECTOR-VIEWS:EVAL-ID
                                                                   (HTML-INSPECTOR-VIEWS:THUNK
                                                                     (EXECUTE-TRAIL-WITNESS)))
                                                                  "Explicitly rerun witness"))
                                                                (:P
                                                                 (:SPAN :CLASS
                                                                  "inspector-inspect"
                                                                  :ID
                                                                  (HTML-INSPECTOR-VIEWS:EVAL-ID
                                                                   (HTML-INSPECTOR-VIEWS:THUNK
                                                                     (TRAIL-WORKSPACE
                                                                      FOLLOWING)))
                                                                  "Open learning path in the existing Workspace"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (FOLLOWING-BOUNDARY
                                                                   FOLLOWING)
                                                                  :DISPLAY
                                                                  "Exact unverified boundaries")))))

(HTML-INSPECTOR-VIEWS:DEFVIEW SELECTED-TRAIL-EVIDENCE (TRAIL SELECTED-TRAIL)
                              (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE
                                                              "Trail provenance"
                                                              :PRIORITY 0
                                                              (HTML-INSPECTOR-VIEWS:HTML
                                                                (:P
                                                                 (TRAIL-READING-LINK))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (TRAIL-FOLLOWING-OF
                                                                   TRAIL)
                                                                  :DISPLAY
                                                                  "Complete learning path"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (TRAIL-PARAGRAPH
                                                                   TRAIL)
                                                                  :DISPLAY
                                                                  "Original paragraph, item ID and text"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (TRAIL-CORRESPONDENCE
                                                                   TRAIL)
                                                                  :DISPLAY
                                                                  "Falsifiable parsed correspondence"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (TRAIL-RELATIONS
                                                                   TRAIL)
                                                                  :DISPLAY
                                                                  "Existing derived directed relations"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (TRAIL-ASPECT
                                                                   TRAIL)
                                                                  :DISPLAY
                                                                  "Actual recorded batch aspect")
                                                                 " · "
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (TRAIL-BEAM-ASPECT
                                                                   TRAIL)
                                                                  :DISPLAY
                                                                  "Independent recorded beam aspect")))))

(HTML-INSPECTOR-VIEWS:DEFVIEW TRAIL-FRAGMENT-EVIDENCE
                              (FRAGMENT TRAIL-SOURCE-FRAGMENT)
                              (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE
                                                              "Retained source"
                                                              :PRIORITY 0
                                                              (HTML-INSPECTOR-VIEWS:HTML
                                                                (:P
                                                                 (TRAIL-READING-LINK))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (FRAGMENT-REVISION-FILE
                                                                   FRAGMENT)
                                                                  :DISPLAY
                                                                  "Revision, file and retained location"
                                                                  :SELECT
                                                                  "Evidence locations"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (FRAGMENT-METADATA
                                                                   FRAGMENT)
                                                                  :DISPLAY
                                                                  "Recorded ranges and digests"))
                                                                (:PRE
                                                                 (CL-WHO:ESC
                                                                  (FRAGMENT-TEXT
                                                                   FRAGMENT))))))

(HTML-INSPECTOR-VIEWS:DEFVIEW TRAIL-LEARNING-WARRANT
                              (ASSOCIATION
                               DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION)
                              (LET* ((PROPERTIES
                                      (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-PROPERTIES-OF
                                       ASSOCIATION))
                                     (FOLLOWING (GETF PROPERTIES :FOLLOWING)))
                                (WHEN FOLLOWING
                                  (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE
                                                                  "Trail warrant"
                                                                  :PRIORITY 0
                                                                  (HTML-INSPECTOR-VIEWS:HTML
                                                                    (:P
                                                                     (TRAIL-READING-LINK))
                                                                    (:P
                                                                     (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                      FOLLOWING
                                                                      :DISPLAY
                                                                      "Learning path"))
                                                                    (:P
                                                                     "Warrant: "
                                                                     (CL-WHO:ESC
                                                                      (FORMAT
                                                                       NIL "~A"
                                                                       (GETF
                                                                        PROPERTIES
                                                                        :WARRANT))))
                                                                    (:P
                                                                     "Identity claim: "
                                                                     (CL-WHO:ESC
                                                                      (FORMAT
                                                                       NIL "~A"
                                                                       (GETF
                                                                        PROPERTIES
                                                                        :IDENTITY))))
                                                                    (:P
                                                                     (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                      (GETF
                                                                       PROPERTIES
                                                                       :BASIS)
                                                                      :DISPLAY
                                                                      "Actual source/capture or derivation")))))))

(HTML-INSPECTOR-VIEWS:DEFVIEW TRAIL-RECORDED-RESULT (FOLLOWING TRAIL-FOLLOWING)
                              (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE
                                                              "Recorded result"
                                                              :PRIORITY 1
                                                              (LET* ((RECORD
                                                                      (GETHASH
                                                                       "image"
                                                                       (GETHASH
                                                                        "files"
                                                                        (FOLLOWING-MANIFEST
                                                                         FOLLOWING))))
                                                                     (FILE
                                                                      (FOLLOWING-PATH
                                                                       (GETHASH
                                                                        "file"
                                                                        RECORD))))
                                                                (ASSERT
                                                                 (EQUAL
                                                                  (GETHASH
                                                                   "sha256"
                                                                   RECORD)
                                                                  (IRONCLAD:BYTE-ARRAY-TO-HEX-STRING
                                                                   (IRONCLAD:DIGEST-FILE
                                                                    :SHA256
                                                                    FILE))))
                                                                (HTML-INSPECTOR-VIEWS:HTML
                                                                  (:P
                                                                   (TRAIL-READING-LINK))
                                                                  (:P
                                                                   "Historical screenshot from the recorded run; complete original SVG outerHTML was not retained.")
                                                                  (:IMG :STYLE
                                                                   "max-width:100%;height:auto;"
                                                                   :ALT
                                                                   "Recorded Solo result: two trails converge in Reflective Practice"
                                                                   :SRC
                                                                   (FORMAT NIL
                                                                           "data:image/png;base64,~A"
                                                                           (CL-BASE64:USB8-ARRAY-TO-BASE64-STRING
                                                                            (ALEXANDRIA:READ-FILE-INTO-BYTE-VECTOR
                                                                             FILE))))
                                                                  (:P
                                                                   (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                    (FOLLOWING-RENDER
                                                                     FOLLOWING)
                                                                    :DISPLAY
                                                                    "Actual recorded DOT and SVG node/edge tables"))
                                                                  (:P
                                                                   (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                    (GETHASH
                                                                     "before-state"
                                                                     (FOLLOWING-HOVER
                                                                      FOLLOWING))
                                                                    :DISPLAY
                                                                    "Existing recorded edge DOM and John Dewey node fragments"))))))
