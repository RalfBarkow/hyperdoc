;;;; Inspecting Revision Provenance and Source Locations

(IN-PACKAGE #:DREYECK/INSPECTOR/GIT)

(DEFMETHOD HTML-INSPECTOR-VIEWS:TEXT-REPRESENTATION
           ((REVISION DREYECK/GIT:GIT-REVISION-REFERENCE))
  (FORMAT NIL "~A @ ~A" (DREYECK/GIT:GIT-REVISION-AUTHORITY-OF REVISION)
          (DREYECK/GIT:GIT-REVISION-DISPLAY-ID-OF REVISION)))

(HTML-INSPECTOR-VIEWS:DEFVIEW REVISION-EVIDENCE-VIEW
                              (REVISION DREYECK/GIT:GIT-REVISION-REFERENCE)
                              (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE
                                                              "Evidence revision"
                                                              :PRIORITY 0
                                                              (HTML-INSPECTOR-VIEWS:HTML
                                                                (:P
                                                                 (CL-WHO:ESC
                                                                  (DREYECK/GIT:GIT-REVISION-AUTHORITY-OF
                                                                   REVISION)))
                                                                (:P
                                                                 "Full OID: "
                                                                 (:CODE
                                                                  (CL-WHO:ESC
                                                                   (DREYECK/GIT:GIT-COMMIT-HASH-OF
                                                                    REVISION))))
                                                                (:P
                                                                 "Display only: "
                                                                 (CL-WHO:ESC
                                                                  (DREYECK/GIT:GIT-REVISION-DISPLAY-ID-OF
                                                                   REVISION)))
                                                                (:P
                                                                 "Provenance role: "
                                                                 (CL-WHO:ESC
                                                                  (FORMAT NIL
                                                                          "~A"
                                                                          (DREYECK/GIT:GIT-REVISION-ROLE-OF
                                                                           REVISION))))
                                                                (:P
                                                                 "Local checkout: "
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (DREYECK/GIT:GIT-COMMIT-REPOSITORY-OF
                                                                   REVISION)))
                                                                (:P
                                                                 "Local object status: "
                                                                 (CL-WHO:ESC
                                                                  (FORMAT NIL
                                                                          "~A"
                                                                          (DREYECK/GIT:GIT-REVISION-LOCAL-STATUS
                                                                           REVISION))))
                                                                (:P
                                                                 "Recorded retention identifies a local commit object and verified source excerpts. Current local availability is shown separately. This evidence does not identify the current implementation.")
                                                                (:UL
                                                                 (DOLIST
                                                                     (FILE
                                                                      (DREYECK/GIT:GIT-REVISION-FILES-OF
                                                                       REVISION))
                                                                   (HTML-INSPECTOR-VIEWS:HTML
                                                                     (:LI
                                                                      (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                       FILE
                                                                       :DISPLAY
                                                                       (DREYECK/GIT:GIT-FILE-PATH-OF
                                                                        FILE)
                                                                       :SELECT
                                                                       "Evidence locations")))))
                                                                (WHEN
                                                                    (DREYECK/GIT:GIT-REVISION-WEB-URL-OF
                                                                     REVISION)
                                                                  (HTML-INSPECTOR-VIEWS:HTML
                                                                    (:P
                                                                     (:A :HREF
                                                                      (DREYECK/GIT:GIT-REVISION-WEB-URL-OF
                                                                       REVISION)
                                                                      :TARGET
                                                                      "_blank"
                                                                      "External repository commit")))))))

(HTML-INSPECTOR-VIEWS:DEFVIEW EVIDENCE-FILE-LOCATIONS-VIEW
                              (FILE DREYECK/GIT:GIT-EVIDENCE-FILE)
                              (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE
                                                              "Evidence locations"
                                                              :PRIORITY 0
                                                              (HTML-INSPECTOR-VIEWS:HTML
                                                                (:P
                                                                 (:CODE
                                                                  (CL-WHO:ESC
                                                                   (DREYECK/GIT:GIT-FILE-PATH-OF
                                                                    FILE))))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  (DREYECK/GIT:GIT-FILE-COMMIT-OF
                                                                   FILE)
                                                                  :DISPLAY
                                                                  "Repository authority and full revision"
                                                                  :SELECT
                                                                  "Evidence revision"))
                                                                (:P
                                                                 (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                  FILE :DISPLAY
                                                                  "Read the complete Git blob in the local checkout"
                                                                  :SELECT
                                                                  "Contents"))
                                                                (:P
                                                                 "Relevant definitions and exact retained source ranges:")
                                                                (:UL
                                                                 (DOLIST
                                                                     (LOCATION
                                                                      (REVERSE
                                                                       (DREYECK/GIT:GIT-EVIDENCE-FILE-LOCATIONS-OF
                                                                        FILE)))
                                                                   (HTML-INSPECTOR-VIEWS:HTML
                                                                     (:LI
                                                                      (HTML-INSPECTOR-VIEWS:OBJECT-REF
                                                                       LOCATION))))))))
