;;;; Finding an Existing Page Lookup Function: executable example for the Work HyperDoc.
(in-package #:dreyeck/work/reading)

(hyperdoc:defexample page-lookup-methods-example
  "Inspect existing CLOS dispatch methods of HYPERBOOK:FIND-PAGE, without looking up pages."
  (mapcar (lambda (method)
            (mapcar (lambda (specializer)
                      (if (typep specializer 'class)
                          (class-name specializer)
                          specializer))
                    (sb-mop:method-specializers method)))
          (sb-mop:generic-function-methods #'hyperbook:find-page)))
