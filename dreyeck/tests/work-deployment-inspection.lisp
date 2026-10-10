;;;; Deployment Reader Journey and Browser Witness

(DEFPACKAGE #:DREYECK/WORK/DEPLOYMENT-INSPECTION/TESTS
  (:USE #:CL)
  (:LOCAL-NICKNAMES (#:D #:DREYECK/WORK/DEPLOYMENT-INSPECTION)
                    (#:R #:DREYECK/WORK/DEPLOYMENT-READING)
                    (#:V #:HTML-INSPECTOR-VIEWS)
                    (#:G #:DREYECK/GIT)
                    (#:N #:DREYECK/NESTED-ACTIONS)
                    (#:C #:DREYECK/FEDWIKI-CONFIG))
  (:EXPORT #:RUN-TESTS #:SERVE-BROWSER-WITNESS))

(IN-PACKAGE #:DREYECK/WORK/DEPLOYMENT-INSPECTION/TESTS)

(DEFVAR *CHECKS* 0)

(DEFUN CHECK (VALUE &OPTIONAL (REASON "Deployment reader contract"))
  (INCF *CHECKS*)
  (UNLESS VALUE (ERROR "Failed at check ~D: ~A" *CHECKS* REASON))
  VALUE)

(DEFUN RENDER (OBJECT TITLE)
  (LET ((VIEW
         (FIND TITLE (V:ALL-VIEWS OBJECT) :KEY #'V:VIEW-TITLE :TEST #'EQUAL)))
    (CHECK VIEW TITLE)
    (V:VIEW-HTML VIEW)
    (CHECK
     (NOTANY (LAMBDA (X) (TYPEP (CDR X) 'CONDITION)) (V:VIEW-REFERENCES VIEW))
     "native references resolve")
    VIEW))

(DEFUN REFERENCES (VIEW) (MAPCAR #'CDR (V:VIEW-REFERENCES VIEW)))

(DEFUN RUN-TESTS ()
  (LET ((*CHECKS* 0)
        (BOOK
         (HYPERBOOK:FIND-HYPERBOOK "dreyeck/work/reading" :SIGNAL-ERROR? T)))
    (CHECK
     (= 1
        (COUNT "dreyeck/work/reading"
               (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*) :KEY
               #'HYPERBOOK:ID-OF :TEST #'EQUAL)))
    (CHECK
     (= 1
        (COUNT "dreyeck/fedwiki-config/reading"
               (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*) :KEY
               #'HYPERBOOK:ID-OF :TEST #'EQUAL)))
    (DOLIST
        (TITLE
         '("wiki.ralfbarkow.ch deployment" "dreyeck.ch deployment"
           "Federated Wiki deployment state" "Work Breakdown"))
      (LET* ((PAGE (HYPERBOOK:FIND-PAGE BOOK TITLE :SIGNAL-ERROR? T))
             (DOM (PLUMP-PARSER:PARSE (HYPERDOC:FILE-OF PAGE)))
             (VIEW (RENDER PAGE "Content")))
        (DOLIST (A (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME DOM "a"))
          (LET ((TARGET (PLUMP-DOM:ATTRIBUTE A "page"))
                (EXPR (PLUMP-DOM:ATTRIBUTE A "expr")))
            (WHEN TARGET
              (CHECK
               (HYPERBOOK:FIND-PAGE
                (OR (PLUMP-DOM:ATTRIBUTE A "hyperbook") BOOK) TARGET
                :SIGNAL-ERROR? T)))
            (WHEN EXPR
              (LET* ((*PACKAGE*
                      (FIND-PACKAGE :DREYECK/WORK/DEPLOYMENT-INSPECTION))
                     (VALUE
                      (EVAL
                       (READ-FROM-STRING (PLUMP-DOM:DECODE-ENTITIES EXPR)))))
                (CHECK VALUE "native expression produces a concrete object")
                (WHEN (TYPEP VALUE 'D:DEPLOYMENT-OBJECT)
                  (LET ((OBJECT-VIEW (RENDER VALUE "Deployment evidence")))
                    (CHECK
                     (MEMBER
                      (HYPERBOOK:FIND-PAGE BOOK (D:OBJECT-PAGE VALUE)
                                           :SIGNAL-ERROR? T)
                      (REFERENCES OBJECT-VIEW) :TEST #'EQ))
                    (CHECK (> (LENGTH (D:OBJECT-SUMMARY VALUE)) 60))))
                (WHEN (TYPEP VALUE 'D:DEPLOYMENT-REVISION)
                  (RENDER VALUE "Deployment revision"))))))
        (UNLESS (EQUAL TITLE "Work Breakdown")
          (CHECK
           (MEMBER (HYPERBOOK:FIND-PAGE BOOK "Work Breakdown" :SIGNAL-ERROR? T)
                   (REFERENCES VIEW) :TEST #'EQ))
          (CHECK
           (MEMBER
            (C:READING-PAGE "Reading FedWiki Configuration and Fork Behavior")
            (REFERENCES VIEW) :TEST #'EQ)))))
    (LET* ((CFG-VIEW
            (RENDER
             (C:READING-PAGE "Reading FedWiki Configuration and Fork Behavior")
             "Content"))
           (REFS (REFERENCES CFG-VIEW)))
      (DOLIST
          (TITLE '("wiki.ralfbarkow.ch deployment" "dreyeck.ch deployment"))
        (CHECK
         (MEMBER (HYPERBOOK:FIND-PAGE BOOK TITLE :SIGNAL-ERROR? T) REFS :TEST
                 #'EQ))))
    (CHECK
     (EQUAL (R:DEPLOYMENT-EVIDENCE) (D:OBJECT-RECORD (D:HISTORICAL-WIKI))))
    (CHECK (EQ :OBSERVATION (D:OBJECT-KIND (D:HISTORICAL-WIKI))))
    (CHECK (EQ :PACKAGE (D:OBJECT-KIND (D:WIKI-PACKAGE))))
    (CHECK (EQ :SERVICE (D:OBJECT-KIND (D:WIKI-SERVICE))))
    (CHECK (EQ :PROCESS (D:OBJECT-KIND (D:SERVED-PROCESS))))
    (CHECK (EQ :SELECTION (D:OBJECT-KIND (D:SERVED-SELECTION))))
    (CHECK
     (EQUAL (R:DEPLOYMENT-UPDATE-OBSERVATION)
            (D:OBJECT-RECORD (D:RECORDED-ACTIVATION))))
    (CHECK (EQ :ACTIVATION (D:OBJECT-KIND (D:RECORDED-ACTIVATION))))
    (CHECK
     (EQUAL (R:SERVED-STATE-OBSERVATION-2026-10-08)
            (D:OBJECT-RECORD (D:LATEST-HYPERDOC))))
    (DOLIST (KEY '("ralfbarkow" "dreyeck"))
      (LET ((DECLARED (D:DECLARED-WIKI KEY)) (BOUNDARY (D:WIKI-BOUNDARY KEY)))
        (CHECK (TYPEP (D:OBJECT-RECORD DECLARED) 'C:CONFIGURATION-BASE))
        (CHECK (EQ :DECLARATION (D:OBJECT-KIND DECLARED)))
        (CHECK (NULL (GETF (D:OBJECT-RECORD BOUNDARY) :ACTIVATION-OBSERVED)))
        (CHECK (EQ :UNRESOLVED (GETF (D:OBJECT-RECORD BOUNDARY) :STATUS)))
        (CHECK
         (NOT (TYPEP (D:OBJECT-RECORD DECLARED) 'G:GIT-REVISION-REFERENCE))
         "configuration is distinct from its revision")))
    (DOLIST (REV (LIST (D:WIKI-SOURCE) (D:SERVED-REVISION)))
      (CHECK (NULL (G:GIT-COMMIT-REPOSITORY-OF REV)))
      (CHECK (= 40 (LENGTH (G:GIT-COMMIT-HASH-OF REV))))
      (CHECK (G:GIT-REVISION-FILES-OF REV)
             "revision reaches retained source file")
      (RENDER REV "Deployment revision")
      (RENDER REV "Patch")
      (DOLIST (FILE (G:GIT-REVISION-FILES-OF REV))
        (LET ((VIEW (RENDER FILE "Evidence locations")))
          (CHECK (G:GIT-EVIDENCE-FILE-LOCATIONS-OF FILE))
          (DOLIST (SOURCE (G:GIT-EVIDENCE-FILE-LOCATIONS-OF FILE))
            (CHECK (MEMBER SOURCE (REFERENCES VIEW) :TEST #'EQ))
            (RENDER SOURCE "Deployment source")))))
    (CHECK
     (EQUAL
      '("https://github.com/RalfBarkow/wiki"
        "b42eb888d6e5d59803667c6320e0779523fc265c")
      (G:GIT-REVISION-IDENTITY (D:WIKI-SOURCE))))
    (CHECK
     (EQUAL
      '("https://github.com/RalfBarkow/hyperdoc"
        "fab214334279bc5d3df0f2f624d34e6a1bdc1897")
      (G:GIT-REVISION-IDENTITY (D:SERVED-REVISION))))
    (LET* ((HISTORY (D:HISTORICAL-WIKI))
           (PACKAGE
            (CDR
             (ASSOC "Nix package identity" (D:OBJECT-LINKS HISTORY) :TEST
                    #'EQUAL)))
           (REVISION
            (CDR
             (ASSOC "Reported source revision" (D:OBJECT-LINKS PACKAGE) :TEST
                    #'EQUAL)))
           (FILE (FIRST (G:GIT-REVISION-FILES-OF REVISION)))
           (SOURCE (FIRST (G:GIT-EVIDENCE-FILE-LOCATIONS-OF FILE))))
      (CHECK (EQ :PACKAGE (D:OBJECT-KIND PACKAGE)))
      (CHECK (EQ REVISION (N:SOURCE-REVISION SOURCE)))
      (CHECK
       (MEMBER
        (HYPERBOOK:FIND-PAGE BOOK "wiki.ralfbarkow.ch deployment"
                             :SIGNAL-ERROR? T)
        (REFERENCES (RENDER SOURCE "Deployment source")) :TEST #'EQ)))
    (FORMAT T
            "~&DEPLOYMENT-INSPECTION-PASS: ~D checks; historical/source/package/service identities, activation boundary and native return journey.~%"
            *CHECKS*)
    T))

(DEFUN SERVE-BROWSER-WITNESS (PORT STOP-FILE)
  "Disposable ordinary Inspector, fresh process, loopback only, no authoring capability."
  (CLOG:INITIALIZE
   (LAMBDA (BODY)
     (SETF (CLOG:TEXT (CLOG:CREATE-STYLE-BLOCK BODY))
             CLOG-MOLDABLE-INSPECTOR::*CSS*)
     (LET* ((WIDTH
             (PARSE-INTEGER (CLOG:JS-QUERY BODY "String(window.innerWidth)")))
            (INSPECTOR
             (CLOG-MOLDABLE-INSPECTOR::CREATE-INSPECTOR BODY :PANE-WIDTH
                                                        (FORMAT NIL "~Dpx"
                                                                (MIN 700
                                                                     (- WIDTH
                                                                        36)))
                                                        :PLAYGROUND? NIL)))
       (CLOG-MOLDABLE-INSPECTOR::CREATE-PANE INSPECTOR
                                             (HYPERBOOK:FIND-PAGE
                                              "dreyeck/work/reading"
                                              "Work Breakdown" :SIGNAL-ERROR?
                                              T)
                                             :SELECT "Content")))
   :PORT PORT :HOST "127.0.0.1")
  (FORMAT T "~&DEPLOYMENT-BROWSER-READY ~D~%" PORT)
  (FINISH-OUTPUT)
  (UNWIND-PROTECT
      (LOOP REPEAT 2400
            UNTIL (PROBE-FILE STOP-FILE)
            DO (SLEEP 0.1))
    (CLOG:SHUTDOWN)))
