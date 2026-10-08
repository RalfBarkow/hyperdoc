;;;; Git Revisions Behind the Source

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

(DEFUN REVISION-REFERENCE-INDEX ()
  "Explicit recorded authorities/OIDs, never short-SHA recognition or automatic fetching."
  (LOOP FOR METADATA ACROSS (READ-MESSAGE-JSON
                             "dreyeck/nested-actions/sources/revision-provenance.json")
        COLLECT (CONS (GETHASH "key" METADATA)
                      (DREYECK/GIT:MAKE-GIT-REVISION-REFERENCE :REPOSITORY
                                                               (MAKE-INSTANCE
                                                                'DREYECK/GIT:GIT-REPOSITORY-CHECKOUT
                                                                :ROOT
                                                                (UIOP/PATHNAME:ENSURE-DIRECTORY-PATHNAME
                                                                 (PATHNAME
                                                                  (GETHASH
                                                                   "root"
                                                                   METADATA)))
                                                                :ROOT-SOURCE
                                                                METADATA)
                                                               :AUTHORITY
                                                               (GETHASH
                                                                "authority"
                                                                METADATA)
                                                               :OID
                                                               (GETHASH "oid"
                                                                        METADATA)
                                                               :DISPLAY-ID
                                                               (GETHASH
                                                                "display"
                                                                METADATA)
                                                               :ROLE
                                                               (GETHASH "role"
                                                                        METADATA)
                                                               :WEB-URL
                                                               (GETHASH
                                                                "webUrl"
                                                                METADATA)))))

(DEFUN MESSAGE-SOURCE-FROM-METADATA (METADATA INDEX)
  (LET* ((FILE
          (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME
           "dreyeck/nested-actions/reading" (GETHASH "file" METADATA)))
         (DIGEST
          (IRONCLAD:BYTE-ARRAY-TO-HEX-STRING
           (IRONCLAD:DIGEST-FILE :SHA256 FILE)))
         (KEY
          (OR (GETHASH "revisionKey" METADATA)
              (WHEN (GETHASH "revision" METADATA) "mech-witness")))
         (REVISION (CDR (ASSOC KEY INDEX :TEST #'EQUAL)))
         (GIT-FILE
          (WHEN REVISION
            (DREYECK/GIT:ENSURE-GIT-EVIDENCE-FILE REVISION
                                                  (GETHASH "path" METADATA)))))
    (UNLESS (EQUAL DIGEST (GETHASH "sha256" METADATA))
      (ERROR "Source observation hash mismatch: ~A" FILE))
    (WHEN (AND KEY (NOT REVISION))
      (ERROR "Unknown explicit evidence revision ~S" KEY))
    (WHEN REVISION
      (UNLESS
          (EQUAL (GETHASH "revision" METADATA)
                 (DREYECK/GIT:GIT-COMMIT-HASH-OF REVISION))
        (ERROR "Source metadata and explicit revision disagree.")))
    (LET ((SOURCE
           (MAKE-INSTANCE 'MESSAGE-SOURCE :METADATA METADATA :FILE FILE :TEXT
                          (UIOP/STREAM:READ-FILE-STRING FILE) :REVISION
                          REVISION :REVISION-FILE GIT-FILE :DEFINITION
                          (OR (GETHASH "definition" METADATA)
                              (CDR
                               (ASSOC (GETHASH "role" METADATA)
                                      '(("listen"
                                         . "listen_emit / listen(event)")
                                        ("report" . "report_emit")
                                        ("run" . "run(nest, state, initiator)")
                                        ("render" . "emit")
                                        ("message" . "message_emit")
                                        ("producer"
                                         . "Ward's supplied click-handler fragment"))
                                      :TEST #'EQUAL))))))
      (WHEN GIT-FILE (DREYECK/GIT:ADD-GIT-EVIDENCE-LOCATION GIT-FILE SOURCE))
      SOURCE)))

(HYPERDOC:DEFEXAMPLE MECH-EVIDENCE-REVISION
  "Repository authority/full OID of the local Mech witness revision, with verified LISTEN/REPORT source locations."
  (SOURCE-REVISION
   (FIND "listen" (MESSAGE-SOURCE-OBSERVATIONS) :KEY
         (LAMBDA (S) (GETHASH "role" (SOURCE-METADATA S))) :TEST #'EQUAL)))

(DEFUN EVIDENCE-SOURCE (ROLE)
  (OR
   (FIND ROLE (MESSAGE-SOURCE-OBSERVATIONS) :KEY
         (LAMBDA (S) (GETHASH "role" (SOURCE-METADATA S))) :TEST #'EQUAL)
   (ERROR "No retained Mech evidence role ~S" ROLE)))

(HYPERDOC:DEFEXAMPLE HISTORICAL-SOURCE-OBSERVATIONS
  "Verified local-history excerpts, each carrying an explicit revision and file-at-commit identity."
  (LET ((INDEX (REVISION-REFERENCE-INDEX)))
    (MAP 'LIST
         (LAMBDA (METADATA) (MESSAGE-SOURCE-FROM-METADATA METADATA INDEX))
         (READ-MESSAGE-JSON
          "dreyeck/nested-actions/sources/historical-provenance.json"))))
