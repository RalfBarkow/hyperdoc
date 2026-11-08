;;;; Run one ASDF test system (SUITE) of the tree PR_TREE and print SUITE-PASS or SUITE-ERROR with the condition type.
(require :asdf)
(defparameter cl-user::*review-tree*
  (uiop:ensure-directory-pathname
   (or (uiop:getenv "PR_TREE")
       (truename (merge-pathnames "../../../../" (uiop:pathname-directory-pathname *load-truename*))))))
(asdf:load-asd (merge-pathnames "dreyeck.asd" cl-user::*review-tree*))
(let ((s (or (uiop:getenv "SUITE") (error "Set SUITE to an ASDF system name."))))
  (format t "~&SUITE-BEGIN ~A~%" s)
  (handler-case (progn (asdf:test-system s) (format t "~&SUITE-PASS ~A~%" s))
    (error (c) (format t "~&SUITE-ERROR ~A ~S: ~A~%" s (type-of c)
                       ;; one line: newlines and runs of blanks collapsed
                       (let ((out (make-string-output-stream)) (blank nil))
                         (loop for ch across (princ-to-string c)
                               do (if (member ch '(#\Space #\Newline #\Tab))
                                      (setf blank t)
                                      (progn (when blank (write-char #\Space out) (setf blank nil)) (write-char ch out))))
                         (get-output-stream-string out))))))
