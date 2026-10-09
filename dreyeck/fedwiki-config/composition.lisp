;;;; Inspecting Mech Package Composition

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

(DEFCLASS MECH-PROFILE NIL
          ((RECORD :INITARG :RECORD :READER PROFILE-RECORD)
           (CONTEXT :INITARG :CONTEXT :READER PROFILE-CONTEXT)))

(DEFUN INITIALIZE-PROFILES (CONTEXT)
  (LET ((OUTPUTS
         (GETHASH "profileOutputs" (RECORD-OF CONTEXT "package-evidence"))))
    (SETF (CONTEXT-PROFILES CONTEXT)
            (LOOP FOR NAME IN '("mech-upstream" "mech-discourse")
                  COLLECT (MAKE-INSTANCE 'MECH-PROFILE :CONTEXT CONTEXT :RECORD
                                         (GETHASH NAME OUTPUTS))))))

(DEFUN PROFILE-OF (CONTEXT NAME)
  (OR
   (FIND NAME (CONTEXT-PROFILES CONTEXT) :TEST #'EQUAL :KEY
         (LAMBDA (P) (GETHASH "profile" (GETHASH "mech" (PROFILE-RECORD P)))))
   (ERROR "No Mech profile ~A" NAME)))

(DEFMETHOD V:TEXT-REPRESENTATION ((PROFILE MECH-PROFILE))
  (FORMAT NIL "Mech ~A — retained built artifact"
          (GETHASH "profile" (GETHASH "mech" (PROFILE-RECORD PROFILE)))))

(V:DEFVIEW MAINTAINED-PROFILE-VIEW (PROFILE MECH-PROFILE)
           (V:HTML-VIEW :TITLE "Mech profile" :PRIORITY 0
                        (LET* ((CONTEXT (PROFILE-CONTEXT PROFILE))
                               (RECORD (PROFILE-RECORD PROFILE))
                               (COMPOSITION (CONTEXT-MECH CONTEXT)))
                          (V:HTML
                            (:P
                             "Mech source composition, a built Wiki package, isolated browser execution and activation are separate claims.")
                            (:P
                             (V:OBJECT-REF RECORD :DISPLAY
                                           "Complete profile, source and artifact identities"))
                            (:P
                             (V:OBJECT-REF
                              (MECH:SOURCE-BY-KEY COMPOSITION
                                                  "upstream:blocks")
                              :SELECT "Composition source" :DISPLAY
                              "Pinned upstream exported catalog")
                             " · "
                             (V:OBJECT-REF
                              (SOURCE-OF CONTEXT "maintained-installer")
                              :SELECT "Configuration source" :DISPLAY
                              "Committed installDiscourse contract"))
                            (:P
                             (V:OBJECT-REF
                              (SOURCE-OF CONTEXT "maintained-entry") :SELECT
                              "Configuration source" :DISPLAY
                              "Committed composition entry")
                             " · "
                             (V:OBJECT-REF
                              (SOURCE-OF CONTEXT "maintained-build") :SELECT
                              "Configuration source" :DISPLAY
                              "Module buildProfiles")
                             " · "
                             (V:OBJECT-REF
                              (SOURCE-OF CONTEXT "mech-derivation") :SELECT
                              "Configuration source" :DISPLAY
                              "Mech Nix derivation"))
                            (:P
                             (V:OBJECT-REF
                              (SOURCE-OF CONTEXT "profile-overlay") :SELECT
                              "Configuration source" :DISPLAY
                              "Build-time replacement in the unchanged base Wiki recipe"))
                            (:P
                             (V:OBJECT-REF
                              (SOURCE-OF CONTEXT "package-evidence") :SELECT
                              "Configuration source" :DISPLAY
                              "Separate Mech rebuild, Wiki rebuild and browser evidence"))
                            (:P
                             (V:OBJECT-REF
                              (MECH:RECORD-OF COMPOSITION
                                              "behavioral-equivalence.json")
                              :DISPLAY
                              "Historical full equivalence remains FAIL")
                             " · "
                             (V:OBJECT-REF
                              (MECH:RECORD-OF COMPOSITION "twins-results.json")
                              :DISPLAY
                              "Duplicate-slug ambiguity remains undecided"))
                            (:P
                             (V:OBJECT-REF
                              (MECH:READING-PAGE
                               "Reading a Maintained Mech Composition")
                              :SELECT "Content" :DISPLAY
                              "Earlier maintained-composition reading"))
                            (RETURN-LINKS CONTEXT)))))

(HYPERDOC:DEFEXAMPLE COMPOSITION-EXAMPLE
  "Inspect both actual artifact records and the owned installer; do not execute JavaScript or Nix."
  (LET ((CONTEXT (RETAINED-CONFIGURATIONS)))
    (LIST :UPSTREAM (PROFILE-OF CONTEXT "upstream") :DISCOURSE
          (PROFILE-OF CONTEXT "discourse") :INSTALLER
          (SOURCE-OF CONTEXT "maintained-installer") :ENTRY
          (SOURCE-OF CONTEXT "maintained-entry") :WIKI-REPLACEMENT
          (SOURCE-OF CONTEXT "profile-overlay") :ACCEPTANCE
          (RECORD-OF CONTEXT "package-evidence"))))
