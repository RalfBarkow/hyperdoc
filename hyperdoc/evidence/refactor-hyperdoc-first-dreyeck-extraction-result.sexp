(:refactor-hyperdoc-first-dreyeck-extraction-result
 (:operation (!execute-first-low-risk-dreyeck-extraction-slice))
 (:source-commit "c2b42abf")
 (:selection-artifact
  "hyperdoc/evidence/refactor-hyperdoc-first-dreyeck-extraction-selection.sexp")
 (:moved-files
  ((:from "hyperdoc/contact-db-codex-next-htn.sexp"
    :to "dreyeck/codex/contact-db/contact-db-codex-next-htn.sexp"
    :class :dreyeck-owned-situated-surface
    :target-system :dreyeck/codex
    :kind :plan-artifact)
   (:from "hyperdoc/contact-db-codex-next-shop3-plan.sexp"
    :to "dreyeck/codex/contact-db/contact-db-codex-next-shop3-plan.sexp"
    :class :dreyeck-owned-situated-surface
    :target-system :dreyeck/codex
    :kind :plan-artifact)
   (:from "hyperdoc/contact-db-codex-next-prompt.md"
    :to "dreyeck/codex/contact-db/contact-db-codex-next-prompt.md"
    :class :dreyeck-owned-situated-surface
    :target-system :dreyeck/codex
    :kind :codex-handover)))
 (:content-updates
  ((:file "dreyeck/codex/contact-db/contact-db-codex-next-htn.sexp"
    :change "Updated internal artifact and prompt paths to the dreyeck/codex/contact-db location.")))
 (:compatibility-shells nil)
 (:compatibility-required-p nil)
 (:asdf-updates nil)
 (:target-system :dreyeck/codex)
 (:target-directory "dreyeck/codex/contact-db/")
 (:tests-run
  ((:git-diff-check :passed)
   (:hyperdoc-load :passed)
   (:shop3-provider-boundary-tests :passed)
   (:dreyeck-target-smoke :passed)
   (:file-presence-and-plan-smoke :passed)))
 (:invariants
  ((:hyperdoc-core-loads-without-dreyeck :passed)
   (:dreyeck-target-system-loads :passed)
   (:shop3-provider-boundary-preserved :passed)
   (:no-broad-shop3-tree t)
   (:no-pi-actions t)
   (:no-ssh t)
   (:no-sudo t)
   (:no-nixos-rebuild t)
   (:no-secret-prompts t)
   (:no-bulk-move t)
   (:no-deletions t)
   (:no-hyperdoc-core-code-moved t)
   (:no-hyperbook-core-code-moved t)
   (:no-shop3-provider-boundary-code-moved t)
   (:no-kioskbeerli-build-operator-moved t)))
 (:next
  (!review-first-extraction-slice-before-continuing)))
