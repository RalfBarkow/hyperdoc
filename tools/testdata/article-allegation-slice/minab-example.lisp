(:slice-id minab-school-strike
           :mode :article-allegation
           :incident-title "Minab school strike allegations"
           :source-label "user-provided article summary"
           :incident-date "2026-03-13"
           :anchor-date "2026-03-13"
           :epistemic-status :disputed
           :summary
           "Reported school strike case used to document stale targeting data, disputed attribution, civilian-harm accountability, and AI-assisted targeting responsibility."
           :incident-sections
           ("Claimed sequence of events"
            "Reported attribution"
            "Investigative or forensic claims"
            "Accountability questions"
            "Open uncertainties"
            "Related concepts")
           :daily-anchor-note
           "Dry-run sample for the reusable article-allegation-slice scaffolding routine."
           :incident-page-reference? t
           :known-uncertainties
           ("The underlying article text is preserved here as a claim source rather than as independently verified fact."
            "Strike responsibility, the stale-coordinate hypothesis, and the later forensic reconstruction remain allegation-qualified unless stronger source metadata is supplied.")
           :concepts
           ((:title "Stale target coordinates"
                    :topic-handle stale-target-coordinates-topic
                    :kind :failure-mode
                    :related-titles ("Target validation"
                                     "Precision weapons and wrong-target failure"))
            (:title "Precision weapons and wrong-target failure"
                    :topic-handle precision-weapon-mistargeting-topic
                    :kind :failure-mode
                    :related-titles ("Stale target coordinates"
                                     "Target validation"))
            (:title "Target validation"
                    :topic-handle target-validation-topic
                    :kind :process-failure
                    :related-titles ("Stale target coordinates"
                                     "Civilian harm accountability"))
            (:title "Civilian harm accountability"
                    :topic-handle civilian-harm-accountability-topic
                    :kind :accountability-model
                    :related-titles ("Target validation"
                                     "Human responsibility in AI-assisted targeting"))
            (:title "Public attribution after disputed airstrikes"
                    :topic-handle disputed-strike-attribution-topic
                    :kind :attribution-method
                    :related-titles ("Civilian harm accountability"
                                     "Human responsibility in AI-assisted targeting"))
            (:title "Human responsibility in AI-assisted targeting"
                    :topic-handle human-in-the-loop-targeting-topic
                    :kind :human-ai-boundary
                    :related-titles ("Civilian harm accountability"
                                     "Target validation")))
           :flags
           (:legal-conclusions-conditional t
                                           :require-open-uncertainties t
                                           :generate-fedwiki-twins t
                                           :generate-daily-anchor t))
