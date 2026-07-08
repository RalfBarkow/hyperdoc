(:artifact llm-wiki-note-8892-shop3-current-image-boundary
 :kind planner-boundary
 :status recorded

 :observed
 (:candidate-task
  (!design-hyperdoc-fedwiki-okf-profile
   :mode :concept-design-only
   :must-not-implement-converter-yet t)

  :current-image
  (:shop3-package-present nil
   :shop3-find-plans-fboundp nil
   :hyperdoc-shop3-system-known-to-asdf t
   :load-attempt-result
   (:blocked true
    :condition system-out-of-date
    :reported-system "cl-who")))

 :meaning
 "This is not evidence that no plan exists. It only says that SHOP3 is not
  presently callable as SHOP3:FIND-PLANS in the running SLY image. Plan
  discovery must therefore continue through either a clean SHOP3 process or
  HyperDoc's already-loaded plan protocol objects. Filesystem text search is
  not promoted back to primary plan discovery."

 :method-order
 ((!inspect-loaded-hyperdoc-plan-protocol)
  (!probe-shop3-route-in-fresh-sbcl)
  (!select-shop3-or-hyperdoc-native-plan-protocol)
  (!inspect-applicable-plan-or-record-plan-gap))

 :forbidden-shortcut
 (:rg-as-plan-finder nil
  :grep-as-plan-finder nil)

 :continuation
 (!select-shop3-or-hyperdoc-native-plan-protocol
  :candidate-task
  (!design-hyperdoc-fedwiki-okf-profile
   :mode :concept-design-only
   :must-not-implement-converter-yet t)
  :mode :plan-only)

 :preserved-boundary
 (:do-not-implement-okf-converter-yet t
  :do-not-resume-contact-db-materialization t
  :do-not-edit-zkn3-source t))
