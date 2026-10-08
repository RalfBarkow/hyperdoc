;;;; Original Public CODE Execution Acceptance

(IN-PACKAGE #:DREYECK/WORK/TRAILS-RENDERED-READING/TESTS)

(DEFUN CHECK-ORIGINAL-CODE-BROWSER ()
  (LET* ((CHECK (READING:ORIGINAL-CODE-BROWSER-CHECK))
         (MANIFEST (READING::BROWSER-CHECK-MANIFEST CHECK))
         (CAPTURE (READING::BROWSER-CHECK-CAPTURE CHECK))
         (FAILED (READING::BROWSER-CHECK-FAILING CHECK))
         (CONTROL (READING::BROWSER-CHECK-CONTROL CHECK))
         (SOURCES (READING::BROWSER-CHECK-SOURCES CHECK))
         (PAGE (READING::BROWSER-CHECK-PAGE CHECK))
         (FAILED-PAGE (READING::BROWSER-CHECK-FAILING-PAGE CHECK))
         (ITEMS (READING::BROWSER-CHECK-CODE-ITEMS CHECK))
         (FAILED-ITEMS (READING::BROWSER-CHECK-FAILING-CODE-ITEMS CHECK))
         (PROBE (READING::BROWSER-CHECK-PROBE CHECK))
         (ERROR-TEXT "CODE doesn't name a block we know."))
    (ASSERT (EQUAL "success" (GETHASH "outcome" CAPTURE)))
    (ASSERT (EQ :NULL (GETHASH "diagnostic" CAPTURE)))
    (ASSERT (SEARCH "CODE trails ⇒ 2 aspects" (GETHASH "after" CAPTURE)))
    (ASSERT (NOT (SEARCH "✖︎" (GETHASH "after" CAPTURE))))
    (ASSERT (ZEROP (LENGTH (GETHASH "pageErrors" CAPTURE))))
    (ASSERT (ZEROP (LENGTH (GETHASH "failedRequests" CAPTURE))))
    (ASSERT
     (NOTANY (LAMBDA (EVENT) (EQUAL "error" (GETHASH "type" EVENT)))
             (GETHASH "console" CAPTURE)))
    (ASSERT
     (EVERY (LAMBDA (RESPONSE) (< (GETHASH "status" RESPONSE) 400))
            (GETHASH "responses" CAPTURE)))
    (DOLIST (RUN (LIST FAILED CONTROL))
      (ASSERT (EQUAL "trouble" (GETHASH "outcome" RUN)))
      (ASSERT (EQUAL ERROR-TEXT (GETHASH "diagnosticMessage" RUN)))
      (ASSERT (SEARCH "CODE trails✖︎" (GETHASH "after" RUN)))
      (ASSERT (SEARCH ERROR-TEXT (GETHASH "diagnostic" RUN)))
      (ASSERT (ZEROP (LENGTH (GETHASH "pageErrors" RUN))))
      (ASSERT
       (NOTANY
        (LAMBDA (R)
          (SEARCH "wardcunningham.github.io/graph/" (GETHASH "url" R)))
        (GETHASH "requests" RUN)))
      (ASSERT (EQ :FALSE (GETHASH "isOwner" (GETHASH "before" RUN))))
      (LET ((TRAIL
             (FIND "trails-rendered" (GETHASH "lineup" (GETHASH "before" RUN))
                   :TEST #'EQUAL :KEY (LAMBDA (P) (GETHASH "slug" P)))))
        (ASSERT TRAIL)
        (ASSERT (EQ :FALSE (GETHASH "remote" TRAIL))))
      (LET ((BUILD (GETHASH "mechBuild" (GETHASH "before" RUN))))
        (ASSERT (EQUAL "0.1.32-dev.1" (GETHASH "MECH_VERSION" BUILD)))
        (ASSERT
         (EQUAL "abd88d2da6c89029515f2a456356832dffe038ab"
                (GETHASH "MECH_GIT_COMMIT" BUILD)))))
    (ASSERT (= 2 (LENGTH (GETHASH "lineup" (GETHASH "before" FAILED)))))
    (ASSERT (= 1 (LENGTH (GETHASH "lineup" (GETHASH "before" CONTROL)))))
    (ASSERT (PLUSP (LENGTH (GETHASH "failedRequests" FAILED))))
    (ASSERT
     (EVERY (LAMBDA (REQUEST) (SEARCH "favicon.png" (GETHASH "url" REQUEST)))
            (GETHASH "failedRequests" FAILED)))
    (ASSERT (EQUAL "explained" (GETHASH "reported-failure-status" MANIFEST)))
    (ASSERT (EQUAL ERROR-TEXT (GETHASH "reported-error" MANIFEST)))
    (ASSERT (= 3 (LENGTH ITEMS) (LENGTH FAILED-ITEMS)))
    (LOOP FOR A ACROSS ITEMS
          FOR B ACROSS FAILED-ITEMS
          DO (ASSERT
              (EQ A
                  (FIND (GETHASH "id" A) (GETHASH "story" PAGE) :TEST #'EQUAL
                        :KEY (LAMBDA (I) (GETHASH "id" I))))) (ASSERT
                                                               (EQ B
                                                                   (FIND
                                                                    (GETHASH
                                                                     "id" B)
                                                                    (GETHASH
                                                                     "story"
                                                                     FAILED-PAGE)
                                                                    :TEST
                                                                    #'EQUAL
                                                                    :KEY
                                                                    (LAMBDA (I)
                                                                      (GETHASH
                                                                       "id"
                                                                       I))))) (ASSERT
                                                                               (NOT
                                                                                (EQ
                                                                                 A
                                                                                 B))) (ASSERT
                                                                                       (EQUAL
                                                                                        (GETHASH
                                                                                         "id"
                                                                                         A)
                                                                                        (GETHASH
                                                                                         "id"
                                                                                         B))) (ASSERT
                                                                                               (EQUAL
                                                                                                (GETHASH
                                                                                                 "text"
                                                                                                 A)
                                                                                                (GETHASH
                                                                                                 "text"
                                                                                                 B))))
    (ASSERT
     (SEARCH "https://wardcunningham.github.io/graph/graph.js"
             (GETHASH "text" (AREF ITEMS 0))))
    (ASSERT (SEARCH "export function trails" (GETHASH "text" (AREF ITEMS 1))))
    (LET* ((REFS
            (MAPCAR #'CDR
                    (VIEWS:VIEW-REFERENCES
                     (FOLLOWING-VIEW CHECK "Browser execution"))))
           (OLD
            (FIND "hyperdoc-blocks.js" SOURCES :TEST #'EQUAL :KEY
                  (LAMBDA (S)
                    (GETHASH "key" (READING::BROWSER-SOURCE-METADATA S)))))
           (MODERN
            (FIND "mech-mapped-blocks" SOURCES :TEST #'EQUAL :KEY
                  (LAMBDA (S)
                    (GETHASH "key" (READING::BROWSER-SOURCE-METADATA S)))))
           (MAP
            (READING::VERIFIED-TRAIL-ARTIFACT
             (GETHASH "mech-source-map" MANIFEST) :JSON T))
           (POSITION
            (POSITION "../src/client/blocks.js" (GETHASH "sources" MAP) :TEST
                      #'EQUAL)))
      (DOLIST
          (ACTUAL
           (LIST CAPTURE FAILED CONTROL PAGE FAILED-PAGE ITEMS FAILED-ITEMS
                 SOURCES PROBE MANIFEST))
        (ASSERT (MEMBER ACTUAL REFS :TEST #'EQ)))
      (ASSERT
       (EQUAL (READING::BROWSER-SOURCE-TEXT MODERN)
              (AREF (GETHASH "sourcesContent" MAP) POSITION)))
      (ASSERT
       (SEARCH "async function code_emit"
               (READING::BROWSER-SOURCE-TEXT MODERN)))
      (ASSERT (SEARCH "btoa(code)" (READING::BROWSER-SOURCE-TEXT MODERN)))
      (ASSERT
       (SEARCH "module[way].apply(proxy, args.slice(1))"
               (READING::BROWSER-SOURCE-TEXT MODERN)))
      (ASSERT (NOT (SEARCH "code_emit" (READING::BROWSER-SOURCE-TEXT OLD))))
      (ASSERT
       (SEARCH "else if (op.match(/^[A-Z]+$/))"
               (READING::BROWSER-SOURCE-TEXT OLD)))
      (DOLIST (SOURCE (LIST OLD MODERN))
        (LET* ((FRAGMENT (READING::BROWSER-SOURCE-REVISION-FRAGMENT SOURCE))
               (FILE (READING::FRAGMENT-REVISION-FILE FRAGMENT)))
          (ASSERT
           (MEMBER FRAGMENT
                   (MAPCAR #'CDR
                           (VIEWS:VIEW-REFERENCES
                            (FOLLOWING-VIEW SOURCE "Browser source")))
                   :TEST #'EQ))
          (ASSERT
           (MEMBER FILE
                   (MAPCAR #'CDR
                           (VIEWS:VIEW-REFERENCES
                            (FOLLOWING-VIEW FRAGMENT "Retained source")))
                   :TEST #'EQ))
          (FOLLOWING-VIEW FILE "Evidence locations"))))
    (LOOP FOR SOURCE ACROSS SOURCES
          FOR RECORD = (READING::BROWSER-SOURCE-METADATA SOURCE)
          DO (FOLLOWING-VIEW SOURCE "Browser source") (WHEN
                                                          (GETHASH
                                                           "definitions"
                                                           RECORD)
                                                        (LET ((LINES
                                                               (COERCE
                                                                (UIOP/UTILITY:SPLIT-STRING
                                                                 (READING::BROWSER-SOURCE-TEXT
                                                                  SOURCE)
                                                                 :SEPARATOR
                                                                 '(#\Newline))
                                                                'VECTOR)))
                                                          (MAPHASH
                                                           (LAMBDA (NAME RANGE)
                                                             (LET ((START
                                                                    (AREF LINES
                                                                          (1-
                                                                           (AREF
                                                                            RANGE
                                                                            0))))
                                                                   (END
                                                                    (AREF LINES
                                                                          (1-
                                                                           (AREF
                                                                            RANGE
                                                                            1)))))
                                                               (ASSERT
                                                                (IF (EQUAL
                                                                     "blocks"
                                                                     NAME)
                                                                    (SEARCH
                                                                     "export const blocks = {"
                                                                     START)
                                                                    (SEARCH
                                                                     (FORMAT
                                                                      NIL
                                                                      "function ~A("
                                                                      NAME)
                                                                     START)))
                                                               (ASSERT
                                                                (EQUAL "}"
                                                                       END))))
                                                           (GETHASH
                                                            "definitions"
                                                            RECORD)))) (WHEN
                                                                           (GETHASH
                                                                            "loaded-response"
                                                                            RECORD)
                                                                         (LET* ((RUN
                                                                                 (IF (EQUAL
                                                                                      "hyperdoc"
                                                                                      (GETHASH
                                                                                       "runtime"
                                                                                       RECORD))
                                                                                     FAILED
                                                                                     CAPTURE))
                                                                                (LOADED
                                                                                 (FIND
                                                                                  (GETHASH
                                                                                   "url"
                                                                                   RECORD)
                                                                                  (GETHASH
                                                                                   "sources"
                                                                                   RUN)
                                                                                  :TEST
                                                                                  #'EQUAL
                                                                                  :KEY
                                                                                  (LAMBDA
                                                                                      (
                                                                                       R)
                                                                                    (GETHASH
                                                                                     "url"
                                                                                     R)))))
                                                                           (ASSERT
                                                                            LOADED)
                                                                           (ASSERT
                                                                            (=
                                                                             200
                                                                             (GETHASH
                                                                              "status"
                                                                              LOADED)))
                                                                           (ASSERT
                                                                            (EQUAL
                                                                             (GETHASH
                                                                              "sha256"
                                                                              RECORD)
                                                                             (GETHASH
                                                                              "sha256"
                                                                              LOADED))))))
    (LET ((RUNNER (SYMBOL-FUNCTION 'UIOP/RUN-PROGRAM:RUN-PROGRAM)) (CALLS 0))
      (UNWIND-PROTECT
          (PROGN
           (SETF (SYMBOL-FUNCTION 'UIOP/RUN-PROGRAM:RUN-PROGRAM)
                   (LAMBDA (&REST ARGS)
                     (DECLARE (IGNORE ARGS))
                     (INCF CALLS)
                     (ERROR "Inspection attempted process execution.")))
           (FOLLOWING-VIEW CHECK "Browser execution")
           (LOOP FOR SOURCE ACROSS SOURCES
                 DO (FOLLOWING-VIEW SOURCE "Browser source")))
        (SETF (SYMBOL-FUNCTION 'UIOP/RUN-PROGRAM:RUN-PROGRAM) RUNNER))
      (ASSERT (ZEROP CALLS)))
    (ASSERT (EQ :FALSE (GETHASH "hasCode" (GETHASH "registry" PROBE))))
    (ASSERT
     (NOT
      (FIND "CODE" (GETHASH "keys" (GETHASH "registry" PROBE)) :TEST #'EQUAL)))
    (ASSERT (ZEROP (GETHASH "handlerCalls" PROBE)))
    (ASSERT
     (EQUAL ERROR-TEXT
            (GETHASH "message" (AREF (GETHASH "diagnostics" PROBE) 0))))
    (LET* ((OUTPUT
            (UIOP/RUN-PROGRAM:RUN-PROGRAM
             (LIST "env" "-u" "DYLD_LIBRARY_PATH" "-u"
                   "DYLD_FALLBACK_LIBRARY_PATH" "-u" "LD_LIBRARY_PATH" "node"
                   (NAMESTRING
                    (READING::FOLLOWING-PATH
                     "dreyeck/work/trails-rendered-dispatch-probe.mjs"))
                   (NAMESTRING (READING::FOLLOWING-PATH "")))
             :OUTPUT :STRING))
           (ACTUAL
            (SHASHT:READ-JSON* :STREAM (MAKE-STRING-INPUT-STREAM OUTPUT)
                               :SINGLE-VALUE T :OBJECT-FORMAT :HASH-TABLE
                               :HASH-TABLE-TEST 'EQUAL :ARRAY-FORMAT :VECTOR
                               :TRUE-VALUE :TRUE :FALSE-VALUE :FALSE
                               :NULL-VALUE :NULL)))
      (ASSERT (DREYECK/WORK/READING::%JSON-EQUAL PROBE ACTUAL)))
    (MULTIPLE-VALUE-BIND (READING-PAGE CONTENT)
        (RENDER-PAGE "dreyeck/work/reading" "Original CODE Browser Check")
      (DECLARE (IGNORE READING-PAGE))
      (ASSERT
       (SOME (LAMBDA (REF) (TYPEP (CDR REF) 'READING::TRAIL-BROWSER-CHECK))
             (VIEWS:VIEW-REFERENCES CONTENT))))
    (LET ((CODE-PAGE
           (HYPERBOOK:FIND-PAGE "dreyeck/work/reading"
                                "Checking Original CODE Execution"
                                :SIGNAL-ERROR? T)))
      (HYPERDOC:LOAD-PAGE CODE-PAGE)
      (ASSERT
       (FIND "Original CODE Browser Check"
             (HYPERBOOK:PAGE-LINKS-OF (HYPERBOOK:LINKS-OF CODE-PAGE)) :KEY
             #'HYPERBOOK:TARGET-PAGE-OF :TEST #'EQUAL))
      (FOLLOWING-VIEW CODE-PAGE "Source"))
    (LET ((PROJECTION
           (READING::TRAIL-LEARNING-PROJECTION (READING:TRAIL-FOLLOWING))))
      (ASSERT (= 46 (LENGTH (TM:TOPICMAP-PROJECTION-TOPICS-OF PROJECTION))))
      (ASSERT
       (= 69 (LENGTH (TM:TOPICMAP-PROJECTION-ASSOCIATIONS-OF PROJECTION)))))
    (FORMAT T "~&ORIGINAL-CODE-BROWSER-EVIDENCE-PASS~%")))
