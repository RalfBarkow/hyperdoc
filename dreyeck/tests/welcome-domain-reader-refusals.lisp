;;;; D2: diagnostics only; no restart may recover an accepted source object.
(in-package #:dreyeck/work/welcome-development)

(defun w2-exact-reader-refusal (text detail)
  (handler-case (progn (read-development-domain-form text) (error "Expected reader refusal"))
    (invalid-development-record (c)
      (assert (equal (list :domain-version-untrusted detail) (refusal-reason c)))
      (format t "~&D2 refusal PASS: ~S~%" (refusal-reason c)))))

(defun run-domain-reader-refusal-tests ()
  (dolist (pair '(("#:x" :unsupported-dispatch-macro)
                  ("other-package::x" :foreign-package)
                  ("(cl:car x)" :symbol-not-allowlisted)
                  ("#S(x)" :structure)
                  ("#+w2-reader-feature x" :feature-expression)
                  ("#'x" :unsupported-dispatch-macro)))
    (w2-exact-reader-refusal
     (format nil "(shop3:defdomain (welcome-development :noset t) (~A))" (first pair)) (second pair)))
  (let ((wrapped-seen nil) (recover-offered nil) (recover-invoked nil) (calls 0)
        (public (w2-public-snapshot)) (cache (w2-cache-snapshot)))
    ;; Force the client-level fallback despite the strict reader's NIL policy.
    ;; Eclector itself wraps the client's real refusal and offers RECOVER.
    (w2-wrapped (eclector.reader:state-value
                 (lambda (original client aspect)
                   (if (eq '*read-eval* aspect) t (funcall original client aspect))))
      (w2-wrapped (eclector.reader:read-from-string
                   (lambda (original &rest args)
                     (handler-bind
                         ((eclector.reader:read-time-evaluation-error
                            (lambda (condition)
                              (setf wrapped-seen t
                                    recover-offered (not (null (find-restart 'eclector.base:recover condition)))))))
                       (multiple-value-prog1 (apply original args)
                         ;; Reaching a returned object after that condition would
                         ;; indicate recovery; the production reader must escape.
                         (when wrapped-seen (setf recover-invoked t))))))
        (w2-wrapped (clear-development-domain-cache
                     (lambda (original &rest args) (incf calls) (apply original args)))
          (w2-exact-reader-refusal
           "(shop3:defdomain (welcome-development :noset t) (#.(clear-development-domain-cache)))"
           :read-time-evaluation))))
    (assert wrapped-seen) (assert recover-offered) (assert (not recover-invoked)) (assert (zerop calls))
    (w2-cache-unchanged cache) (w2-public-unchanged public)
    (format t "~&D2 WRAPPED PASS: real Eclector condition/recover restart observed; client reason preserved; no recovery/object/mutation.~%"))
  ;; Reader syntax failures still refuse with their original Eclector class.
  (handler-case (progn (read-development-domain-form "(shop3:defdomain (") (error "Expected syntax refusal"))
    (invalid-development-record (c)
      (assert (eq :domain-version-untrusted (first (refusal-reason c))))
      (assert (eq :reader-condition (first (second (refusal-reason c)))))
      (format t "~&D2 SYNTAX PASS: ~S~%" (refusal-reason c))))
  t)
