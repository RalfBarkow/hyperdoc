(:shop3-plan-artifact
 (:id implement-zettel-6537-zettelkasten-file-reader)
 (:title "Implement Zettel 6537 Zettelkasten File Reader")
 (:type :shop3-plan)
 (:planner :shop3)
 (:status :closed)
 (:closed-at "2026-07-04")
 (:created-before-implementation t)
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:predecessor-plan "hyperdoc/read-zettel-6537-and-advice-taker-shop3-plan.sexp")
 (:source-context
  ((zettel-note zettel-6537)
   (authoritative-source zettel-6537-zettelkasten-file-source)
   (projection-source zettel-6537-fedwiki-projection)
   (fedwiki-page physics-not-advice)
   (configuration-variable "HYPERDOC_ZETTELKASTEN_ROOTS")
   (project hyperdoc-8470)
   (prior-project shop3-8853)))

 (:domain
  (defdomain zettelkasten-file-reader-follow-up
    ((:operator (!record-plan-artifact ?plan)
      ((repo-root "/Users/rgb/workspace/hyperdoc")
       (shop3-plan-artifact ?plan))
      ()
      ((plan-artifact-recorded ?plan)
       (plan-created-before-implementation ?plan)))

     (:operator (!define-task-topic ?id ?topic-id ?title)
      ((plan-artifact-recorded implement-zettel-6537-zettelkasten-file-reader))
      ()
      ((task-topic-defined ?id ?topic-id ?title)
       (dmx-topic-identity-stable ?topic-id)))

     (:operator (!materialize-task-topics-to-dmx-sqlite ?plan ?store)
      ((task-topic-defined implement-zettel-6537-zettelkasten-file-reader
                           implement-zettel-6537-zettelkasten-file-reader
                           "Implement Zettel 6537 Zettelkasten File Reader")
       (task-topic-defined zettel-6537-zettelkasten-file-source
                           zettel-6537-zettelkasten-file-source
                           "Zettel 6537 Zettelkasten File Source")
       (task-topic-defined zettelkasten-file-reader
                           zettelkasten-file-reader
                           "Zettelkasten File Reader")
       (task-topic-defined zettelkasten-file-source-authority
                           zettelkasten-file-source-authority
                           "Zettelkasten File Source Authority")
       (task-topic-defined zettel-6537-fedwiki-projection
                           zettel-6537-fedwiki-projection
                           "Zettel 6537 FedWiki Projection")
       (task-topic-defined zettel-6537-source-authority-reconciliation
                           zettel-6537-source-authority-reconciliation
                           "Zettel 6537 Source Authority Reconciliation"))
      ()
      ((task-topics-materialized ?plan ?store)
       (source-authority-distinction-recorded zettel-6537)))

     (:operator (!inspect-existing-zettelkasten-lookup-seams)
      ((plan-artifact-recorded implement-zettel-6537-zettelkasten-file-reader))
      ()
      ((existing-zettelkasten-root-logic-inspected
        "HYPERDOC_ZETTELKASTEN_ROOTS")))

     (:operator (!implement-direct-zettelkasten-file-reader)
      ((task-topics-materialized
        implement-zettel-6537-zettelkasten-file-reader
        dreyeck-dmx-sqlite-production-db)
       (existing-zettelkasten-root-logic-inspected
        "HYPERDOC_ZETTELKASTEN_ROOTS"))
      ()
      ((direct-zettelkasten-file-reader-implemented zettel-6537)))

     (:operator (!integrate-direct-reader-with-existing-zettel-6537-source-reader)
      ((direct-zettelkasten-file-reader-implemented zettel-6537))
      ()
      ((zettel-6537-source-reader-authority-layered
        zettel-6537-zettelkasten-file-source
        zettel-6537-fedwiki-projection)))

     (:operator (!preserve-fedwiki-reader-as-projection-reader)
      ((zettel-6537-source-reader-authority-layered
        zettel-6537-zettelkasten-file-source
        zettel-6537-fedwiki-projection))
      ()
      ((fedwiki-reader-preserved-as-projection-reader physics-not-advice)))

     (:operator (!run-zettelkasten-file-reader-smoke-tests)
      ((direct-zettelkasten-file-reader-implemented zettel-6537)
       (fedwiki-reader-preserved-as-projection-reader physics-not-advice))
      ()
      ((zettelkasten-file-reader-smoke-tests-pass t)))

     (:operator (!update-hyperdoc-documentation-projection)
      ((zettelkasten-file-reader-smoke-tests-pass t))
      ()
      ((hyperdoc-documentation-projection-updated
        "Read Zettel 6537 and Advice Taker")))

     (:operator (!commit-plan-artifact ?plan)
      ((plan-artifact-recorded ?plan))
      ()
      ((plan-artifact-committed ?plan)))

     (:operator (!close-plan-artifact ?plan)
      ((hyperdoc-documentation-projection-updated
        "Read Zettel 6537 and Advice Taker"))
      ()
      ((plan-artifact-closed ?plan))))))

 (:selected-plan
  ((!record-plan-artifact implement-zettel-6537-zettelkasten-file-reader)
   (!define-task-topic implement-zettel-6537-zettelkasten-file-reader
                       implement-zettel-6537-zettelkasten-file-reader
                       "Implement Zettel 6537 Zettelkasten File Reader")
   (!define-task-topic zettel-6537-zettelkasten-file-source
                       zettel-6537-zettelkasten-file-source
                       "Zettel 6537 Zettelkasten File Source")
   (!define-task-topic zettelkasten-file-reader
                       zettelkasten-file-reader
                       "Zettelkasten File Reader")
   (!define-task-topic zettelkasten-file-source-authority
                       zettelkasten-file-source-authority
                       "Zettelkasten File Source Authority")
   (!define-task-topic zettel-6537-fedwiki-projection
                       zettel-6537-fedwiki-projection
                       "Zettel 6537 FedWiki Projection")
   (!define-task-topic zettel-6537-source-authority-reconciliation
                       zettel-6537-source-authority-reconciliation
                       "Zettel 6537 Source Authority Reconciliation")
   (!materialize-task-topics-to-dmx-sqlite
    implement-zettel-6537-zettelkasten-file-reader
    dreyeck-dmx-sqlite-production-db)
   (!inspect-existing-zettelkasten-lookup-seams)
   (!implement-direct-zettelkasten-file-reader)
   (!integrate-direct-reader-with-existing-zettel-6537-source-reader)
   (!preserve-fedwiki-reader-as-projection-reader)
   (!run-zettelkasten-file-reader-smoke-tests)
   (!update-hyperdoc-documentation-projection)
   (!commit-plan-artifact implement-zettel-6537-zettelkasten-file-reader)
   (!close-plan-artifact implement-zettel-6537-zettelkasten-file-reader)))

 (:completion-evidence
  ((hyperdoc-commits
    ((:commit "066b2d70"
      :message "docs(hyperdoc): plan zettelkasten file reader"
      :evidence "Plan artifact and authority/projection task topics were recorded before reader implementation.")
     (:commit "bf3ea90f"
      :message "feat(dmx): add zettelkasten file reader"
      :evidence "Exported locate-zettel-note-file, read-zettelkasten-note-file, and read-zettel-6537-zettelkasten-source; added fixture-root smoke tests.")
     (:commit "86738d82"
      :message "docs(hyperdoc): document zettelkasten reader authority"
      :evidence "Updated HyperDoc page and topic constructors to distinguish Zettelkasten file authority from FedWiki projection/context.")))
   (fedwiki-commits
    ((:commit "c465c4c7"
      :message "docs(fedwiki): add zettel file reader twins"
      :evidence "Added localhost FedWiki twins for new authority/projection topics and updated the narrative/daily pages.")))
   (validation-commands
    ((:command "git diff --check"
      :status :passed)
     (:command "nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :dreyeck/dmx/sqlite/tests)' --eval '(funcall (intern \"RUN-ZETTELKASTEN-FILE-READER-TEST\" \"DREYECK.DMX.SQLITE/TESTS\"))' --eval '(format t \"zettelkasten-file-reader-ok~%\")' --eval '(funcall (intern \"RUN-SOURCE-READER-SURFACE-TEST\" \"DREYECK.DMX.SQLITE/TESTS\"))' --eval '(format t \"source-reader-surface-ok~%\")' --eval '(uiop:quit)'"
      :status :passed
      :output "zettelkasten-file-reader-ok; source-reader-surface-ok")
     (:command "nix develop -c timeout 120 sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :dreyeck/dmx/sqlite/tests)' --eval '(funcall (intern \"RUN-SOURCE-READER-TASK-TOPIC-MATERIALIZATION-TEST\" \"DREYECK.DMX.SQLITE/TESTS\"))' --eval '(format t \"source-reader-task-materialization-ok~%\")' --eval '(uiop:quit)'"
      :status :passed
      :output "source-reader-task-materialization-ok")
     (:command "tools/validate-documentation-slice.sh --page \"hyperdoc/Read Zettel 6537 and Advice Taker.html\" --topic read-zettel-6537-and-advice-taker-topic --topic implement-zettel-6537-zettelkasten-file-reader-topic --topic zettel-6537-topic --topic zettel-6537-zettelkasten-file-source-topic --topic zettelkasten-file-reader-topic --topic zettelkasten-file-source-authority-topic --topic zettel-6537-fedwiki-projection-topic --topic zettel-6537-source-authority-reconciliation-topic --topic zettel-reader-topic --topic source-reader-replay-validation-topic"
      :status :passed
      :output "DOC_SLICE_VALIDATION_OK")
     (:command "python3 -m json.tool <changed-fedwiki-pages>"
      :status :passed
      :output "fedwiki-json-ok")
     (:command "nix develop -c sbcl --no-userinit --script tools/journal-gate.lisp <changed-fedwiki-pages>"
      :status :passed
      :output "all changed FedWiki pages PASS? T")))
   (authority-boundary
    ((zettelkasten-file-reader "authoritative source for Zettel 6537")
     (fedwiki-physics-not-advice-reader
      "projection / interpretive bridge / context")
     (test-root-boundary
      "smoke tests use temporary fixture roots and do not require private Zettelkasten files")))))

 (:output-contract
  ((required-topic-ids
    ("implement-zettel-6537-zettelkasten-file-reader"
     "zettel-6537"
     "zettel-6537-zettelkasten-file-source"
     "zettelkasten-file-reader"
     "zettelkasten-file-source-authority"
     "zettel-6537-fedwiki-projection"
     "zettel-6537-source-authority-reconciliation"))
   (required-authority-relations
    (("zettel-6537" "has-authoritative-source"
      "zettel-6537-zettelkasten-file-source")
     ("zettel-6537" "has-projection"
      "zettel-6537-fedwiki-projection")
     ("physics-not-advice-source-station" "contextualizes"
      "zettel-6537")))
   (required-reader-output-fields
    (:source-identity
     :provenance
     :extracted-fragments
     :derived-topics
     :failure-state))
   (validation
    ((plan-created-before-implementation t)
     (task-topics-defined-before-reader-code t)
     (zettelkasten-roots-use "HYPERDOC_ZETTELKASTEN_ROOTS")
     (network-required nil))))))
