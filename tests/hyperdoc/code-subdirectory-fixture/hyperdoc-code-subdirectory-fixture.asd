(asdf:defsystem #:hyperdoc-code-subdirectory-fixture
  :description "Fixture for HyperDoc code-subdirectory tests"
  :serial t
  :components
  ((:module "pages"
    :components
    ((:static-file "Main.html")))
   (:module "src"
    :serial t
    :components
    ((:file "package")
     (:module "nested"
      :serial t
      :components
      ((:file "example")))))))
