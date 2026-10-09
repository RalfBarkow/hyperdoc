;;;; Inspecting Fork Access and Journal Provenance

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

(DEFCLASS FORK-CASE NIL
          ((RECORD :INITARG :RECORD :READER FORK-RECORD)
           (CONTEXT :INITARG :CONTEXT :READER FORK-CONTEXT)))

(DEFUN INITIALIZE-FORKS (CONTEXT)
  (SETF (CONTEXT-FORKS CONTEXT)
          (LOOP FOR RECORD ACROSS (GETHASH "cases"
                                           (RECORD-OF CONTEXT "fork-evidence"))
                COLLECT (MAKE-INSTANCE 'FORK-CASE :CONTEXT CONTEXT :RECORD
                                       RECORD))))

(DEFUN FORK-OF (CONTEXT KEY)
  (OR
   (FIND KEY (CONTEXT-FORKS CONTEXT) :TEST #'EQUAL :KEY
         (LAMBDA (C) (GETHASH "label" (FORK-RECORD C))))
   (ERROR "No retained fork case ~A" KEY)))

(DEFUN FORK-STEP (CASE NAME)
  (OR
   (FIND NAME (GETHASH "tests" (FORK-RECORD CASE)) :TEST #'EQUAL :KEY
         (LAMBDA (X) (GETHASH "name" X)))
   (ERROR "No fork step ~A" NAME)))

(DEFMETHOD V:TEXT-REPRESENTATION ((CASE FORK-CASE))
  (FORMAT NIL "~A — isolated fork observation"
          (GETHASH "label" (FORK-RECORD CASE))))

(V:DEFVIEW RETAINED-FORK-VIEW (CASE FORK-CASE)
           (V:HTML-VIEW :TITLE "Fork contract" :PRIORITY 0
                        (LET* ((CONTEXT (FORK-CONTEXT CASE))
                               (RECORD (FORK-RECORD CASE))
                               (LABEL (GETHASH "label" RECORD)))
                          (V:HTML
                            (:H3
                             (CL-WHO:ESC
                              (GETHASH "intendedLocalToRemoteWorkflow" RECORD)))
                            (:P
                             "The initiating browser uses the destination Wiki origin. Source localhost:3000 is a disposable browser-route fixture, not access to a user's local service. The wire write is a same-origin authenticated PUT carrying forkPage. A local-origin fork normally writes to that local origin; it does not itself select a remote destination.")
                            (:P
                             (V:OBJECT-REF RECORD :DISPLAY
                                           "Actual retained requests, writes, journal and fixture boundaries"))
                            (:P
                             (V:OBJECT-REF (SOURCE-OF CONTEXT "fork-harness")
                                           :SELECT "Configuration source"
                                           :DISPLAY
                                           "Trusted harness and exact controls")
                             " · "
                             (V:OBJECT-REF (SOURCE-OF CONTEXT "fork-evidence")
                                           :SELECT "Configuration source"
                                           :DISPLAY
                                           "Committed acceptance record"))
                            (:P
                             (V:OBJECT-REF
                              (SOURCE-OF CONTEXT
                               (CONCATENATE 'STRING LABEL "-siteAdapter"))
                              :SELECT "Configuration source" :DISPLAY
                              "Site adapter: acquisition and access checks")
                             " · "
                             (V:OBJECT-REF
                              (SOURCE-OF CONTEXT
                               (CONCATENATE 'STRING LABEL "-pageHandler"))
                              :SELECT "Configuration source" :DISPLAY
                              "Fork snapshot and provenance transformation"))
                            (WHEN
                                (MEMBER LABEL '("ralfbarkow" "localhost") :TEST
                                        #'EQUAL)
                              (V:HTML
                                (:P
                                 (V:OBJECT-REF
                                  (SOURCE-OF CONTEXT
                                   (CONCATENATE 'STRING LABEL
                                                "-networkSecurity"))
                                  :SELECT "Configuration source" :DISPLAY
                                  "Loopback predicates and origin checks"))))
                            (:P
                             "P41 definitions also match the retained patched package-input archive and the personal revision. Its upstream base is a different revision. Dreyeck retains client source separately from its prebuilt browser bundle: those source definitions are not asserted to be the exact loaded runtime. The observed asset digests identify the tested runtime separately.")
                            (:P
                             (V:OBJECT-REF
                              (GETHASH "servedClientSha256" RECORD) :DISPLAY
                              "Recorded served-client digest")
                             " · "
                             (V:OBJECT-REF (CONFIGURATION-OF CONTEXT LABEL)
                                           :SELECT "Configuration" :DISPLAY
                                           "Compare source/configuration authority"))
                            (:P
                             (V:OBJECT-REF (READING-WORKSPACE CONTEXT :FORK)
                                           :SELECT "Topicmap" :DISPLAY
                                           "Fork Behavior and Provenance Workspace"))
                            (RETURN-LINKS CONTEXT)))))

(HYPERDOC:DEFEXAMPLE INSPECT-LOOPBACK-DEFINITIONS
  "The actual locked localhost client and P41 personal source have distinct acquisition paths."
  (LET ((CONTEXT (RETAINED-CONFIGURATIONS)))
    (LIST :LOCKED-CLIENT
          (CONFIGURATION-CLIENT (CONFIGURATION-OF CONTEXT "localhost"))
          :LOCALHOST-ACQUISITION (SOURCE-OF CONTEXT "localhost-siteAdapter")
          :LOCALHOST-PROVENANCE (SOURCE-OF CONTEXT "localhost-pageHandler")
          :P41-PERSONAL-SOURCE (SOURCE-OF CONTEXT "ralfbarkow-networkSecurity")
          :P41-ACQUISITION (SOURCE-OF CONTEXT "ralfbarkow-siteAdapter")
          :P41-PATCHES (SOURCE-OF CONTEXT "p41-wiki-client"))))

(HYPERDOC:DEFEXAMPLE COMPARE-FORK-BEHAVIOR
  "Return structured historical observations; source policy alone is not a diagnosis of a user's failed operation."
  (CONTEXT-FORKS (RETAINED-CONFIGURATIONS)))
