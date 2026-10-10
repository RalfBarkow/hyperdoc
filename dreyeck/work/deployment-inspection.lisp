;;;; Reading Deployment Evidence Through Objects

(DEFPACKAGE #:DREYECK/WORK/DEPLOYMENT-INSPECTION
  (:USE #:CL)
  (:LOCAL-NICKNAMES (#:V #:HTML-INSPECTOR-VIEWS)
                    (#:G #:DREYECK/GIT)
                    (#:N #:DREYECK/NESTED-ACTIONS)
                    (#:R #:DREYECK/WORK/DEPLOYMENT-READING)
                    (#:C #:DREYECK/FEDWIKI-CONFIG))
  (:EXPORT #:DEPLOYMENT-OBJECT
           #:OBJECT-KIND
           #:OBJECT-RECORD
           #:OBJECT-LINKS
           #:OBJECT-SUMMARY
           #:OBJECT-PAGE
           #:DEPLOYMENT-REVISION
           #:DEPLOYMENT-SOURCE
           #:HISTORICAL-WIKI
           #:WIKI-PACKAGE
           #:WIKI-SERVICE
           #:WIKI-SOURCE
           #:DECLARED-WIKI
           #:WIKI-BOUNDARY
           #:LATEST-HYPERDOC
           #:SERVED-PACKAGE
           #:SERVED-SERVICE
           #:SERVED-PROCESS
           #:SERVED-SELECTION
           #:SERVED-REVISION
           #:RECORDED-ACTIVATION
           #:STARTUP-CONFIRMATION
           #:EARLIER-HYPERDOC
           #:HYPERDOC-BOUNDARY
           #:ASSETS-IDENTITY
           #:SOURCE-OBJECT))

(IN-PACKAGE #:DREYECK/WORK/DEPLOYMENT-INSPECTION)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "wiki.ralfbarkow.ch deployment" :HYPERBOOK
                 "dreyeck/work/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "dreyeck.ch deployment" :HYPERBOOK "dreyeck/work/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Work Breakdown" :HYPERBOOK "dreyeck/work/reading"))

(DEFCLASS DEPLOYMENT-OBJECT NIL
          ((KIND :INITARG :KIND :READER OBJECT-KIND)
           (TITLE :INITARG :TITLE :READER OBJECT-TITLE)
           (SUMMARY :INITARG :SUMMARY :READER OBJECT-SUMMARY)
           (RECORD :INITARG :RECORD :READER OBJECT-RECORD)
           (PAGE :INITARG :PAGE :READER OBJECT-PAGE)
           (LINKS :INITARG :LINKS :INITFORM NIL :ACCESSOR OBJECT-LINKS)))

(DEFCLASS DEPLOYMENT-REVISION (G:GIT-REVISION-REFERENCE)
          ((PAGE :INITARG :PAGE :READER REVISION-PAGE)))

(DEFCLASS DEPLOYMENT-SOURCE (N:MESSAGE-SOURCE)
          ((PAGE :INITARG :PAGE :READER SOURCE-PAGE)))

(DEFUN PAGE (TITLE)
  (HYPERBOOK:FIND-PAGE "dreyeck/work/reading" TITLE :SIGNAL-ERROR? T))

(DEFUN FACT (EVIDENCE ID &OPTIONAL (CATEGORY :OBSERVED))
  (OR
   (FIND ID (GETF EVIDENCE CATEGORY) :KEY (LAMBDA (X) (GETF X :ID)) :TEST
         #'EQUAL)
   (ERROR "No reported deployment fact ~A" ID)))

(DEFUN OBJECT (KIND TITLE SUMMARY RECORD PAGE &OPTIONAL LINKS)
  (MAKE-INSTANCE 'DEPLOYMENT-OBJECT :KIND KIND :TITLE TITLE :SUMMARY SUMMARY
                 :RECORD RECORD :PAGE PAGE :LINKS LINKS))

(DEFUN REVISION (AUTHORITY OID ROLE PAGE)
  (CHANGE-CLASS
   (G:MAKE-GIT-REVISION-REFERENCE :AUTHORITY AUTHORITY :OID OID :ROLE ROLE
                                  :WEB-URL
                                  (FORMAT NIL "~A/commit/~A" AUTHORITY OID))
   'DEPLOYMENT-REVISION :PAGE PAGE))

(DEFUN WIKI-SOURCE ()
  (N:SOURCE-REVISION (SOURCE-OBJECT "p41-historical-flake")))

(DEFUN SERVED-REVISION ()
  (N:SOURCE-REVISION (SOURCE-OBJECT "served-catalog-start")))

(DEFUN SOURCE-OBJECT (KEY)
  (LET* ((ROOT
          (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME "dreyeck/work/reading"
                                                "dreyeck/work/deployment-evidence/"))
         (ENTRIES
          (WITH-OPEN-FILE (IN (MERGE-PATHNAMES "manifest.json" ROOT))
            (SHASHT:READ-JSON* :STREAM IN :SINGLE-VALUE T :OBJECT-FORMAT
                               :HASH-TABLE :HASH-TABLE-TEST 'EQUAL
                               :ARRAY-FORMAT :VECTOR)))
         (METADATA
          (OR
           (FIND KEY ENTRIES :KEY (LAMBDA (X) (GETHASH "key" X)) :TEST #'EQUAL)
           (ERROR "No retained deployment definition")))
         (FILE (MERGE-PATHNAMES (GETHASH "file" METADATA) ROOT))
         (TEXT (UIOP/STREAM:READ-FILE-STRING FILE))
         (REV
          (REVISION (GETHASH "authority" METADATA) (GETHASH "oid" METADATA)
                    :RETAINED-SOURCE-EVIDENCE (GETHASH "page" METADATA)))
         (GIT-FILE (G:ENSURE-GIT-EVIDENCE-FILE REV (GETHASH "path" METADATA))))
    (UNLESS
        (EQUAL (GETHASH "sha256" METADATA)
               (DREYECK/MECH-INTAKE::FILE-DIGEST FILE))
      (ERROR "Deployment source hash mismatch"))
    (LET ((SOURCE
           (MAKE-INSTANCE 'DEPLOYMENT-SOURCE :PAGE (GETHASH "page" METADATA)
                          :METADATA METADATA :TEXT TEXT :FILE FILE :DEFINITION
                          (GETHASH "path" METADATA) :REVISION REV
                          :REVISION-FILE GIT-FILE)))
      (G:ADD-GIT-EVIDENCE-LOCATION GIT-FILE SOURCE)
      SOURCE)))

(DEFUN WIKI-PACKAGE ()
  (LET ((RAW (FIRST (GETF (R:DEPLOYMENT-EVIDENCE) :OBSERVED))))
    (OBJECT :PACKAGE "Reported P41 Wiki package"
            "This immutable Nix store path identifies the package the operator named. Its bin/wiki starts the Wiki server. The source-to-package association is supplied by the witness; this reading neither rebuilds it nor treats the path as a process or Git object."
            RAW "wiki.ralfbarkow.ch deployment"
            (LIST (CONS "Reported source revision" (WIKI-SOURCE))
                  (CONS "Historical package recipe"
                        (SOURCE-OBJECT "p41-historical-flake"))))))

(DEFUN WIKI-SERVICE ()
  (LET ((RAW (FIRST (GETF (R:DEPLOYMENT-EVIDENCE) :OBSERVED))))
    (OBJECT :SERVICE "Reported wiki.service"
            "systemd keeps the Federated Wiki server running. The operator reported this service active/running, with ExecStart selecting the reported package's bin/wiki. The capture time was not supplied; this is not a current service query."
            RAW "wiki.ralfbarkow.ch deployment"
            (LIST
             (CONS "Package selected by reported ExecStart" (WIKI-PACKAGE))))))

(DEFUN HISTORICAL-WIKI ()
  (OBJECT :OBSERVATION "Historical RalfBarkow deployment witness"
          "The operator supplied a P41 package, its reported source revision and an active Wiki service together. Introduce that relationship before inspecting the raw fields. No capture time was supplied, and no new activation is implied."
          (R:DEPLOYMENT-EVIDENCE) "wiki.ralfbarkow.ch deployment"
          (LIST (CONS "Nix package identity" (WIKI-PACKAGE))
                (CONS "Recorded service observation" (WIKI-SERVICE))
                (CONS "Reported source" (WIKI-SOURCE)))))

(DEFUN DECLARED-WIKI (KEY)
  (LET* ((CONTEXT (C:RETAINED-CONFIGURATIONS))
         (BASE (C:CONFIGURATION-OF CONTEXT KEY))
         (TITLE
          (IF (EQUAL KEY "ralfbarkow")
              "wiki.ralfbarkow.ch deployment"
              "dreyeck.ch deployment")))
    (OBJECT :DECLARATION "Newer declared Wiki package choices"
            "This repository configuration adds selectable wiki-upstream and wiki-discourse packages while preserving the previous default. It describes what can be built; publishing its commit is not evidence of host activation."
            BASE TITLE
            (LIST
             (CONS
              "Actual configuration: flake, lock, pins and package outputs"
              BASE)
             (CONS "Published consumer revision"
                   (CHANGE-CLASS (C:CONFIGURATION-REVISION BASE)
                                 'DEPLOYMENT-REVISION :PAGE TITLE))))))

(DEFUN WIKI-BOUNDARY (KEY)
  (OBJECT :BOUNDARY "Publication is separate from activation"
          "The new consumer source is published and its configuration is inspectable. No service update or new host observation was performed. The historical package remains the reported witness; which package is serving now requires separate evidence."
          (LIST :STATUS :UNRESOLVED :SOURCE-PUBLICATION :VERIFIED-ON-2026-10-10
                :ACTIVATION-OBSERVED NIL :HOST-PROBE-PERFORMED NIL
                :PUBLICATION-RECORD
                (WITH-OPEN-FILE
                    (IN
                     (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME
                      "dreyeck/work/reading"
                      "dreyeck/work/deployment-evidence/publication.json"))
                  (SHASHT:READ-JSON* :STREAM IN :SINGLE-VALUE T :OBJECT-FORMAT
                                     :HASH-TABLE :HASH-TABLE-TEST 'EQUAL)))
          (IF (EQUAL KEY "ralfbarkow")
              "wiki.ralfbarkow.ch deployment"
              "dreyeck.ch deployment")
          (LIST (CONS "New declared configuration" (DECLARED-WIKI KEY)))))

(DEFUN SERVED-PROCESS ()
  (OBJECT :PROCESS "Recorded HyperDoc SBCL process"
          "At the operator's capture time this process belonged to hyperdoc.service and loaded its startup script from an immutable store source. A PID is an observation at a time, not a permanent deployment identity. The process reported no source revision of its own."
          (FACT (R:SERVED-STATE-OBSERVATION-2026-10-08) "served-process")
          "dreyeck.ch deployment"))

(DEFUN SERVED-PACKAGE ()
  (OBJECT :PACKAGE "Recorded HyperDoc executable and source"
          "Nix supplies an executable and immutable source paths. The recorded ExecStart points to hyperdoc-catalog, whose SBCL script loads the store source. This identity is distinct from the mutable checkout and the separate site-assets copy."
          (LIST :SERVICE
                (FACT (R:SERVED-STATE-OBSERVATION-2026-10-08) "served-service")
                :STORE-SOURCE
                (FACT (R:SERVED-STATE-OBSERVATION-2026-10-08)
                      "hyperdoc-store-source"))
          "dreyeck.ch deployment"
          (LIST (CONS "Recorded Nix source selection" (SERVED-SELECTION))
                (CONS "Loaded startup definition"
                      (SOURCE-OBJECT "served-catalog-start")))))

(DEFUN SERVED-SELECTION ()
  (LET ((RAW (R:SERVED-STATE-OBSERVATION-2026-10-08)))
    (OBJECT :SELECTION "Recorded Nix source selection"
            "The host lock names a HyperDoc revision. Its narHash matches the store source, and the recorded exported-tree comparison matches that source to the commit. This is a warranted source correspondence, not a revision reported directly by the running Lisp image."
            (LIST :LOCK (FACT RAW "hyperdoc-input-lock") :STORE
                  (FACT RAW "hyperdoc-store-source") :CORRESPONDENCE
                  (FACT RAW "store-source-is-commit" :DERIVED))
            "dreyeck.ch deployment"
            (LIST
             (CONS "Repository-qualified HyperDoc revision" (SERVED-REVISION))
             (CONS "Application startup source"
                   (SOURCE-OBJECT "served-application"))))))

(DEFUN SERVED-SERVICE ()
  (LET ((RAW (R:SERVED-STATE-OBSERVATION-2026-10-08)))
    (OBJECT :SERVICE "Recorded HyperDoc and Wiki services"
            "The exact dreyeck.ch route reaches the Lisp HyperDoc application. The recorded wildcard route reaches a separate Node Wiki farm. They share a machine, not an application identity. Explicit MCP routing is another exception to the wildcard; this observation is dated, not a live route check."
            (LIST :HYPERDOC (FACT RAW "served-service") :WIKI-FARM
                  (FACT RAW "node-wiki-service") :APEX-ROUTE
                  (FACT RAW "apex-route") :WILDCARD-ROUTE
                  (FACT RAW "wildcard-route") :MCP-ROUTE
                  (FACT RAW "mcp-route"))
            "dreyeck.ch deployment"
            (LIST (CONS "Recorded SBCL process" (SERVED-PROCESS))
                  (CONS "Separate Wiki configuration"
                        (DECLARED-WIKI "dreyeck"))))))

(DEFUN ASSETS-IDENTITY ()
  (LET ((RAW (R:SERVED-STATE-OBSERVATION-2026-10-08)))
    (OBJECT :ASSETS "Recorded mutable assets copy"
            "The twelve observed files match one assets commit by content. That does not establish who copied them, when, or from which checkout. The recorded source policy refuses page-attached execution in a served runtime; it was not queried from the running image."
            (LIST :COPY (FACT RAW "served-assets-copy") :COMPARISON
                  (FACT RAW "assets-copy-content-is-commit" :DERIVED))
            "dreyeck.ch deployment"
            (LIST
             (CONS "Matching assets revision: content only"
                   (REVISION "https://github.com/RalfBarkow/assets"
                             "bdb09ff431b1750ade5be5ea15ae9d2467194f71"
                             :CONTENT-IDENTITY-NOT-COPY-PROVENANCE
                             "dreyeck.ch deployment"))
             (CONS "Retained deployed assets policy"
                   (SOURCE-OBJECT "served-assets-policy"))))))

(DEFUN LATEST-HYPERDOC ()
  (OBJECT :OBSERVATION "HyperDoc served-state observation — 8 October 2026"
          "This operator-supplied observation has capture time 2026-10-08T03:29:16Z. It separates the service, process, source selection, routing and assets. Later browser/content-comparison supplements have their own stated limitations. It is the latest supported observation in this reading, not a live view of today's server."
          (R:SERVED-STATE-OBSERVATION-2026-10-08) "dreyeck.ch deployment"
          (LIST (CONS "Applications, services and routing" (SERVED-SERVICE))
                (CONS "Nix package and source" (SERVED-PACKAGE))
                (CONS "Assets identity and provenance boundary"
                      (ASSETS-IDENTITY)))))

(DEFUN EARLIER-HYPERDOC ()
  (OBJECT :OBSERVATION "Historical checkout and service snapshot"
          "Recorded on 28 September, with that service-start time in the report; capture time for the snapshot was not supplied. ExecStart used nix develop and a relative script. Startup from the checkout commit was inferred from directory and times, not directly observed. The later store-based startup does not rewrite this earlier witness."
          (R:DEPLOYMENT-EVIDENCE) "dreyeck.ch deployment"
          (LIST
           (CONS "Observed checkout revision: not proven loaded revision"
                 (REVISION "https://github.com/RalfBarkow/hyperdoc"
                           "84ee991aa4591a873a63753b89b37737ba5f2efc"
                           :HISTORICAL-CHECKOUT-NOT-DIRECT-RUNTIME-SOURCE
                           "dreyeck.ch deployment")))))

(DEFUN STARTUP-CONFIRMATION ()
  (OBJECT :OBSERVATION "Built startup confirmation — 1 October"
          "The operator confirmed that the service starts hyperdoc-catalog. It answers the startup-program question only; exact arguments, package path and current WorkingDirectory were not supplied."
          (R:SERVICE-START-CONFIRMATION) "dreyeck.ch deployment"))

(DEFUN RECORDED-ACTIVATION ()
  (LET* ((RAW (R:DEPLOYMENT-UPDATE-OBSERVATION))
         (STEPS (GETF (FIRST (GETF RAW :OBSERVED)) :STEPS))
         (UPDATE (FIRST STEPS)))
    (OBJECT :ACTIVATION "Recorded update and activation — 3 October"
            "First the HyperDoc flake input changed. Then NixOS activation built the application, stopped the service and started it in the new configuration. Successful activation does not establish post-restart browser health, proxy state or the service's full ExecStart. These commands are recorded evidence, not buttons to run them."
            RAW "dreyeck.ch deployment"
            (LIST
             (CONS "Input before update"
                   (REVISION "https://github.com/RalfBarkow/hyperdoc"
                             (GETF UPDATE :REVISION-BEFORE)
                             :RECORDED-INPUT-BEFORE "dreyeck.ch deployment"))
             (CONS "Input after update"
                   (REVISION "https://github.com/RalfBarkow/hyperdoc"
                             (GETF UPDATE :REVISION-AFTER)
                             :RECORDED-INPUT-AFTER "dreyeck.ch deployment"))))))

(DEFUN HYPERDOC-BOUNDARY ()
  (OBJECT :BOUNDARY "What the observations leave unresolved"
          "The latest capture supports the lock/store/source correspondence at that time. It does not identify the application's current state after later source publication. Assets copy provenance, a possible second writer, and a runtime-reported revision remain unresolved. The newer Wiki consumer is a separate declaration."
          (GETF (R:SERVED-STATE-OBSERVATION-2026-10-08) :UNRESOLVED)
          "dreyeck.ch deployment"
          (LIST (CONS "Recorded source selection" (SERVED-SELECTION))
                (CONS "Unactivated Wiki declaration"
                      (DECLARED-WIKI "dreyeck")))))

(DEFUN FOOTER (TITLE)
  (V:HTML
    (:P
     (V:OBJECT-REF (PAGE TITLE) :SELECT "Content" :DISPLAY
                   "Return to deployment explanation")
     " · "
     (V:OBJECT-REF (PAGE "Work Breakdown") :SELECT "Content" :DISPLAY
                   "Work Breakdown")
     " · "
     (V:OBJECT-REF
      (C:READING-PAGE "Reading FedWiki Configuration and Fork Behavior")
      :SELECT "Content" :DISPLAY
      "Investigate client revisions, Mech profiles and fork behavior"))))

(DEFMETHOD V:TEXT-REPRESENTATION ((OBJECT DEPLOYMENT-OBJECT))
  (OBJECT-TITLE OBJECT))

(DEFUN OBJECT-VIEW-TITLE (OBJECT)
  (IF (TYPEP OBJECT 'DEPLOYMENT-REVISION)
      "Deployment revision"
      (IF (TYPEP OBJECT 'DEPLOYMENT-SOURCE)
          "Deployment source"
          (IF (TYPEP OBJECT 'DEPLOYMENT-OBJECT)
              "Deployment evidence"
              NIL))))

(V:DEFVIEW DEPLOYMENT-OBJECT-VIEW (OBJECT DEPLOYMENT-OBJECT)
           (V:HTML-VIEW :TITLE "Deployment evidence" :PRIORITY 0
                        (V:HTML
                          (:DIV :CLASS "deployment-reading" :STYLE
                           "max-width:100%;overflow-wrap:anywhere;line-height:1.55"
                           (:H3 (CL-WHO:ESC (OBJECT-TITLE OBJECT)))
                           (:P (CL-WHO:ESC (OBJECT-SUMMARY OBJECT)))
                           (:P "Kind: "
                            (CL-WHO:ESC
                             (STRING-DOWNCASE
                              (SYMBOL-NAME (OBJECT-KIND OBJECT))))
                            ". "
                            (V:OBJECT-REF (OBJECT-RECORD OBJECT) :DISPLAY
                                          "Original record or represented configuration"))
                           (DOLIST (LINK (OBJECT-LINKS OBJECT))
                             (V:HTML
                               (:P
                                (V:OBJECT-REF (CDR LINK) :SELECT
                                              (OBJECT-VIEW-TITLE (CDR LINK))
                                              :DISPLAY (CAR LINK)))))
                           (FOOTER (OBJECT-PAGE OBJECT))))))

(V:DEFVIEW DEPLOYMENT-REVISION-VIEW (REVISION DEPLOYMENT-REVISION)
           (V:HTML-VIEW :TITLE "Deployment revision" :PRIORITY 0
                        (V:HTML
                          (:DIV :CLASS "deployment-reading" :STYLE
                           "max-width:100%;overflow-wrap:anywhere;line-height:1.55"
                           (:H3 "Repository-qualified source revision")
                           (:P
                            "A repository authority and full object id identify this source. The provenance role states why it is referenced; it does not prove current activation.")
                           (:P
                            (CL-WHO:ESC
                             (G:GIT-REVISION-AUTHORITY-OF REVISION)))
                           (:P
                            (:CODE :STYLE
                             "overflow-wrap:anywhere;white-space:pre-wrap"
                             (CL-WHO:ESC (G:GIT-COMMIT-HASH-OF REVISION))))
                           (:P "Role: "
                            (CL-WHO:ESC
                             (PRIN1-TO-STRING
                              (G:GIT-REVISION-ROLE-OF REVISION))))
                           (:P
                            (:A :HREF (G:GIT-REVISION-WEB-URL-OF REVISION)
                             :TARGET "_blank" "Open canonical external commit")
                            " · "
                            (V:OBJECT-REF REVISION :SELECT "Evidence revision"
                                          :DISPLAY
                                          "Existing Git evidence and local availability views"))
                           (:P
                            "External publication and a local checkout are different resources. Git-dependent views still need an optional local repository; no checkout is attached or fetched here.")
                           (DOLIST (FILE (G:GIT-REVISION-FILES-OF REVISION))
                             (V:HTML
                               (:P
                                (V:OBJECT-REF FILE :SELECT "Evidence locations"
                                              :DISPLAY
                                              (G:GIT-FILE-PATH-OF FILE)))))
                           (FOOTER (REVISION-PAGE REVISION))))))

(V:DEFVIEW DEPLOYMENT-SOURCE-VIEW (SOURCE DEPLOYMENT-SOURCE)
           (V:HTML-VIEW :TITLE "Deployment source" :PRIORITY -1
                        (V:HTML
                          (:DIV :CLASS "deployment-reading" :STYLE
                           "max-width:100%;overflow-wrap:anywhere"
                           (:H3 (CL-WHO:ESC (N:SOURCE-DEFINITION SOURCE)))
                           (:P
                            "Retained exact source bytes. A source definition is not a query of a running process.")
                           (:P
                            (V:OBJECT-REF (N:SOURCE-REVISION SOURCE) :SELECT
                                          "Deployment revision" :DISPLAY
                                          "Revision and provenance")
                            " · "
                            (V:OBJECT-REF (N:SOURCE-REVISION-FILE SOURCE)
                                          :SELECT "Evidence locations" :DISPLAY
                                          "File and evidence locations")
                            " · "
                            (V:OBJECT-REF (N:SOURCE-METADATA SOURCE) :DISPLAY
                                          "Recorded SHA-256 and coordinates"))
                           (:PRE :STYLE
                            "white-space:pre-wrap;overflow-wrap:anywhere;max-width:100%"
                            (CL-WHO:ESC (N:SOURCE-TEXT SOURCE)))
                           (FOOTER (SOURCE-PAGE SOURCE))))))

(V:DEFVIEW N::MESSAGE-SOURCE-VIEW (SOURCE DEPLOYMENT-SOURCE)
           (V:HTML-VIEW :TITLE "Source evidence" :PRIORITY 1
                        (V:HTML
                          (:DIV :CLASS "deployment-reading" :STYLE
                           "max-width:100%;overflow-wrap:anywhere"
                           (:H3 (CL-WHO:ESC (N:SOURCE-DEFINITION SOURCE)))
                           (:P
                            "Retained exact source bytes. A source definition is not a query of a running process.")
                           (:P
                            (V:OBJECT-REF (N:SOURCE-REVISION SOURCE) :SELECT
                                          "Deployment revision" :DISPLAY
                                          "Revision and provenance")
                            " · "
                            (V:OBJECT-REF (N:SOURCE-REVISION-FILE SOURCE)
                                          :SELECT "Evidence locations" :DISPLAY
                                          "File and evidence locations")
                            " · "
                            (V:OBJECT-REF (N:SOURCE-METADATA SOURCE) :DISPLAY
                                          "Recorded SHA-256 and coordinates"))
                           (:PRE :STYLE
                            "white-space:pre-wrap;overflow-wrap:anywhere;max-width:100%"
                            (CL-WHO:ESC (N:SOURCE-TEXT SOURCE)))
                           (FOOTER (SOURCE-PAGE SOURCE))))))

(DEFMETHOD V:TEXT-REPRESENTATION ((REVISION DEPLOYMENT-REVISION))
  (FORMAT NIL "Source revision ~A" (G:GIT-REVISION-DISPLAY-ID-OF REVISION)))

(DEFMETHOD V:TEXT-REPRESENTATION ((SOURCE DEPLOYMENT-SOURCE))
  "Retained deployment source")
