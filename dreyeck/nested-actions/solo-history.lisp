;;;; Tracing Historical Popup Additions

(IN-PACKAGE #:DREYECK/NESTED-ACTIONS)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Nested Actions in Solo" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "What Does a Nested Action Inherit?" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Two Relations Hidden in One Nest" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "From Message to Nested Input" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Adding to an Already Rendered Solo Popup" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(DEFCLASS SOLO-HISTORY NIL
          ((SOURCES :INITARG :SOURCES :READER HISTORICAL-SOURCES)
           (CLAIMS :INITARG :CLAIMS :READER HISTORICAL-CLAIMS)))

(DEFUN HISTORICAL-SOURCE (HISTORY ROLE)
  (OR
   (FIND ROLE (HISTORICAL-SOURCES HISTORY) :KEY
         (LAMBDA (S) (GETHASH "role" (SOURCE-METADATA S))) :TEST #'EQUAL)
   (ERROR "Unknown historical evidence role ~S" ROLE)))

(HYPERDOC:DEFEXAMPLE HISTORICAL-INVESTIGATION
  "Historical popup updates and fetch work are established separately; continuity to current LISTEN stays hypothesized."
  (LET ((SOURCES (HISTORICAL-SOURCE-OBSERVATIONS)))
    (FLET ((SOURCE (ROLE)
             (FIND ROLE SOURCES :KEY
                   (LAMBDA (S) (GETHASH "role" (SOURCE-METADATA S))) :TEST
                   #'EQUAL)))
      (MAKE-INSTANCE 'SOLO-HISTORY :SOURCES SOURCES :CLAIMS
                     (LIST
                      (LIST :ID :WARD-CLUE :STATUS :AUTHOR-REPORTED :QUOTATION
                            "there was a path to spontaneous additions to Solo's pop-up"
                            :MEMORY
                            "Markov Monkey / Speed Bot async-fetch optimization"
                            :ORIGIN :WARD-NEW-TASK)
                      (LIST :ID :POPUP-APPEND :STATUS :SOURCE-OBSERVED :SOURCE
                            (SOURCE "solo-append-receiver") :SENDER
                            (SOURCE "solo-append-sender") :RENDER
                            (SOURCE "solo-refresh") :MECHANISM
                            "Named popup reused; batch {type:batch, graphs} posted after load or directly to existing dialog; message callback stamps and appends data.graphs to beam, then refreshBeam rebuilds the displayed list."
                            :AUTOMATIC-FETCH-TRIGGER :NOT-ESTABLISHED
                            :NESTED-ACTION-INPUT :NOT-PRESENT)
                      (LIST :ID :FETCH-BARRIER :STATUS :SOURCE-OBSERVED :SOURCE
                            (SOURCE "solo-fetch-barrier") :MECHANISM
                            "LINK fetches start during parse; emit awaits Promise.all(parsed.graphs) before installing the popup button. This is a barrier before delivery, not per-fetch popup injection.")
                      (LIST :ID :POPUP-REPLACEMENT :STATUS :SOURCE-OBSERVED
                            :SOURCE (SOURCE "solo-replace-receiver") :MECHANISM
                            "Later batch contains sources/aspects; beam.splice(0) clears prior items before appending current source aspects. Do not transfer early append semantics to every revision.")
                      (LIST :ID :SPEED-FETCH :STATUS :SOURCE-OBSERVED :SOURCE
                            (SOURCE "speed-getfrom") :MECHANISM
                            "getfrom concurrently fills missing sitemap cache via Promise.all, selects a site from sitemap membership, fetches that page, then derives the next site's context from reference items and journal. Site selection precedes that fetched page's journal inspection."
                            :EARLIER-SOURCE (SOURCE "speed-getfrom-earlier")
                            :OPTIMIZED-CURRENT-BEHAVIOR :NOT-CLAIMED)
                      (LIST :ID :SPEED-RESULTS :STATUS :SOURCE-OBSERVED :SOURCE
                            (SOURCE "speed-run") :MECHANISM
                            "dostart awaits getfrom for a hop, pushes next into all, extends DOT/display, updates pick, and eventually calls imported frame open on a generated Journey page. No Solo batch sender appears in this retained runner."
                            :IMPORTED-FRAME-RUNTIME-REVISION :UNVERIFIED)
                      (LIST :ID :HISTORICAL-ANCESTOR :STATUS :HYPOTHESIZED
                            :ANSWER NIL :CANDIDATE
                            "Persistent receiver plus incoming-data mutation and refresh is a possible historical analogy."
                            :BOUNDARY
                            "No located code/revision chain connects Speed Bot fetch completion to Solo append messages, or Solo beam mutation to current LISTEN's nested input/REPORT caller."
                            :CURRENT-LISTEN-HANDOFF :OPEN :RUNTIME-CLAIM
                            NIL))))))

(V:DEFVIEW HISTORICAL-PATHS-VIEW (HISTORY SOLO-HISTORY)
           (V:HTML-VIEW :TITLE "Historical paths" :PRIORITY 1
                        (V:HTML
                          (:P
                           "Source-observed historical popup append, later replacement and Speed Bot fetch/results. Current nested-input continuity remains a hypothesis.")
                          (:P
                           (V:OBJECT-REF (HISTORICAL-CLAIMS HISTORY) :DISPLAY
                                         "Claims, warrants and exact remaining boundaries"))
                          (:UL
                           (DOLIST (SOURCE (HISTORICAL-SOURCES HISTORY))
                             (V:HTML
                               (:LI
                                (V:OBJECT-REF (SOURCE-REVISION SOURCE) :DISPLAY
                                              (FORMAT NIL "~A / ~A"
                                                      (DREYECK/GIT:GIT-REVISION-AUTHORITY-OF
                                                       (SOURCE-REVISION
                                                        SOURCE))
                                                      (DREYECK/GIT:GIT-REVISION-DISPLAY-ID-OF
                                                       (SOURCE-REVISION
                                                        SOURCE)))
                                              :SELECT "Evidence revision")
                                " · "
                                (V:OBJECT-REF SOURCE :DISPLAY
                                              (SOURCE-DEFINITION SOURCE)
                                              :SELECT "Source evidence")))))
                          (:P
                           (V:OBJECT-REF
                            (TOPIC-WORKSPACE "historical-ancestor") :DISPLAY
                            "Inspect the hypothesis boundary in the Workspace"
                            :SELECT "Topicmap"))
                          (:P
                           (V:OBJECT-REF
                            (HYPERDOC:PAGE
                             "Adding to an Already Rendered Solo Popup"
                             :HYPERBOOK "dreyeck/nested-actions/reading")
                            :DISPLAY "Return to the historical reading" :SELECT
                            "Content")))))
