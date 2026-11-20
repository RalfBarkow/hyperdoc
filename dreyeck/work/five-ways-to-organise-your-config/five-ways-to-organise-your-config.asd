;;;; Five ways to organise your config (The Nix Arms, The Brewhouse) as Topic Maps and a HyperDoc.
;;;; A page-attached ASDF system: the system name is the page slug. Exactly one system depends directly on HYPERDOC.

(asdf:defsystem "five-ways-to-organise-your-config"
  :description "Die fünf Wege der Brewhouse-Seite als CTM-Topic-Maps, HyperDoc-Text- und Code-Pages und Topicmap-Workspace"
  :license "BSD; quoted Nix code from nixarms.com under the MIT License (LICENSE-nixarms.txt)"
  :depends-on ("hyperdoc" "topic-maps/ctm" "topic-maps/tmdm" "dreyeck/topicmap" "dreyeck/inspector/topicmap"
               "dreyeck/inspector/tmdm" "html-inspector-views")
  :serial t
  :components ((:module "src" :serial t
                :components ((:file "package") (:file "maps") (:file "workspace") (:file "sheets")))
               (:module "ctm"
                :components ((:static-file "schema.ctm") (:static-file "brewhouse.ctm") (:static-file "vanilla.ctm")
                             (:static-file "flakes.ctm") (:static-file "flake-parts.ctm") (:static-file "dendritic.ctm")
                             (:static-file "den.ctm") (:static-file "fleet.ctm")))
               (:module "pages"
                :components ((:static-file "five-ways.html") (:static-file "step-1-vanilla.html")
                             (:static-file "step-2-flakes.html") (:static-file "step-3-flake-parts.html")
                             (:static-file "step-4-dendritic.html") (:static-file "step-5-den.html")
                             (:static-file "tasting-board.html") (:static-file "fleet.html")
                             (:static-file "how-this-is-built.html")))
               (:module "fedwiki" :components ((:static-file "five-ways-to-organise-your-config.json")))
               (:static-file "LICENSE-nixarms.txt")
               (:file "hyperdoc"))
  :in-order-to ((asdf:test-op (asdf:test-op "five-ways-to-organise-your-config/tests"))))

(asdf:defsystem "five-ways-to-organise-your-config/tests"
  :depends-on ("five-ways-to-organise-your-config")
  :components ((:module "tests" :components ((:file "tests"))))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :five-ways :run-tests)))
