;;;; Thin CLI for HyperDoc's topic coverage helper.

(require :asdf)
(asdf:load-system :hyperdoc)

(defun main ()
  (let ((args (remove "--" (uiop:command-line-arguments) :test #'string=)))
    (handler-case
        (let ((report (if args
                          (hyperdoc:documentation-topic-coverage-report
                           :pages args)
                          (hyperdoc:documentation-topic-coverage-report))))
          (hyperdoc:print-documentation-topic-coverage-report report)
          (uiop:quit (if (hyperdoc:documentation-topic-coverage-pass-p report)
                         0
                         1)))
      (error (condition)
        (format t "TOPIC_COVERAGE_FAIL~%")
        (format t "SCRIPT_ERROR ~A~%" condition)
        (uiop:quit 1)))))

(main)
