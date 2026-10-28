;;;; The ASDF method collision found while reviewing the Topic Maps packaging candidate, as part of that reading.
;;;; A separate system with its own .asd, added after the reading on port 18776 was started, so that the running
;;;; reading stays the pre-correction reference: it loaded neither this system nor its page. The collision was corrected on
;;;; 2026-10-27; this system keeps its records and the first guard's text, and says what holds now.

(asdf:defsystem "topic-maps-deployment-review-asdf-collision"
  :description "The first guard's ASDF method collision: its methods (kept), ASDF's originals, the recorded finding, its consequences and the correction"
  :license "BSD"
  :depends-on ("topic-maps-deployment-review" "sb-introspect")
  :components ((:file "collision")
               (:static-file "probe-asdf-method-collision.lisp")
               (:module "evidence" :components ((:static-file "project-workspace-pin-at-8e64e718.lisp") (:static-file "baseline.sexp") (:static-file "with-guard.sexp")
                                       (:static-file "catalog-topic-maps-before-correction.lisp"))))
  :in-order-to ((asdf:test-op (asdf:test-op "topic-maps-deployment-review-asdf-collision/tests"))))

(asdf:defsystem "topic-maps-deployment-review-asdf-collision/tests"
  :depends-on ("topic-maps-deployment-review-asdf-collision" "topic-maps-deployment-review/tests")
  :components ((:file "collision-tests"))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :topic-maps-deployment-review/tests :run-collision-tests)))
