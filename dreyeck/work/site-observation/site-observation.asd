;;;; Read-only HTTPS observation of the Dreyeck hosts and sites, with one DITA task and Play per site.
;;;; Its own .asd, so that a running HyperDoc image (the white image on port 8080) can load it from a
;;;; separate checkout without redefining dreyeck.asd.

(asdf:defsystem "site-observation"
  :description "Host and site views that observe the deployed FedWiki and HyperDoc sites over HTTPS on request"
  :license "BSD"
  :depends-on ("dreyeck/shop3" "dreyeck/authority-policy" "dreyeck/dita-story-item"
               "html-inspector-views" "hyperbook/server" "clog" "clog-moldable-inspector" "plump" "shasht" "ironclad")
  :components ((:file "observation") (:static-file "observe-site.dita")
               (:static-file "playground-guard.dita") (:static-file "playground-guard-code.dita")
               (:static-file "check-playground-binding.dita"))
  :in-order-to ((asdf:test-op (asdf:test-op "site-observation/tests"))))

(asdf:defsystem "site-observation/tests"
  :depends-on ("site-observation" "usocket")
  :components ((:module "tests" :components ((:file "observation"))))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :site-observation :run-tests)))
