(:artifact llm-wiki-note-8892-okf-profile-fedwiki-page-materialization-result
 :kind fedwiki-page-materialization-result
 :status recorded
 :mode result-recording

 :source-task
 (!materialize-fedwiki-page-projection-for-okf-profile
  :mode :page-json-write
  :explicit-operator-approval t)

 :fedwiki-page
 (:site-root "/Users/rgb/.wiki/wiki.ralfbarkow.ch/"
  :pages-root "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/"
  :slug "hyperdoc-fedwiki-okf-profile"
  :path "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/hyperdoc-fedwiki-okf-profile"
  :written t
  :story-item-count 7
  :journal-action-count 8)

 :git-results
 (:pages-submodule
  (:commit "7b5fc076"
   :status-after "")

  :site-superproject
  (:commit "b31eb4c"
   :status-after "m pages"))

 :boundary
 (:fedwiki-page-written t
  :okf-converter-implemented nil
  :okf-importer-implemented nil
  :okf-exporter-implemented nil
  :zkn3-source-edited nil
  :contact-db-materialization-resumed nil)

 :next
 (!inspect-fedwiki-page-projection-for-okf-profile
  :mode :read-only-validation
  :page "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/hyperdoc-fedwiki-okf-profile"))
