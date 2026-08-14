(asdf:defsystem "page-attached-asdf-fixture")

(asdf:defsystem "page-attached-asdf-fixture/hyperdoc"
  :depends-on
  ("page-attached-asdf-fixture"))

(asdf:defsystem "page-attached-asdf-fixture/tests"
  :depends-on
  ("page-attached-asdf-fixture"))
