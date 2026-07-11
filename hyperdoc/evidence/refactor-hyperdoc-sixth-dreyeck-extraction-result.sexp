(:refactor-hyperdoc-sixth-dreyeck-extraction-result
 (:operation (!execute-sixth-low-risk-dreyeck-extraction-slice))
 (:base "8750d551")
 (:selection "491ac513")
 (:review "8750d551")
 (:moved-file
  ("hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
   "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp"))
 (:target-system :dreyeck/codex)
 (:target-directory "dreyeck/codex/")
 (:updated-live-references
  ((:file "dreyeck/codex.lisp"
    :old "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
    :new "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp")
   (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
    :old "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
    :new "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp")
   (:file "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp"
    :old "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
    :new "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp")))
 (:live-old-path-references
  (:command "git grep -n \"hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp\" -- ':!hyperdoc/evidence/*'"
   :matches nil))
 (:new-path-references
  (:command "git grep -n \"dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp\" -- ':!hyperdoc/evidence/*'"
   :matches
   ((:file "dreyeck/codex.lisp" :classification :active-dreyeck-codex-source)
    (:file "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp"
     :classification :moved-plan-self-reference)
    (:file "dreyeck/dmx/sqlite/durable-notes.lisp" :classification :active-dreyeck-dmx-source))))
 (:compatibility-shells nil)
 (:asdf-updates nil)
 (:validations
  ((:git-diff-check :passed)
   (:moved-plan-read :passed)
   (:execution-result-read :passed)
   (:old-path-reference-check :passed)
   (:new-path-reference-check :passed)
   (:hyperdoc-load :passed)
   (:dreyeck/codex-load :passed)
   (:dreyeck/dmx/sqlite-load :passed)
   (:hyperdoc/shop3-provider-boundary/tests :passed)
   (:dreyeck/codex/tests :passed)
   (:dreyeck/dmx/sqlite/tests :passed)))
 (:actions-not-performed
  ((:deletions t)
   (:bulk-migration t)
   (:pi-actions t)
   (:ssh t)
   (:sudo t)
   (:nixos-rebuild t)
   (:wifi-secret-prompt t)))
 (:next (!review-sixth-extraction-slice-after-execution)))
