;;;; Reading supplied deployment observations
(defpackage #:dreyeck/work/deployment-reading
  (:use #:cl)
  (:export #:deployment-evidence))
(in-package #:dreyeck/work/deployment-reading)

(hyperdoc:see (hyperdoc:page "Federated Wiki deployment state"))

(hyperdoc:defexample deployment-evidence
  "Inspect supplied observations, not a live host query. Each call returns
fresh data. Inferences retain their observed basis; missing evidence stays
unresolved. Event times do not supply a capture time for the whole snapshot."
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
      (:id "dreyeck-checkout" :subject "dreyeck.ch" :kind :checkout
       :path "/home/rgb/workspace/hyperdoc"
       :head "84ee991aa4591a873a63753b89b37737ba5f2efc")
      (:id "hyperdoc-service" :subject "dreyeck.ch" :kind :service
       :service "hyperdoc.service" :active-state "active" :sub-state "running"
       :working-directory "/home/rgb/workspace/hyperdoc"
       :exec-start "nix develop .#tala -c ./scripts/serve-catalog.sh 8080")
      (:id "checkout-fast-forward" :subject "dreyeck.ch" :kind :checkout-transition
       :checkout "dreyeck-checkout" :transition :fast-forward
       :to "84ee991aa4591a873a63753b89b37737ba5f2efc"
       :at "2026-09-28 06:25:03 +0200")
      (:id "sbcl-process-start" :subject "dreyeck.ch" :kind :process-start
       :runtime "SBCL" :time "06:25:13" :precision :approximate)
      (:id "hyperdoc-service-start" :subject "dreyeck.ch" :kind :service-start
       :service "hyperdoc.service" :at "2026-09-28 06:25:14 CEST")
      (:id "nginx-exact-host" :subject "dreyeck.ch" :kind :nginx-route
       :host "dreyeck.ch" :match :exact :upstream "127.0.0.1:8080"
       :observed-paths ("/" "/clog"))
      (:id "nginx-wildcard-host" :subject "dreyeck.ch" :kind :nginx-route
       :host "*.dreyeck.ch" :match :wildcard :upstream "127.0.0.1:3000")
      (:id "nginx-mcp-host" :subject "dreyeck.ch" :kind :nginx-route
       :host "mcp.dreyeck.ch" :match :exact :upstream "127.0.0.1:8787")
      (:id "nginx-tls" :subject "dreyeck.ch" :kind :tls-termination
       :host "dreyeck.ch" :terminator "nginx")
      (:id "hyperdoc-listener" :subject "dreyeck.ch" :kind :listener
       :runtime "HyperDoc" :address "0.0.0.0:8080")
      (:id "fedwiki-listener" :subject "dreyeck.ch" :kind :listener
       :runtime "Node/FedWiki" :address "*:3000")
      (:id "mcp-listener" :subject "dreyeck.ch" :kind :listener
       :runtime "MCP/SBCL" :address "127.0.0.1:8787")
      (:id "nginx-listeners" :subject "dreyeck.ch" :kind :listener
       :runtime "nginx" :addresses (":80" ":443"))
      (:id "nixos-firewall" :subject "dreyeck.ch" :kind :firewall
       :allowed-tcp-ports (80 443))
      (:id "external-8080" :subject "dreyeck.ch" :kind :connection-attempt
       :origin :external :destination "dreyeck.ch:8080" :result :timed-out)
      (:id "fedwiki-config" :subject "dreyeck.ch" :kind :service-config
       :service "wiki.service" :user "rgb" :config "/home/rgb/.wiki/config.json"
       :farm t :security-type "friends"
       :not-explicitly-configured (:data :root :wiki-domains))
      (:id "fedwiki-pages" :subject "dreyeck.ch" :kind :path-existence
       :path "/home/rgb/.wiki/dreyeck.ch/pages" :exists t))
     :derived
     ((:id "public-apex-route" :subject "dreyeck.ch" :relation :public-host-route
       :host "dreyeck.ch" :scope :observed-public-nginx-routing
       :reaches "127.0.0.1:8080" :does-not-reach "Node/FedWiki :3000"
       :basis ("nginx-exact-host" "nginx-wildcard-host" "nginx-mcp-host")
       :limit "Local/operator-side requests remain possible; no claim about whether Node can write the pages directory."))
     :inferred
     ((:id "hyperdoc-started-from-checkout" :subject "dreyeck.ch"
       :relation :service-source-commit :service "hyperdoc.service"
       :source-commit "84ee991aa4591a873a63753b89b37737ba5f2efc"
       :basis ("dreyeck-checkout" "hyperdoc-service" "checkout-fast-forward"
               "sbcl-process-start" "hyperdoc-service-start")
       :reason "The supplied process/service start times follow the checkout fast-forward; the observed WorkingDirectory names that checkout."
       :verification :not-directly-observed))
     :hypothesized ()
     :unresolved
     ((:subject "dreyeck.ch" :relation :service-source-commit
       :status :not-directly-observed :inference "hyperdoc-started-from-checkout")
      (:subject "dreyeck.ch" :relation :external-8080-filtering-cause
       :status :not-established :basis ("nixos-firewall" "external-8080")
       :limit "Other network filtering was not excluded; the timeout does not prove that the firewall alone protects port 8080.")))))
