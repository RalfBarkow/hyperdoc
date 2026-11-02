;;;; The assessment of one upstream commit, as examples of the Upstream Intake reading. Nothing here opens a repository: the commit is known from recorded
;;;; evidence (docs/upstream-intake/evidence), the decisions from the ledger (docs/upstream-intake/ledger.lisp-data), the fork from this checkout's source.

(in-package #:dreyeck/upstream-intake)

(defparameter +assessed-commit+ "58a2b2c66f0f5a0900a32910e5991e7d1833d9ed"
  "Konrad Hinsen's \"Catch more name service errors\", 2026-11-02: the worked example of the assessment.")

(defun upstream-assessment-root ()
  (uiop:ensure-directory-pathname (asdf:system-source-directory "dreyeck/upstream-intake")))

(defun upstream-assessment-run ()
  "An intake run for the worked example, from recorded evidence and the ledger of this checkout. It reads files of the checkout and writes none."
  (let ((root (upstream-assessment-root)))
    (dreyeck/upstream-assessment:assess-upstream
     :fork-root root :policy (dreyeck/upstream-assessment:default-ownership-policy root) :commits (list +assessed-commit+)
     :state (dreyeck/upstream-assessment:read-state (merge-pathnames "docs/upstream-intake/state.lisp-data" root))
     :ledger (dreyeck/upstream-assessment:read-ledger (merge-pathnames "docs/upstream-intake/ledger.lisp-data" root))
     :recorded-evidence (dreyeck/upstream-assessment:read-evidence-directory (merge-pathnames "docs/upstream-intake/evidence/" root)))))

(hyperdoc:defexample upstream-assessment-run-example
  "The intake run for the worked example: what was last examined, which commit is assessed, and on what evidence."
  (upstream-assessment-run))

(hyperdoc:defexample upstream-assessment-commit-example
  "The assessment of upstream 58a2b2c against this checkout's source: its changed definition, where that stands in the fork, who owns it, what it may affect, what is proposed and what is recorded."
  (first (dreyeck/upstream-assessment:intake-run-commits (upstream-assessment-run))))

(hyperdoc:defexample upstream-assessment-chain-example
  "The chain from the upstream commit to the decision, its required migration and its verification, as a Topicmap workspace whose links name what supports them."
  (dreyeck/inspector/upstream-assessment:change-chain-workspace
   (first (dreyeck/upstream-assessment:commit-assessment-changes (first (dreyeck/upstream-assessment:intake-run-commits (upstream-assessment-run)))))))
