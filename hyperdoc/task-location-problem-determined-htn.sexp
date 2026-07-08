(:task
 (!integrate-problem-determined-systems-into-htn
  :source-zettel 6129
  :task-location-zettel 8992
  :definition "48.2 Problem: A task that cannot be solved by existing routines of behavior, action, or interaction."))

(:operational-rule
 (:for-each-task
  (ordered
   (!localize-task-in-task-topicmap ?task)
   (:if (:localized ?task ?routine)
        (!execute-localized-routine ?task ?routine))
   (:if (:not-localized ?task)
        (ordered
         (!declare-problem-from-task ?task)
         (!form-problem-determined-system ?task)
         (!search-or-design-new-method ?task))))))

(:task-location-topicmap
 (:backend sqlite
  :path #P"/Users/rgb/workspace/hyperdoc/var/task-location.sqlite"
  :topic-types
  (dmx.task_space.concept
   dmx.task_space.definition
   dmx.task_space.task
   dmx.task_space.routine
   dmx.task_space.problem)
  :association-types
  (dmx.task_space.precedes
   dmx.task_space.uses-routine
   dmx.task_space.leads-to
   dmx.task_space.becomes-problem
   dmx.task_space.instance-of-definition)))

(:problem-48.2
 (:meaning "A problem is not every task. It is a task for which the existing routine space does not provide an adequate method.")
 (:htn-effect "The HTN opens a problem-determined system only after failed or insufficient task localization."))

(:search-policy
 (:grep-first false)
 (:first-search-space task-location-topicmap)
 (:source-search-allowed-only-after
  (:missing-topic-or-method-gap-declared true))
 (:grep-output-status raw-sensor-data))

(:next-task
 (!design-zkn3-unresolved-reference-record
  :module zk-core
  :mode :core-vocabulary-design-only
  :records (Zkn3UnresolvedReferenceRecord
            Zkn3UnresolvedReferenceKind
            Zkn3UnresolvedReferenceReason)
  :batch-field unresolvedReferences
  :source-fields (manlinks luhmann)
  :first-use-case (:manlinks :out-of-range-reference)
  :must-not-implement-record-yet t
  :must-not-change-source-reader-acceptance-yet t
  :must-not-write-to-sqlite t
  :must-not-touch-ui t))
