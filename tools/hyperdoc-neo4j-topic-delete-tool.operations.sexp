(:tool
 (:id "HyperdocNeo4jTopicDeleteTool"
  :class-name "HyperdocNeo4jTopicDeleteTool"
  :source-file "tools/HyperdocNeo4jTopicDeleteTool.java"
  :model-kind :source-parity-operation-ir
  :scope
  (:store "offline Neo4j store"
   :not-generic-node-deleter-p t
   :intended-for "HyperDoc-owned workspace annotation cleanup"
   :supports-workspace-na-annotation-deletion-p t
   :does-not-model-low-level-graph-mutation-p t)
  :safety
  (:destructive-execution-modeled-p nil
   :generated-neo4j-mutation-code-p nil
   :inspector-execution-p nil
   :command-preview-only-p t)
  :operations
  ((:id :report-topic
    :command "report-topic"
    :java-method "runReportTopic"
    :mode :read
    :safety-classification :read-only
    :destructive-p nil
    :arguments ((:name "db-path" :kind :offline-neo4j-store-path)
                (:name "topic-id" :kind :neo4j-node-id))
    :arity 2
    :java-args-length 3
    :confirmation-token nil
    :requires-prior-plan-p nil
    :known-statuses (:reported :missing)
    :description "Reports one topic, including workspace status, topicmap memberships, ownership class, and refusal reasons."
    :warning "Read-only inspection of an offline store; not a generic graph traversal command.")
   (:id :plan-delete-topic
    :command "plan-delete-topic"
    :java-method "runPlanDeleteTopic"
    :mode :read
    :safety-classification :read-only-plan
    :destructive-p nil
    :arguments ((:name "db-path" :kind :offline-neo4j-store-path)
                (:name "topic-id" :kind :neo4j-node-id)
                (:name "workspace-topicmap-id" :kind :dmx-topicmap-id)
                (:name "expected-uri" :kind :dmx-topic-uri))
    :arity 4
    :java-args-length 5
    :confirmation-token nil
    :requires-prior-plan-p nil
    :known-statuses (:deletable :refused :missing)
    :description "Plans the hand-audited deletion closure for one supported HyperDoc workspace annotation topic."
    :warning "Planning is read-only; it refuses unsupported ownership, workspace, URI, topicmap, and relationship shapes.")
   (:id :delete-topic
    :command "delete-topic"
    :java-method "runDeleteTopic"
    :mode :write
    :safety-classification :destructive-planned-write
    :destructive-p t
    :arguments ((:name "db-path" :kind :offline-neo4j-store-path)
                (:name "topic-id" :kind :neo4j-node-id)
                (:name "workspace-topicmap-id" :kind :dmx-topicmap-id)
                (:name "expected-uri" :kind :dmx-topic-uri))
    :arity 4
    :java-args-length 5
    :confirmation-token nil
    :requires-prior-plan-p nil
    :requires-deletable-plan-p t
    :internal-preflight-plan-p t
    :known-statuses (:deleted :refused :missing)
    :description "Builds the same deletion plan internally and deletes only a deletable, closed HyperDoc annotation closure."
    :warning "Destructive offline Neo4j store mutation; this IR only models the command surface and does not execute it.")
   (:id :force-detach-delete-topic
    :command "force-detach-delete-topic"
    :java-method "runForceDetachDeleteTopic"
    :mode :emergency-write
    :safety-classification :emergency-destructive-write
    :destructive-p t
    :arguments ((:name "db-path" :kind :offline-neo4j-store-path)
                (:name "topic-id" :kind :neo4j-node-id)
                (:name "expected-uri" :kind :dmx-topic-uri)
                (:name "confirmation-token" :kind :exact-confirmation-token))
    :arity 4
    :java-args-length 5
    :confirmation-token "I_UNDERSTAND_THIS_DETACH_DELETES_PRIMARY_TOPIC_ONLY"
    :requires-prior-plan-p nil
    :known-statuses (:deleted-primary-topic-only :refused :missing)
    :description "Emergency command that detaches all relationships from the primary topic and deletes only that primary topic node."
    :warning "Emergency-only fallback; it can leave orphan association/context/composition nodes that require separate cleanup.")
   (:id :plan-force-delete-orphan-assoc-nodes
    :command "plan-force-delete-orphan-assoc-nodes"
    :java-method "runPlanForceDeleteOrphanAssocNodes"
    :mode :read
    :safety-classification :read-only-emergency-plan
    :destructive-p nil
    :arguments ((:name "db-path" :kind :offline-neo4j-store-path)
                (:name "node-id-csv" :kind :neo4j-node-id-csv))
    :arity 2
    :java-args-length 3
    :confirmation-token nil
    :requires-prior-plan-p nil
    :known-statuses (:deletable :refused)
    :description "Plans cleanup for listed orphan association-like nodes and directly attached instantiation helper nodes."
    :warning "Read-only emergency cleanup planning; only association/context/composition/instantiation target types are supported.")
   (:id :force-delete-orphan-assoc-nodes
    :command "force-delete-orphan-assoc-nodes"
    :java-method "runForceDeleteOrphanAssocNodes"
    :mode :emergency-write
    :safety-classification :emergency-destructive-write
    :destructive-p t
    :arguments ((:name "db-path" :kind :offline-neo4j-store-path)
                (:name "node-id-csv" :kind :neo4j-node-id-csv)
                (:name "confirmation-token" :kind :exact-confirmation-token))
    :arity 3
    :java-args-length 4
    :confirmation-token "I_UNDERSTAND_THIS_DELETES_LISTED_ASSOCIATION_NODES"
    :requires-prior-plan-p nil
    :requires-deletable-plan-p t
    :internal-preflight-plan-p t
    :known-statuses (:deleted-orphan-association-nodes :refused)
    :description "Emergency command that deletes listed orphan association-like nodes and incident relationships after internal planning."
    :warning "Emergency-only offline Neo4j store mutation; ordinary topics, workspaces, and topicmaps are not deletion targets.")
   (:id :report-workspace-na-candidates
    :command "report-workspace-na-candidates"
    :java-method "runReportWorkspaceNaCandidates"
    :mode :read
    :safety-classification :read-only-inventory
    :destructive-p nil
    :arguments ((:name "db-path" :kind :offline-neo4j-store-path)
                (:name "workspace-topicmap-id" :kind :dmx-topicmap-id))
    :arity 2
    :java-args-length 3
    :confirmation-token nil
    :requires-prior-plan-p nil
    :known-statuses (:reported)
    :description "Reports supported HyperDoc workspace annotation candidates whose workspace status is n/a in the selected topicmap."
    :warning "Read-only inventory for supported workspace n/a annotation deletion scenarios.")
   (:id :delete-manifest
    :command "delete-manifest"
    :java-method "runDeleteManifest"
    :mode :write
    :safety-classification :destructive-manifest-write
    :destructive-p t
    :arguments ((:name "db-path" :kind :offline-neo4j-store-path)
                (:name "manifest.tsv" :kind :manifest-tsv))
    :arity 2
    :java-args-length 3
    :confirmation-token nil
    :requires-prior-plan-p nil
    :requires-deletable-plan-p t
    :internal-preflight-plan-p t
    :known-statuses (:deleted :refused :planned :missing)
    :description "All-or-nothing manifest deletion; each row is planned before any row is deleted."
    :warning "Destructive offline Neo4j store mutation for a manifest of supported HyperDoc annotation topics."))))
