
(:artifact llm-wiki-note-8892-fedwiki-page-materialization-htn-correction :kind
 htn-correction :status recorded :detected-error
 (:symptom
  "Scan Page fetched hyperdocfedwiki-okf-profile.json while the first materialized canonical page file was hyperdoc-fedwiki-okf-profile."
  :commit-gate-symptom
  "The first attempted HTN correction artifact itself failed check-parens with an unmatched bracket or quote."
  :observed-repair-task (!repair-fedwiki-title-slug-mismatch-for-okf-profile)
  :repair-evidence
  (:page-file-was-written t :title-contained-slash t
   :fedwiki-title-link-slug-dropped-slash t :scan-page-looked-for-alias-slug
   t))
 :responsible-task
 (!materialize-fedwiki-page-projection-for-okf-profile :mode :page-json-write)
 :responsible-subtask
 (!define-fedwiki-page-identity :site "wiki.ralfbarkow.ch" :slug
  "hyperdoc-fedwiki-okf-profile" :title "HyperDoc/FedWiki OKF Profile")
 :defect
 (:missing-fedwiki-title-slug-invariant :missing-alias-strategy-before-write
  :missing-scan-page-validation-before-success
  :too-specific-profile-materialization-task)
 :rectification
 (:replace-specific-task-with-generalized-task
  (:old
   (!materialize-fedwiki-page-projection-for-okf-profile :mode
    :page-json-write)
   :new
   (!materialize-fedwiki-page-projection-for-topic :topic ?topic :mode
    :page-json-write))
  :okf-profile-is-specialization
  (!materialize-fedwiki-page-projection-for-topic :topic
   :hyperdoc-fedwiki-okf-profile :mode :page-json-write)
  :method-artifact
  "hyperdoc/fedwiki-page-projection-materialization-generic-htn.sexp")
 :new-required-subtasks
 ((!derive-fedwiki-title-slug :title ?title :result ?title-derived-slug)
  (!check-fedwiki-page-identity-invariant :declared-slug ?slug
   :title-derived-slug ?title-derived-slug)
  (!choose-fedwiki-title-slug-strategy :allowed-strategies
   (:rewrite-canonical-title-to-match-slug
    :write-alias-page-for-title-derived-slug :abort-before-write))
  (!detect-fedwiki-pages-git-boundary :site-root ?site-root :pages-root
   ?pages-root)
  (!commit-fedwiki-page-in-pages-repository :repo ?pages-root :pathspecs
   (?canonical-slug ?alias-slug))
  (!commit-site-submodule-pointer :repo ?site-root :pathspec "pages")
  (!validate-fedwiki-page-fetch-slugs :canonical-slug ?canonical-slug
   :alias-slug ?alias-slug))
 :acceptance-criteria
 (:before-json-write
  (:declared-title-derived-slug-known t
   :declared-slug-matches-title-derived-slug-or-alias-plan-exists t)
  :after-json-write
  (:canonical-page-fetchable-by-canonical-title t
   :alias-page-fetchable-if-title-spelling-differs t
   :scan-page-does-not-fetch-missing-json t)
  :git
  (:pages-submodule-commit-recorded t
   :site-superproject-pointer-commit-recorded t
   :unrelated-fedwiki-page-modifications-not-staged t)
  :boundary
  (:okf-converter-implemented nil :okf-importer-implemented nil
   :okf-exporter-implemented nil :zkn3-source-edited nil
   :contact-db-materialization-resumed nil))
 :operator-rule
 "When a downstream Scan Page or link-resolution error is detected, identify the upstream HTN task that made the invalid state reachable. Do not merely add a compensating repair task; amend the responsible method with missing preconditions, invariants, and validation subtasks."
 :next
 (!validate-fedwiki-page-materialization-htn-correction :mode :read-only
  :generic-method
  "hyperdoc/fedwiki-page-projection-materialization-generic-htn.sexp"
  :correction
  "hyperdoc/llm-wiki-note-8892-fedwiki-page-materialization-htn-correction.sexp"))
