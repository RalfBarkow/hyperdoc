(in-package #:dreyeck/sly-mrepl/recording/tests)

(defun run-capture-record-test ()
  (let* ((failure-object
          (handler-case (error "Deterministic recording abort")
                        (error (failure-object) failure-object)))
         (success-capture
          (make-instance
           'dreyeck/sly-mrepl/recording::sly-mrepl-evaluation-capture
           :remote-id 1 :input-string "(values :success 37)" :package-before
           "COMMON-LISP-USER" :directory-before "/tmp/"))
         (abort-capture
          (make-instance
           'dreyeck/sly-mrepl/recording::sly-mrepl-evaluation-capture
           :remote-id 1 :input-string "(error \"abort\")" :package-before
           "COMMON-LISP-USER" :directory-before "/tmp/")))
    (setf (dreyeck/sly-mrepl/recording::capture-inner-returned-p
           success-capture)
            t
          (dreyeck/sly-mrepl/recording::capture-results-of success-capture)
            '(:success 37)
          (dreyeck/sly-mrepl/recording::capture-package-after-of
           success-capture)
            "DREYECK/SLICE-SUMMARY"
          (dreyeck/sly-mrepl/recording::capture-directory-after-of
           success-capture)
            "/tmp/"
          (dreyeck/sly-mrepl/recording::capture-condition-object-of
           abort-capture)
            failure-object
          (dreyeck/sly-mrepl/recording::capture-package-after-of abort-capture)
            "COMMON-LISP-USER"
          (dreyeck/sly-mrepl/recording::capture-directory-after-of
           abort-capture)
            "/tmp/")
    (let ((success
           (dreyeck/sly-mrepl/recording::record-from-capture success-capture
                                                             t))
          (aborted
           (dreyeck/sly-mrepl/recording::record-from-capture abort-capture
                                                             nil)))
      (unless
          (and
           (eq :returned
               (dreyeck/evaluation-record:evaluation-status-of success))
           (equal '(:success 37)
                  (dreyeck/evaluation-record:evaluation-result-of success))
           (null (dreyeck/evaluation-record:evaluation-failure-of success))
           (eq :aborted
               (dreyeck/evaluation-record:evaluation-status-of aborted))
           (null (dreyeck/evaluation-record:evaluation-result-of aborted))
           (eq failure-object
               (dreyeck/evaluation-record:evaluation-evidence-of aborted))
           (eq failure-object
               (dreyeck/evaluation-record:evaluation-failure-of aborted)))
        (error "SLY mREPL recording capture violates its contract."))
      t)))

(defun run-sly-mrepl-recording-tests () (run-capture-record-test))
