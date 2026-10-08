;;;; Reading supplied deployment observations
(defpackage #:dreyeck/work/deployment-reading
  (:use #:cl)
  (:export #:deployment-evidence #:service-start-confirmation
           #:deployment-update-observation
           #:served-state-observation-2026-10-08))
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

;;; A second, later observation, kept apart: DEPLOYMENT-EVIDENCE stays as it
;;; was reported. This one answers a single question that snapshot also
;;; answered, which command starts hyperdoc.service now, and no other.
(hyperdoc:defexample service-start-confirmation
  "Inspect the operator's confirmation of 2026-10-01 that the NixOS service
runs the built hyperdoc-catalog executable. It supersedes DEPLOYMENT-EVIDENCE
only as the answer to which command currently starts the service; that
snapshot's other observations are neither confirmed nor withdrawn. Each call
returns fresh data."
  (copy-tree
   '(:provenance (:kind :operator-supplied :observation-time "2026-10-01"
                  :scope :operator-confirmation :host-probe :not-performed)
     :observed
     ((:id "hyperdoc-service-program" :subject "dreyeck.ch" :kind :service
       :service "hyperdoc.service" :exec-start-program "hyperdoc-catalog"
       :artifact :not-supplied :exec-start :not-supplied))
     :derived
     ((:id "current-service-start" :subject "dreyeck.ch"
       :relation :current-service-start-command :service "hyperdoc.service"
       :starts "hyperdoc-catalog"
       :no-longer-starts "nix develop .#tala -c ./scripts/serve-catalog.sh 8080"
       :basis ("hyperdoc-service-program"
               (deployment-evidence :observed "hyperdoc-service"))
       :reason "This confirmation is dated 2026-10-01; DEPLOYMENT-EVIDENCE was recorded on 2026-09-28 (bee9d0a1). The later answer to the same question is the current one."
       :limit "Answers only which command currently starts hyperdoc.service. DEPLOYMENT-EVIDENCE keeps the ExecStart it reported."))
     :inferred ()
     :hypothesized ()
     :unresolved
     ((:subject "dreyeck.ch" :relation :current-exec-start-arguments
       :status :not-established
       :limit "The confirmation names the program, not its store path, arguments, port or working directory.")))))

;;; A deployment operation answers how a revision was activated, not which
;;; program systemd starts. Neither earlier observation is superseded here.
(hyperdoc:defexample deployment-update-observation
  "Inspect operator-supplied command output from the successful update of
2026-10-03. The flake input update precedes NixOS activation; service stop and
start belong to the activation result. This is separate from both the older
snapshot and SERVICE-START-CONFIRMATION. Each call returns fresh data without
executing a command or querying a host."
  (copy-tree
   '(:provenance (:kind :operator-supplied :observation-time "2026-10-03"
                  :recorded-at "2026-10-03" :scope :command-output
                  :host-probe :not-performed)
     :observed
     ((:id "dreyeck-update-2026-10-03" :subject "dreyeck.ch"
       :kind :deployment-operation :operation :update-and-activate
       :directory "/etc/nixos"
       :steps
       ((:kind :flake-input-update :command "nix flake update hyperdoc"
         :input "hyperdoc" :lock-file "/etc/nixos/flake.lock"
         :revision-before "384fab636fd2695109aea626b12963cd58bbdcac"
         :revision-after "548f73d09826795cbeaea1eae38da9a4b6e8a9e7")
        (:kind :nixos-activation
         :command "nixos-rebuild switch --flake /etc/nixos#dreyeck"
         :flake "/etc/nixos#dreyeck"
         :built ("hyperdoc-catalog") :rebuilt-units ("hyperdoc.service")
         :result
         (:status :completed-successfully
          :transition ((:kind :service-stop :service "hyperdoc.service")
                       (:kind :configuration-activation :flake "/etc/nixos#dreyeck")
                       (:kind :service-start :service "hyperdoc.service")))))))
     :derived ()
     :inferred ()
     :hypothesized ()
     :unresolved
     ((:subject "dreyeck.ch" :relation :post-activation-verification
       :status :not-established :basis ("dreyeck-update-2026-10-03")
       :outside-observation (:exec-start :working-directory :proxy-state
                             :browser-reachability :application-health)
       :limit "This update output does not establish the service's ExecStart, WorkingDirectory, proxy state, browser reachability or application-level health after restart; each needs a separate observation.")))))

;;; A fourth observation, the first with its own capture time. It answers what
;;; was serving dreyeck.ch when the operator ran read-only commands on the host.
;;; Process, service, locked source, store source, assets copy, routes and
;;; listeners are separate records. Where an earlier observation answered the
;;; same question, this is the later answer; the earlier records are unchanged.
;;; It is not what the runtime reports about itself.
(hyperdoc:defexample served-state-observation-2026-10-08
  "Inspect what was observed serving dreyeck.ch at 2026-10-08T03:29:16Z, from
read-only commands the operator ran on the host. Two later browser observations
and two content comparisons made away from the host are marked as such. Earlier
observations are not changed. Each call returns fresh data without executing a
command or querying a host."
  (copy-tree
   '(:provenance (:kind :operator-supplied :observation-time "2026-10-08T03:29:16Z"
                  :recorded-at "2026-10-08" :scope :read-only-command-output
                  :host-probe :operator-run-read-only
                  :supplements
                  ((:kind :browser-observation :observer "Claude"
                    :observation-time :not-recorded :after "2026-10-08T03:29:16Z"
                    :records ("served-catalog" "view-route-response"))
                   (:kind :content-comparison :where :away-from-host
                    :records ("store-source-is-commit" "assets-copy-content-is-commit"))))
     :observed
     ((:id "served-process" :subject "dreyeck.ch" :kind :process
       :pid 1062025 :ppid 1 :user "rgb" :cwd "/"
       :started-at "Thu Oct  8 04:31:36 2026"
       :cgroup "/system.slice/hyperdoc.service"
       :executable "/nix/store/7m20fryjy300sakr6s93g2ikgqiqb44q-sbcl-2.4.10/bin/sbcl"
       :arguments ("--dynamic-space-size" "3000" "--noinform" "--no-sysinit"
                   "--no-userinit" "--script"
                   "/nix/store/46h64h5l6bz1857x5m1swmzy7kqlbx1l-source/scripts/catalog-main.lisp"
                   "8080")
       :environment (:hyperdoc-catalog-host "127.0.0.1"
                     :hyperdoc-hyperspec-root
                     "/nix/store/sbnljd0w8w2513iicp77533lwk06bfva-common-lisp-hyperspec-7.0/share/common-lisp-hyperspec/HyperSpec"
                     :cl-source-registry-last-entry
                     "/nix/store/46h64h5l6bz1857x5m1swmzy7kqlbx1l-source//"))
      (:id "served-service" :subject "dreyeck.ch" :kind :service
       :service "hyperdoc.service" :load-state "loaded"
       :active-state "active" :sub-state "running"
       :unit-file "/etc/systemd/system/hyperdoc.service"
       :unit-file-target "/nix/store/plhsz6rnvnlzs4sxrmv3cmjm7pmbxbk3-unit-hyperdoc.service/hyperdoc.service"
       :drop-ins () :need-daemon-reload nil
       :main-pid 1062025 :exec-main-start "Thu 2026-10-08 04:31:37 CEST" :restarts 0
       :user "rgb" :user-home "/home/rgb" :working-directory :not-set
       :exec-start-program "/nix/store/l3f9prfckv2yabr2n0byhkh474xzyh4y-hyperdoc-catalog/bin/hyperdoc-catalog"
       :exec-start "/nix/store/l3f9prfckv2yabr2n0byhkh474xzyh4y-hyperdoc-catalog/bin/hyperdoc-catalog 8080"
       :environment (:hyperdoc-catalog-host "127.0.0.1")
       :environment-names-only ("HOME" "LOCALE_ARCHIVE" "PATH" "TZDIR"))
      (:id "current-generation" :subject "dreyeck.ch" :kind :nixos-generation
       :generation 698
       :system "/nix/store/0s4fr93nxv7fzchmn2jryl4gr8vnjvsj-nixos-system-dreyeck-25.11.20260429.755f5aa"
       :link-created "2026-10-08 04:31:34 +0200" :current t
       :hyperdoc-unit "/nix/store/plhsz6rnvnlzs4sxrmv3cmjm7pmbxbk3-unit-hyperdoc.service/hyperdoc.service"
       :booted-system "/nix/store/jdqjmjwlvamms1q6w7y8jx78jlz1xjka-nixos-system-dreyeck-25.11.20260429.755f5aa"
       :previous ((:generation 697 :link-created "2026-10-07 22:32:39 +0200")
                  (:generation 696 :link-created "2026-10-07 08:05:28 +0200")))
      (:id "hyperdoc-input-lock" :subject "dreyeck.ch" :kind :flake-input-lock
       :lock-file "/etc/nixos/flake.lock" :lock-file-modified "2026-10-08 04:31:06 +0200"
       :flake-file "/etc/nixos/flake.nix" :flake-file-modified "2026-10-01 07:51:13 +0200"
       :configuration-under-version-control nil
       :input "hyperdoc" :original "github:RalfBarkow/hyperdoc?ref=dreyeck.ch"
       :rev "fab214334279bc5d3df0f2f624d34e6a1bdc1897"
       :nar-hash "sha256-wACuGd0WGd8crpzY8UarUUediGZ1QkUWTtxU2WOpC+Q="
       :last-modified 1791418004)
      (:id "hyperdoc-store-source" :subject "dreyeck.ch" :kind :store-source
       :path "/nix/store/46h64h5l6bz1857x5m1swmzy7kqlbx1l-source"
       :nar-hash "sha256-wACuGd0WGd8crpzY8UarUUediGZ1QkUWTtxU2WOpC+Q="
       :git-directory nil
       :referenced-by (:process-script :exec-start-program :cl-source-registry))
      (:id "deployed-source-text" :subject "dreyeck.ch" :kind :source-text
       :store-source "/nix/store/46h64h5l6bz1857x5m1swmzy7kqlbx1l-source"
       :excerpts
       ((:file "dreyeck/src/fedwiki-assets.lisp" :line 57
         :text "(defparameter +default-local-site-name+ \"dreyeck.ch\"")
        (:file "dreyeck/src/catalog-application.lisp" :line 49
         :text "The executable never enables development tools.")
        (:file "dreyeck/src/page-attached-workspace-reconstruction.lisp" :line 44
         :text "A served runtime started without development refuses"))
       :present-files ("workspace-operation.lisp" "workspace-operation-package.lisp")
       :absent-files ("evaluation-journal*" "evaluation-record-history*"))
      (:id "served-assets-copy" :subject "dreyeck.ch" :kind :assets-copy
       :path "/home/rgb/.wiki/dreyeck.ch/assets/pages/reading-java-source-as-data"
       :assets-root "/home/rgb/.wiki/dreyeck.ch/assets"
       :git-checkout nil :versioned nil :mutability :mutable-copy
       :directory-modified "2026-08-15 18:05:47 +0200"
       :files (("b25c15b81fae06e1c55946ac6270bfdb293870e8" ".gitignore")
               ("f07f00e47c9db51260f1bab72f61a45f2fe7321e" "pages/Reading Java source as data.html")
               ("0cac5489b0d9691553f675def386d76896fdd6d9" "reading-java-source-as-data.asd")
               ("919d28a6908972a4d80305fe6bbe5ec34419d63f" "src/hyperdoc.lisp")
               ("53ce9a45d34f470695a1595d82d7ef00a492e2b4" "src/hyperdoc-package.lisp")
               ("a414ba9dec9acec18279af3149d82ebb1d2899fe" "src/java-token.lisp")
               ("abd168bd05d74f23a1e2d7e685958e39c7d89554" "src/package.lisp")
               ("7ce17b7dd449d436329525aa1080902c75999375" "src/scanner.lisp")
               ("fcefb038a43780fc6712f08f52a5dd709c91d7db" "src/source-span.lisp")
               ("6b8c8f23cc6761ddb755448f1cf5a7bdbe23ce33" "tests/package.lisp")
               ("ce9c63945158c54f6ee252130d0cba0f5d0035c7" "tests/scanner.lisp")
               ("d732fb0ba56e9e9acf676fbb6da9496f7ac0bf58" "tests/smoke.lisp"))
       :absent ("src/identity*"))
      (:id "served-fedwiki-page" :subject "dreyeck.ch" :kind :fedwiki-page
       :path "/home/rgb/.wiki/dreyeck.ch/pages/reading-java-source-as-data"
       :size 1665 :modified "2026-08-15 16:40:34 +0200"
       :blob "104eb23b46f24ebc45ef6034a29d7baf5d6503f9")
      (:id "apex-route" :subject "dreyeck.ch" :kind :nginx-route
       :config "/nix/store/r0bijcpdd1wma1y1yf2f3s2qgiy2pq24-nginx.conf"
       :host "dreyeck.ch" :match :exact :upstream "127.0.0.1:8080"
       :observed-paths ("/" "/clog"))
      (:id "wildcard-route" :subject "dreyeck.ch" :kind :nginx-route
       :config "/nix/store/r0bijcpdd1wma1y1yf2f3s2qgiy2pq24-nginx.conf"
       :host "*.dreyeck.ch" :match :wildcard :upstream "127.0.0.1:3000")
      (:id "mcp-route" :subject "dreyeck.ch" :kind :nginx-route
       :config "/nix/store/r0bijcpdd1wma1y1yf2f3s2qgiy2pq24-nginx.conf"
       :host "mcp.dreyeck.ch" :match :exact :upstream "127.0.0.1:8787"
       :observed-paths ("/mcp"))
      (:id "hyperdoc-loopback-listener" :subject "dreyeck.ch" :kind :listener
       :runtime "HyperDoc" :address "127.0.0.1:8080" :pid 1062025)
      (:id "node-listener" :subject "dreyeck.ch" :kind :listener
       :runtime "Node/FedWiki" :address "*:3000" :pid 801)
      (:id "mcp-loopback-listener" :subject "dreyeck.ch" :kind :listener
       :runtime "MCP/SBCL" :address "127.0.0.1:8787" :pid 920)
      (:id "nginx-public-listeners" :subject "dreyeck.ch" :kind :listener
       :runtime "nginx" :addresses ("0.0.0.0:80" "0.0.0.0:443" "[::]:80" "[::]:443")
       :pids (815 1062120))
      (:id "node-wiki-service" :subject "dreyeck.ch" :kind :service
       :service "wiki.service" :pid 801 :user "rgb"
       :program "/nix/store/vrqcpwq576gar2i430lj91v37b7k8jw2-nodejs-22.18.0/bin/node"
       :config "/home/rgb/.wiki/config.json" :farm t :security-type "friends"
       :started-at "Sun Aug 16 07:11:56 2026" :cgroup "/system.slice/wiki.service")
      (:id "mcp-service" :subject "dreyeck.ch" :kind :service
       :service "hyperdoc-mcp.service" :description "HyperDoc DMX MCP service"
       :pid 920 :user-as-displayed "hyperdo+"
       :started-at "Sun Aug 16 07:12:04 2026" :cgroup "/system.slice/hyperdoc-mcp.service")
      (:id "host-boot" :subject "dreyeck.ch" :kind :host-boot
       :at "Sun Aug 16 07:11:51 2026")
      (:id "historical-checkout-head" :subject "dreyeck.ch" :kind :checkout
       :path "/home/rgb/workspace/hyperdoc"
       :head "35a83fdffb9285fbe7de575dac0a4b8ca8234305"
       :head-committed-at "2026-10-02 11:14:13 +0200"
       :directory-modified "2026-10-02 11:48:33 +0200")
      (:id "served-catalog" :subject "dreyeck.ch" :kind :served-catalog
       :url "https://dreyeck.ch/" :hyperbooks 21
       :includes-title-reading-java-source-as-data nil)
      (:id "view-route-response" :subject "dreyeck.ch" :kind :served-route-response
       :url "https://dreyeck.ch/view/reading-java-source-as-data"
       :renders :local-fedwiki-page :title "Reading Java Source as Data"
       :assets-item "pages/reading-java-source-as-data"
       :side-effect (:catalog-entries-before 21 :catalog-entries-after 22
                     :admitted "reading-java-source-as-data" :evaluated nil)))
     :derived
     ((:id "process-of-service" :subject "dreyeck.ch" :relation :process-of-service
       :process 1062025 :service "hyperdoc.service"
       :basis ("served-process" "served-service")
       :reason "The process's cgroup is the unit's, and its PID is the unit's MainPID and the PID recorded on the ExecStart invocation.")
      (:id "locked-source-is-store-source" :subject "dreyeck.ch"
       :relation :locked-source-is-store-source
       :basis ("hyperdoc-input-lock" "hyperdoc-store-source")
       :reason "The lock's narHash for the hyperdoc input equals the store path's narHash.")
      (:id "store-source-is-commit" :subject "dreyeck.ch"
       :relation :store-source-content-is-commit
       :commit "fab214334279bc5d3df0f2f624d34e6a1bdc1897"
       :basis ("hyperdoc-store-source")
       :computation (:where :away-from-host
                     :operation "git archive fab214334279bc5d3df0f2f624d34e6a1bdc1897 | nix hash path"
                     :result "sha256-wACuGd0WGd8crpzY8UarUUediGZ1QkUWTtxU2WOpC+Q="
                     :control (:commit "6198f254" :result "sha256-gXGLTK0g3tXxOU5/0De8hVubpovJqXdCe6XFCM+2iQE="))
       :reason "The commit's exported tree has the store source's narHash; the control commit does not.")
      (:id "process-loaded-store-source" :subject "dreyeck.ch"
       :relation :process-loaded-source
       :basis ("served-process" "hyperdoc-store-source")
       :reason "The process was started with --script naming a file in the store source, which cannot change."
       :limit "Covers code loaded at startup. Pages and assets read later come from the site root, not from this path.")
      (:id "site-root" :subject "dreyeck.ch" :relation :configured-site-root
       :path "/home/rgb/.wiki/dreyeck.ch/"
       :basis ("served-service" "deployed-source-text")
       :reason "HYPERDOC_FEDWIKI_SITE_ROOT is not set, the service user's home is /home/rgb, and the deployed default site name is dreyeck.ch.")
      (:id "page-attached-execution-refused" :subject "dreyeck.ch"
       :relation :page-attached-execution :status :refused
       :basis ("deployed-source-text")
       :reason "The deployed executable never enables development tools, and a served runtime started without development refuses page-attached code."
       :limit "Read from the deployed source; the running runtime was not asked.")
      (:id "assets-copy-content-is-commit" :subject "dreyeck.ch"
       :relation :assets-copy-content-is-commit
       :repository "RalfBarkow/assets"
       :commit "bdb09ff431b1750ade5be5ea15ae9d2467194f71"
       :basis ("served-assets-copy")
       :computation (:where :away-from-host
                     :operation "Blob ids compared with the bundle tree of every assets commit touching pages/reading-java-source-as-data"
                     :result :exactly-one-tree-match)
       :limit "Content identity, not provenance: how and when the copy was made is not recorded.")
      (:id "public-apex-route-2026-10-08" :subject "dreyeck.ch"
       :relation :public-host-route :host "dreyeck.ch" :reaches "127.0.0.1:8080"
       :basis ("apex-route" "hyperdoc-loopback-listener" "served-process")
       :reason "nginx sends dreyeck.ch to 127.0.0.1:8080, where the served process listens.")
      (:id "service-not-started-from-checkout" :subject "dreyeck.ch"
       :relation :service-working-directory :status :not-the-checkout
       :basis ("served-service" "served-process" "historical-checkout-head")
       :reason "The unit sets no WorkingDirectory, the process cwd is /, and its script is in the store."
       :limit "Concerns the start of 2026-10-08. The inference about the start of 2026-09-28 is unchanged."))
     :inferred
     ((:id "generation-698-started-service" :subject "dreyeck.ch"
       :relation :activation-started-service :generation 698 :service "hyperdoc.service"
       :basis ("hyperdoc-input-lock" "current-generation" "served-service")
       :reason "The lock was written at 04:31:06, generation 698 was linked at 04:31:34 and the service started at 04:31:37 with no restarts; its unit resolves into that generation."
       :verification :not-directly-observed))
     :hypothesized ()
     :unresolved
     ((:subject "dreyeck.ch" :relation :runtime-reported-version
       :status :not-available :basis ("served-process")
       :limit "The running process reports no source revision of its own. The revision comes from the lock and the store, not from the runtime.")
      (:subject "dreyeck.ch" :relation :assets-copy-provenance
       :status :not-established :basis ("served-assets-copy")
       :limit "When and how the copy was made, and from which checkout, is not recorded.")
      (:subject "dreyeck.ch" :relation :assets-second-writer
       :status :not-established
       :basis ("node-wiki-service" "wildcard-route" "node-listener")
       :limit "The farm keeps site data under /home/rgb/.wiki, which contains dreyeck.ch, and nginx sends no dreyeck.ch request to it. Whether it writes the assets copy, and whether port 3000 is reachable from outside, was not observed.")
      (:subject "dreyeck.ch" :relation :mcp-runtime-source
       :status :not-established :basis ("mcp-service")
       :limit "Running since boot on 2026-08-16; its source revision was not observed.")
      (:subject "dreyeck.ch" :relation :nixos-configuration-history
       :status :not-available :basis ("hyperdoc-input-lock")
       :limit "/etc/nixos is not a Git repository; earlier configurations exist only as generation store paths.")))))
