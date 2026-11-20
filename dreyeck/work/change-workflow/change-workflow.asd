;;;; The change workflow as a SHOP3 plan: for each registered change, the next step of the DITA task
;;;; "Eine Änderung vom Branch bis auf die Server bringen". Plan only: it proposes, the operator acts.

(asdf:defsystem "change-workflow"
  :description "Branch, pull request, staging acceptance, merge, re-pin and production for each registered change, as SHOP3 offers"
  :license "BSD"
  :depends-on ("dreyeck/shop3" "dreyeck/authority-policy" "dreyeck/dita-story-item" "html-inspector-views"
               "hyperbook/server" "clog" "clog-moldable-inspector" "plump" "shasht")
  :components ((:file "workflow") (:static-file "change-workflow.dita") (:static-file "register.sexp"))
  :in-order-to ((asdf:test-op (asdf:test-op "change-workflow/tests"))))

(asdf:defsystem "change-workflow/tests"
  :depends-on ("change-workflow")
  :components ((:module "tests" :components ((:file "workflow") (:static-file "register-2026-11-20-initial.sexp"))))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :change-workflow :run-tests)))
