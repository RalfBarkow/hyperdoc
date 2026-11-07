;;;; Fresh-process check of the opt-in link-resolution model, its neighbours, and the Inspector rendering.
;;;; With the project's dependency registry (e.g. in `nix develop`):
;;;;   sbcl --noinform --no-sysinit --no-userinit --non-interactive --load scripts/test-fedwiki-link-resolution.lisp
;;;; No network is used: the Java observations are read from tests/fedwiki-java-reference/observed.json.
(require :asdf)
(asdf:load-asd (merge-pathnames "../dreyeck.asd" (uiop:pathname-directory-pathname *load-truename*)))

(asdf:load-system "dreyeck/shop3")
(let ((catalog-before (copy-list (hyperbook:hyperbooks-of hyperbook:*catalog*)))
      (default-domain shop3:*domain*))
  (asdf:test-system "dreyeck/work/fedwiki-link-resolution")
  (assert (equal catalog-before (hyperbook:hyperbooks-of hyperbook:*catalog*)))
  (assert (eq default-domain shop3:*domain*))
  (format t "~&LINK-RESOLUTION-OPT-IN-PASS: no Catalog member added; SHOP3:*DOMAIN* unchanged.~%"))

(dolist (system '("dreyeck/work/defederation-planning/tests" "dreyeck/work/planning/tests"
                  "dreyeck/work/remote-control-planning/tests"))
  (asdf:test-system system)
  (format t "~&LINK-RESOLUTION-NEIGHBOUR-PASS: ~A~%" system))

;; The existing Inspector views, rendered to HTML without a server or browser.
(asdf:load-system "html-inspector-views/standard")
(loop for (scenario policy) in '(("context-newest-first" collaborative) ("context-newest-first" local-only)
                                 ("network-error" collaborative) ("panel-site" collaborative))
      for context = (dreyeck/work/fedwiki-link-resolution:link-resolution-experiment
                     scenario (if (string= scenario "panel-site") 1 0)
                     (find-symbol (string-upcase policy) :dreyeck/work/fedwiki-link-resolution))
      for result = (getf context :result)
      for view = (html-inspector-views/standard:👀slots result)
      for html = (string-downcase (html-inspector-views:view-html view))
      for references = (html-inspector-views:view-references view)
      do (assert (eq result (html-inspector-views:view-object view)))
         (dolist (slot '("problem-name" "plans" "raw-plans" "plan-trees" "final-states" "time" "execution-mode"))
           (assert (search slot html)))
         (dolist (value (list (dreyeck/shop3:plans-of result) (dreyeck/shop3:plan-trees-of result) (dreyeck/shop3:final-states-of result)))
           (assert (member value references :key #'cdr :test #'eq)))
         (dolist (object (list result context))
           (dolist (v (html-inspector-views:all-views object))
             (when (typep v 'html-inspector-views:html-view) (html-inspector-views:view-html v))))
         (format t "~&LINK-RESOLUTION-INSPECTOR-PASS ~A ~(~A~): ~S; result slots and plan/tree/state references; every HTML view of result and context renders.~%"
                 scenario policy (mapcar (lambda (o) (getf o :outcome)) (getf context :outcomes))))
(format t "~&LINK-RESOLUTION-ALL-PASS: plans only; no request, fork or write was executed.~%")
