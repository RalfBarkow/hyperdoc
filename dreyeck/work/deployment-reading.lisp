;;;; Reading supplied deployment observations
(defpackage #:dreyeck/work/deployment-reading
  (:use #:cl)
  (:export #:deployment-evidence))
(in-package #:dreyeck/work/deployment-reading)

(hyperdoc:see (hyperdoc:page "Federated Wiki deployment state"))

(hyperdoc:defexample deployment-evidence
  "Inspect supplied observations, not a live host query. Each call returns
fresh data. An absent relation remains unresolved, never an inferred fact."
  (copy-tree
   '(:provenance (:kind :operator-supplied
                  :observation-time :not-supplied
                  :scope :reported-snapshot :host-probe :not-performed)
     :observed
     ((:subject "wiki.ralfbarkow.ch" :kind :deployment-witness
       :source-commit "b42eb888d6e5d59803667c6320e0779523fc265c"
       :artifact "/nix/store/q8ppar443gy3ahm33hbbp3b5kwf4j930-wiki-p41-0.41.0-rc.3"
       :service "wiki.service" :active-state "active" :sub-state "running"
       :exec-start-program "/nix/store/q8ppar443gy3ahm33hbbp3b5kwf4j930-wiki-p41-0.41.0-rc.3/bin/wiki")
      (:subject "dreyeck.ch" :kind :checkout
       :path "/home/rgb/workspace/hyperdoc"
       :head "84ee991aa4591a873a63753b89b37737ba5f2efc")
      (:subject "dreyeck.ch" :kind :service
       :service "hyperdoc.service" :active-state "active" :sub-state "running"
       :exec-start "nix develop .#tala -c ./scripts/serve-catalog.sh 8080"))
     :derived () :inferred () :hypothesized ()
     :unresolved
     ((:subject "dreyeck.ch" :relation :service-working-directory
       :status :not-established)
      (:subject "dreyeck.ch" :relation :service-source-commit
       :status :not-established)))))
