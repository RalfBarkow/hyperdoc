(:schema-version 1
 :relation-overrides
 ((:id "layout/page-lookup/repair-after-overview"
   :title "Repair follows overview"
   :summary "Repair remains a secondary pane after Overview."
   :layer :layout
   :subject :repair-pane
   :predicate :after
   :object :overview-pane))
 :findings
 ("This repo-native source file is the narrow mutation target for the page-lookup authored relation artifact."
  "Only the explicit layout relation override is persisted here in this slice."))
