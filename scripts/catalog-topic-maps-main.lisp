;;; Executable adapter of hyperdoc-catalog-topic-maps, as scripts/catalog-main.lisp is of hyperdoc-catalog.
(require :asdf)
;; Loopback only, decided before anything is loaded: the optional Topic Maps readings have run buttons that the
;; served Catalog's authority policy does not gate. An unset host becomes 127.0.0.1; any other host is refused.
(let ((host (uiop:getenv "HYPERDOC_CATALOG_HOST")))
  (cond ((member host '(nil "") :test #'equal) (setf (uiop:getenv "HYPERDOC_CATALOG_HOST") "127.0.0.1"))
        ((not (member host '("127.0.0.1" "::1") :test #'equal))
         (format *error-output* "~&hyperdoc-catalog-topic-maps serves loopback only (127.0.0.1 or ::1), not ~A.~%" host)
         (uiop:quit 2))))
;; The same registry rule as scripts/catalog-main.lisp: only the supplied trees, no inherited configuration.
(asdf:initialize-source-registry
 `(:source-registry
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "")
                                        :separator ":")
           unless (zerop (length path))
             collect `(:tree ,(uiop:ensure-directory-pathname
                              (string-right-trim "/" path))))
   :ignore-inherited-configuration))
(asdf:load-system "dreyeck/catalog-topic-maps")
(uiop:quit (uiop:symbol-call :dreyeck/catalog-topic-maps :main))
