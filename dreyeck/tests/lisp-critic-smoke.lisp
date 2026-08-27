(in-package #:dreyeck/lisp-critic/tests)

(defun run-lisp-critic-runtime-test ()
  (let* ((root (asdf/system:system-source-directory "dreyeck"))
         (missing-root
          (namestring
           (merge-pathnames ".__dreyeck-lisp-critic-missing__/" root)))
         (target
          (namestring (merge-pathnames "dreyeck/src/lisp-critic.lisp" root)))
         (source-station
          (make-instance 'dreyeck/lisp-critic:lisp-critic-source-station :id
                         "missing-source-station" :title
                         "Missing source station" :asset-root missing-root))
         (contract
          (make-instance 'dreyeck/lisp-critic:lisp-critic-contract :id
                         "missing-source-station-contract" :title
                         "Missing source station contract" :source-station
                         source-station)))
    (when (probe-file missing-root)
      (error "LISP-CRITIC missing-asset fixture unexpectedly exists."))
    (when
        (dreyeck/lisp-critic:lisp-critic-source-station-present-p
         source-station)
      (error "Missing source station was reported present."))
    (when (dreyeck/lisp-critic:lisp-critic-contract-available-p contract)
      (error "Contract with missing source station was reported available."))
    (let ((record
           (dreyeck/lisp-critic:run-lisp-critic-contract contract
                                                         (list target))))
      (unless
          (and (typep record 'dreyeck/lisp-critic:lisp-critic-run-record)
               (eq contract
                   (dreyeck/lisp-critic:lisp-critic-run-record-contract-of
                    record))
               (eq :asset-missing
                   (dreyeck/lisp-critic:lisp-critic-run-record-status record))
               (stringp
                (dreyeck/lisp-critic:lisp-critic-run-record-raw-output record))
               (equal (list target)
                      (dreyeck/lisp-critic:lisp-critic-run-record-target-paths
                       record))
               (equal
                (list :not-run :reason :asset-missing :asset-root missing-root)
                (dreyeck/lisp-critic:lisp-critic-run-record-invocation-form-of
                 record)))
        (error "Missing-source-station run record violates its contract.")))
    (handler-case
     (progn
      (dreyeck/lisp-critic:run-lisp-critic-contract contract
                                                    '("relative-target.lisp"))
      (error "Relative target path was accepted."))
     (error (condition)
            (unless
                (search
                 "Relative LISP-CRITIC target path requires adapter-specific resolution"
                 (princ-to-string condition))
              (error condition))))
    t))

(defun run-lisp-critic-tests () (run-lisp-critic-runtime-test))
