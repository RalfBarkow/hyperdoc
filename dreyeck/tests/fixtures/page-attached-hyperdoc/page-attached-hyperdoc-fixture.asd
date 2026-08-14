(asdf:defsystem "page-attached-hyperdoc-fixture"
  :serial t
  :components
  ((:module "src"
    :serial t
    :components
    ((:file "package")
     (:file "core")))
   (:module "pages"
    :components
    ((:static-file "Fixture.html")))))

(asdf:defsystem "page-attached-hyperdoc-fixture/presentation"
  :depends-on
  ("page-attached-hyperdoc-fixture"
   "hyperdoc")
  :serial t
  :components
  ((:file "hyperdoc")))
