(:artifact llm-wiki-note-8892-okf-profile-plan-protocol-selection
 :kind planner-protocol-selection
 :status recorded

 :candidate-task
 (!design-hyperdoc-fedwiki-okf-profile
  :mode :concept-design-only
  :must-not-implement-converter-yet t)

 :observed
 (:shop3-current-image
  (:package-present nil
   :find-plans-fboundp nil)

  :hyperdoc-native-plan-protocol
  (:decision :use-hyperdoc-native-plan-protocol
   :available-functions
   (critical-reading-plan
    critical-reading-report
    build-hyperdoc-authoring-plan
    asdf-find-system-topic
    asdf-definition-discovery
    asdf-system-topic
    asdf-traverse-plan-semantics-topic
    %fedwiki-attached-asdf-system-lookup-trace)

   :available-plan-values
   (*critical-reading-selected-plan*
    *executable-dita-pddl-domain*
    *localhost-fedwiki-page-promotion-plan-specs*)))

 :source-authorities
 ((:local-shop3
   :path "/Users/rgb/workspace/shop3/shop3/shop3.asd"
   :role :shop3-asdf-authority)

  (:vendored-hyperdoc-shop3
   :path "/Users/rgb/workspace/hyperdoc/.flake-deps/shop3/shop3.asd"
   :role :hyperdoc-nix-flake-shop3-authority)

  (:fedwiki-llm-wiki-paper
   :path "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/documents-as-a-maintained-wiki/llm-wiki-paper-hyperdoc/llm-wiki-paper-hyperdoc.asd"
   :role :fedwiki-page-attached-llm-wiki-authority)

  (:fedwiki-symbolic-regression
   :path "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/symbolic-regression/symbolic-regression.asd"
   :role :fedwiki-page-attached-shop3-pddl-precedent)

  (:fedwiki-ai-planning-competition
   :path "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/the-1998-ai-planning-systems-competition.asd"
   :role :fedwiki-page-attached-planning-precedent))

 :meaning
 "SHOP3 remains a source authority and future execution route, but the current
  SLY image does not expose SHOP3:FIND-PLANS. For this slice, the applicable
  route is to construct the OKF profile design as a HyperDoc-native plan
  artifact, using the loaded critical-reading plan, Executable DITA/PDDL
  domain model, and FedWiki page-attached ASDF source-authority protocol."

 :forbidden-shortcut
 (:rg-as-primary-plan-finder nil
  :grep-as-primary-plan-finder nil)

 :next
 (!construct-okf-profile-design-plan-as-hyperdoc-native-plan
  :mode :concept-design-only
  :must-not-implement-converter-yet t
  :basis
  (:critical-reading-plan
   :executable-dita-pddl-domain
   :fedwiki-attached-asdf-source-authority)))
