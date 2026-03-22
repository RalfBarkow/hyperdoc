;;;; Thin CLI for HyperDoc's semantic-first anchor audit.

(require :asdf)
(asdf:load-system :hyperdoc)

(defun usage ()
  (format t
          "Usage:~%  tools/semantic-first-anchor-audit.sh~%~%Or directly:~%  sbcl --no-userinit --script tools/semantic-first-anchor-audit.lisp~%"))

(defun main ()
  (handler-case
      (let ((arguments (uiop:command-line-arguments)))
        (when (member "--help" arguments :test #'string=)
          (usage)
          (uiop:quit 0))
        (let ((report (hyperdoc:semantic-first-anchor-audit-report)))
          (hyperdoc:print-semantic-first-anchor-audit-report report)
          (uiop:quit (if (hyperdoc:semantic-first-anchor-audit-pass-p report)
                         0
                         1))))
    (error (condition)
      (format *error-output* "~A~%" condition)
      (uiop:quit 2))))

(main)
