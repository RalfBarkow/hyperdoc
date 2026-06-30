(:shop3-plan-artifact
 (:id path-sensitive-hyperdoc-pre-commit-gate)
 (:title "Path-sensitive HyperDoc pre-commit gate")
 (:type :shop3-plan)
 (:planner :shop3)
 (:status :implemented-validated-committed)
 (:created-before-implementation t)
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:execution-status
  ((planned t)
   (implemented t)
   (validated t)
   (commit-status :committed)
   (implementation-commit "241bece03b6df5c61265f0b22d945002b5a78881")))

 (:problem-topic
  (path-sensitive-hyperdoc-pre-commit-gate
   :title "Path-sensitive HyperDoc pre-commit gate"
   :summary
   "HyperDoc should distinguish static documentation-page commits from Lisp/Nix/runtime commits before selecting the pre-commit validation gate."))

 (:knowledge
  ((repository-boundaries
    ((fedwiki-page-store "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/")
     (fedwiki-asset-store "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/")
     (hyperdoc-repository "/Users/rgb/workspace/hyperdoc/")))
   (observed-current-hook-chain
    ((local-hook ".git/hooks/pre-commit")
     (shape-check "tools/check-lisp-parens.sh")
     (load-gate "tools/check-lisp-load-gate.sh :hyperbook/server")
     (path-sensitive-shape-check t)
     (path-sensitive-load-gate nil)))
   (problem
    "HyperDoc currently runs the full Lisp/Nix/server load gate for every commit, even when the staged change is only static documentation HTML. This is safe but coarse.")
   (non-goal
    "Do not weaken validation for Lisp, ASDF, Nix, runtime, server, inspector, tests, executable HyperDoc HTML, or uncertain changes.")
   (validation-policy
    ((lisp-asdf-nix-server-runtime-inspector-tests full-load-gate)
     (static-hyperdoc-html-page-only light-html-page-gate)
     (executable-hyperdoc-html strong-page-runtime-or-full-load-gate)
     (uncertain-change full-load-gate)
     (fedwiki-page-store-own-repository-validation)
     (fedwiki-asset-store-own-repository-validation)))
   (executable-html-markers
    ("expr="
     "<html-expr"
     "<html-generator"
     "<view-transclusion"
     "<source-of-function"
     "<source-of-class"
     "<lisp-code"))
   (implementation-constraint
    ((first-artifact-before-code-edits t)
     (tracked-dispatcher-preferred t)
     (local-git-hook-is-not-durable-repo-artifact t)
     (full-gate-not-weakened-silently t)
     (codex-prompt-stays-slice-local t)))))

 (:domain
  (defdomain hyperdoc-pre-commit-gate-policy
    ((:operator
      (!record-problem-and-ordered-plan ?slice ?artifact)
      ((slice ?slice)
       (shop3-plan-artifact ?artifact))
      ()
      ((problem-plan-recorded ?slice ?artifact)))

     (:operator
      (!inspect-current-hook-chain ?slice)
      ((problem-plan-recorded ?slice ?artifact))
      ()
      ((current-hook-chain-known ?slice)))

     (:operator
      (!define-staged-path-classification ?slice)
      ((current-hook-chain-known ?slice))
      ()
      ((staged-path-classification-defined ?slice)))

     (:operator
      (!define-static-html-page-gate ?slice)
      ((staged-path-classification-defined ?slice))
      ()
      ((static-html-page-gate-defined ?slice)))

     (:operator
      (!define-escalation-rules ?slice)
      ((staged-path-classification-defined ?slice))
      ()
      ((full-gate-escalation-rules-defined ?slice)))

     (:operator
      (!implement-tracked-pre-commit-dispatcher ?slice)
      ((static-html-page-gate-defined ?slice)
       (full-gate-escalation-rules-defined ?slice))
      ()
      ((tracked-pre-commit-dispatcher-implemented ?slice)))

     (:operator
      (!wire-local-hook-to-dispatcher ?slice)
      ((tracked-pre-commit-dispatcher-implemented ?slice))
      ()
      ((local-hook-wired-to-dispatcher ?slice)))

     (:operator
      (!document-validation-policy ?slice)
      ((tracked-pre-commit-dispatcher-implemented ?slice))
      ()
      ((validation-policy-documented ?slice)))

     (:operator
      (!validate-policy-slice ?slice)
      ((tracked-pre-commit-dispatcher-implemented ?slice)
       (local-hook-wired-to-dispatcher ?slice)
       (validation-policy-documented ?slice))
      ()
      ((policy-slice-validated ?slice)))

     (:operator
      (!report-gate-policy-result ?slice)
      ((policy-slice-validated ?slice))
      ()
      ((gate-policy-result-reported ?slice)))

     (:method
      (implement-path-sensitive-pre-commit-gate ?slice)
      ((slice ?slice)
       (shop3-plan-artifact ?artifact))
      ((!record-problem-and-ordered-plan ?slice ?artifact)
       (!inspect-current-hook-chain ?slice)
       (!define-staged-path-classification ?slice)
       (!define-static-html-page-gate ?slice)
       (!define-escalation-rules ?slice)
       (!implement-tracked-pre-commit-dispatcher ?slice)
       (!wire-local-hook-to-dispatcher ?slice)
       (!document-validation-policy ?slice)
       (!validate-policy-slice ?slice)
       (!report-gate-policy-result ?slice))))))

 (:problem
  (defproblem path-sensitive-hyperdoc-pre-commit-gate-problem
    hyperdoc-pre-commit-gate-policy
    ((slice path-sensitive-hyperdoc-pre-commit-gate)
     (shop3-plan-artifact
      path-sensitive-hyperdoc-pre-commit-gate-plan))
    ((implement-path-sensitive-pre-commit-gate
      path-sensitive-hyperdoc-pre-commit-gate))))

 (:selected-plan
  ((!record-problem-and-ordered-plan
    path-sensitive-hyperdoc-pre-commit-gate
    path-sensitive-hyperdoc-pre-commit-gate-plan)
   (!inspect-current-hook-chain
    path-sensitive-hyperdoc-pre-commit-gate)
   (!define-staged-path-classification
    path-sensitive-hyperdoc-pre-commit-gate)
   (!define-static-html-page-gate
    path-sensitive-hyperdoc-pre-commit-gate)
   (!define-escalation-rules
    path-sensitive-hyperdoc-pre-commit-gate)
   (!implement-tracked-pre-commit-dispatcher
    path-sensitive-hyperdoc-pre-commit-gate)
   (!wire-local-hook-to-dispatcher
    path-sensitive-hyperdoc-pre-commit-gate)
   (!document-validation-policy
    path-sensitive-hyperdoc-pre-commit-gate)
   (!validate-policy-slice
    path-sensitive-hyperdoc-pre-commit-gate)
   (!report-gate-policy-result
    path-sensitive-hyperdoc-pre-commit-gate)))

 (:ordered-task-plan
  ((1
    :task !record-problem-and-ordered-plan
    :do "Create this durable SHOP3-style problem and ordered task plan before implementation edits.")
   (2
    :task !inspect-current-hook-chain
    :do "Reconfirm the current local hook calls the Lisp paren gate and then the full :hyperbook/server load gate.")
   (3
    :task !define-staged-path-classification
    :do "Classify staged paths into full-gate, static HyperDoc HTML page-only, executable HyperDoc HTML, FedWiki external store, and uncertain.")
   (4
    :task !define-static-html-page-gate
    :do "Define a light gate for static hyperdoc/*.html files that checks file existence, title/package shape, basic executable-marker absence, and git diff/status evidence.")
   (5
    :task !define-escalation-rules
    :do "Escalate to full load gate for Lisp, ASDF, Nix, runtime/server/inspector/test/validation changes, executable HTML, mixed changes, and uncertain classifications.")
   (6
    :task !implement-tracked-pre-commit-dispatcher
    :do "Add a tracked dispatcher under tools/ and keep the existing full load gate callable without semantic weakening.")
   (7
    :task !wire-local-hook-to-dispatcher
    :do "Update the checkout-local .git/hooks/pre-commit only after the tracked dispatcher exists.")
   (8
    :task !document-validation-policy
    :do "Update the durable HyperDoc validation/staging documentation and topic objects without restating all AGENTS.md rules.")
   (9
    :task !validate-policy-slice
    :do "Run syntax checks, dispatcher branch checks, documentation-slice validation, and the full load gate for the validation-policy implementation.")
   (10
    :task !report-gate-policy-result
    :do "Report exact files changed, exact validation commands, and whether static page materialization no longer masquerades as a runtime/Lisp change.")))

 (:output-contract
  ((general-task
    (implement-path-sensitive-pre-commit-gate ?slice))
   (current-instance
    (implement-path-sensitive-pre-commit-gate
     path-sensitive-hyperdoc-pre-commit-gate))
   (required-first-artifact
    "hyperdoc/path-sensitive-hyperdoc-pre-commit-gate-plan.sexp")
   (policy-outcomes
    ((static-html-only-commit-uses-light-gate t)
     (executable-html-commit-does-not-use-static-only-gate t)
     (lisp-asdf-nix-runtime-server-inspector-test-commit-uses-full-gate t)
     (fedwiki-store-change-validated-in-own-repository t)
     (uncertain-change-uses-full-gate t)))
   (validation
    ((shop3-plan-artifact-readable-as-s-expression t)
     (tracked-dispatcher-shell-syntax-ok t)
     (html-page-gate-syntax-ok t)
     (local-hook-shell-syntax-ok t)
     (full-load-gate-still-passes-for-runtime-slice t)
     (documentation-slice-validation-passes t)
     (git-diff-check-passes t))))))
