(in-package #:dreyeck/slice-summary/tests)

(defun run-heterogeneous-slice-summary-test ()
  (let* ((state-machine-record
          (dreyeck/state-machine/tests::make-example-state-machine-run))
         (root (asdf/system:system-source-directory "dreyeck"))
         (missing-root
          (namestring
           (merge-pathnames ".__dreyeck-lisp-critic-missing__/" root)))
         (target
          (namestring (merge-pathnames "dreyeck/src/lisp-critic.lisp" root)))
         (source-station
          (make-instance 'dreyeck/lisp-critic:lisp-critic-source-station :id
                         "slice-summary-missing-source-station" :title
                         "Slice summary missing source station" :asset-root
                         missing-root))
         (contract
          (make-instance 'dreyeck/lisp-critic:lisp-critic-contract :id
                         "slice-summary-missing-source-station-contract" :title
                         "Slice summary missing source station contract"
                         :source-station source-station))
         (lisp-critic-record
          (progn
           (when (probe-file missing-root)
             (error
              "Slice-summary missing-source fixture unexpectedly exists."))
           (dreyeck/lisp-critic:run-lisp-critic-contract contract
                                                         (list target))))
         (workspace-operation
          (make-instance 'dreyeck/workspace-operation:workspace-operation :id
                         "operation:slice-summary-test" :label
                         "Slice summary workspace evaluation" :subject-topic-id
                         "topic:slice-summary-subject" :subject
                         '(:subject :slice-summary-test) :function-symbol
                         'identity :result-topic-id
                         "topic:slice-summary-result" :intention :query
                         :perlocutionary-action :none :propositional-object
                         '(:proposition :slice-summary-test)))
         (workspace-record
          (dreyeck/workspace-operation:invoke-workspace-operation-recording-result
           workspace-operation))
         (records
          (list state-machine-record lisp-critic-record workspace-record))
         (summary (dreyeck/slice-summary:make-slice-summary records)))
    (unless
        (and (= 3 (dreyeck/slice-summary:slice-summary-record-count summary))
             (every #'eq records
                    (dreyeck/slice-summary:slice-summary-records-of summary))
             (equal '(:success :asset-missing :returned)
                    (mapcar (lambda (observation) (getf observation :status))
                            (dreyeck/slice-summary:slice-summary-status-observations
                             summary)))
             (equal (list lisp-critic-record)
                    (dreyeck/slice-summary:slice-summary-failure-records
                     summary))
             (equal (list state-machine-record)
                    (dreyeck/slice-summary:slice-summary-trace-records
                     summary))
             (equal (list state-machine-record lisp-critic-record)
                    (dreyeck/slice-summary:slice-summary-evidence-records
                     summary))
             (equal (list state-machine-record lisp-critic-record)
                    (dreyeck/slice-summary:slice-summary-identified-records
                     summary))
             (equal (list state-machine-record lisp-critic-record)
                    (dreyeck/slice-summary:slice-summary-annotated-records
                     summary)))
      (error "Heterogeneous slice-summary projection violates its contract."))
    t))

(defun run-slice-summary-tests () (run-heterogeneous-slice-summary-test))
