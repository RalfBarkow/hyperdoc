(load (merge-pathnames "topic-maps-project-bootstrap.lisp" *load-truename*))
;; Executions in this fresh process. The review adds no corpus registration and no topic-maps change.
(asdf:load-system "dreyeck/work/topic-maps-ctm-review")
(asdf:test-system "dreyeck/work/topic-maps-ctm-review")
(asdf:test-system "dreyeck/work/topic-maps-project-example")
(format t "~&TOPIC-MAPS-CTM-REVIEW-REGRESSIONS-PASS~%")
