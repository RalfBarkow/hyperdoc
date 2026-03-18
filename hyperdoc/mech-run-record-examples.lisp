(in-package :hyperdoc)

(defexample mech-run-record-story-neighborhood-example
  "Return an inspectable illustrative run ledger for a story-neighborhood script."
  (let* ((ledger
           (list
            :run-kind :story-neighborhood
            :script '("WALK 3 clicks"
                      "PRINT draft"
                      "PREVIEW synopsis items")
            :chronology
            (list
             (list :step 1
                   :block "WALK"
                   :args '(3 clicks)
                   :produced '(:aspect-set :gateway-pages :neighborhood-pages))
             (list :step 2
                   :block "PRINT"
                   :args '(draft)
                   :consumed '(:aspect-set)
                   :produced '(:draft-document :assembly-report))
             (list :step 3
                   :block "PREVIEW"
                   :args '(synopsis items)
                   :consumed '(:assembly-report)
                   :produced '(:preview-page)))
            :provenance
            (list
             (list :artifact :aspect-set
                   :from-step 1)
             (list :artifact :draft-document
                   :from-step 2
                   :derived-from '(:aspect-set))
             (list :artifact :assembly-report
                   :from-step 2
                   :derived-from '(:aspect-set :draft-document))
             (list :artifact :preview-page
                   :from-step 3
                   :derived-from '(:assembly-report)))
            :findings
            (list
             (list :kind :gateway-page
                   :page "Author Story Gateway"
                   :click-distance 1)
             (list :kind :included-page
                   :page "Garden Context Page"
                   :click-distance 2)
             (list :kind :warning
                   :page "Loose Reference Page"
                   :reason :missing-from-neighborhood))
            :artifact-links
            (list
             (list :kind :draft-document
                   :label "Draft volume"
                   :href "/drafts/story-neighborhood-2026-03-15.html")
             (list :kind :preview-page
                   :label "Synopsis items"
                   :href "/view/story-neighborhood-run-synopsis")
             (list :kind :graph-view
                   :label "Walked aspects"
                   :href "/view/story-neighborhood-run-aspects"))
            :execution-context
            (list :story-page "Author Story"
                  :origin-site "ward.dojo.fed.wiki"
                  :walk-limit 3
                  :walk-unit :clicks
                  :timestamp "2026-03-15T04:59:00Z")))
         (script (-> (getf ledger :script)
                     (assert-equal '("WALK 3 clicks"
                                     "PRINT draft"
                                     "PREVIEW synopsis items"))))
         (chronology (-> (getf ledger :chronology)
                         (assert-equal 3 :key #'length)))
         (artifact-links (-> (getf ledger :artifact-links)
                             (assert-equal 3 :key #'length))))
    (declare (ignore script chronology artifact-links))
    ledger))
