(assert (equal (namestring sb-ext:*runtime-pathname*) (uiop:getenv "A1_PORTABLE_LAUNCHER")))
(multiple-value-bind (out err code)
    (uiop:run-program (list (namestring sb-ext:*runtime-pathname*) "--no-userinit" "--non-interactive"
                           "--eval" "(format t \"~&A1-CHILD-RUNTIME ~A ~A~%\" (lisp-implementation-type) (lisp-implementation-version))"
                           "--eval" "(assert (equal (namestring sb-ext:*runtime-pathname*) (uiop:getenv \"A1_PORTABLE_LAUNCHER\")))"
                           "--eval" "(uiop:quit 7)")
                      :output :string :error-output :string :ignore-error-status t)
  (write-string out) (write-string err)
  (assert (= 7 code))
  (assert (search "A1-CHILD-RUNTIME SBCL 2.4.10" out))
  (format t "~&A1-LAUNCHER-PASS: child executed Lisp; deliberate exit 7 preserved.~%"))
