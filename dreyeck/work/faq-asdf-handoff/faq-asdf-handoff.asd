;;;; FAQ asdf-fasl-nix-store, revision 2: the SHOP3 plan and DITA tasks that bind the handoff commit,
;;;; run its checks and hand the evidence to Codex.
;;;; It has its own .asd so that a running HyperDoc image, such as the white image on port 8080, can load it
;;;; from a separate checkout of the handoff branch without redefining dreyeck.asd.

(asdf:defsystem "faq-asdf-handoff"
  :description "Executable SHOP3 plan with DITA tasks and Play steps for the FAQ asdf-fasl-nix-store revision 2 handoff"
  :license "BSD"
  :depends-on ("dreyeck/shop3" "dreyeck/git" "dreyeck/authority-policy" "dreyeck/dita-story-item"
               "html-inspector-views" "hyperbook/server" "clog" "ironclad" "plump" "shasht")
  :components ((:file "handoff")
               (:static-file "faq-asdf-handoff.ditamap")
               (:module "topics"
                :components ((:static-file "bind-revision.dita") (:static-file "check-asdf-output.dita")
                             (:static-file "check-mac.dita") (:static-file "hand-over-codex.dita")))
               (:static-file "run-checks.sh")
               (:static-file "restore-probe.lisp")
               (:module "evidence" :components ((:static-file "browser-run-linux.sexp"))))
  :in-order-to ((asdf:test-op (asdf:test-op "faq-asdf-handoff/tests"))))

(asdf:defsystem "faq-asdf-handoff/tests"
  :depends-on ("faq-asdf-handoff")
  :components ((:module "tests" :components ((:file "handoff"))))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :faq-asdf-handoff :run-tests)))
