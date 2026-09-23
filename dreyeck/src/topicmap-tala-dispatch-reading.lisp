;;;; From DEFVIEW to Generic Dispatch
(in-package #:dreyeck/inspector/topicmap/tala)

(hyperdoc:see (hyperdoc:page "From DEFVIEW to Generic Dispatch"))

(hyperdoc:defexample reading-view-generic-function
  (fdefinition '👀tala-input))

(defun dispatch-method-observations (generic-function)
  "Keep the actual methods and specializers beside their observed sources.
For a generic function the existing Lisp-image projection already keeps
the live method, so this is only needed where there is no projection on
the page to read it from."
  (mapcar (lambda (method)
            (list :method method
                  :qualifiers (method-qualifiers method)
                  :specializers (sb-mop:method-specializers method)
                  :definition-source
                  (dreyeck/lisp-image::method-definition-source-of
                   generic-function method)))
          (sb-mop:generic-function-methods generic-function)))

(hyperdoc:defexample reading-view-workspace
  (tm::make-topicmap-workspace-for-object (reading-view-generic-function)))

(hyperdoc:defexample reading-view-projection
  (tm:topicmap-projection-of (reading-view-workspace)))

(hyperdoc:defexample reading-view-operations
  (mapcar
   (lambda (name)
     (let* ((function (fdefinition name))
            (generic-p (typep function 'generic-function)))
       (list :name name :function function
             :kind (if generic-p :generic-function :ordinary-function)
             :definition-sources
             (sb-introspect:find-definition-sources-by-name
              name (if generic-p :generic-function :function))
             ;; Accessor generic functions may have no pathname of their own.
             ;; Preserve that absence and show method sources separately.
             :methods (when generic-p
                        (dispatch-method-observations function)))))
   '(views:object-ref views:view-references views:all-views views:view-html)))
