;;;; CLI runner for FedWiki-to-DMX import

(in-package :cl-user)

(require :asdf)
(asdf:load-system :hyperdoc/dmx-import :force t)

(defun usage ()
  (format t "Usage:~%")
  (format t "  sbcl --no-userinit --non-interactive ~%")
  (format t "    --eval '(require :asdf)' ~%")
  (format t "    --eval '(asdf:load-system :hyperdoc :force t)' ~%")
  (format t "    --load tools/import-fedwiki-site-to-dmx.lisp -- ~%")
  (format t "    --domain sfw.c2.com [--dry-run|--live] [--limit N] [--verbose]~%"))

(defun parse-args (args)
  (let ((domain nil)
        (dry-run t)
        (limit nil)
        (verbose nil))
    (loop while args
          for arg = (pop args)
          do (cond
               ((string= arg "--")
                nil)
               ((string= arg "--domain")
                (setf domain (pop args)))
               ((string= arg "--limit")
                (let ((raw (pop args)))
                  (setf limit (and raw (parse-integer raw)))))
               ((string= arg "--live")
                (setf dry-run nil))
               ((string= arg "--dry-run")
                (setf dry-run t))
               ((string= arg "--verbose")
                (setf verbose t))
               ((or (string= arg "-h")
                    (string= arg "--help"))
                (usage)
                (uiop:quit 0))
               (t
                (format *error-output* "~&Unknown argument: ~A~%" arg)
                (usage)
                (uiop:quit 2))))
    (unless domain
      (format *error-output* "~&Missing required --domain argument.~%")
      (usage)
      (uiop:quit 2))
    (list :domain domain
          :dry-run dry-run
          :limit limit
          :verbose verbose)))

(let* ((args (remove "--" (uiop:command-line-arguments) :test #'string=))
       (options (parse-args args)))
  (apply #'hyperdoc::import-fedwiki-site-to-dmx options)
  (uiop:quit 0))
