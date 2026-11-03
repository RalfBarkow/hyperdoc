;;; The walk's negative control: CHECK-REACHABLE-CONTROLS, unchanged, with SERVED replaced by DEVELOPING. It must fail.
(require :asdf)
(asdf:load-system "dreyeck/topic-maps-public-views/tests")
(in-package :dreyeck/topic-maps-public-views/tests)
(setf (fdefinition 'served) #'developing)
(flet ((summary ()
         (let ((controls (getf *walk* :controls)))
           (format t "~&WALK (developing, offline): ~D objects, ~D controls, kinds ~S; connections refused to ~S~%"
                   (getf *walk* :objects) (length controls)
                   (loop for kind in '(:inert :slot-reader :reviewed :reviewed-class :refused :unknown)
                         collect (cons kind (length (controls-of-kind kind controls))))
                   (getf *walk* :connection-hosts)))))
  (handler-case (progn (check-reachable-controls) (summary) (format t "~&NEGATIVE-CONTROL-UNEXPECTED-PASS~%") (uiop:quit 1))
    (error (condition)
      (summary)
      (format t "~&NEGATIVE-CONTROL-FAILS-AS-EXPECTED: ~A~%"
              (let ((text (princ-to-string condition))) (subseq text 0 (min 600 (length text))))))))
