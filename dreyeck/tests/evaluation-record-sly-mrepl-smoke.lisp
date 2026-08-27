(in-package #:dreyeck/evaluation-record/sly-mrepl/tests)

(defun run-sly-mrepl-evaluation-record-test ()
  (let* ((failure-object
          (handler-case (error "Deterministic mREPL abort")
                        (error (failure) failure)))
         (success
          (dreyeck/sly-mrepl:make-sly-mrepl-evaluation-record :remote-id 1
                                                              :input-string
                                                              "(values :success 42)"
                                                              :package-before
                                                              "COMMON-LISP-USER"
                                                              :directory-before
                                                              "/tmp/" :status
                                                              :returned
                                                              :results
                                                              '(:success 42)
                                                              :condition-object
                                                              nil
                                                              :package-after
                                                              "COMMON-LISP-USER"
                                                              :directory-after
                                                              "/tmp/"))
         (aborted
          (dreyeck/sly-mrepl:make-sly-mrepl-evaluation-record :remote-id 1
                                                              :input-string
                                                              "(error \"abort\")"
                                                              :package-before
                                                              "COMMON-LISP-USER"
                                                              :directory-before
                                                              "/tmp/" :status
                                                              :aborted :results
                                                              nil
                                                              :condition-object
                                                              failure-object
                                                              :package-after
                                                              "COMMON-LISP-USER"
                                                              :directory-after
                                                              "/tmp/"))
         (summary
          (dreyeck/slice-summary:make-slice-summary (list success aborted))))
    (unless
        (and
         (null (dreyeck/evaluation-record:evaluation-specification-of success))
         (equal "(values :success 42)"
                (dreyeck/evaluation-record:evaluation-input-of success))
         (eq :returned
             (dreyeck/evaluation-record:evaluation-status-of success))
         (equal '(:success 42)
                (dreyeck/evaluation-record:evaluation-result-of success))
         (null (dreyeck/evaluation-record:evaluation-failure-of success))
         (eq :aborted (dreyeck/evaluation-record:evaluation-status-of aborted))
         (null (dreyeck/evaluation-record:evaluation-result-of aborted))
         (eq failure-object
             (dreyeck/evaluation-record:evaluation-evidence-of aborted))
         (eq failure-object
             (dreyeck/evaluation-record:evaluation-failure-of aborted))
         (= 2 (dreyeck/slice-summary:slice-summary-record-count summary))
         (equal '(:returned :aborted)
                (mapcar (lambda (observation) (getf observation :status))
                        (dreyeck/slice-summary:slice-summary-status-observations
                         summary)))
         (= 1
            (length
             (dreyeck/slice-summary:slice-summary-failure-records summary)))
         (= 1
            (length
             (dreyeck/slice-summary:slice-summary-evidence-records summary)))
         (= 0
            (length
             (dreyeck/slice-summary:slice-summary-trace-records summary)))
         (= 0
            (length
             (dreyeck/slice-summary:slice-summary-identified-records summary)))
         (= 2
            (length
             (dreyeck/slice-summary:slice-summary-annotated-records summary))))
      (error "SLY mREPL evaluation-record integration violates its contract."))
    t))

(defun run-sly-mrepl-evaluation-record-tests ()
  (run-sly-mrepl-evaluation-record-test))
