;;;; Thin CLI for HyperDoc's documentation slice validation helper.

(require :asdf)
(asdf:load-system :hyperdoc)

(defun usage ()
  (format t
          "Usage:~%  tools/validate-documentation-slice.sh --page <hyperdoc-page-path> [--topic <topic-function-name> ...] [--fedwiki <fedwiki-page-file> ...]~%~%Examples:~%  tools/validate-documentation-slice.sh --page \"hyperdoc/Documentation Architecture in HyperDoc.html\" --topic documentation-architecture-in-hyperdoc-topic~%  tools/validate-documentation-slice.sh --page \"hyperdoc/Documentation Architecture in HyperDoc.html\" --fedwiki /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/documentation-architecture-in-hyperdoc~%"))

(defun parse-arguments (arguments)
  (let ((page nil)
        (topics '())
        (fedwiki-pages '()))
    (loop while arguments
          for arg = (pop arguments)
          do (cond
               ((member arg '("-h" "--help") :test #'string=)
                (usage)
                (uiop:quit 0))
               ((string= arg "--page")
                (unless arguments
                  (error "Missing value for --page."))
                (setf page (pop arguments)))
               ((string= arg "--topic")
                (unless arguments
                  (error "Missing value for --topic."))
                (push (pop arguments) topics))
               ((string= arg "--fedwiki")
                (unless arguments
                  (error "Missing value for --fedwiki."))
                (push (pop arguments) fedwiki-pages))
               (t
                (error "Unknown argument: ~A" arg))))
    (unless page
      (error "Missing required --page argument."))
    (values page (nreverse topics) (nreverse fedwiki-pages))))

(defun main ()
  (handler-case
      (multiple-value-bind (page topics fedwiki-pages)
          (parse-arguments (uiop:command-line-arguments))
        (let ((report (hyperdoc:validate-documentation-slice
                       :page page
                       :topics topics
                       :fedwiki-pages fedwiki-pages)))
          (hyperdoc:print-documentation-slice-validation-report report)
          (uiop:quit (if (hyperdoc:documentation-slice-validation-pass-p report)
                         0
                         1))))
    (error (condition)
      (format *error-output* "~A~%" condition)
      (uiop:quit 2))))

(main)
