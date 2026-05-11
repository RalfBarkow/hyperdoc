;;;; SLY/MREPL Git helpers for HyperDoc maintenance.
;;;;
;;;; These helpers are intentionally small and image-friendly. They support
;;;; committing generated HyperDoc pages and artifacts from a live SLY MREPL.

(in-package #:hyperdoc)

(defparameter *hyperdoc-repo*
  (asdf:system-relative-pathname :hyperdoc ""))

(defun git-output* (repo &rest args)
  "Run git in REPO and return combined stdout/stderr as a string.
This helper ignores non-zero exit status so callers can inspect Git output
without dropping into the debugger for routine no-op cases."
  (let ((out (make-string-output-stream)))
    (uiop:run-program
     (append (list "git" "-C" (namestring repo)) args)
     :output out
     :error-output out
     :ignore-error-status t)
    (get-output-stream-string out)))

(defun git!* (repo &rest args)
  "Run git in REPO, streaming output to the current REPL.
This helper is intended for commands whose failure should be visible
immediately, such as add and commit."
  (uiop:run-program
   (append (list "git" "-C" (namestring repo)) args)
   :output t
   :error-output t))

(defun commit-dm6-upstream-narrative-page! ()
  "Commit the generated dm6 upstream narrative HyperDoc page and report asset."
  (let ((files '("hyperdoc/DM6 Upstream Narrative Inspector.html"
                 "assets/dm6-elm/dm6-upstream-narrative-report.txt")))
    (apply #'git!* *hyperdoc-repo* "add" "--" files)
    (apply #'git!* *hyperdoc-repo*
           (append
            (list "commit"
                  "-m" "Document dm6 upstream narrative inspector"
                  "-m" "Add a HyperDoc page documenting the read-only dm6 upstream narrative inspector, including usage snippets, integration guidance, and a generated report link."
                  "--")
            files))
    (list
     :head (git-output* *hyperdoc-repo* "log" "--oneline" "-1")
     :status (git-output* *hyperdoc-repo* "status" "--short")
     :selected-status
     (apply #'git-output* *hyperdoc-repo* "status" "--short" "--" files))))

(defun commit-hyperdoc-sly-git-helpers! ()
  "Commit this helper source file itself."
  (let ((file "hyperdoc/sly-git-helpers.lisp"))
    (git!* *hyperdoc-repo* "add" "--" file)
    (git!* *hyperdoc-repo*
           "commit"
           "-m" "Persist SLY Git helpers for HyperDoc"
           "-m" "Add durable MREPL helper functions for running Git commands and committing generated dm6 upstream narrative documentation artifacts from the HyperDoc image."
           "--"
           file)
    (list
     :head (git-output* *hyperdoc-repo* "log" "--oneline" "-1")
     :status (git-output* *hyperdoc-repo* "status" "--short")
     :selected-status
     (git-output* *hyperdoc-repo* "status" "--short" "--" file))))
