;;;; Contracts for reading ASDF definition source as syntax.
;;
;; The point of this layer is that reading is not a step towards
;; running. So the tests check two things at once: that the scanner
;; reports what is written, and that it declines to report what only
;; execution could establish.

(defpackage #:dreyeck/asdf-source/tests
  (:use #:cl)
  (:local-nicknames (#:src #:dreyeck/asdf-source))
  (:export #:run-tests))

(in-package #:dreyeck/asdf-source/tests)

(defun check (value control &rest arguments)
  (unless value (error (apply #'format nil control arguments)))
  value)

(defun defsystem-in (source)
  (multiple-value-bind (nodes issues) (src:scan-asdf-source source)
    (values (find-if #'src:asdf-defsystem-form-p nodes) issues)))

(defun declared-name (source)
  (let ((form (defsystem-in source)))
    (and form
         (src:simple-asdf-designator-name
          (second (src:asdf-source-node-children form))))))

(defun declared-dependencies (source)
  (let* ((form (defsystem-in source))
         (node (and form (src:depends-on-node form))))
    (and node
         (mapcar #'src:simple-asdf-designator-name
                 (src:asdf-source-node-children node)))))

(defun run-tests ()
  ;; What is written, is reported.
  (check (equal "plain" (declared-name "(defsystem #:plain)"))
         "A literal system name was not read.")
  (check (equal "quoted-name" (declared-name "(defsystem \"quoted-name\")"))
         "A string system name was not read.")
  (check (equal '("uiop" "alexandria")
                (declared-dependencies
                 "(defsystem #:x :depends-on (#:uiop #:alexandria))"))
         "Literal dependencies were not read.")
  ;; Nested components keep their structure.
  (let* ((form (defsystem-in
                   "(defsystem #:x :components ((:file \"a\")
                                                (:module \"src\" :components
                                                 ((:file \"b\")))))"))
         (components
           (loop for tail on (cddr (src:asdf-source-node-children form))
                 for key = (first tail)
                 when (and key (eq :token (src:asdf-source-node-kind key))
                           (string-equal ":components" (src:asdf-source-node-raw key)))
                   return (second tail))))
    (check components "A components list was not found.")
    (check (= 2 (length (src:asdf-source-node-children components)))
           "The components list lost an entry.")
    (check (find-if (lambda (child)
                      (src:asdf-source-node-children child))
                    (src:asdf-source-node-children components))
           "A nested module kept no children."))
  ;; Comments are skipped rather than mistaken for content.
  (check (equal "after-comments"
                (declared-name "; line comment
#| block (defsystem #:decoy) |#
(defsystem #:after-comments)"))
         "Comments were not skipped correctly.")
  ;; What only execution could establish, is not claimed.
  (check (null (declared-name "(defsystem (compute-name))"))
         "A computed system name was guessed instead of declined.")
  (check (null (defsystem-in "(when (probe-file \"x\") (defsystem #:hidden))"))
         "A definition inside another form was reported as top-level.")
  ;; Constructs whose meaning needs the reader or the image are flagged
  ;; or left as text, never resolved.
  (multiple-value-bind (form issues)
      (defsystem-in "(defsystem #:x :depends-on #.(list :uiop))")
    (check form "A definition with #. was not found at all.")
    (check issues "Read-time evaluation was passed over without an issue."))
  (multiple-value-bind (form issues) (defsystem-in "#| unterminated")
    (check (null form) "A definition was found in unterminated source.")
    (check issues "Unterminated source produced no issue."))
  ;; #+ and #- are structure, not truth: the same text scans the same
  ;; way in any image, which is why the scanner must not apply them.
  (check (equal "x" (declared-name "(defsystem #:x #+sbcl :depends-on #+sbcl (#:uiop))"))
         "A feature conditional prevented reading the name.")
  (format t "~&ASDF-SOURCE-PASS: what is written is read; what only running ~
could settle is not claimed.~%")
  t)
