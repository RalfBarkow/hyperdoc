(asdf/parse-defsystem:defsystem "page-attached-asdf-prerequisite-target")
(asdf/parse-defsystem:defsystem "page-attached-asdf-prerequisite-target/tests"
  :depends-on
  ("explicit-prerequisite"))
