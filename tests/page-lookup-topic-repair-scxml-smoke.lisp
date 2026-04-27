;;;; Smoke test for the page lookup topic repair SCXML protocol
;;
;;;; This test treats uSCXML as an optional local tool. If USCXML_BROWSER is
;;;; unset and the local default is absent, the test skips instead of making the
;;;; whole suite machine-specific.

(in-package :hyperdoc/tests)

(defun page-lookup-topic-repair-scxml-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun page-lookup-topic-repair-scxml-assert-substring (needle haystack message)
  (page-lookup-topic-repair-scxml-assert-true
   (and haystack (search needle haystack :test #'char=))
   (format nil "~A -- missing substring ~S" message needle)))

(defun page-lookup-topic-repair-scxml-browser ()
  (let ((env (uiop:getenv "USCXML_BROWSER"))
        (local-default "/Users/rgb/workspace/uscxml/build/bin/uscxml-browser"))
    (cond
      ((and env (probe-file env))
       env)
      (env
       (error "USCXML_BROWSER is set but does not point to a file: ~A" env))
      ((probe-file local-default)
       local-default)
      (t
       nil))))

(defun run-page-lookup-topic-repair-scxml-smoke-tests ()
  (let ((browser (page-lookup-topic-repair-scxml-browser)))
    (unless browser
      (format t "~&Page lookup topic repair SCXML smoke test skipped: USCXML_BROWSER not found.~%")
      (return-from run-page-lookup-topic-repair-scxml-smoke-tests t))

    (let* ((scxml (asdf:system-relative-pathname
                   :hyperdoc
                   "hyperdoc/page-lookup-issue-topic-repair.stub.scxml"))
           (command (list browser "-v" "-l5" (namestring scxml))))
      (multiple-value-bind (stdout stderr exit-code)
          (uiop:run-program command
                            :output :string
                            :error-output :string
                            :ignore-error-status t)
        (page-lookup-topic-repair-scxml-assert-true
         (zerop exit-code)
         (format nil "uSCXML run must exit zero.~%STDERR:~%~A~%STDOUT:~%~A"
                 stderr stdout))
        (page-lookup-topic-repair-scxml-assert-substring
         "classification=missing-topic"
         stdout
         "SCXML trace must classify needs-topic-creation as missing-topic")
        (page-lookup-topic-repair-scxml-assert-substring
         "repairOperation='create topic'"
         stdout
         "SCXML trace must expose create-topic repair operation")
        (page-lookup-topic-repair-scxml-assert-substring
         "UI.REPAIR_FIXED"
         stdout
         "SCXML trace must reach fixed")
        (format t "~&Page lookup topic repair SCXML smoke tests passed.~%")
        t))))