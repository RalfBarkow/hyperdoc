(:artifact llm-wiki-note-8892-shop3-plan-location-discipline
 :kind htn-correction
 :status recorded

 :problem
 "The OKF/FedWiki profile localization step drifted back to text search
  with rg/grep. In this project, locating a task or plan means using the
  HTN/SHOP3 planning layer first. Text search is only a fallback evidence
  operation after the planning route has been checked or after a known plan
  asks for source anchors."

 :corrected-method
 (:name locate-existing-plan-with-shop3-before-source-search
  :task
  (!locate-okf-profile-design-plan-with-shop3
   :candidate-task
   (!design-hyperdoc-fedwiki-okf-profile
    :mode :concept-design-only
    :must-not-implement-converter-yet t)
   :mode :plan-only)

  :subtasks
  ((!check-shop3-available)
   (!load-or-late-bind-shop3-domain-and-problem)
   (!ask-shop3-find-plans
    :task
    (!design-hyperdoc-fedwiki-okf-profile
     :mode :concept-design-only
     :must-not-implement-converter-yet t)
    :which :first
    :plan-tree t)
   (!inspect-shop3-plan-result)
   (!select-existing-plan-or-record-plan-gap)))

 :forbidden-primary-methods
 (:rg-as-plan-finder nil
  :grep-as-plan-finder nil
  :ad-hoc-filesystem-search-as-plan-location nil)

 :allowed-secondary-methods
 (:rg-or-grep
  (:allowed-after (:shop3-route-checked t)
   :allowed-for (:source-anchor-discovery :validation-evidence :known-plan-file-location)
   :not-allowed-for (:deciding-no-plan-exists :replacing-shop3-plan-location)))

 :continuation
 (!locate-okf-profile-design-plan-with-shop3
  :candidate-task
  (!design-hyperdoc-fedwiki-okf-profile
   :mode :concept-design-only
   :must-not-implement-converter-yet t)
  :mode :plan-only
  :then
  (!inspect-applicable-plan-or-record-gap))

 :preserved-boundary
 (:do-not-implement-okf-converter-yet t
  :do-not-resume-contact-db-materialization t
  :do-not-edit-zkn3-source t))
