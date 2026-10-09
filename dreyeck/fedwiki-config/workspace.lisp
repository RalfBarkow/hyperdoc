;;;; Navigating Deployment and Fork Projections

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

(DEFUN WARRANTED-PROJECTION (CONTEXT TOPICS RELATIONS)
  (TM:MAKE-TOPICMAP-PROJECTION :SOURCE CONTEXT :TOPICS
                               (LOOP FOR (ID LABEL OBJECT STATUS) IN TOPICS
                                     FOR I FROM 0
                                     DO (UNLESS
                                            (AND OBJECT (NOT (STRINGP OBJECT)))
                                          (ERROR "Missing domain object ~A"
                                                 ID))
                                     COLLECT (TM:MAKE-TOPICMAP-TOPIC :ID ID
                                                                     :TYPE
                                                                     :FEDWIKI-CONFIGURATION
                                                                     :LABEL
                                                                     LABEL
                                                                     :OBJECT
                                                                     OBJECT
                                                                     :VIEW-PROPERTIES
                                                                     (LIST :X
                                                                           (+
                                                                            30
                                                                            (*
                                                                             270
                                                                             (MOD
                                                                              I
                                                                              4)))
                                                                           :Y
                                                                           (+
                                                                            30
                                                                            (*
                                                                             140
                                                                             (FLOOR
                                                                              I
                                                                              4)))
                                                                           :VISIBLE
                                                                           T
                                                                           :EVIDENCE-STATUS
                                                                           STATUS)))
                               :ASSOCIATIONS
                               (LOOP FOR (FROM TO LABEL KIND STATUS BASIS
                                          EVIDENCE) IN RELATIONS
                                     FOR I FROM 0
                                     DO (UNLESS
                                            (AND EVIDENCE BASIS KIND STATUS)
                                          (ERROR
                                           "Unwarranted configuration relation ~A"
                                           LABEL))
                                     COLLECT (TM:MAKE-TOPICMAP-ASSOCIATION :ID
                                                                           (FORMAT
                                                                            NIL
                                                                            "fedwiki-relation-~D"
                                                                            I)
                                                                           :TYPE
                                                                           LABEL
                                                                           :FROM
                                                                           FROM
                                                                           :TO
                                                                           TO
                                                                           :PROPERTIES
                                                                           (LIST
                                                                            :RELATION-KIND
                                                                            KIND
                                                                            :EVIDENCE-STATUS
                                                                            STATUS
                                                                            :BASIS
                                                                            BASIS
                                                                            :WARRANT
                                                                            (LIST
                                                                             :STATUS
                                                                             STATUS
                                                                             :SOURCE
                                                                             EVIDENCE
                                                                             :BASIS
                                                                             BASIS))))
                               :VIEW-PROPERTIES '(:WIDTH 1180 :HEIGHT 1500)))

(DEFUN DEPLOYMENT-PROJECTION (CONTEXT)
  (LET ((TOPICS NIL) (RELATIONS NIL))
    (DOLIST (BASE (CONTEXT-BASES CONTEXT))
      (LET* ((RECORD (CONFIGURATION-RECORD BASE))
             (KEY (GETHASH "key" RECORD))
             (FLAKE (SOURCE-OF CONTEXT (GETHASH "flakeSource" RECORD)))
             (LOCK (SOURCE-OF CONTEXT (GETHASH "lockSource" RECORD))))
        (FLET ((ID (PART)
                 (CONCATENATE 'STRING KEY "-" PART)))
          (SETF TOPICS
                  (APPEND TOPICS
                          (LIST
                           (LIST (ID "configuration") (GETHASH "branch" RECORD)
                                 BASE :OBSERVED)
                           (LIST (ID "declaration")
                                 "Declared flake inputs and recipe" FLAKE
                                 :OBSERVED)
                           (LIST (ID "lock") "Resolved root input graph" LOCK
                                 :OBSERVED)
                           (LIST (ID "inputs")
                                 "Root lock nodes, not all component pins"
                                 (CONFIGURATION-INPUTS BASE) :OBSERVED)
                           (LIST (ID "client") "Selected client base revision"
                                 (CONFIGURATION-CLIENT BASE) :OBSERVED)
                           (LIST (ID "package") "Retained built Wiki package"
                                 (CONFIGURATION-PACKAGES BASE) :OBSERVED)
                           (LIST (ID "deployment")
                                 "Active server selection: unknown"
                                 (GETHASH "activeDeployment" RECORD) :OPEN))))
          (SETF RELATIONS
                  (APPEND RELATIONS
                          (LIST
                           (LIST (ID "configuration") (ID "declaration")
                                 "declares recipe" :CONFIGURATION-SOURCE
                                 :OBSERVED
                                 "Exact Git file at the observed branch commit"
                                 FLAKE)
                           (LIST (ID "declaration") (ID "lock")
                                 "has corresponding resolved input graph"
                                 :LOCK-RESOLUTION :OBSERVED
                                 "flake.nix and flake.lock are different retained source objects"
                                 LOCK)
                           (LIST (ID "lock") (ID "inputs")
                                 "records root input resolutions"
                                 :LOCK-RESOLUTION :OBSERVED
                                 "Only root-reachable input nodes; library client pins do not select P41 client"
                                 LOCK)
                           (LIST (ID "declaration") (ID "client")
                                 "selects component through its recorded mechanism"
                                 :COMPONENT-SELECTION :OBSERVED
                                 (GETHASH "selectionKind"
                                          (GETHASH "client" RECORD))
                                 (COND
                                  ((EQUAL KEY "localhost") (LIST FLAKE LOCK))
                                  ((EQUAL KEY "ralfbarkow")
                                   (LIST FLAKE
                                         (SOURCE-OF CONTEXT "p41-provenance")
                                         (SOURCE-OF CONTEXT
                                                    "p41-source-inputs")))
                                  (T FLAKE)))
                           (LIST (ID "client") (ID "package")
                                 "contributes selected source, with recorded patches/assets"
                                 :PACKAGE-COMPOSITION :DERIVED
                                 "Source selection corresponds to recorded component provenance; source and served bundle are not equated"
                                 (CONFIGURATION-PACKAGES BASE))
                           (LIST (ID "package") (ID "deployment")
                                 "does not establish activated host package"
                                 :DEPLOYMENT-BOUNDARY :OPEN
                                 "No active host observation in this slice"
                                 (GETHASH "activeDeployment" RECORD))))))))
    (PUSH
     (LIST "localhost-inputs" "localhost-client"
           "resolves selected client revision" :LOCK-RESOLUTION :OBSERVED
           "Root wiki-client-src lock node; distinct from its declared URL"
           (SOURCE-OF CONTEXT "localhost-lock"))
     RELATIONS)
    (SETF TOPICS
            (APPEND TOPICS
                    (LIST
                     (LIST "upstream-profile" "Mech upstream-only artifact"
                           (PROFILE-OF CONTEXT "upstream") :OBSERVED)
                     (LIST "discourse-profile" "Mech Discourse artifact"
                           (PROFILE-OF CONTEXT "discourse") :OBSERVED)
                     (LIST "installer" "Owned installDiscourse"
                           (SOURCE-OF CONTEXT "maintained-installer")
                           :OBSERVED)
                     (LIST "overlay" "Build-time Wiki package replacement"
                           (SOURCE-OF CONTEXT "profile-overlay") :OBSERVED)
                     (LIST "equivalence" "Full behavioral equivalence: FAIL"
                           (MECH:RECORD-OF (CONTEXT-MECH CONTEXT)
                                           "behavioral-equivalence.json")
                           :OBSERVED))))
    (DOLIST (BASE (CONTEXT-BASES CONTEXT))
      (LET ((ID
             (CONCATENATE 'STRING (GETHASH "key" (CONFIGURATION-RECORD BASE))
                          "-package")))
        (PUSH
         (LIST ID
               (IF (EQUAL "discourse"
                          (GETHASH "profile"
                                   (GETHASH "composition"
                                            (CONFIGURATION-PACKAGES BASE))))
                   "discourse-profile"
                   "upstream-profile")
               "records selected Mech composition" :PROFILE-SELECTION :OBSERVED
               "Recorded package provenance identifies final Mech; defaults remain separate"
               (CONFIGURATION-PACKAGES BASE))
         RELATIONS)))
    (SETF RELATIONS
            (APPEND RELATIONS
                    (LIST
                     (LIST "installer" "discourse-profile"
                           "registers EXTRACT EDGES DEBUG and wraps WALK"
                           :CATALOG-COMPOSITION :OBSERVED
                           "Catalog validation and unchanged ordinary WALK delegation"
                           (SOURCE-OF CONTEXT "maintained-installer"))
                     (LIST "overlay" "upstream-profile"
                           "can insert upstream artifact" :BUILD-COMPOSITION
                           :OBSERVED
                           "Explicit profile passed at build time; not runtime plugin mutation"
                           (SOURCE-OF CONTEXT "profile-overlay"))
                     (LIST "overlay" "discourse-profile"
                           "can insert composed artifact" :BUILD-COMPOSITION
                           :OBSERVED "Same overlay and unchanged base recipe"
                           (SOURCE-OF CONTEXT "profile-overlay"))
                     (LIST "discourse-profile" "equivalence"
                           "technical acceptance leaves two strict differences"
                           :ACCEPTANCE-BOUNDARY :DERIVED
                           "Technical acceptance and application equivalence are separate decisions"
                           (SOURCE-OF CONTEXT "package-evidence")))))
    (WARRANTED-PROJECTION CONTEXT TOPICS RELATIONS)))

(DEFUN FORK-PROJECTION (CONTEXT)
  (LET ((TOPICS NIL) (RELATIONS NIL))
    (DOLIST (CASE (CONTEXT-FORKS CONTEXT))
      (LET* ((RECORD (FORK-RECORD CASE))
             (KEY (GETHASH "label" RECORD))
             (BASE (CONFIGURATION-OF CONTEXT KEY))
             (ADAPTER
              (SOURCE-OF CONTEXT (CONCATENATE 'STRING KEY "-siteAdapter")))
             (PUT (SOURCE-OF CONTEXT (CONCATENATE 'STRING KEY "-pageHandler")))
             (ACCESS
              (FORK-STEP CASE
                         "local source reachability from destination origin"))
             (PROVENANCE
              (FORK-STEP CASE
                         "loopback source provenance from preloaded snapshot"))
             (WRITE
              (FORK-STEP CASE
                         "authorized remote write with correct non-loopback fork provenance"))
             (ORIGIN
              (LIST :URL (GETHASH "origin" RECORD) :ROLE
                    :DESTINATION-ORIGIN-BROWSER :SCOPE :ISOLATED-FIXTURE)))
        (FLET ((ID (PART)
                 (CONCATENATE 'STRING KEY "-" PART)))
          (SETF TOPICS
                  (APPEND TOPICS
                          (LIST
                           (LIST (ID "configuration") "Selected configuration"
                                 BASE :OBSERVED)
                           (LIST (ID "origin") "Destination-origin browser"
                                 ORIGIN :OBSERVED)
                           (LIST (ID "adapter") "Client acquisition operation"
                                 ADAPTER :OBSERVED)
                           (LIST (ID "access")
                                 "Observed localhost access outcome" ACCESS
                                 :OBSERVED)
                           (LIST (ID "put")
                                 "Client fork snapshot / put operation" PUT
                                 :OBSERVED)
                           (LIST (ID "write") "Authenticated same-origin write"
                                 WRITE :OBSERVED)
                           (LIST (ID "provenance")
                                 "Loopback journal site outcome" PROVENANCE
                                 :OBSERVED)
                           (LIST (ID "case")
                                 "Requests, writes and fixture boundaries" CASE
                                 :OBSERVED))))
          (SETF RELATIONS
                  (APPEND RELATIONS
                          (LIST
                           (LIST (ID "configuration") (ID "adapter")
                                 "selects corresponding source authority"
                                 :COMPONENT-SOURCE :OBSERVED
                                 "Dreyeck served prebuilt bundle is recorded separately; P41 personal source matches package input"
                                 ADAPTER)
                           (LIST (ID "origin") (ID "adapter")
                                 "invokes wiki.site(site).get in fixture"
                                 :CLIENT-INVOCATION :OBSERVED
                                 "Trusted destination-origin execution; source fulfilled by route"
                                 (SOURCE-OF CONTEXT "fork-harness"))
                           (LIST (ID "adapter") (ID "access")
                                 "compared with observed acquisition"
                                 :SOURCE-EXECUTION-COMPARISON :DERIVED
                                 "Source and actual served bundle digests remain separately recorded"
                                 RECORD)
                           (LIST (ID "put") (ID "write")
                                 "sends forkPage snapshot through origin.put"
                                 :FORK-WRITE :DERIVED
                                 "Actual authenticated fork UI/wire/server acceptance is retained; production auth not tested"
                                 WRITE)
                           (LIST (ID "write") (ID "provenance")
                                 "does not determine loopback site retention"
                                 :PROVENANCE-BOUNDARY :DERIVED
                                 "Non-loopback write control and loopback provenance are independent cases"
                                 RECORD)
                           (LIST (ID "put") (ID "provenance")
                                 "compared with provenance transformation"
                                 :SOURCE-EXECUTION-COMPARISON :DERIVED
                                 "No attribution to an unobserved user operation"
                                 PROVENANCE)
                           (LIST (ID "case") (ID "access")
                                 "records access separately from write"
                                 :TEST-EVIDENCE :OBSERVED
                                 "One exact case with its own served-client digest"
                                 ACCESS)
                           (LIST (ID "case") (ID "provenance")
                                 "records journal source separately"
                                 :TEST-EVIDENCE :OBSERVED
                                 "Loopback snapshot control is not ordinary acquisition when blocked"
                                 PROVENANCE)))))))
    (DOLIST (CASE (CONTEXT-FORKS CONTEXT))
      (LET* ((RECORD (FORK-RECORD CASE))
             (KEY (GETHASH "label" RECORD))
             (ACCESS (CONCATENATE 'STRING KEY "-access"))
             (PUT (CONCATENATE 'STRING KEY "-put")))
        (PUSH
         (LIST ACCESS PUT "preloaded snapshot is separate from acquisition"
               :CONTROLLED-INPUT-BOUNDARY :DERIVED
               "Harness supplies the trusted raw fixture explicitly; matching values do not establish JavaScript object identity"
               (LIST (SOURCE-OF CONTEXT "fork-harness") RECORD))
         RELATIONS)
        (WHEN (MEMBER KEY '("localhost" "ralfbarkow") :TEST #'EQUAL)
          (LET* ((POLICY
                  (SOURCE-OF CONTEXT
                             (CONCATENATE 'STRING KEY "-networkSecurity")))
                 (ID (CONCATENATE 'STRING KEY "-policy")))
            (PUSH
             (LIST ID "Loopback origin / provenance predicates" POLICY
                   :OBSERVED)
             TOPICS)
            (PUSH
             (LIST PUT ID "calls loopback provenance predicate" :SOURCE-CALL
                   :OBSERVED
                   "The retained pageHandler source calls shouldStripLoopbackProvenance"
                   (SOURCE-OF CONTEXT
                              (CONCATENATE 'STRING KEY "-pageHandler")))
             RELATIONS)
            (PUSH
             (LIST ID (CONCATENATE 'STRING KEY "-provenance")
                   "compared with observed site stripping"
                   :SOURCE-EXECUTION-COMPARISON :DERIVED
                   "Separate source and served-bundle identities; this is the controlled fixture, not a user-operation diagnosis"
                   (LIST POLICY RECORD))
             RELATIONS)
            (WHEN (EQUAL KEY "ralfbarkow")
              (PUSH
               (LIST (CONCATENATE 'STRING KEY "-adapter") ID
                     "calls public-to-loopback blocking predicate" :SOURCE-CALL
                     :OBSERVED
                     "The personal adapter checks shouldBlockLoopbackTarget before acquisition"
                     (SOURCE-OF CONTEXT "ralfbarkow-siteAdapter"))
               RELATIONS))))))
    (WARRANTED-PROJECTION CONTEXT TOPICS RELATIONS)))

(DEFUN READING-WORKSPACE
       (&OPTIONAL (CONTEXT (RETAINED-CONFIGURATIONS)) (MODE :DEPLOYMENT))
  (TM:MAKE-TOPICMAP-WORKSPACE
   (ECASE MODE
     (:DEPLOYMENT (DEPLOYMENT-PROJECTION CONTEXT))
     (:FORK (FORK-PROJECTION CONTEXT)))
   "localhost-configuration"))

(DEFUN SWITCH-PROJECTION (WORKSPACE MODE)
  (LET ((CONTEXT
         (TM:TOPICMAP-PROJECTION-SOURCE-OF
          (TM:TOPICMAP-WORKSPACE-PROJECTION-OF WORKSPACE))))
    (TM:TOPICMAP-WORKSPACE-REPROJECT WORKSPACE
                                     (ECASE MODE
                                       (:DEPLOYMENT
                                        (DEPLOYMENT-PROJECTION CONTEXT))
                                       (:FORK (FORK-PROJECTION CONTEXT))))
    WORKSPACE))

(HYPERDOC:DEFEXAMPLE CONFIGURATION-WORKSPACE
  (READING-WORKSPACE))

(HYPERDOC:DEFEXAMPLE FORK-WORKSPACE
  (READING-WORKSPACE (RETAINED-CONFIGURATIONS) :FORK))

(HYPERDOC:DEFEXAMPLE LAYOUT-EXAMPLE
  "TALA changes layout only; it does not resolve source identity or activate a deployment."
  (LAYOUT:COMPARE-WORKSPACE-LAYOUTS (READING-WORKSPACE) :SEED 44))

(DREYECK/HYPERDOC:DEFHYPERDOC *READING* :TITLE
                              "Reading FedWiki Configuration and Fork Behavior"
                              :ID "dreyeck/fedwiki-config/reading"
                              :ASDF-SYSTEM-NAME
                              "dreyeck/fedwiki-config/reading" :SUBDIRECTORY
                              "dreyeck/pages/fedwiki-config" :CODE-SUBDIRECTORY
                              "dreyeck/fedwiki-config" :MAIN-PAGE-ID
                              "Reading FedWiki Configuration and Fork Behavior")
