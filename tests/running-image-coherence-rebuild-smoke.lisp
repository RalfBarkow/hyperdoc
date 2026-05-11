;;;; Smoke tests for the running-image coherence rebuild workflow.
;;
;; This test covers the documentation/runbook slice:
;;
;;   hyperdoc/running-image-coherence-rebuild.scxml
;;   hyperdoc/Running Image Coherence Rebuild Workflow.html
;;   hyperdoc/SCXML Architect.html
;;
;; It intentionally checks exact page lookup first. Near-match repair
;; candidates belong to a later diagnostic layer, not to this smoke test.

(in-package :hyperdoc/tests)

(defun ric-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun ric-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S"
           message expected actual)))

(defun ric-assert-substring (needle haystack message)
  (ric-assert-true
   (and haystack
        (search needle haystack :test #'char-equal))
   (format nil "~A -- missing substring ~S" message needle)))

(defun ric-workflow-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/running-image-coherence-rebuild.scxml"))

(defun ric-workflow-page-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/Running Image Coherence Rebuild Workflow.html"))

(defun ric-scxml-architect-page-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/SCXML Architect.html"))

(defun ric-state-ids (chart)
  (mapcar #'hyperdoc/scxml:scxml-state-id-of
          (hyperdoc/scxml:scxml-chart-states-of chart)))

(defun ric-find-state (chart state-id)
  (find state-id
        (hyperdoc/scxml:scxml-chart-states-of chart)
        :key #'hyperdoc/scxml:scxml-state-id-of
        :test #'string=))

(defun ric-transition-exists-p (chart source event target)
  (let ((state (ric-find-state chart source)))
    (and state
         (find-if
          (lambda (transition)
            (and (equal event
                        (hyperdoc/scxml:scxml-transition-event-of transition))
                 (equal target
                        (hyperdoc/scxml:scxml-transition-target-of transition))))
          (hyperdoc/scxml:scxml-state-transitions-of state)))))

(defun ric-error-findings (findings)
  (remove-if-not
   (lambda (finding)
     (eq :error
         (hyperdoc/scxml:scxml-validation-finding-severity-of finding)))
   findings))

(defun run-running-image-coherence-rebuild-scxml-smoke-test ()
  (asdf:load-system :hyperdoc/scxml)
  (let* ((chart (hyperdoc/scxml:parse-scxml-file
                 (ric-workflow-pathname)))
         (findings (hyperdoc/scxml:validate-scxml-chart chart))
         (error-findings (ric-error-findings findings))
         (state-ids (ric-state-ids chart)))
    (ric-assert-equal
     "running-image-coherence-rebuild"
     (hyperdoc/scxml:scxml-chart-name-of chart)
     "Workflow SCXML must have the expected chart name")

    (ric-assert-equal
     "source-changed"
     (hyperdoc/scxml:scxml-chart-initial-state-of chart)
     "Workflow SCXML must start at source-changed")

    (ric-assert-true
     (null error-findings)
     (format nil "Workflow SCXML must validate without :error findings: ~S"
             (mapcar #'hyperdoc/scxml:scxml-validation-finding-code-of
                     error-findings)))

    (dolist (expected-state
              '("source-changed"
                "reload-systems"
                "reload-text-pages"
                "refresh-derived-runtime-state"
                "scan-authored-links"
                "classify-page-lookup-issues"
                "rank-repair-candidates"
                "review-repairs"
                "apply-authored-repair"
                "verify-no-page-lookup-issues"
                "coherent"
                "failed"))
      (ric-assert-true
       (member expected-state state-ids :test #'string=)
       (format nil "Workflow SCXML must include state ~A" expected-state)))

    (dolist (final-state '("coherent" "failed"))
      (ric-assert-true
       (and (ric-find-state chart final-state)
            (hyperdoc/scxml:scxml-state-final-p-of
             (ric-find-state chart final-state)))
       (format nil "State ~A must be marked final" final-state)))

    (dolist (transition
              '(("source-changed" "begin" "reload-systems")
                ("reload-systems" "reload.ok" "reload-text-pages")
                ("reload-text-pages" "pages.reload.ok" "refresh-derived-runtime-state")
                ("refresh-derived-runtime-state" "derived-state.refreshed" "scan-authored-links")
                ("scan-authored-links" "links.scanned" "classify-page-lookup-issues")
                ("classify-page-lookup-issues" "lookup.clean" "verify-no-page-lookup-issues")
                ("classify-page-lookup-issues" "lookup.issues-found" "rank-repair-candidates")
                ("rank-repair-candidates" "candidates.ranked" "review-repairs")
                ("review-repairs" "repair.accepted" "apply-authored-repair")
                ("apply-authored-repair" "repair.applied" "reload-text-pages")
                ("verify-no-page-lookup-issues" "verification.clean" "coherent")))
      (destructuring-bind (source event target) transition
        (ric-assert-true
         (ric-transition-exists-p chart source event target)
         (format nil "Workflow SCXML must include transition ~A --~A--> ~A"
                 source event target)))))

  t)

(defun ric-page-by-title (title)
  (hyperbook:find-page
   hyperdoc::*hyperdoc*
   title
   :signal-error? t))

(defun ric-page-lookup-issues (page)
  (handler-case
      (hyperbook:lookup-issues-of page)
    (condition (condition)
      (error "Lookup-issue discovery signaled for ~S: ~A"
             (hyperbook:title-of page)
             condition))))

(defun run-running-image-coherence-rebuild-page-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (asdf:load-system :hyperdoc/inspector)

  (ric-assert-true
   (probe-file (ric-workflow-page-pathname))
   "Running Image Coherence Rebuild Workflow page file must exist")

  (ric-assert-true
   (probe-file (ric-scxml-architect-page-pathname))
   "SCXML Architect page file must exist")

  (hyperdoc::reload-text-pages hyperdoc::*hyperdoc*)

  (let ((workflow-source
          (uiop:read-file-string (ric-workflow-page-pathname)))
        (architect-source
          (uiop:read-file-string (ric-scxml-architect-page-pathname))))
    (ric-assert-substring
     "hyperdoc/running-image-coherence-rebuild.scxml"
     workflow-source
     "Workflow page must mention the SCXML artifact")

    (ric-assert-substring
     "page-lookup issue"
     workflow-source
     "Workflow page must document the page-lookup gate")

    (ric-assert-substring
     "Running Image Coherence Rebuild Workflow"
     architect-source
     "SCXML Architect page must link back to the rebuild workflow"))

  (dolist (title '("SCXML Architect"
                   "Running Image Coherence Rebuild Workflow"
                   "SCXML C Embedding Decision Map"))
    (let* ((page (ric-page-by-title title))
           (issues (ric-page-lookup-issues page)))
      (ric-assert-true
       page
       (format nil "Page ~S must resolve by exact HyperBook lookup" title))
      (ric-assert-true
       (null issues)
       (format nil "Page ~S must not introduce page-level lookup issues: ~S"
               title issues))))

  t)

(defun run-running-image-coherence-rebuild-smoke-tests ()
  (run-running-image-coherence-rebuild-scxml-smoke-test)
  (run-running-image-coherence-rebuild-page-smoke-test)
  (format t "~&Running-image coherence rebuild smoke tests passed.~%")
  t)
