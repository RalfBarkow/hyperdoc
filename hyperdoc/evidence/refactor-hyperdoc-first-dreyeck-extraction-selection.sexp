(:refactor-hyperdoc-first-dreyeck-extraction-selection
 (:from-plan "hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp")
 (:source-commit "c2b42abf")
 (:selected-task (!execute-first-low-risk-dreyeck-extraction-slice))
 (:candidate-group :codex-belongs-to-dreyeck-artifacts)
 (:candidate-files
  ((:path "hyperdoc/contact-db-codex-next-htn.sexp"
    :kind :plan-artifact
    :class :dreyeck-owned-situated-surface)
   (:path "hyperdoc/contact-db-codex-next-shop3-plan.sexp"
    :kind :plan-artifact
    :class :dreyeck-owned-situated-surface)
   (:path "hyperdoc/contact-db-codex-next-prompt.md"
    :kind :codex-handover
    :class :dreyeck-owned-situated-surface)))
 (:selected-files
  ((:from "hyperdoc/contact-db-codex-next-htn.sexp"
    :to "dreyeck/codex/contact-db/contact-db-codex-next-htn.sexp")
   (:from "hyperdoc/contact-db-codex-next-shop3-plan.sexp"
    :to "dreyeck/codex/contact-db/contact-db-codex-next-shop3-plan.sexp")
   (:from "hyperdoc/contact-db-codex-next-prompt.md"
    :to "dreyeck/codex/contact-db/contact-db-codex-next-prompt.md")))
 (:target-system :dreyeck/codex)
 (:target-directory "dreyeck/codex/contact-db/")
 (:why-low-risk
  ((:classified :dreyeck-owned-situated-surface)
   (:not-manual-review t)
   (:not-necessary-local-core-delta t)
   (:data-only t)
   (:not-asdf-components t)
   (:no-hyperdoc-core-load-dependency t)
   (:no-hyperbook-core-load-dependency t)
   (:coherent-group "Contact DB Codex continuation HTN, selected SHOP3 plan, and handoff prompt.")))
 (:inbound-hyperdoc-core-references
  ((:command "rg -n \"contact-db-codex-next|Contact DB|contact-db|Codex next\" .")
   (:result
    (:references-outside-selected-files
     ("hyperdoc/design-hyperdoc-contact-db-topic-and-fedwiki-page-plan.sexp"
      "hyperdoc/llm-wiki-note-8892-*.sexp"
      "hyperdoc/fedwiki-page-projection-materialization-generic-htn.sexp")
     :classification "contextual Contact DB mentions only; no HyperDoc, HyperBook, or ASDF component requires these selected old paths"))))
 (:compatibility-required-p nil)
 (:asdf-updates-required-p nil)
 (:validation-plan
  ((:git-diff-check t)
   (:hyperdoc-load t)
   (:shop3-provider-boundary-tests t)
   (:dreyeck-target-system-load :dreyeck/codex)
   (:file-presence-and-plan-smoke t)))
 (:forbidden-actions
  ((:bulk-move nil)
   (:deletions nil)
   (:move-hyperdoc-core-code nil)
   (:move-hyperbook-core-code nil)
   (:move-shop3-provider-boundary-code nil)
   (:move-kioskbeerli-build-operator nil)
   (:pi-actions nil)
   (:ssh nil)
   (:sudo nil)
   (:nixos-rebuild nil)
   (:wifi-secret-prompt nil))))
