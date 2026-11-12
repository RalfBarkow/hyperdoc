;;;; Fixed trusted punctuation examples only; this is not the production extractor.
(with-standard-io-syntax
  (let ((*read-eval* nil))
    (dolist (case '(("#\\a;" #\a 3) ("#\\a\"" #\a 3)
                    ("#\\;" #\; 3) ("#\\\"" #\" 3)))
      (multiple-value-bind (character end) (read-from-string (first case))
        (assert (char= character (second case)))
        (assert (= end (third case)))
        (format t "~&CHARACTER-BOUNDARY ~S -> ~S end=~D~%" (first case) character end)))))
(format t "~&A2-TRUSTED-CHARACTER-ORACLE-PASS: 4 cases.~%")
