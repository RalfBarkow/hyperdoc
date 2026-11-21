;;;; The Zettelkasten kiosk as a project: its work items, their evidence, open decisions, and the next step as SHOP3
;;;; computes it. A page-attached ASDF system: the system name is the page slug. Exactly one system depends directly on
;;;; HYPERDOC.

(asdf:defsystem "zettelkasten-kiosk"
  :description "Projektstatus des Zettelkasten-Kiosks: Vorhaben, Belege, Entscheidungen und der nächste Schritt aus SHOP3"
  :license "BSD"
  :depends-on ("hyperdoc" "dreyeck/shop3" "dreyeck/authority-policy" "dreyeck/dita-story-item" "html-inspector-views"
               "shasht")
  :serial t
  :components ((:module "src" :serial t
                :components ((:file "package") (:file "register") (:file "plan") (:file "observe") (:file "views")))
               (:static-file "status.sexp")
               (:static-file "project-task.dita")
               (:static-file "open-locally.dita")
               (:module "pages"
                :components ((:static-file "zettelkasten-kiosk.html") (:static-file "how-tracked.html")
                             (:static-file "remote-screen-decision.html") (:static-file "project-task.html")
                             (:static-file "open-locally.html")))
               (:module "fedwiki" :components ((:static-file "zettelkasten-kiosk.json")))
               (:file "hyperdoc"))
  :in-order-to ((asdf:test-op (asdf:test-op "zettelkasten-kiosk/tests"))))

(asdf:defsystem "zettelkasten-kiosk/tests"
  :depends-on ("zettelkasten-kiosk" "plump")
  :components ((:module "tests" :components ((:file "tests"))))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :zettelkasten-kiosk :run-tests)))
