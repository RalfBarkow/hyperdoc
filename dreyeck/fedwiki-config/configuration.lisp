;;;; Inspecting Declared and Resolved Wiki Sources

(DEFPACKAGE #:DREYECK/FEDWIKI-CONFIG
  (:USE #:CL)
  (:LOCAL-NICKNAMES (#:V #:HTML-INSPECTOR-VIEWS)
                    (#:N #:DREYECK/NESTED-ACTIONS)
                    (#:GIT #:DREYECK/GIT)
                    (#:TM #:DREYECK/TOPICMAP)
                    (#:MECH #:DREYECK/MECH-INTAKE)
                    (#:LAYOUT #:DREYECK/INSPECTOR/TOPICMAP/TALA))
  (:EXPORT #:RETAINED-CONFIGURATIONS
           #:CONFIGURATION-BASE
           #:CONFIGURATION-OF
           #:CONFIGURATION-RECORD
           #:CONFIGURATION-REVISION
           #:CONFIGURATION-INPUTS
           #:CONFIGURATION-CLIENT
           #:CONFIGURATION-PACKAGES
           #:CONFIGURATION-CONTEXT
           #:DEPLOYMENT-SOURCE
           #:SOURCE-OF
           #:SOURCE-CONTEXT
           #:READING-PAGE
           #:CONTEXT-MANIFEST
           #:CONTEXT-SOURCES
           #:CONTEXT-BASES
           #:CONTEXT-MECH
           #:CONTEXT-PROFILES
           #:CONTEXT-FORKS
           #:RECORD-OF
           #:REVISION-OF
           #:INSPECT-LOCALHOST-RESOLUTION
           #:COMPARE-CONFIGURATION-BASES
           #:COMPOSITION-EXAMPLE
           #:PROFILE-OF
           #:PROFILE-RECORD
           #:PROFILE-CONTEXT
           #:MECH-PROFILE
           #:FORK-CASE
           #:FORK-RECORD
           #:FORK-CONTEXT
           #:FORK-OF
           #:INSPECT-LOOPBACK-DEFINITIONS
           #:COMPARE-FORK-BEHAVIOR
           #:READING-WORKSPACE
           #:DEPLOYMENT-PROJECTION
           #:FORK-PROJECTION
           #:SWITCH-PROJECTION
           #:CONFIGURATION-WORKSPACE
           #:FORK-WORKSPACE
           #:LAYOUT-EXAMPLE))

(IN-PACKAGE #:DREYECK/FEDWIKI-CONFIG)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Reading FedWiki Configuration and Fork Behavior" :HYPERBOOK
                 "dreyeck/fedwiki-config/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "From Declared Inputs to Resolved Packages" :HYPERBOOK
                 "dreyeck/fedwiki-config/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Two Mech Profiles in One Wiki Recipe" :HYPERBOOK
                 "dreyeck/fedwiki-config/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Forking a Local Page Across Origins" :HYPERBOOK
                 "dreyeck/fedwiki-config/reading"))

(DEFUN EVIDENCE-PATH (NAME)
  (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME "dreyeck/fedwiki-config/reading"
                                        (CONCATENATE 'STRING
                                                     "dreyeck/fedwiki-config/evidence/"
                                                     NAME)))

(DEFUN READ-JSON (NAME)
  (WITH-OPEN-FILE (IN (EVIDENCE-PATH NAME) :EXTERNAL-FORMAT :UTF-8)
    (SHASHT:READ-JSON* :STREAM IN :SINGLE-VALUE T :OBJECT-FORMAT :HASH-TABLE
                       :HASH-TABLE-TEST 'EQUAL :ARRAY-FORMAT :VECTOR
                       :TRUE-VALUE T :FALSE-VALUE NIL :NULL-VALUE NIL)))

(DEFUN READING-PAGE (TITLE)
  (HYPERBOOK:FIND-PAGE "dreyeck/fedwiki-config/reading" TITLE :SIGNAL-ERROR? T))

(DEFCLASS CONFIGURATION-EVIDENCE NIL
          ((MANIFEST :INITARG :MANIFEST :READER CONTEXT-MANIFEST)
           (SOURCES :INITFORM NIL :ACCESSOR CONTEXT-SOURCES)
           (REVISIONS :INITFORM NIL :ACCESSOR CONTEXT-REVISIONS)
           (BASES :INITFORM NIL :ACCESSOR CONTEXT-BASES)
           (PROFILES :INITFORM NIL :ACCESSOR CONTEXT-PROFILES)
           (FORKS :INITFORM NIL :ACCESSOR CONTEXT-FORKS)
           (MECH :INITFORM NIL :ACCESSOR CONTEXT-MECH)))

(DEFCLASS CONFIGURATION-BASE NIL
          ((RECORD :INITARG :RECORD :READER CONFIGURATION-RECORD)
           (CONTEXT :INITARG :CONTEXT :READER CONFIGURATION-CONTEXT)
           (REVISION :INITARG :REVISION :READER CONFIGURATION-REVISION)
           (INPUTS :INITFORM NIL :ACCESSOR CONFIGURATION-INPUTS)
           (CLIENT :INITFORM NIL :ACCESSOR CONFIGURATION-CLIENT)
           (PACKAGES :INITFORM NIL :ACCESSOR CONFIGURATION-PACKAGES)))

(DEFCLASS DEPLOYMENT-SOURCE (N:MESSAGE-SOURCE)
          ((CONTEXT :INITARG :CONTEXT :READER SOURCE-CONTEXT)))

(DEFUN SOURCE-OF (CONTEXT KEY)
  (OR
   (FIND KEY (CONTEXT-SOURCES CONTEXT) :KEY
         (LAMBDA (S) (GETHASH "key" (N:SOURCE-METADATA S))) :TEST #'EQUAL)
   (ERROR "No source definition ~A" KEY)))

(DEFUN REVISION-OF (CONTEXT AUTHORITY OID &OPTIONAL (ROLE :SOURCE-EVIDENCE))
  (OR
   (CDR (ASSOC (LIST AUTHORITY OID) (CONTEXT-REVISIONS CONTEXT) :TEST #'EQUAL))
   (LET ((REVISION
          (GIT:MAKE-GIT-REVISION-REFERENCE :AUTHORITY AUTHORITY :OID OID :ROLE
                                           ROLE :WEB-URL
                                           (FORMAT NIL "~A/commit/~A" AUTHORITY
                                                   OID))))
     (PUSH (CONS (LIST AUTHORITY OID) REVISION) (CONTEXT-REVISIONS CONTEXT))
     REVISION)))

(DEFUN RECORD-OF (CONTEXT KEY)
  (DECLARE (IGNORE CONTEXT))
  (READ-JSON (CONCATENATE 'STRING KEY ".json")))

(DEFUN CONFIGURATION-OF (CONTEXT KEY)
  (OR
   (FIND KEY (CONTEXT-BASES CONTEXT) :KEY
         (LAMBDA (B) (GETHASH "key" (CONFIGURATION-RECORD B))) :TEST #'EQUAL)
   (ERROR "Unknown configuration ~A" KEY)))

(DEFUN RETAINED-CONFIGURATIONS ()
  "Construct retained source objects; no Git, Nix, browser or server operation occurs."
  (LET* ((MANIFEST (READ-JSON "manifest.json"))
         (CONTEXT (MAKE-INSTANCE 'CONFIGURATION-EVIDENCE :MANIFEST MANIFEST)))
    (LOOP FOR FILE ACROSS (GETHASH "files" MANIFEST)
          UNLESS (EQUAL
                  (MECH::FILE-DIGEST (EVIDENCE-PATH (GETHASH "file" FILE)))
                  (GETHASH "sha256" FILE))
          DO (ERROR "Retained configuration source hash mismatch: ~A"
                    (GETHASH "file" FILE)))
    (SETF (CONTEXT-SOURCES CONTEXT)
            (LOOP FOR METADATA ACROSS (GETHASH "sources" MANIFEST)
                  FOR TEXT = (UIOP/STREAM:READ-FILE-STRING
                              (EVIDENCE-PATH (GETHASH "file" METADATA)))
                  FOR EXCERPT = (SUBSEQ TEXT (GETHASH "start" METADATA)
                                        (GETHASH "end" METADATA))
                  FOR REVISION = (REVISION-OF CONTEXT
                                              (GETHASH "authority" METADATA)
                                              (GETHASH "revision" METADATA))
                  FOR FILE = (GIT:ENSURE-GIT-EVIDENCE-FILE REVISION
                                                           (GETHASH "path"
                                                                    METADATA))
                  FOR SOURCE = (MAKE-INSTANCE 'DEPLOYMENT-SOURCE :CONTEXT
                                              CONTEXT :METADATA METADATA :TEXT
                                              EXCERPT :FILE
                                              (EVIDENCE-PATH
                                               (GETHASH "file" METADATA))
                                              :DEFINITION
                                              (GETHASH "definition" METADATA)
                                              :REVISION REVISION :REVISION-FILE
                                              FILE)
                  DO (UNLESS
                         (EQUAL (MECH::TEXT-DIGEST EXCERPT)
                                (GETHASH "excerptSha256" METADATA))
                       (ERROR
                        "Configuration excerpt hash mismatch")) (GIT:ADD-GIT-EVIDENCE-LOCATION
                                                                 FILE SOURCE)
                  COLLECT SOURCE))
    (SETF (CONTEXT-BASES CONTEXT)
            (LOOP FOR RECORD ACROSS (GETHASH "bases" MANIFEST)
                  FOR BASE = (MAKE-INSTANCE 'CONFIGURATION-BASE :RECORD RECORD
                                            :CONTEXT CONTEXT :REVISION
                                            (REVISION-OF CONTEXT
                                                         (GETHASH "authority"
                                                                  RECORD)
                                                         (GETHASH "oid" RECORD)
                                                         :DECLARED-CONFIGURATION))
                  DO (SETF (CONFIGURATION-INPUTS BASE)
                             (GETHASH "lockedInputs" RECORD)
                           (CONFIGURATION-CLIENT BASE)
                             (REVISION-OF CONTEXT
                                          (GETHASH "authority"
                                                   (GETHASH "client" RECORD))
                                          (GETHASH "oid"
                                                   (GETHASH "client" RECORD))
                                          :SELECTED-CLIENT-BASE)
                           (CONFIGURATION-PACKAGES BASE)
                             (GETHASH "packageEvidence" RECORD))
                  COLLECT BASE))
    (SETF (CONTEXT-MECH CONTEXT) (MECH:RETAINED-COMPOSITION))
    (INITIALIZE-PROFILES CONTEXT)
    (INITIALIZE-FORKS CONTEXT)
    CONTEXT))

(DEFMETHOD V:TEXT-REPRESENTATION ((CONTEXT CONFIGURATION-EVIDENCE))
  "FedWiki configuration: retained declarations, packages and fork observations")

(DEFMETHOD V:TEXT-REPRESENTATION ((BASE CONFIGURATION-BASE))
  (FORMAT NIL "~A — declared Wiki configuration"
          (GETHASH "branch" (CONFIGURATION-RECORD BASE))))

(DEFMETHOD V:TEXT-REPRESENTATION ((SOURCE DEPLOYMENT-SOURCE))
  (FORMAT NIL "~A: ~A" (GETHASH "key" (N:SOURCE-METADATA SOURCE))
          (N:SOURCE-DEFINITION SOURCE)))

(DEFUN RETURN-LINKS (CONTEXT)
  (V:HTML
    (:P
     (V:OBJECT-REF CONTEXT :SELECT "Configurations" :DISPLAY
                   "All configuration objects")
     " · "
     (V:OBJECT-REF
      (READING-PAGE "Reading FedWiki Configuration and Fork Behavior") :SELECT
      "Content" :DISPLAY "Return to reading")
     " · "
     (V:OBJECT-REF (READING-WORKSPACE CONTEXT) :SELECT "Topicmap" :DISPLAY
                   "Deployment Composition Workspace"))))

(DEFUN SOURCE-VIEW (SOURCE)
  (LET ((CONTEXT (SOURCE-CONTEXT SOURCE)))
    (V:HTML
      (:H3 (CL-WHO:ESC (N:SOURCE-DEFINITION SOURCE)))
      (:P
       "Exact retained Git blob/excerpt, not a newly loaded browser definition. "
       (V:OBJECT-REF (N:SOURCE-METADATA SOURCE) :DISPLAY
                     "Coordinates, hashes and provenance"))
      (:P
       (V:OBJECT-REF (N:SOURCE-REVISION SOURCE) :SELECT "Evidence revision"
                     :DISPLAY "Repository-qualified full revision")
       " · "
       (V:OBJECT-REF (N:SOURCE-REVISION-FILE SOURCE) :SELECT
                     "Evidence locations" :DISPLAY
                     "Source file and relevant definition")
       " · "
       (V:OBJECT-REF (N:SOURCE-FILE SOURCE) :DISPLAY "Retained full file"))
      (:PRE (CL-WHO:ESC (N:SOURCE-TEXT SOURCE)))
      (RETURN-LINKS CONTEXT))))

(V:DEFVIEW CONFIGURATION-SOURCE-VIEW (SOURCE DEPLOYMENT-SOURCE)
           (V:HTML-VIEW :TITLE "Configuration source" :PRIORITY 0
                        (SOURCE-VIEW SOURCE)))

(V:DEFVIEW N::MESSAGE-SOURCE-VIEW (SOURCE DEPLOYMENT-SOURCE)
           (V:HTML-VIEW :TITLE "Source evidence" :PRIORITY 1
                        (SOURCE-VIEW SOURCE)))

(V:DEFVIEW CONFIGURATION-BASE-VIEW (BASE CONFIGURATION-BASE)
           (V:HTML-VIEW :TITLE "Configuration" :PRIORITY 0
                        (LET* ((CONTEXT (CONFIGURATION-CONTEXT BASE))
                               (RECORD (CONFIGURATION-RECORD BASE)))
                          (V:HTML
                            (:H3 (CL-WHO:ESC (GETHASH "branch" RECORD)))
                            (:P
                             "Declared package configuration; active deployment remains unknown.")
                            (:P
                             (V:OBJECT-REF (CONFIGURATION-REVISION BASE)
                                           :SELECT "Evidence revision" :DISPLAY
                                           "Configuration revision")
                             " · "
                             (V:OBJECT-REF RECORD :DISPLAY
                                           "Inputs, selected versions, plugins, outputs and boundaries"))
                            (:P
                             (V:OBJECT-REF
                              (SOURCE-OF CONTEXT
                                         (GETHASH "flakeSource" RECORD))
                              :SELECT "Configuration source" :DISPLAY
                              "flake.nix: declared recipe")
                             " · "
                             (V:OBJECT-REF
                              (SOURCE-OF CONTEXT (GETHASH "lockSource" RECORD))
                              :SELECT "Configuration source" :DISPLAY
                              "flake.lock: resolved input graph"))
                            (:P
                             (V:OBJECT-REF (GETHASH "declaredInputs" RECORD)
                                           :DISPLAY
                                           "URLs written in flake.nix")
                             " · "
                             (V:OBJECT-REF (CONFIGURATION-INPUTS BASE) :DISPLAY
                                           "Resolved root inputs"))
                            (:P
                             (V:OBJECT-REF (GETHASH "core" RECORD) :DISPLAY
                                           "Wiki core source and version")
                             " · "
                             (V:OBJECT-REF (GETHASH "availableOutputs" RECORD)
                                           :DISPLAY
                                           "All declared package outputs"))
                            (:P
                             (V:OBJECT-REF (CONFIGURATION-CLIENT BASE) :SELECT
                                           "Evidence revision" :DISPLAY
                                           "Selected client base revision")
                             " · "
                             (V:OBJECT-REF (GETHASH "client" RECORD) :DISPLAY
                                           "Client selection mechanism and patch identity")
                             " · "
                             (V:OBJECT-REF (GETHASH "server" RECORD) :DISPLAY
                                           "Server selection and versions"))
                            (LOOP FOR KEY ACROSS (GETHASH "sourceDefinitions"
                                                          (GETHASH "client"
                                                                   RECORD))
                                  DO (V:HTML
                                       (:P
                                        (V:OBJECT-REF (SOURCE-OF CONTEXT KEY)
                                                      :SELECT
                                                      "Configuration source"
                                                      :DISPLAY KEY))))
                            (LOOP FOR KEY ACROSS (GETHASH "patchSources"
                                                          RECORD)
                                  DO (V:HTML
                                       (:P
                                        (V:OBJECT-REF (SOURCE-OF CONTEXT KEY)
                                                      :SELECT
                                                      "Configuration source"
                                                      :DISPLAY KEY))))
                            (:P
                             (V:OBJECT-REF (CONFIGURATION-PACKAGES BASE)
                                           :DISPLAY
                                           "Retained built package, components and asset digests")
                             " · "
                             (V:OBJECT-REF
                              (FORK-OF CONTEXT (GETHASH "key" RECORD)) :SELECT
                              "Fork contract" :DISPLAY
                              "Corresponding isolated fork observation"))
                            (RETURN-LINKS CONTEXT)))))

(V:DEFVIEW CONFIGURATION-EVIDENCE-VIEW (CONTEXT CONFIGURATION-EVIDENCE)
           (V:HTML-VIEW :TITLE "Configurations" :PRIORITY 0
                        (V:HTML
                          (:P
                           "A Wiki package combines a server, a browser client and plugins. These are retained repository declarations and isolated execution observations, not active hosts.")
                          (DOLIST (BASE (CONTEXT-BASES CONTEXT))
                            (V:HTML
                              (:P (V:OBJECT-REF BASE :SELECT "Configuration"))))
                          (:P
                           (V:OBJECT-REF (SOURCE-OF CONTEXT "package-evidence")
                                         :SELECT "Configuration source"
                                         :DISPLAY
                                         "Recorded package acceptance")
                           " · "
                           (V:OBJECT-REF (SOURCE-OF CONTEXT "fork-evidence")
                                         :SELECT "Configuration source"
                                         :DISPLAY "Recorded fork acceptance"))
                          (:P
                           (V:OBJECT-REF
                            (GETHASH "runtimeBoundary"
                                     (CONTEXT-MANIFEST CONTEXT))
                            :DISPLAY "What has not been observed here"))
                          (RETURN-LINKS CONTEXT))))

(HYPERDOC:DEFEXAMPLE INSPECT-LOCALHOST-RESOLUTION
  "Follow actual declared URLs and resolved root inputs to source definitions, not a host query."
  (LET* ((CONTEXT (RETAINED-CONFIGURATIONS))
         (BASE (CONFIGURATION-OF CONTEXT "localhost")))
    (LIST :CONFIGURATION BASE :DECLARATION
          (SOURCE-OF CONTEXT "localhost-flake") :LOCK
          (SOURCE-OF CONTEXT "localhost-lock") :DECLARED
          (GETHASH "declaredInputs" (CONFIGURATION-RECORD BASE)) :RESOLVED
          (CONFIGURATION-INPUTS BASE) :CLIENT (CONFIGURATION-CLIENT BASE)
          :DEFINITION (SOURCE-OF CONTEXT "localhost-pageHandler"))))

(HYPERDOC:DEFEXAMPLE COMPARE-CONFIGURATION-BASES
  "Three independently selected core recipes with the same optional Mech dependency."
  (CONTEXT-BASES (RETAINED-CONFIGURATIONS)))
