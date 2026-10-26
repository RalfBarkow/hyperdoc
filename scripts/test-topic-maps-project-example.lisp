(load (merge-pathnames "topic-maps-project-bootstrap.lisp" *load-truename*))
;; These are executions in this process, not reused Slice 12A outcomes.
(asdf:test-system "dreyeck/work/topic-maps-project-example")
(asdf:test-system "dreyeck/work/tmdm-reading/tests")
(asdf:test-system "dreyeck/evaluation-record/tests")
(asdf:test-system "dreyeck/git/tests")
(asdf:test-system "dreyeck/topicmap/tests")
;; The separate Project Workspace is pinned to 5a4a668, not Slice 22U.
;; Its complete regression runs in its own fresh process with that checkout;
;; never mix TMDM implementations within this process.
(format t "~&TOPIC-MAPS-22U-INTEGRATION-REGRESSIONS-PASS~%")
