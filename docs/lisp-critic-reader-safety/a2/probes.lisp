;;;; Independent reconstructions; verbatim cases are in reviewer-probes.lisp.
(asdf:load-system "dreyeck/lisp-critic/text-criticism/tests")
(when (uiop:getenv "A2_BASELINE_SOURCE") (load (uiop:getenv "A2_BASELINE_SOURCE")))
(in-package #:dreyeck/lisp-critic/text-criticism/tests)
(let* ((baseline (uiop:getenv "A2_BASELINE_SOURCE"))
       (definition "(defun historical-claims () (copy-tree '((:subject :a))))")
       (comment (format nil "#\\a;~A~%" definition))
       ;; Escaped quotes let the defective character scanner swallow both string
       ;; delimiters while the genuine Lisp reader keeps the definition inside it.
       (string-source (format nil "#\\a\"~A~%#\\b\"" definition))
       (checks 0))
  (labels ((check-a2 (value label) (incf checks) (assert value () "A2: ~A" label))
           (refusal (text) (nth-value 1 (passage:read-claim-table text))))
    (dolist (pair (list (cons "RECONSTRUCTED-COMMENT" comment)
                       (cons "RECONSTRUCTED-STRING" string-source)))
      (let ((why (refusal (cdr pair))))
        (format t "~&~A source=~S refusal=~S~%" (car pair) (cdr pair) why)
        (check-a2 (if baseline (null why) why) (car pair))))
    (unless baseline
      (dolist (character '(#\; #\" #\( #\) #\' #\` #\, #\\ #\| #\Space #\Newline))
        (let ((source (format nil "#\\~C~%~A" character definition)))
          (check-a2 (null (refusal source)) "literal punctuation must not consume the next form")))
      (dolist (name '("a" "Space" "Newline" "Tab" "Return" "Page" "Rubout" "Backspace"))
        (check-a2 (null (refusal (format nil "#\\~A; ignored~%~A" name definition))) "adjacent comment")
        (check-a2 (null (refusal (format nil "#\\~A\"ignored\"~%~A" name definition))) "adjacent string"))
      (dolist (source (list "#\\" "#\\NotACharacter" "#\\a\\b" "#S(x)"
                            "#+x (defun historical-claims () (copy-tree '()))"
                            (format nil "#\\a\"unterminated~%~A" definition)))
        (check-a2 (refusal source) "unsupported/incomplete syntax"))
      (check-a2 (null (refusal (file-text +claims+))) "committed Fischer source")
      (check-a2 (refusal (table-source "((:subject #\\a))")) "characters remain unsupported table values"))
    (format t "~&A2-~A-PASS: ~D checks.~%" (if baseline "BASELINE-REPRODUCTION" "CORRECTED") checks)))
