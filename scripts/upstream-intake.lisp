;;;; Upstream intake: observe an upstream repository and assess what its new commits mean for this checkout. READ-ONLY and repeatable.
;;;;
;;;;   sbcl --noinform --no-sysinit --no-userinit --script scripts/upstream-intake.lisp --upstream-repository PATH [options]
;;;;
;;;;   --upstream-repository PATH   a repository this run may READ (a separate checkout or clone of upstream; never this one, never written, never fetched into)
;;;;   --ref NAME                   the upstream ref to observe (default main)
;;;;   --commit SHA                 assess this commit whatever the observed range (repeatable): for a notification that names one
;;;;   --state FILE                 default docs/upstream-intake/state.lisp-data (the last examined upstream commit; a person advances it, this never does)
;;;;   --ledger FILE                default docs/upstream-intake/ledger.lisp-data (the recorded decisions)
;;;;   --evidence-directory DIR     default docs/upstream-intake/evidence (recorded evidence for commits whose objects are in no repository given)
;;;;   --record-evidence SHA FILE   the one command that writes: save commit evidence read from --upstream-repository as plain data, to FILE
;;;;
;;;; Exit status: 0 nothing new, 10 new commits assessed (decisions are needed), 20 evidence missing for some commit, 2 usage.
;;;; It fetches nothing. A commit whose objects are not in the repositories given is reported as missing evidence.
;;;; To run it from a notification or on a schedule, call it with these arguments from whatever receives the notification or the timer. Nothing installs
;;;; that here: no service, no cron entry, no scheduler.
(require :asdf)
(asdf:initialize-source-registry
 `(:source-registry
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           unless (zerop (length path)) collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
   :inherit-configuration))
(let ((*standard-output* (make-broadcast-stream)) (*error-output* (make-broadcast-stream)))
  (asdf:load-system "dreyeck/workflow/upstream-assessment"))
(defun option (name arguments &optional default) (let ((p (position name arguments :test #'string=))) (if p (nth (1+ p) arguments) default)))
(defun options (name arguments) (loop for (a b) on arguments when (string= a name) collect b))
(let* ((arguments (uiop:command-line-arguments))
       (root (uiop:ensure-directory-pathname (or (uiop:getenv "HYPERDOC_ROOT") (asdf:system-source-directory "dreyeck"))))
       (upstream (option "--upstream-repository" arguments)))
  (when (or (null upstream) (member "--help" arguments :test #'string=))
    (format t "Usage: upstream-intake.lisp --upstream-repository PATH [--ref NAME] [--commit SHA]... [--state FILE] [--ledger FILE] [--evidence-directory DIR]~%       upstream-intake.lisp --upstream-repository PATH --record-evidence SHA FILE~%")
    (uiop:quit (if upstream 0 2)))
  (let ((upstream-repository (dreyeck/upstream-assessment:open-repository upstream)))
    (if (member "--record-evidence" arguments :test #'string=)
        (let* ((position (position "--record-evidence" arguments :test #'string=)) (sha (nth (1+ position) arguments)) (file (nth (+ 2 position) arguments))
               (evidence (dreyeck/upstream-assessment:evidence-from-repository upstream-repository sha)))
          (when (eq :missing (dreyeck/upstream-assessment:commit-evidence-availability evidence))
            (format t "~A is not in ~A: nothing to record. Nothing was fetched.~%" sha upstream) (uiop:quit 20))
          (dreyeck/upstream-assessment:write-recorded-evidence
           evidence file :recorded-from (list :upstream-url (or (getf (rest (dreyeck/upstream-assessment:read-state (merge-pathnames "docs/upstream-intake/state.lisp-data" root))) :upstream-url) "unknown")
                                              :method "scripts/upstream-intake.lisp --record-evidence: git rev-list, diff-tree and show, read-only"
                                              :recorded-at (let ((now (get-universal-time))) (multiple-value-bind (s mi h d mo y) (decode-universal-time now 0) (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ" y mo d h mi s)))))
          (format t "Recorded ~A (~D changed definition~:P) in ~A~%" sha (length (dreyeck/upstream-assessment:commit-evidence-changes evidence)) file)
          (uiop:quit 0))
        (let* ((fork-repository (dreyeck/upstream-assessment:open-repository root))
               (state (dreyeck/upstream-assessment:read-state (option "--state" arguments (merge-pathnames "docs/upstream-intake/state.lisp-data" root))))
               (ledger-file (option "--ledger" arguments (merge-pathnames "docs/upstream-intake/ledger.lisp-data" root)))
               (ledger (if (probe-file ledger-file) (dreyeck/upstream-assessment:read-ledger ledger-file) (dreyeck/upstream-assessment:make-ledger)))
               (run (dreyeck/upstream-assessment:assess-upstream
                     :upstream-repository upstream-repository :fork-repository fork-repository :fork-root root :ref (option "--ref" arguments "main")
                     :state state :ledger ledger :policy (dreyeck/upstream-assessment:default-ownership-policy root)
                     :commits (options "--commit" arguments)
                     :recorded-evidence (dreyeck/upstream-assessment:read-evidence-directory
                                         (option "--evidence-directory" arguments (merge-pathnames "docs/upstream-intake/evidence/" root))))))
          (dreyeck/upstream-assessment:report-run run)
          (finish-output)
          (uiop:quit (dreyeck/upstream-assessment:run-exit-status run))))))
