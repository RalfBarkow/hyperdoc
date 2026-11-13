(load (merge-pathnames "probes-prelude.lisp" (directory-namestring *load-truename*)))
(in-package #:a1-review)
(let ((bs (string (code-char 92))) (semi (string (code-char 59))) (nl (string #\Newline)))
  ;; a valid character literal for the semicolon, then a real definition
  (probe "char-literal-semicolon" (concatenate 'string "(defvar *c* (list #" bs semi " 1))" (src "((:a :b))")) :truth t)
  ;; a real definition directly after a character literal and a semicolon comment marker: hidden?
  (probe "real-definition-after-char" (concatenate 'string "#" bs "a" nl (subseq (src "((:subject :real))") 1)) :truth t))
