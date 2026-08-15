(defpackage #:dreyeck/fedwiki-hyperdoc-demo/tests
  (:use #:cl)
  (:export
   #:run-fedwiki-hyperdoc-demo-tests))

(in-package #:dreyeck/fedwiki-hyperdoc-demo/tests)

(defun run-fedwiki-hyperdoc-demo-tests ()
  (let ((hyperdoc
          dreyeck/fedwiki-hyperdoc-demo:*fedwiki-hyperdoc-demo*))
    (assert
     (typep hyperdoc 'hyperdoc:hyperdoc))
    (assert
     (string=
      "dreyeck/fedwiki-hyperdoc-demo"
      (hyperbook:id-of hyperdoc)))
    (assert
     (string=
      "dreyeck/fedwiki-hyperdoc-demo"
      (asdf:component-name
       (hyperdoc:asdf-system-of hyperdoc))))
    t))
