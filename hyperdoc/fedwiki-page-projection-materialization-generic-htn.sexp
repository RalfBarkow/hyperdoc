
(:artifact fedwiki-page-projection-materialization-generic-htn :kind
 htn-method-refactor :status recorded :generalized-task
 (!materialize-fedwiki-page-projection-for-topic :topic ?topic :mode
  :page-json-write :site-root ?site-root :pages-root ?pages-root :page-identity
  ?page-identity :story ?story :source-authorities ?source-authorities
  :requires-explicit-operator-approval t)
 :replaces-profile-specific-task
 (!materialize-fedwiki-page-projection-for-okf-profile :mode :page-json-write)
 :specialization
 (:topic :hyperdoc-fedwiki-okf-profile :old-task
  (!materialize-fedwiki-page-projection-for-okf-profile :mode :page-json-write
   :explicit-operator-approval t)
  :new-task
  (!materialize-fedwiki-page-projection-for-topic :topic
   :hyperdoc-fedwiki-okf-profile :mode :page-json-write :site-root
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/" :pages-root
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/" :page-identity
   (:declared-slug "hyperdoc-fedwiki-okf-profile" :declared-title
    "HyperDoc FedWiki OKF Profile" :alias-title "HyperDoc/FedWiki OKF Profile")
   :source-authorities
   (:zkn3-zettel-8892 :okf-reading-result :profile-design
    :topic-materialization-design :page-projection-plan)
   :requires-explicit-operator-approval t))
 :method
 ((!record-materialization-intent :task
   (!materialize-fedwiki-page-projection-for-topic :topic ?topic :mode
    :page-json-write))
  (!derive-fedwiki-title-slug :title ?declared-title :result
   ?title-derived-slug)
  (!check-fedwiki-page-identity-invariant :declared-slug ?declared-slug
   :title-derived-slug ?title-derived-slug :on-match :continue :on-mismatch
   :repair-before-write)
  (!choose-fedwiki-title-slug-strategy :topic ?topic :declared-slug
   ?declared-slug :declared-title ?declared-title :title-derived-slug
   ?title-derived-slug :allowed-strategies
   (:rewrite-canonical-title-to-match-slug
    :write-alias-page-for-title-derived-slug :abort-before-write)
   :result
   (:canonical-slug ?canonical-slug :canonical-title ?canonical-title
    :alias-required ?alias-required :alias-slug ?alias-slug :alias-title
    ?alias-title))
  (!write-fedwiki-page-json :pages-root ?pages-root :slug ?canonical-slug
   :title ?canonical-title :story ?story :role :canonical-page)
  (!if-alias-required :alias-required ?alias-required :then
   (!write-fedwiki-page-json :pages-root ?pages-root :slug ?alias-slug :title
    ?alias-title :story ?alias-story :role :alias-page))
  (!detect-fedwiki-pages-git-boundary :site-root ?site-root :pages-root
   ?pages-root :result ?git-boundary)
  (!commit-fedwiki-page-in-pages-repository :repo ?pages-root :pathspecs
   (?canonical-slug ?alias-slug) :only-stage-topic-paths t)
  (!commit-site-submodule-pointer :repo ?site-root :pathspec "pages"
   :only-after-pages-commit t)
  (!validate-fedwiki-page-fetch-slugs :canonical-slug ?canonical-slug
   :canonical-title ?canonical-title :alias-slug ?alias-slug :alias-title
   ?alias-title :checks
   (:canonical-title-link-opens-canonical-page
    :alias-title-link-opens-alias-page :explicit-slug-opens-canonical-page
    :scan-page-does-not-fetch-missing-json))
  (!record-fedwiki-page-materialization-result :topic ?topic :include
   (:responsible-task :generalized-task :title-slug-invariant :alias-strategy
    :pages-submodule-commit :site-submodule-pointer-commit
    :scan-page-validation)))
 :preconditions
 (:explicit-operator-approval-present t :title-derived-slug-known-before-write
  t :pages-git-boundary-known-before-commit t
  :unrelated-fedwiki-page-modifications-not-staged t)
 :postconditions
 (:canonical-page-written t :alias-page-written-if-needed t
  :pages-submodule-commit-recorded t :site-submodule-pointer-commit-recorded t
  :scan-page-validation-recorded t)
 :forbidden-effects
 (:okf-converter-implemented nil :okf-importer-implemented nil
  :okf-exporter-implemented nil :zkn3-source-edited nil
  :contact-db-materialization-resumed nil))
