(require :asdf)
(asdf:load-system "dreyeck/topicmap/tests")
(dolist (name '(dreyeck/topicmap/tests::run-generic-topicmap-view-test
                dreyeck/topicmap/tests::run-topicmap-workspace-test
                dreyeck/topicmap/tests::run-topicmap-workspace-association-navigation-test
                dreyeck/topicmap/tests::run-semantic-topicmap-presentation-smoke-test
                dreyeck/topicmap/tests::run-structural-containment-sign-mapping-test))
  (assert (funcall name))
  (format t "~&EXISTING-TOPICMAP ~A PASS~%" name))
