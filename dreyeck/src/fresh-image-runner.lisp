
(defpackage #:dreyeck/fresh-image-runner
  (:use #:cl)
  (:export #:run-fresh-asdf-test))

(in-package #:dreyeck/fresh-image-runner)

(defun current-lisp-program ()
  (or (uiop/image:argv0) (first sb-ext:*posix-argv*)
      (error "Cannot determine the current SBCL program.")))

(defun run-fresh-asdf-test
       (system-designator
        &key additional-asds package-name (function-name "RUN-TESTS")
        (marker "DREYECK-FRESH-ASDF-TEST-PASSED"))
  (let ((system (asdf/system:find-system system-designator nil)))
    (unless system (error "Unknown ASDF system ~S." system-designator))
    (let* ((system-name (asdf/component:component-name system))
           (system-asd (asdf/system:system-source-file system))
           (effective-package-name
            (or package-name (string-upcase system-name)))
           (program (current-lisp-program))
           (asds
            (remove-duplicates (cons system-asd additional-asds) :test
                               #'equal))
           (child-form
            `(progn
              (require :asdf)
              (dolist (asd ',asds) (asdf/find-system:load-asd asd))
              (asdf/operate:load-system ,system-name)
              (let* ((package (find-package ,effective-package-name))
                     (runner-symbol
                      (and package (find-symbol ,function-name package)))
                     (runner
                      (and runner-symbol (fboundp runner-symbol)
                           (symbol-function runner-symbol))))
                (unless runner
                  (error "Fresh child cannot resolve ~A::~A."
                         ,effective-package-name ,function-name))
                (let ((result (funcall runner)))
                  (unless (eq :passed (getf result :status))
                    (error "Fresh test failed: ~S" result))
                  (format t "~&~A~%" ,marker)
                  (finish-output)))))
           (command
            (list program "--noinform" "--non-interactive" "--eval"
                  "(progn (require :asdf) (unless (find-package \"DREYECK/FRESH-IMAGE-RUNNER\") (make-package \"DREYECK/FRESH-IMAGE-RUNNER\" :use '(\"CL\"))))"
                  "--eval" (prin1-to-string child-form))))
      (assert system-asd)
      (assert (and (stringp program) (plusp (length program))))
      (multiple-value-bind (output error-output status)
          (uiop/run-program:run-program command :output :string :error-output
                                        :output :ignore-error-status t)
        (declare (ignore error-output))
        (unless
            (and (zerop status) (stringp output)
                 (search marker output :test #'char=))
          (error "Fresh ASDF test failed for ~S (status ~S).~%~A" system-name
                 status output))
        (list :status :passed :system system-name :system-asd system-asd
              :additional-asds additional-asds :package-name
              effective-package-name :function-name function-name :program
              program :marker marker :child-status status :marker-observed-p
              t)))))
