;;;; Reading the public Trails Rendered reproduction
(defpackage #:dreyeck/work/trails-rendered-reading
  (:use #:cl)
  (:export #:provenance-evidence #:initial-state #:integration-decision
           #:runtime-verification #:provenance-chain #:operations-record))
(in-package #:dreyeck/work/trails-rendered-reading)

(hyperdoc:see (hyperdoc:page "Trails Rendered public reproduction"))

;;; Each reading answers one question and keeps its own provenance. Facts
;;; observed by the agent are kept apart from what is derived from them,
;;; inferred from them, or merely hypothesized. A later observation is
;;; added as a further reading; an earlier one is not rewritten.

(hyperdoc:defexample provenance-evidence
  "Where does Ward Cunningham's 'layers of interpretation' code live?
Inspect the read-only provenance search of 2026-10-04: repositories, npm
releases, served plugin assets and public wiki pages. Each call returns
fresh data. The snippet itself was not found; its location is inferred."
  (copy-tree
   '(:provenance (:kind :agent-observed :observer "Claude Code"
                  :observation-date "2026-10-04"
                  :method (:read-only-git :read-only-http :npm-registry-query)
                  :scope :public-sources)
     :question "Where does the getBBox / g.node title snippet live?"
     :snippet "Array.from(svg.querySelectorAll('g.node title')).find(title => title.textContent == want).closest('g.node').getBBox()"
     :observed
     ((:id "mech-upstream-tip" :kind :git-ref
       :repository "https://github.com/WardCunningham/wiki-plugin-mech"
       :ref "refs/heads/main" :commit "a028b4bba04e539dcaa090423d38a00a0050489d"
       :date "2026-09-10" :subject "update dev dependencies")
      (:id "mech-npm-latest" :kind :npm-release :package "wiki-plugin-mech"
       :version "0.1.48-3" :git-head "54b769596f27ad97b79fa83061e0b238090fdc59"
       :published "2026-06-30T18:55:00Z")
      (:id "mech-tip-vs-release" :kind :git-diff
       :from "54b769596f27ad97b79fa83061e0b238090fdc59"
       :to "a028b4bba04e539dcaa090423d38a00a0050489d"
       :changed-files ("ReadMe.md" "package-lock.json" "package.json"))
      (:id "mech-snippet-search" :kind :search-result
       :repository "https://github.com/WardCunningham/wiki-plugin-mech"
       :scope (:all-branches :refs/pull/1-6 :full-history)
       :terms ("getBBox" "g.node" "closest('g.node'" "layer" "interpret")
       :hits 0)
      (:id "solo-upstream-tip" :kind :git-ref
       :repository "https://github.com/WardCunningham/wiki-plugin-solo"
       :ref "refs/heads/main" :commit "17915844349bada64c901bd5ea73472702c446f9"
       :date "2025-12-11" :version "0.1.30-0")
      (:id "solo-npm-latest" :kind :npm-release :package "wiki-plugin-solo"
       :version "0.1.30-1" :git-head "3ad7796217d564407fd36cf62c37844654fdc967"
       :git-head-on-github :absent :github-commit-api-status 422)
      (:id "solo-npm-source" :kind :sourcemap-recovery :package "wiki-plugin-solo"
       :version "0.1.30-1" :recovered-from "client/solo.js.map sourcesContent"
       :difference-from "17915844349bada64c901bd5ea73472702c446f9"
       :difference "module wrapper only: IIFE replaced by an ESM export"
       :dialog-identical t)
      (:id "solo-snippet-search" :kind :search-result
       :repository "https://github.com/WardCunningham/wiki-plugin-solo"
       :scope (:all-branches :refs/pull/1 :full-history :npm-0.1.30-1)
       :terms ("getBBox" "g.node" "Trace" "layer" "interpret") :hits 0)
      (:id "solo-title-idiom" :kind :source-location
       :repository "https://github.com/WardCunningham/wiki-plugin-solo"
       :commit "17915844349bada64c901bd5ea73472702c446f9"
       :path "client/dialog/index.html" :lines (450 487 515)
       :functions ("hoverbold" "clickready" "dogroup")
       :uses ("querySelector('title').textContent" "closest('.node')"
              "getBoundingClientRect"))
      (:id "ward-statement" :kind :wiki-paragraph
       :site "ward.voices.ustawi.wiki" :slug "increment-of-progress"
       :title "Increment of Progress" :created "2026-10-02T18:49:24Z"
       :fragment "an experimental version of the Solo popup viewer which was only deployed to localhost:3000")
      (:id "trails-rendered-page" :kind :wiki-page
       :site "ward.voices.ustawi.wiki" :slug "trails-rendered"
       :title "Trails Rendered" :last-journal-date "2026-10-03T16:36:46Z"
       :items ((:id "49488010256113991680" :type "graphviz")
               (:id "29487849520185925632" :type "solo")
               (:id "6405b752d1739af0" :type "mech")
               (:id "17a5b123160ef0d9" :type "code")
               (:id "cc6a77771de7edbd" :type "code")
               (:id "84da00fa76850971" :type "code")))
      (:id "trail-rel-type-change" :kind :journal-entry
       :site "ward.voices.ustawi.wiki" :slug "trails-rendered"
       :item-id "84da00fa76850971" :date "2026-10-01T17:18:24Z"
       :rel-type-before "" :rel-type-after "Trail"
       :before-item-id "c5296b272145f193")
      (:id "next-ward-served-plugins" :kind :served-asset
       :site "next.ward.dojo.fed.wiki"
       :mech-banner "wiki-plugin-mech - 0.1.48-3 - Tue, 30 Jun 2026 18:53:10 GMT"
       :solo-dialog-identical-to "17915844349bada64c901bd5ea73472702c446f9"
       :trace-hits 0 :getbbox-hits 0)
      (:id "graceful-polyline-asset" :kind :served-asset
       :site "next.ward.dojo.fed.wiki" :slug "graceful-polyline"
       :url "http://next.ward.dojo.fed.wiki/assets/pages/graceful-polyline/polyline.html"
       :identical-to (:repository "https://github.com/WardCunningham/assets"
                      :commit "59091e9" :path "pages/graceful-polyline/polyline.html"))
      (:id "phrase-search" :kind :search-result
       :scope (:sitemaps 23 :page-json 65)
       :terms ("layers of interpretation" "layer of interpretation") :hits 0)
      (:id "federation-search" :kind :connection-attempt
       :destination "search.fed.wiki.org:3030" :result :timed-out))
     :derived
     ((:id "mech-tip-behaves-as-release" :relation :behaviour-equivalence
       :subject "a028b4bba04e539dcaa090423d38a00a0050489d"
       :equivalent-to "wiki-plugin-mech 0.1.48-3"
       :basis ("mech-tip-vs-release" "mech-npm-latest")
       :reason "No file under src/ or client/ changed between the release gitHead and the tip."
       :limit "A rebuild with newer dev dependencies may produce different bundle bytes.")
      (:id "public-solo-lacks-trace" :relation :absence
       :subject "public wiki-plugin-solo" :absent "Trace relation handling"
       :basis ("solo-snippet-search" "solo-npm-source" "next-ward-served-plugins")))
     :inferred
     ((:id "snippet-location" :relation :implementation-location
       :subject "getBBox snippet"
       :location "Ward Cunningham's local, unpushed wiki-plugin-solo client/dialog/index.html"
       :basis ("ward-statement" "solo-title-idiom" "public-solo-lacks-trace")
       :reason "Ward states the change was made in an experimental Solo popup deployed only to localhost:3000; the popup is the only component in the chain that renders Graphviz SVG into its own document."
       :verification :not-directly-observed)
      (:id "project-identity" :relation :names-same-work
       :subject "layers of interpretation" :work "trace / trails drawn over Solo aspect graphs"
       :basis ("ward-statement" "trails-rendered-page" "trail-rel-type-change"
               "graceful-polyline-asset")
       :verification :not-directly-observed))
     :hypothesized
     ((:id "want-is-node-index" :proposition "In the snippet, want is a Solo node index, because Solo's dotify names Graphviz nodes by index and so each g.node title holds that index."
       :basis ("solo-title-idiom") :status :unverified))
     :unresolved
     ((:subject "getBBox snippet" :relation :source-revision
       :status :not-public :inference "snippet-location")
      (:subject "layers of interpretation" :relation :public-anchor
       :status :not-found :basis ("phrase-search"))
      (:subject "federation" :relation :search-coverage
       :status :incomplete :basis ("federation-search")
       :limit "Sites outside the inspected neighbourhood were not searched.")))))

(hyperdoc:defexample initial-state
  "What was the state of the wiki checkout before this slice changed
anything? Observed on 2026-10-04 before any modification. Source state
only: no running wiki was observed here. Each call returns fresh data."
  (copy-tree
   '(:provenance (:kind :agent-observed :observer "Claude Code"
                  :observation-date "2026-10-04" :method :read-only-git-and-filesystem
                  :scope :source-state :runtime-observed nil)
     :observed
     ((:id "wiki-checkout" :kind :checkout
       :path "/Users/rgb/Projects/RalfBarkow/wiki" :branch "localhost"
       :upstream "origin/localhost" :ahead 0 :behind 0
       :head "47a9ca6b97597eedebe602bd80b8657978b813e3"
       :clean t :stash-entries 0)
      (:id "flake-mech-pin" :kind :flake-binding :file "flake.nix"
       :binding "mechSrc" :fetcher "fetchFromGitHub"
       :repository "https://github.com/RalfBarkow/wiki-plugin-mech"
       :rev "4b8051417dec6b0eff40878290a703b1fa60fb52"
       :hash "sha256-UQyFvFY+buaZQ8mAilJL1/XOCzTMS02D4O9d3BKbiYc=")
      (:id "pinned-mech-revision" :kind :git-commit
       :repository "https://github.com/RalfBarkow/wiki-plugin-mech"
       :commit "4b8051417dec6b0eff40878290a703b1fa60fb52" :branch "0.1.32-dev.1"
       :date "2026-01-31" :code-block-present nil
       :in-upstream-history nil)
      (:id "mech-code-block-introduced" :kind :git-commit
       :repository "https://github.com/WardCunningham/wiki-plugin-mech"
       :commit "215d9cd" :date "2026-03-17" :subject "add CODE block (work in progress)")
      (:id "flake-solo-pin" :kind :flake-binding :file "flake.nix"
       :binding "soloSrc" :fetcher "fetchurl"
       :url "https://registry.npmjs.org/wiki-plugin-solo/-/wiki-plugin-solo-0.1.30-1.tgz"
       :hash "sha256-HnKwvcEaA8uagQus0wmaC+uNAx5PuZdVVh+wJ7lYqrw=")
      (:id "lock-wiki-client" :kind :flake-lock-node :input "wiki-client-src"
       :original-rev "1aba55920f95b957bc8ccf3b3648c9b23d534c9a"
       :locked-url "https://github.com/RalfBarkow/wiki-client.git"
       :locked-ref "refs/heads/master"
       :locked-rev "4b290709a1906c2010306f0f47ebfad530d8b4b6")
      (:id "lock-wiki-server" :kind :flake-lock-node :input "wiki-server-src"
       :original "github:fedwiki/wiki-server/ec3527abf0d1c1e1929272d580a80905c1dbf381"
       :locked-url "https://github.com/RalfBarkow/wiki-server.git"
       :locked-ref "refs/heads/main"
       :locked-rev "0ea9ba00d8286faba7633e413e9786e3c4508fa8")
      (:id "existing-result" :kind :out-link
       :path "/Users/rgb/Projects/RalfBarkow/wiki/result"
       :target "/nix/store/ib56gml232vfswinxwqw65cin4z98xsc-wiki-0.39.2"
       :package-version "0.39.2" :wrapper-sets-rev-env nil
       :mech-version "0.1.32-dev.1" :solo-version "0.1.30-1")
      (:id "checkout-package-version" :kind :file-field
       :file "package.json" :field "version" :value "0.39.1")
      (:id "personal-wiki-config" :kind :path-existence
       :path "/Users/rgb/.wiki/config.json" :exists t
       :keys ("admin" "autoseed" "cookieSecret" "farm" "id" "port"
              "security_legacy" "security_type" "uploadLimit"))
      (:id "dirty-mech-checkout" :kind :checkout
       :path "/Users/rgb/workspace/wiki-plugin-mech" :branch "main"
       :head "47cba6d57bef6db43e237abcbad60829d78b691c"
       :untracked (".direnv/" "client/mech-build-info.js" "mech.patch"
                   "repomix-output.md" "wiki-plugin-mech-repomix-output.md")
       :disposition :left-untouched)
      (:id "mech-upstream-clone" :kind :checkout
       :path "/Users/rgb/workspace/wiki-plugin-mech-upstream" :branch "main"
       :head "a028b4bba04e539dcaa090423d38a00a0050489d" :clean t
       :origin "https://github.com/WardCunningham/wiki-plugin-mech.git"
       :created "2026-10-04 by this work"))
     :derived
     ((:id "pinned-mech-cannot-run-trails-rendered" :relation :capability-absence
       :subject "4b8051417dec6b0eff40878290a703b1fa60fb52" :lacks "CODE block"
       :basis ("pinned-mech-revision" "mech-code-block-introduced")
       :consequence "The mech item CODE trails on Trails Rendered cannot run.")
      (:id "existing-result-not-head-build" :relation :artifact-provenance
       :subject "/nix/store/ib56gml232vfswinxwqw65cin4z98xsc-wiki-0.39.2"
       :not-built-from "47a9ca6b97597eedebe602bd80b8657978b813e3"
       :basis ("existing-result" "checkout-package-version")
       :reason "The flake takes its version from package.json (0.39.1) and its postFixup sets WIKI_SERVER_REV / WIKI_CLIENT_REV; the artifact reports 0.39.2 and its wrapper sets neither."))
     :inferred
     ((:id "lock-governs-build" :relation :build-input-revision
       :subject "wiki-client-src, wiki-server-src"
       :revisions ("4b290709a1906c2010306f0f47ebfad530d8b4b6"
                   "0ea9ba00d8286faba7633e413e9786e3c4508fa8")
       :basis ("lock-wiki-client" "lock-wiki-server")
       :reason "Nix keeps a locked input whose original matches flake.nix; the locked revisions, not the revisions written in flake.nix, are then built."
       :verification :pending-runtime-check))
     :hypothesized ()
     :unresolved
     ((:subject "flake.lock" :relation :consistency-with-flake.nix
       :status :not-changed-by-this-work
       :limit "The locked revisions differ from the revisions named in flake.nix. This slice neither repairs nor relies on repairing that.")))))

(hyperdoc:defexample integration-decision
  "How should a CODE-capable mech enter the Nix-built wiki without a broad
dependency upgrade? Records the alternatives, the choice and its limits,
decided before the wiki checkout was modified. Each call returns fresh data."
  (copy-tree
   '(:provenance (:kind :agent-decision :decider "Claude Code"
                  :decision-date "2026-10-04" :requested-by "operator")
     :requirement "Run Trails Rendered with public mech 0.1.48-3 behaviour and public Solo 0.1.30-1 behaviour, keeping the Nix execution model."
     :observed
     ((:id "plugin-route-resolution" :kind :source-location
       :file "wiki-server lib/server.js (in the existing result)"
       :mechanism "require.resolve(plugin/package) from the wiki-server location in the Nix store"
       :consequence "A runtime packageDir overlay cannot replace the served mech client.")
      (:id "flake-mech-binding" :kind :source-location :file "flake.nix"
       :mechanism "postInstall copies mechSrc into node_modules/wiki-plugin-mech and links plugins/mech"))
     :alternatives
     ((:id "runtime-overlay" :choice :rejected
       :basis ("plugin-route-resolution"))
      (:id "change-default-pin" :choice :rejected
       :reason "A permanent upgrade of the checkout's default mech pin; broader than a local development override.")
      (:id "flake-input-override" :choice :rejected
       :reason "Adds a flake input and a lock node to a flake.lock whose nodes already disagree with flake.nix.")
      (:id "impure-environment-override" :choice :chosen
       :mechanism "WIKI_MECH_SRC=<built checkout> nix build .#wiki --impure"
       :reason "Default pin and flake.lock stay unchanged; the override is explicit in the build command and visible in the store path name."))
     :boundaries
     ((:not-changed "default mech pin 4b8051417dec6b0eff40878290a703b1fa60fb52")
      (:not-changed "solo pin 0.1.30-1")
      (:not-changed "flake.lock")
      (:not-changed "/Users/rgb/Projects/RalfBarkow/wiki/result")
      (:not-changed "/Users/rgb/.wiki")
      (:not-changed "/Users/rgb/workspace/wiki-plugin-mech")
      (:not-added "Trace relation suppression, missing-node layout, getBBox lookup, swoopy-arrow overlay")))))

;;; Runtime state, kept apart from source state. Nothing here is inferred
;;; from a source revision; each record names the running artifact, the
;;; process, the HTTP response or the browser observation it comes from.
(hyperdoc:defexample runtime-verification
  "What did the running local wiki actually load and do? Observed on
2026-10-04 against the process on 127.0.0.1:3477 and in a separate Chrome
window. Failed attempts are kept: they explain why the final observation
was made the way it was. Each call returns fresh data."
  (copy-tree
   '(:provenance (:kind :agent-observed :observer "Claude Code"
                  :observation-date "2026-10-04" :scope :runtime-state
                  :browser-run (:started "2026-10-04T06:43:16.234Z"
                                :finished "2026-10-04T06:43:21.755Z"))
     :observed
     ((:id "artifact" :kind :nix-artifact
       :path "/nix/store/155fjjd6pv29d8lwpzljmqpv4ifa44bg-wiki-0.39.1"
       :out-link "/Users/rgb/workspace/wiki-trails-rendered-local/result-wiki"
       :mech-input "/nix/store/c8734mbf8g7xxr9j8yypmxws8732fgj0-wiki-plugin-mech-local"
       :mech-version "0.1.48-3"
       :mech-bundle-sha256 "c72ed0a572469d29c3287dafe8c8770c636d2537dbcfbededdd60a244d1e2384"
       :solo-version "0.1.30-1" :solo-dialog-identical-to "17915844349bada64c901bd5ea73472702c446f9"
       :graphviz-version "0.11.9" :frame-version "0.10.3" :code-version "0.5.0")
      (:id "artifact-rev-stamps" :kind :wrapper-environment
       :artifact "/nix/store/155fjjd6pv29d8lwpzljmqpv4ifa44bg-wiki-0.39.1"
       :wiki-server-rev "0ea9ba00d8286faba7633e413e9786e3c4508fa8"
       :wiki-client-rev "4b290709a1906c2010306f0f47ebfad530d8b4b6")
      (:id "local-mech-build" :kind :build-output
       :checkout "/Users/rgb/workspace/wiki-plugin-mech-upstream"
       :commit "a028b4bba04e539dcaa090423d38a00a0050489d"
       :file "client/mech.js"
       :sha256 "c72ed0a572469d29c3287dafe8c8770c636d2537dbcfbededdd60a244d1e2384"
       :banner "wiki-plugin-mech - 0.1.48-3 - Sun, 04 Oct 2026 06:32:59 GMT"
       :esbuild "0.28.2" :tests (:total 72 :pass 67 :skipped 5 :fail 0)
       :prettier-check :pass)
      (:id "published-mech-bundle" :kind :served-asset
       :site "next.ward.dojo.fed.wiki"
       :banner "wiki-plugin-mech - 0.1.48-3 - Tue, 30 Jun 2026 18:53:10 GMT"
       :bytes 87879 :local-bundle-bytes 89830)
      (:id "process" :kind :process :pid 28582 :worker-pid 28595
       :program "/nix/store/155fjjd6pv29d8lwpzljmqpv4ifa44bg-wiki-0.39.1/lib/node_modules/wiki/index.js"
       :node "/nix/store/qf5mbd0idrxp0ahb45pd5yqajfyz5kbc-nodejs-22.18.0/bin/node"
       :arguments ("--port" "3477" "--host" "127.0.0.1" "--data"
                   "/Users/rgb/workspace/wiki-trails-rendered-local/data")
       :home "/Users/rgb/workspace/wiki-trails-rendered-local/home"
       :listener "127.0.0.1:3477" :security-module "./security.js"
       :personal-config-keys-present nil)
      (:id "served-assets" :kind :http-check :base "http://127.0.0.1:3477"
       :mech-sha256 "c72ed0a572469d29c3287dafe8c8770c636d2537dbcfbededdd60a244d1e2384"
       :solo-dialog-identical-to "17915844349bada64c901bd5ea73472702c446f9"
       :client-stamp "wiki-client - 0.31.6-dev+4b29070"
       :plugins-include ("code" "frame" "graphviz" "mech" "solo")
       :factories-include ("Code" "Graphviz" "Mech" "Solo"))
      (:id "local-page" :kind :wiki-page
       :file "/Users/rgb/workspace/wiki-trails-rendered-local/data/pages/trails-rendered"
       :source-url "http://ward.voices.ustawi.wiki/trails-rendered.json"
       :source-copy "/Users/rgb/workspace/wiki-trails-rendered-local/source/trails-rendered.ward.voices.ustawi.wiki.json"
       :source-sha256 "5fdba40fd3a68eddee00497af4dadb3847500356a2f131dbc0745afb86de9810"
       :fetched "2026-10-04T06:33:48Z" :source-journal-entries 103
       :local-journal-entries 104
       :appended-journal-entry (:type "fork" :site "ward.voices.ustawi.wiki" :date 1791095628000)
       :story-identical-to-source t :served-identical-to-file t)
      (:id "pane-popup-attempt" :kind :failed-attempt
       :browser "Claude Code built-in browser pane"
       :observation "window.open returned null; the pane loaded /plugins/solo/dialog/ in the same tab, without an opener"
       :error "TypeError: Cannot read properties of null (reading 'location') in mech SOLO"
       :consequence "The pane cannot host the mech-to-Solo popup handoff.")
      (:id "pane-code-and-preview" :kind :browser-observation
       :browser "Claude Code built-in browser pane"
       :code-status "CODE trails ⇒ 2 aspects"
       :imports (("https://wardcunningham.github.io/graph/graph.js" 200)
                 ("https://wardcunningham.github.io/graph/cypher.js" 200))
       :preview-page "Mech Preview" :preview-solo-text "LINEUP INCLUDED"
       :aspects ((:name "trail 1" :nodes ("Susan Kare" "John Dewey" "Reflective Practice")
                  :rels ((0 1 "Trail") (1 2 "Trail")))
                 (:name "trail 2" :nodes ("Jean Lave" "Dorothy Smith" "Reflective Practice")
                  :rels ((0 1 "Trail") (1 2 "Trail")))))
      (:id "chrome-window" :kind :browser
       :program "/Applications/Google Chrome.app" :version "Chrome/148.0.7778.179"
       :profile "/Users/rgb/workspace/wiki-trails-rendered-local/chrome-profile"
       :devtools "127.0.0.1:9333" :claude-in-chrome :not-connected)
      (:id "outside-interaction" :kind :state-change
       :observation "Between script runs the lineup gained lakoff-und-johnson and the Solo dialog already existed; the driving script had made no such action."
       :handling "The final run starts from a fresh page load and accepts the reused dialog.")
      (:id "script-revisions" :kind :failed-attempt
       :script "/Users/rgb/workspace/wiki-trails-rendered-local/verify-trails-rendered.mjs"
       :failures ("waited for three CLICK buttons before the outer CLICK had run"
                  "required a new popup target, but mech reuses the window named solo"
                  "matched a lower-case console description that Chrome reports as Object"
                  "chose both aspects at once; Solo skips a selection made while drawing"))
      (:id "browser-run" :kind :browser-observation
       :driver "/Users/rgb/workspace/wiki-trails-rendered-local/verify-trails-rendered.mjs"
       :driver-sha256 "dea5da00691551180a1cfbb9d7bbc66f6decf6e4ac4d48c2de521b9d6f550081"
       :evidence-file "/Users/rgb/workspace/wiki-trails-rendered-local/runtime-evidence.json"
       :evidence-sha256 "950916a54e83dafa841fd3d65714df30c4a45f03049da376f30436af79c9d489"
       :browser-mech-sha256 "c72ed0a572469d29c3287dafe8c8770c636d2537dbcfbededdd60a244d1e2384"
       :code-status "⇒ 2 aspects"
       :solo-status "⇒ 1 sources, 2 aspects"
       :dialog-reused t :dialog-opener "http://localhost:3477/view/trails-rendered"
       :batch-received-log "refreshBeam"
       :beam ((:value "0" :name "trail 1" :node-count "3")
              (:value "1" :name "trail 2" :node-count "3")))
      (:id "render-one-aspect" :kind :rendered-svg :chosen ("0")
       :nodes (("0" "Susan Kare") ("1" "John Dewey") ("2" "Reflective Practice"))
       :edges (("0->1" "Trail") ("1->2" "Trail")))
      (:id "render-two-aspects" :kind :rendered-svg :chosen ("0" "1")
       :nodes (("2" "Reflective Practice") ("0" "Susan Kare") ("1" "John Dewey")
               ("3" "Jean Lave") ("4" "Dorothy Smith"))
       :edges (("0->1" "Trail") ("1->2" "Trail") ("3->4" "Trail") ("4->2" "Trail"))
       :emphasized-nodes ("2")
       :screenshot "/Users/rgb/workspace/wiki-trails-rendered-local/screenshot-solo-popup.png"
       :screenshot-sha256 "711f62cc7df954d5a708a0b6545ee47c120af7fc3d40e6934c6a117b28f7312b")
      (:id "console-errors" :kind :browser-console
       :errors ("getScript: Failed to load: /security/security.js (404)"
                "TypeError: Cannot read properties of undefined (reading 'setup') in client.js")
       :related-to "default security module; not mech, not Solo")
      (:id "data-writes" :kind :filesystem
       :directory "/Users/rgb/workspace/wiki-trails-rendered-local/data"
       :files ("pages/trails-rendered" "status/sitemap.json" "status/sitemap.xml"
               "status/site-index.json")
       :page-journal-entries-after-run 104))
     :derived
     ((:id "runtime-serves-local-mech" :relation :artifact-identity
       :subject "http://127.0.0.1:3477/plugins/mech/mech.js"
       :identical-to "client/mech.js built from a028b4bba04e539dcaa090423d38a00a0050489d"
       :basis ("local-mech-build" "artifact" "served-assets" "browser-run")
       :reason "The same SHA-256 in the checkout, in the Nix artifact, over HTTP and as fetched by the browser page.")
      (:id "lock-governs-build-confirmed" :relation :build-input-revision
       :subject "wiki-client-src, wiki-server-src"
       :revisions ("4b290709a1906c2010306f0f47ebfad530d8b4b6"
                   "0ea9ba00d8286faba7633e413e9786e3c4508fa8")
       :basis ("artifact-rev-stamps" "served-assets")
       :confirms (initial-state :inferred "lock-governs-build"))
      (:id "public-path-reproduced" :relation :execution-path
       :subject "Trails Rendered"
       :path ("CLICK" "CODE trails" "this.aspect" "SOLO" "Solo popup" "dotify"
              "Graphviz SVG")
       :basis ("browser-run" "render-one-aspect" "render-two-aspects")
       :limit "Trail relations are drawn as ordinary labelled edges; that is the public behaviour.")
      (:id "no-page-writes" :relation :data-isolation
       :subject "/Users/rgb/workspace/wiki-trails-rendered-local/data"
       :basis ("data-writes" "local-page")
       :reason "Only server status files were added; the page kept its 104 journal entries."))
     :inferred ()
     :hypothesized ()
     :unresolved
     ((:subject "mech bundle bytes" :relation :byte-identity-with-published-release
       :status :not-established :basis ("local-mech-build" "published-mech-bundle")
       :limit "Same source, different esbuild (0.28.2 vs the release build); behaviour is taken from source identity, not from bytes.")))))

(hyperdoc:defexample provenance-chain
  "Follow Trails Rendered from Ward's public page to the rendered result,
one stage at a time, and mark the stage where the public sources end.
Every reproduced stage names the evidence that it ran here. The boundary
stage is described, not reconstructed. Each call returns fresh data."
  (copy-tree
   '(:provenance (:kind :agent-derived :observer "Claude Code"
                  :observation-date "2026-10-04"
                  :basis-readings (provenance-evidence initial-state runtime-verification))
     :stages
     ((:stage 1 :name :page-item :status :reproduced
       :what "Ward's public page and the items the path uses"
       :site "ward.voices.ustawi.wiki" :slug "trails-rendered" :title "Trails Rendered"
       :items ((:id "6405b752d1739af0" :type "mech" :text "CLICK / CODE trails / CLICK SOLO / CLICK PREVIEW synopsis items")
               (:id "17a5b123160ef0d9" :type "code" :role "import Graph from wardcunningham.github.io/graph/graph.js")
               (:id "cc6a77771de7edbd" :type "code" :role "export function trails")
               (:id "84da00fa76850971" :type "code" :role "function trail; rel type Trail"))
       :source-sha256 "5fdba40fd3a68eddee00497af4dadb3847500356a2f131dbc0745afb86de9810"
       :evidence ((provenance-evidence :observed "trails-rendered-page")
                  (runtime-verification :observed "local-page")))
      (:stage 2 :name :plugin-version :status :reproduced
       :what "The plugins that interpret those items"
       :mech (:version "0.1.48-3" :source "a028b4bba04e539dcaa090423d38a00a0050489d"
              :entry "src/client/blocks.js code_emit and solo_emit")
       :solo (:version "0.1.30-1" :behaviour-of "17915844349bada64c901bd5ea73472702c446f9"
              :entry "client/dialog/index.html composite and dotify")
       :external-module (:url "https://wardcunningham.github.io/graph/graph.js"
                         :pinned nil :fetched-at-runtime t)
       :evidence ((runtime-verification :derived "runtime-serves-local-mech")
                  (runtime-verification :observed "served-assets")))
      (:stage 3 :name :intermediate-representation :status :reproduced
       :what "this.aspect from trails(), handed to Solo as a batch"
       :aspect (:source "Trails Rendered"
                :result ((:name "trail 1" :nodes 3 :rels 2 :rel-type "Trail")
                         (:name "trail 2" :nodes 3 :rels 2 :rel-type "Trail")))
       :handoff "postMessage {type: batch, sources, pageKey} from mech SOLO to the window named solo"
       :evidence ((runtime-verification :observed "pane-code-and-preview")
                  (runtime-verification :observed "browser-run")))
      (:stage 4 :name :runtime-transformation :status :reproduced
       :what "Public Solo composites the chosen aspects and writes DOT"
       :transformation "composite merges equal nodes; dotify emits one labelled edge per relation"
       :layout "@hpcc-js/wasm 1.20.1 graphviz.layout(dot, svg, dot)"
       :evidence ((runtime-verification :observed "render-two-aspects")))
      (:stage 5 :name :rendered-result :status :reproduced
       :what "Graphviz SVG in the Solo popup"
       :result "5 nodes, 4 edges labelled Trail, Reflective Practice emphasized as shared"
       :evidence ((runtime-verification :observed "render-one-aspect")
                  (runtime-verification :observed "render-two-aspects")))
      (:stage 6 :name :interpretation-layer :status :not-reproducible
       :what "Ward's unpublished change to the Solo popup"
       :described-by-ward ("trace relations get their own type and are labelled as such"
                           "dotify creates no edge for them (marked null, filtered later)"
                           "nodes of a trace that are not in the chosen aspects are added along the top")
       :reported-snippet "find g.node by its title text, then getBBox()"
       :planned "a swoopy arrow drawn over the graph (cf. graceful-polyline/polyline.html)"
       :first-unreproducible-operation "dotify omitting the edges of trace relations"
       :reason "The modified Solo dialog exists only on Ward's localhost:3000."
       :evidence ((provenance-evidence :observed "ward-statement")
                  (provenance-evidence :derived "public-solo-lacks-trace")
                  (provenance-evidence :inferred "snippet-location"))))
     :boundary (:after-stage 5 :label "PUBLIC REPRODUCTION ENDS HERE")
     :unresolved
     ((:subject "trace relation type name" :status :not-established
       :limit "Ward's prose says Trace; the public page code writes Trail. Which name his local dotify tests is not public.")
      (:subject "unpinned runtime modules" :status :reproducibility-limit
       :limit "graph.js and svg-pan-zoom are fetched unpinned at runtime; a later change there could change stages 3 to 5.")))))

(hyperdoc:defexample operations-record
  "What was changed, by which operations, and how can it be reproduced?
Lists every file this slice created or modified, the repository
operations, the build and run commands, and what was deliberately left
alone. Each call returns fresh data."
  (copy-tree
   '(:provenance (:kind :agent-record :recorder "Claude Code" :date "2026-10-04")
     :files-modified
     ((:repository "/Users/rgb/Projects/RalfBarkow/wiki" :file "flake.nix"
       :change "WIKI_MECH_SRC impure override of mechSrc; default pin unchanged"
       :committed nil
       :patch "/Users/rgb/workspace/wiki-trails-rendered-local/flake-mech-override.patch"
       :patch-sha256 "e3710b63098c23c31c539b91604db63baeb8a2ca0ff2bbcc723919223e782d8f")
      (:repository "/Users/rgb/workspace/hyperdoc-trails-rendered"
       :files ("dreyeck/work/trails-rendered-reading.lisp"
               "dreyeck/pages/work/Trails Rendered public reproduction.html"
               "dreyeck/tests/work-trails-rendered-reading.lisp"
               "dreyeck.asd" "dreyeck/pages/work/Work Breakdown.html")
       :committed nil :authoring :text-edit
       :note "Not authored through the dreyeck/workflow structural writer."))
     :files-created-outside-repositories
     ((:directory "/Users/rgb/workspace/wiki-trails-rendered-local"
       :contents ("source/" "data/" "home/" "chrome-profile/" "result-wiki"
                  "nix-build.log" "wiki.log" "chrome.log" "run.txt"
                  "verify-trails-rendered.mjs" "runtime-evidence.json"
                  "screenshot-main.png" "screenshot-solo-popup.png"
                  "flake-mech-override.patch" "verify-run.out" "hyperdoc-test.log"
                  "hyperdoc-test-full.log" "hyperdoc-test-full-tala.log"))
      (:directory "/Users/rgb/workspace/wiki-plugin-mech-upstream"
       :contents ("node_modules/" "client/mech.js" "client/mech.js.map" "meta-client.json")
       :git-status :clean))
     :repository-operations
     ((:repository "/Users/rgb/workspace/wiki-plugin-mech-upstream"
       :operations ("git clone https://github.com/WardCunningham/wiki-plugin-mech.git"
                    "git fetch origin +refs/pull/*/head:refs/remotes/origin/pr/*"))
      (:repository "/Users/rgb/workspace/hyperdoc"
       :operations ("git worktree add -b claude/trails-rendered-public-slice /Users/rgb/workspace/hyperdoc-trails-rendered 4b56913e88c67e1434bc83665a2d623b73268c56"))
      (:repository "/Users/rgb/Projects/RalfBarkow/wiki"
       :operations ("read-only status, log, diff; no commit, no reset, no stash")))
     :commands
     ((:step :build-mech :directory "/Users/rgb/workspace/wiki-plugin-mech-upstream"
       :run ("npm ci --no-audit --no-fund" "npm run build"))
      (:step :build-wiki :directory "/Users/rgb/Projects/RalfBarkow/wiki"
       :run ("WIKI_MECH_SRC=/Users/rgb/workspace/wiki-plugin-mech-upstream nix build .#wiki --impure --out-link /Users/rgb/workspace/wiki-trails-rendered-local/result-wiki --print-out-paths -L"))
      (:step :stage-page :directory "/Users/rgb/workspace/wiki-trails-rendered-local"
       :run ("curl -fsS http://ward.voices.ustawi.wiki/trails-rendered.json -o source/trails-rendered.ward.voices.ustawi.wiki.json"
             "jq '.journal += [{type: fork, site: ward.voices.ustawi.wiki, date: <now ms>}]' > data/pages/trails-rendered"))
      (:step :run-wiki :directory "/Users/rgb/workspace/wiki-trails-rendered-local"
       :run ("HOME=$PWD/home result-wiki/bin/wiki --port 3477 --host 127.0.0.1 --data $PWD/data"))
      (:step :open-browser
       :run ("Google Chrome --user-data-dir=chrome-profile --remote-debugging-port=9333 --remote-debugging-address=127.0.0.1 --no-first-run --no-default-browser-check --new-window http://localhost:3477/view/trails-rendered"))
      (:step :verify :directory "/Users/rgb/workspace/wiki-trails-rendered-local"
       :run ("node verify-trails-rendered.mjs runtime-evidence.json")))
     :verification
     ((:test "dreyeck/work/trails-rendered-reading/tests run-tests" :shell "nix develop"
       :result :pass)
      (:test "asdf:test-system dreyeck/work/reading/tests" :shell "nix develop"
       :result :fail :cause "existing D2 Connections test: program d2 unavailable"
       :remedy-named-by-test "nix develop .#tala")
      (:test "asdf:test-system dreyeck/work/reading/tests" :shell "nix develop .#tala"
       :result :pass :includes ("existing work tests" "trails-rendered tests")))
     :not-changed
     ("flake.lock" "/Users/rgb/Projects/RalfBarkow/wiki/result" "/Users/rgb/.wiki"
      "/Users/rgb/workspace/wiki-plugin-mech" "/Users/rgb/workspace/hyperdoc-dreyeck-ch"
      "the default mech pin" "the Solo pin")
     :not-added
     ("Trace relation suppression" "missing-node top-row layout" "getBBox lookup"
      "swoopy-arrow overlay"))))
