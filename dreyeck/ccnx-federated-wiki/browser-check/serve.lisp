;;;; A loopback Catalog with the CCNx reading loaded additively. Read only: no site is written.
;;;; Environment: CCNX_PORT (default 48851), CCNX_STOP (a file whose appearance stops the server), CCNX_SITE_ROOT (an empty directory).
(require :asdf)
(asdf:initialize-source-registry
 `(:source-registry
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           unless (zerop (length path)) collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
   :ignore-inherited-configuration))
(asdf:load-system "dreyeck/catalog-application")
(asdf:load-system "dreyeck/ccnx-federated-wiki")
(dreyeck/catalog-application:start-catalog
 :port (parse-integer (or (uiop:getenv "CCNX_PORT") "48851")) :host "127.0.0.1"
 :site-root (uiop:getenv "CCNX_SITE_ROOT") :catalog-system "dreyeck/ccnx-federated-wiki")
(format t "~&LISTENING~%") (finish-output)
(loop until (probe-file (uiop:getenv "CCNX_STOP")) do (sleep 0.2))
(clog:shutdown)
(uiop:quit 0)
