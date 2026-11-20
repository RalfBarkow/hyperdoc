;;; The register of changes on their way from branch to the servers. Each fact names when and how it was observed.
;;; Kept by hand (Claude after each step, or the operator); the Play control can refresh public hyperdoc PRs in the image.
;;; Facts: :pr-open :merged :staging-accepted :staging-active :pin-on-merged :production-done :seen
;;; Flags: :needs-staging (the change is accepted on staging before merge), :needs-production, :needs-view (the operator
;;; looks at it in the local HyperDoc before a PR).

(:id :faq-store-gc :repo :hyperdoc :branch "faq/asdf-registry-store-gc" :head "f5974047" :pr 61
 :title "FAQ asdf-registry-store-gc"
 :flags (:needs-staging)
 :facts ((:pr-open "2026-11-20" "PR RalfBarkow/hyperdoc#61 angelegt")
         (:staging-accepted "2026-11-20" "über fleet ac8d81d0: System dfirimkmr86…, alle FAQ-Dateien byte-gleich über HTTPS")
         (:merged "2026-11-20" "Merge-Commit 059ea6a4 auf dreyeck.ch (Operator), von GitHub gelesen")))

(:id :fleet-faq-pin :repo :fleet :branch "review/staging-faq-store-gc" :head "d2735dc8" :pr 8
 :title "fleet: staging-Pin der FAQ"
 :depends-on (:faq-store-gc)
 :flags (:needs-staging)
 :facts ((:staging-active "2026-11-20" "readlink -f /run/current-system = dfirimkmr86… (Operator)")
         (:staging-accepted "2026-11-20" "Build-Pfad = erwarteter Pfad; FAQ über HTTPS geprüft")
         (:pin-on-merged "2026-11-20" "d2735dc8 pinnt 059ea6a4; gleicher Baum wie f5974047, gleicher Systempfad")
         (:pr-open "2026-11-20" "PR RalfBarkow/fleet#8 angelegt")))

(:id :operator-keys :repo :fleet :branch "review/operator-ssh-keys" :head "95755858" :pr nil
 :title "fleet: SSH-Schlüssel mbp-bs und fbx"
 :flags (:needs-staging :needs-production)
 :facts ())

(:id :local-topics :repo :hyperdoc :branch "docs/start-local-hyperdoc" :head "7f1fc822" :pr nil
 :title "Start-Topic und Workflow-Plan"
 :flags (:needs-view)
 :facts ())

(:id :five-ways :repo :hyperdoc :branch "work/five-ways-config" :head "30fbd420" :pr nil
 :title "Five ways to organise your config"
 :flags (:needs-view)
 :facts ())

(:id :codepath-review :repo :hyperdoc :branch "work/codepath-review" :head "ecce6c7a" :pr nil
 :title "Codepfade in Seiten-Code"
 :flags (:needs-view)
 :facts ())

(:id :site-observation :repo :hyperdoc :branch "work/site-observation" :head "53be886e" :pr nil
 :title "Site-Beobachtung mit Playground-Schranke"
 :flags (:needs-view)
 :facts ())

(:id :acceptance-catalog :repo :fleet :branch "review/staging-acceptance-catalog" :head "34154a29" :pr 9
 :title "fleet: Abnahme-Catalog auf staging"
 :flags (:needs-staging)
 :facts ((:pr-open "2026-11-20" "PR RalfBarkow/fleet#9 angelegt; vor dem Ausrollen DNS catalog.staging.dreyeck.ch setzen")))
