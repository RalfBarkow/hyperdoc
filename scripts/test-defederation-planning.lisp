;;;; Batch fixture proof, separate from the user's coherent SLY image.
;;;; Run with the project's registered dependency closure:
;;;; sbcl --no-sysinit --no-userinit --non-interactive --load scripts/test-defederation-planning.lisp
(require :asdf)
(asdf:load-asd
 (merge-pathnames "../dreyeck.asd" (uiop:pathname-directory-pathname *load-truename*)))

(dolist (system '("dreyeck/work/defederation-planning/tests"
                  "dreyeck/work/planning/tests"
                  "dreyeck/work/remote-control-planning/tests"
                  "dreyeck/work/remote-control-planning/reading/tests"
                  "dreyeck/local-fedwiki-page/tests"
                  "hyperbook/fedwiki/tests"))
  (format t "~&SLICE-1 TEST-BEGIN ~A~%" system)
  (asdf:test-system system)
  (format t "~&SLICE-1 TEST-PASS ~A~%" system))

;; Render existing Inspector views without starting a server or browser.
(asdf:load-system "html-inspector-views/standard")
(loop for case in '(:a :b :c)
      for context = (dreyeck/work/defederation-planning:defederation-experiment case)
      for result = (getf context :result)
      for view = (html-inspector-views/standard:👀slots result)
      for html = (html-inspector-views:view-html view)
      for references = (html-inspector-views:view-references view)
      do (assert (eq result (html-inspector-views:view-object view)))
         (dolist (slot '("problem-name" "plans" "raw-plans" "plan-trees"
                         "final-states" "time" "execution-mode"))
           (assert (search slot (string-downcase html))))
         (dolist (value (list (dreyeck/shop3:plans-of result)
                             (dreyeck/shop3:plan-trees-of result)
                             (dreyeck/shop3:final-states-of result)))
           (assert (member value references :key #'cdr :test #'eq)))
         (format t "~&SLICE-1 INSPECTOR-PASS ~A: existing Slots view; original plan/tree/state references.~%"
                 case))
(format t "~&SLICE-1-PASS: plans observed; real Wiki actions NOT-EXECUTED.~%")
