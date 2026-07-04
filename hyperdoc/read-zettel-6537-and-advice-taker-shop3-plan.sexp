(:shop3-plan-artifact
 (:id read-zettel-6537-and-advice-taker)
 (:title "Read Zettel 6537 and Advice Taker")
 (:type :shop3-plan)
 (:planner :shop3)
 (:status :closed)
 (:created-before-implementation t)
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:production-store dreyeck-dmx-sqlite-production-db)
 (:source-context
  ((fedwiki-page physics-not-advice)
   (zettel-note zettel-6537)
   (source-note advice-taker)
   (project hyperdoc-8470)
   (prior-project shop3-8853)))

 (:domain
  (defdomain source-reader-task-decomposition
    ((:operator (!record-plan-artifact ?plan)
      ((repo-root "/Users/rgb/workspace/hyperdoc")
       (shop3-plan-artifact ?plan))
      ()
      ((plan-artifact-recorded ?plan)
       (plan-created-before-implementation ?plan)))

     (:operator (!define-task-topic ?task ?topic-id ?title)
      ((plan-artifact-recorded read-zettel-6537-and-advice-taker))
      ()
      ((task-topic-defined ?task ?topic-id ?title)
       (dmx-topic-identity-stable ?topic-id)))

     (:operator (!define-zettel-reader-task ?source ?task)
      ((task-topic-defined ?task ?topic-id ?title)
       (zettel-note ?source))
      ()
      ((reader-task-defined zettel-reader ?source ?task)
       (reader-boundary ?task :read-only)))

     (:operator (!define-fedwiki-reader-task ?source ?task)
      ((task-topic-defined ?task ?topic-id ?title)
       (fedwiki-page ?source))
      ()
      ((reader-task-defined fedwiki-page-reader ?source ?task)
       (reader-boundary ?task :local-first)
       (network-required ?task nil)))

     (:operator (!define-advice-taker-reader-task ?source ?task)
      ((task-topic-defined ?task ?topic-id ?title)
       (source-note ?source))
      ()
      ((reader-task-defined advice-taker-note-reader ?source ?task)
       (reader-output ?task source-station-evidence)))

     (:operator (!materialize-task-topics-to-dmx-sqlite ?plan ?db)
      ((plan-artifact-recorded ?plan)
       (task-topic-defined read-zettel-6537 read-zettel-6537-task
                           "Read Zettel 6537")
       (task-topic-defined read-advice-taker-note
                           read-advice-taker-note-task
                           "Read Advice Taker note")
       (task-topic-defined define-zettel-reader
                           define-zettel-reader-task
                           "Define Zettel reader")
       (task-topic-defined define-fedwiki-page-reader
                           define-fedwiki-page-reader-task
                           "Define FedWiki page reader")
       (task-topic-defined persist-reader-task-topics
                           persist-reader-task-topics-task
                           "Persist reader task topics"))
      ()
      ((dmx-sqlite-task-topics-materialized ?plan ?db)
       (sqlite-writes-idempotent ?plan ?db)))

     (:operator (!implement-zettel-reader ?task)
      ((dmx-sqlite-task-topics-materialized
        read-zettel-6537-and-advice-taker
        dreyeck-dmx-sqlite-production-db)
       (reader-task-defined zettel-reader zettel-6537 ?task))
      ()
      ((zettel-reader-defined ?task)
       (reader-output ?task inspectable-object)))

     (:operator (!implement-fedwiki-page-reader ?task)
      ((dmx-sqlite-task-topics-materialized
        read-zettel-6537-and-advice-taker
        dreyeck-dmx-sqlite-production-db)
       (reader-task-defined fedwiki-page-reader physics-not-advice ?task))
      ()
      ((fedwiki-reader-defined ?task)
       (reader-local-first ?task)
       (network-required ?task nil)
       (reader-output ?task inspectable-object)))

     (:operator (!implement-advice-taker-note-reader ?task)
      ((dmx-sqlite-task-topics-materialized
        read-zettel-6537-and-advice-taker
        dreyeck-dmx-sqlite-production-db)
       (reader-task-defined advice-taker-note-reader advice-taker ?task))
      ()
      ((advice-taker-reader-defined ?task)
       (reader-output ?task source-station-evidence)
       (reader-output ?task inspectable-object)))

     (:operator (!create-reader-surfaces ?plan)
      ((zettel-reader-defined define-zettel-reader-task)
       (fedwiki-reader-defined define-fedwiki-page-reader-task)
       (advice-taker-reader-defined read-advice-taker-note-task))
      ()
      ((reader-surfaces-created ?plan)
       (source-reader-surfaces-inspectable ?plan)))

     (:operator (!run-smoke-tests ?plan)
      ((reader-surfaces-created ?plan)
       (dmx-sqlite-task-topics-materialized
        ?plan
        dreyeck-dmx-sqlite-production-db))
      ()
      ((smoke-tests-pass ?plan)
       (network-required ?plan nil)
       (sqlite-topic-materialization-idempotent ?plan)))

     (:operator (!commit-plan-artifact ?plan)
      ((plan-artifact-recorded ?plan))
      ()
      ((plan-artifact-committed ?plan)))

     (:operator (!commit-task-topic-materialization ?plan)
      ((dmx-sqlite-task-topics-materialized
        ?plan
        dreyeck-dmx-sqlite-production-db)
       (sqlite-topic-materialization-idempotent ?plan))
      ()
      ((task-topic-materialization-committed ?plan)))

     (:operator (!commit-reader-implementation ?plan)
      ((reader-surfaces-created ?plan)
       (smoke-tests-pass ?plan))
      ()
      ((reader-implementation-committed ?plan)))

     (:operator (!commit-documentation-projection ?plan)
      ((reader-surfaces-created ?plan))
      ()
      ((documentation-projection-committed ?plan)))

     (:operator (!close-plan-artifact ?plan)
      ((plan-artifact-committed ?plan)
       (task-topic-materialization-committed ?plan)
       (reader-implementation-committed ?plan)
       (documentation-projection-committed ?plan)
       (smoke-tests-pass ?plan))
      ()
      ((plan-artifact-closed ?plan)))

     (:method (define-source-reader-task-topics ?plan)
      ((shop3-plan-artifact ?plan))
      ((!record-plan-artifact ?plan)
       (!define-task-topic read-zettel-6537
                           read-zettel-6537-task
                           "Read Zettel 6537")
       (!define-task-topic read-advice-taker-note
                           read-advice-taker-note-task
                           "Read Advice Taker note")
       (!define-task-topic define-zettel-reader
                           define-zettel-reader-task
                           "Define Zettel reader")
       (!define-task-topic define-fedwiki-page-reader
                           define-fedwiki-page-reader-task
                           "Define FedWiki page reader")
       (!define-task-topic persist-reader-task-topics
                           persist-reader-task-topics-task
                           "Persist reader task topics")))

     (:method (read-zettel-6537-and-advice-taker ?plan)
      ((shop3-plan-artifact ?plan))
      ((!record-plan-artifact ?plan)
       (!define-task-topic read-zettel-6537
                           read-zettel-6537-task
                           "Read Zettel 6537")
       (!define-task-topic read-advice-taker-note
                           read-advice-taker-note-task
                           "Read Advice Taker note")
       (!define-task-topic define-zettel-reader
                           define-zettel-reader-task
                           "Define Zettel reader")
       (!define-task-topic define-fedwiki-page-reader
                           define-fedwiki-page-reader-task
                           "Define FedWiki page reader")
       (!define-task-topic persist-reader-task-topics
                           persist-reader-task-topics-task
                           "Persist reader task topics")
       (!define-zettel-reader-task zettel-6537
                                   define-zettel-reader-task)
       (!define-fedwiki-reader-task physics-not-advice
                                    define-fedwiki-page-reader-task)
       (!define-advice-taker-reader-task advice-taker
                                         read-advice-taker-note-task)
       (!materialize-task-topics-to-dmx-sqlite
        ?plan
        dreyeck-dmx-sqlite-production-db)
       (!implement-zettel-reader define-zettel-reader-task)
       (!implement-fedwiki-page-reader define-fedwiki-page-reader-task)
       (!implement-advice-taker-note-reader read-advice-taker-note-task)
       (!create-reader-surfaces ?plan)
       (!run-smoke-tests ?plan)
       (!commit-plan-artifact ?plan)
       (!commit-task-topic-materialization ?plan)
       (!commit-reader-implementation ?plan)
       (!commit-documentation-projection ?plan)
       (!close-plan-artifact ?plan))))))

 (:problem
  (defproblem read-zettel-6537-and-advice-taker-problem
    source-reader-task-decomposition
    ((shop3-plan-artifact read-zettel-6537-and-advice-taker)
     (repo-root "/Users/rgb/workspace/hyperdoc")
     (production-store dreyeck-dmx-sqlite-production-db)
     (fedwiki-page physics-not-advice)
     (zettel-note zettel-6537)
     (source-note advice-taker)
     (project hyperdoc-8470)
     (prior-project shop3-8853))
    ((read-zettel-6537-and-advice-taker
      read-zettel-6537-and-advice-taker))))

 (:selected-plan
  ((!record-plan-artifact read-zettel-6537-and-advice-taker)
   (!define-task-topic read-zettel-6537
                       read-zettel-6537-task
                       "Read Zettel 6537")
   (!define-task-topic read-advice-taker-note
                       read-advice-taker-note-task
                       "Read Advice Taker note")
   (!define-task-topic define-zettel-reader
                       define-zettel-reader-task
                       "Define Zettel reader")
   (!define-task-topic define-fedwiki-page-reader
                       define-fedwiki-page-reader-task
                       "Define FedWiki page reader")
   (!define-task-topic persist-reader-task-topics
                       persist-reader-task-topics-task
                       "Persist reader task topics")
   (!define-zettel-reader-task zettel-6537
                               define-zettel-reader-task)
   (!define-fedwiki-reader-task physics-not-advice
                                define-fedwiki-page-reader-task)
   (!define-advice-taker-reader-task advice-taker
                                     read-advice-taker-note-task)
   (!materialize-task-topics-to-dmx-sqlite
    read-zettel-6537-and-advice-taker
    dreyeck-dmx-sqlite-production-db)
   (!implement-zettel-reader define-zettel-reader-task)
   (!implement-fedwiki-page-reader define-fedwiki-page-reader-task)
   (!implement-advice-taker-note-reader read-advice-taker-note-task)
   (!create-reader-surfaces read-zettel-6537-and-advice-taker)
   (!run-smoke-tests read-zettel-6537-and-advice-taker)
   (!commit-plan-artifact read-zettel-6537-and-advice-taker)
   (!commit-task-topic-materialization read-zettel-6537-and-advice-taker)
   (!commit-reader-implementation read-zettel-6537-and-advice-taker)
   (!commit-documentation-projection read-zettel-6537-and-advice-taker)
   (!close-plan-artifact read-zettel-6537-and-advice-taker)))

 (:completion-evidence
  ((hyperdoc-commits
    ((:commit "24977fdc" :role :plan-artifact)
     (:commit "c57c9e3c" :role :zettel-terminology-correction)
     (:commit "392a2424" :role :dmx-sqlite-task-topic-materialization)
     (:commit "923b7b2e" :role :zettel-note-predicate-correction)
     (:commit "2794b950" :role :local-source-reader-surfaces)
     (:commit "810091fa" :role :hyperdoc-documentation-projection)))
   (fedwiki-pages-commit
    (:repo "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages"
     :commit "c0e241e3"
     :role :fedwiki-topic-twins-and-daily-anchor))
   (fedwiki-pages-repair-commit
    (:repo "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages"
     :commit "116a2479"
     :role :fedwiki-narrative-twin-link-repair))
   (validation
    ((:command "git diff --check" :status :passed)
     (:command "nix develop -c sbcl ... RUN-SOURCE-READER-SURFACE-TEST"
      :status :passed)
     (:command "nix develop -c sbcl ... RUN-SOURCE-READER-TASK-TOPIC-MATERIALIZATION-TEST"
      :status :passed)
     (:command "tools/validate-documentation-slice.sh --page \"hyperdoc/Read Zettel 6537 and Advice Taker.html\" ..."
      :status :passed)
     (:command "python3 -m json.tool <new-fedwiki-page>"
      :status :passed)
     (:command "nix develop -c sbcl --script tools/journal-gate.lisp <new-fedwiki-pages>"
      :status :passed)))))

 (:output-contract
  ((required-topic-ids
    ("read-zettel-6537-and-advice-taker"
     "source-reader-task-decomposition"
     "zettel-reader"
     "fedwiki-page-reader"
     "advice-taker-note-reader"
     "zettel-6537-source-station"
     "physics-not-advice-source-station"
     "advice-taker-source-station"
     "explicit-task-decomposition-topic"
     "shop3-plan-as-topic"
     "dmx-sqlite-task-topic-store"
     "read-zettel-6537-task"
     "read-advice-taker-note-task"
     "define-zettel-reader-task"
     "define-fedwiki-page-reader-task"
     "persist-reader-task-topics-task"))
   (required-reader-output-fields
    (:source-identity
     :provenance
     :extracted-fragments
     :derived-topics
     :failure-state))
   (validation
    ((shop3-plan-artifact-exists t)
     (plan-created-before-implementation t)
     (task-topics-materialized-in-sqlite t)
     (zettel-reader-defined t)
     (fedwiki-reader-defined t)
     (advice-taker-reader-defined t)
     (reader-surfaces-inspectable t)
     (network-required nil)
     (smoke-tests-pass t))))))
