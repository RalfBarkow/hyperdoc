(in-package #:dreyeck/lisp-image)

(hyperdoc:defhyperdoc *lisp-image-hyperdoc*
  :id "dreyeck/lisp-image"
  :title "dreyeck.ch Lisp image"
  :asdf-system-name "dreyeck/lisp-image"
  :subdirectory "dreyeck/pages/lisp-image"
  :main-page-id "Lisp image HyperBook refactor")

(hyperdoc:defexample lisp-image-page-ownership-example
    "Compare page ownership between the main HyperDoc and the dreyeck.ch Lisp-image HyperDoc."
  (let* ((page-title "Lisp image HyperBook refactor")
         (main-hyperdoc hyperdoc::*hyperdoc*)
         (lisp-image-hyperdoc *lisp-image-hyperdoc*)
         (main-page
           (hyperbook:find-page
            main-hyperdoc
            page-title
            :signal-error? nil))
         (lisp-image-page
           (hyperbook:find-page
            lisp-image-hyperdoc
            page-title
            :signal-error? nil)))
    (list
     :page-title page-title
     :main-hyperdoc
     (list
      :hyperdoc main-hyperdoc
      :directory (hyperdoc::directory-of main-hyperdoc)
      :page main-page)
     :lisp-image-hyperdoc
     (list
      :hyperdoc lisp-image-hyperdoc
      :directory (hyperdoc::directory-of lisp-image-hyperdoc)
      :page lisp-image-page)
     :owned-by-lisp-image-hyperdoc
     (and lisp-image-page
          (null main-page)))))
