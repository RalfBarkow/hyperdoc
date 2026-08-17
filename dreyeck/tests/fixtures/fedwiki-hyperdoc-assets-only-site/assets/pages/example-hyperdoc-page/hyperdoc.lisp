(in-package #:example-hyperdoc-page)

(hyperdoc:defhyperdoc *hyperdoc*
  :title "Example HyperDoc Page"
  :id "example-hyperdoc-page"
  :asdf-system-name "example-hyperdoc-page"
  :subdirectory "pages"
  :code-subdirectory "src"
  :main-page-id "Example HyperDoc Page")
