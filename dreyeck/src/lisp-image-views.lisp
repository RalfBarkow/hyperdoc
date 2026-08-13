(in-package #:dreyeck/lisp-image)

(html-inspector-views:defview 👀loaded-functions
    (hyperbook hyperbook::lisp-functions)
  (let* ((inventory
           (make-lisp-image-inventory))
         (collection
           (make-lisp-image-page-collection
            :function
            inventory)))
    (html-inspector-views:list-view
     (lisp-image-page-collection-pages collection)
     :title "Loaded functions"
     :priority 2)))

(html-inspector-views:defview 👀loaded-classes
    (hyperbook hyperbook::lisp-classes)
  (let* ((inventory
           (make-lisp-image-inventory))
         (collection
           (make-lisp-image-page-collection
            :class
            inventory)))
    (html-inspector-views:list-view
     (lisp-image-page-collection-pages collection)
     :title "Loaded classes"
     :priority 2)))
