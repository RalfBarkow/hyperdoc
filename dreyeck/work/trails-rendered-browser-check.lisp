;;;; Checking Original CODE Execution

(IN-PACKAGE #:DREYECK/WORK/TRAILS-RENDERED-READING)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Original CODE Browser Check" :HYPERBOOK
                 "dreyeck/work/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Following One Recorded Trail" :HYPERBOOK
                 "dreyeck/work/reading"))

(DEFCLASS TRAIL-BROWSER-CHECK NIL
          ((MANIFEST :INITARG :MANIFEST :READER BROWSER-CHECK-MANIFEST)
           (CAPTURE :INITARG :CAPTURE :READER BROWSER-CHECK-CAPTURE)
           (FAILING :INITARG :FAILING :READER BROWSER-CHECK-FAILING)
           (CONTROL :INITARG :CONTROL :READER BROWSER-CHECK-CONTROL)
           (PAGE :INITARG :PAGE :READER BROWSER-CHECK-PAGE)
           (FAILING-PAGE :INITARG :FAILING-PAGE :READER
            BROWSER-CHECK-FAILING-PAGE)
           (CODE-ITEMS :INITARG :CODE-ITEMS :READER BROWSER-CHECK-CODE-ITEMS)
           (FAILING-CODE-ITEMS :INITARG :FAILING-CODE-ITEMS :READER
            BROWSER-CHECK-FAILING-CODE-ITEMS)
           (PROBE :INITARG :PROBE :READER BROWSER-CHECK-PROBE)
           (SOURCES :INITARG :SOURCES :READER BROWSER-CHECK-SOURCES)))

(DEFCLASS TRAIL-BROWSER-SOURCE NIL
          ((METADATA :INITARG :METADATA :READER BROWSER-SOURCE-METADATA)
           (TEXT :INITARG :TEXT :READER BROWSER-SOURCE-TEXT)
           (REVISION-FRAGMENT :INITARG :REVISION-FRAGMENT :READER
            BROWSER-SOURCE-REVISION-FRAGMENT)))

(DEFUN MAKE-TRAIL-BROWSER-CHECK ()
  "Read verified retained objects only. No browser, network, Git process or witness execution."
  (LET* ((MANIFEST
          (READ-OBSERVATION
           "dreyeck/work/trails-rendered-browser-evidence/manifest.json"))
         (PAGE (VERIFIED-TRAIL-ARTIFACT (GETHASH "page" MANIFEST) :JSON T))
         (FAILING-PAGE
          (VERIFIED-TRAIL-ARTIFACT (GETHASH "failing-page" MANIFEST) :JSON T))
         (SOURCES
          (MAP 'VECTOR
               (LAMBDA (RECORD)
                 (MAKE-INSTANCE 'TRAIL-BROWSER-SOURCE :METADATA RECORD :TEXT
                                (VERIFIED-TRAIL-ARTIFACT RECORD)
                                :REVISION-FRAGMENT
                                (WHEN (GETHASH "revision" RECORD)
                                  (TRAIL-SOURCE-FRAGMENT RECORD))))
               (GETHASH "sources" MANIFEST))))
    (MAKE-INSTANCE 'TRAIL-BROWSER-CHECK :MANIFEST MANIFEST :PAGE PAGE
                   :FAILING-PAGE FAILING-PAGE :CAPTURE
                   (VERIFIED-TRAIL-ARTIFACT (GETHASH "capture" MANIFEST) :JSON
                                            T)
                   :FAILING
                   (VERIFIED-TRAIL-ARTIFACT
                    (GETHASH "failing-capture" MANIFEST) :JSON T)
                   :CONTROL
                   (VERIFIED-TRAIL-ARTIFACT
                    (GETHASH "single-page-control" MANIFEST) :JSON T)
                   :PROBE
                   (VERIFIED-TRAIL-ARTIFACT (GETHASH "dispatch-probe" MANIFEST)
                                            :JSON T)
                   :CODE-ITEMS
                   (REMOVE-IF-NOT
                    (LAMBDA (ITEM) (EQUAL "code" (GETHASH "type" ITEM)))
                    (GETHASH "story" PAGE))
                   :FAILING-CODE-ITEMS
                   (REMOVE-IF-NOT
                    (LAMBDA (ITEM) (EQUAL "code" (GETHASH "type" ITEM)))
                    (GETHASH "story" FAILING-PAGE))
                   :SOURCES SOURCES)))

(HYPERDOC:DEFEXAMPLE ORIGINAL-CODE-BROWSER-CHECK
  "Original public runs on 2026-10-08: HyperDoc's Wiki rejects unknown CODE;
Ward's Wiki returns 2 aspects. The failed dispatch precedes trails/Graph import.
Opening this object reads retained evidence; browser and source probes are separate explicit CLI runs."
  (MAKE-TRAIL-BROWSER-CHECK))

(DEFUN BROWSER-CHECK-READING-LINK ()
  (HTML-INSPECTOR-VIEWS:OBJECT-REF
   (HYPERBOOK:FIND-PAGE "dreyeck/work/reading" "Original CODE Browser Check"
                        :SIGNAL-ERROR? T)
   :DISPLAY "Return to Original CODE Browser Check"))

(HTML-INSPECTOR-VIEWS:DEFVIEW TRAIL-BROWSER-EXECUTION
                              (CHECK TRAIL-BROWSER-CHECK)
                              (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE
                                                              "Browser execution"
                                                              :PRIORITY 0
                                                              (HTML-INSPECTOR-VIEWS:HTML
                                                                (:P
                                                                 (BROWSER-CHECK-READING-LINK))
                                                                (:P
                                                                 "Observed failure: "
                                                                 (:CODE
                                                                  (CL-WHO:ESC
                                                                   (GETHASH
                                                                    "diagnosticMessage"
                                                                    (BROWSER-CHECK-FAILING
                                                                     CHECK)))))
                                                                (:P
                                                                 "The loaded older Mech registry has no CODE block. Dispatch reaches trouble before any Graph import or trails call.")
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (BROWSER-CHECK-FAILING
                                                                   CHECK)
                                                                  :DISPLAY
                                                                  "Failing lineup: revealed diagnostic, console, network and build stamp"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (BROWSER-CHECK-CONTROL
                                                                   CHECK)
                                                                  :DISPLAY
                                                                  "Single-page control: same unsupported CODE"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (BROWSER-CHECK-CAPTURE
                                                                   CHECK)
                                                                  :DISPLAY
                                                                  "Ward's successful original browser run: 2 aspects"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (BROWSER-CHECK-PAGE
                                                                   CHECK)
                                                                  :DISPLAY
                                                                  "Ward's retained page")
                                                                 " / "
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (BROWSER-CHECK-FAILING-PAGE
                                                                   CHECK)
                                                                  :DISPLAY
                                                                  "Failing installation's page"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (BROWSER-CHECK-CODE-ITEMS
                                                                   CHECK)
                                                                  :DISPLAY
                                                                  "Ward's actual Code items")
                                                                 " / "
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (BROWSER-CHECK-FAILING-CODE-ITEMS
                                                                   CHECK)
                                                                  :DISPLAY
                                                                  "Failing page's actual Code items"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (BROWSER-CHECK-SOURCES
                                                                   CHECK)
                                                                  :DISPLAY
                                                                  "Loaded sources, revision-qualified definitions and explicit harnesses"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (BROWSER-CHECK-PROBE
                                                                   CHECK)
                                                                  :DISPLAY
                                                                  "Executed source reduction: command, actual registry, diagnostic; 0 handlers"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (BROWSER-CHECK-MANIFEST
                                                                   CHECK)
                                                                  :DISPLAY
                                                                  "Source identities, warrants, comparison and remaining release boundary")))))

(HTML-INSPECTOR-VIEWS:DEFVIEW TRAIL-BROWSER-LOADED-SOURCE
                              (SOURCE TRAIL-BROWSER-SOURCE)
                              (LET ((RECORD (BROWSER-SOURCE-METADATA SOURCE)))
                                (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE
                                                                "Browser source"
                                                                :PRIORITY 0
                                                                (HTML-INSPECTOR-VIEWS:HTML
                                                                  (:P
                                                                   (BROWSER-CHECK-READING-LINK))
                                                                  (WHEN
                                                                      (GETHASH
                                                                       "url"
                                                                       RECORD)
                                                                    (HTML-INSPECTOR-VIEWS:HTML
                                                                      (:P
                                                                       (:A
                                                                        :HREF
                                                                        (GETHASH
                                                                         "url"
                                                                         RECORD)
                                                                        (CL-WHO:ESC
                                                                         (GETHASH
                                                                          "url"
                                                                          RECORD))))))
                                                                  (:P
                                                                   (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                    RECORD
                                                                    :DISPLAY
                                                                    "Runtime digest and retention provenance"))
                                                                  (WHEN
                                                                      (BROWSER-SOURCE-REVISION-FRAGMENT
                                                                       SOURCE)
                                                                    (HTML-INSPECTOR-VIEWS:HTML
                                                                      (:P
                                                                       (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                        (BROWSER-SOURCE-REVISION-FRAGMENT
                                                                         SOURCE)
                                                                        :DISPLAY
                                                                        "Matched repository revision, file and retained definitions"))))
                                                                  (:PRE
                                                                   (CL-WHO:ESC
                                                                    (BROWSER-SOURCE-TEXT
                                                                     SOURCE)))))))
