(asdf:defsystem "example-hyperdoc-page"
  :serial t
  :components
  ((:module "src"
    :serial t
    :components
    ((:file "package")
     (:file "core")))
   (:module "pages"
    :components
    ((:static-file "Example HyperDoc Page.html")))))

(asdf:defsystem "example-hyperdoc-page/presentation"
  :depends-on
  ("example-hyperdoc-page"
   "hyperdoc"
   "hyperdoc/explorer")
  :serial t
  :components
  ((:file "hyperdoc")))

(asdf:defsystem "example-hyperdoc-page/tests"
  :depends-on
  ("example-hyperdoc-page"))
