;;;; A local Catalog with the without-DNS demo named, as HYPERDOC_CATALOG_SYSTEM names it (START-CATALOG loads it with ASDF:LOAD-SYSTEM).
;;;; Reads two files of this checkout; opens no wiki site and no outgoing connection. Loopback only.
;;;;   HYPERDOC_WITHOUT_DNS_PORT (default 8099), HYPERDOC_WITHOUT_DNS_STOP (a file whose appearance stops it; optional)
(require :asdf)
(asdf:initialize-source-registry
 `(:source-registry
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           unless (zerop (length path)) collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
   :ignore-inherited-configuration))
(asdf:load-system "dreyeck/catalog-application")
(defun ids () (mapcar #'hyperbook:id-of (hyperbook:hyperbooks-of hyperbook:*catalog*)))
(defparameter *demo* "dreyeck/fedwiki-without-dns-demo")
;; The default Catalog does not hold it ...
(assert (not (find *demo* (ids) :test #'string=)))
(format t "~&DEFAULT-CATALOG ~D HyperBooks; ~A not among them.~%" (length (ids)) *demo*)
(dreyeck/catalog-application:start-catalog
 :port (parse-integer (or (uiop:getenv "HYPERDOC_WITHOUT_DNS_PORT") "8099"))
 :host "127.0.0.1"
 :site-root (asdf:system-relative-pathname "dreyeck/fedwiki-without-dns-demo" "tests/fedwiki-without-dns/frozen-site/")
 :catalog-system *demo*)
;; ... and starting with the system named adds exactly it.
(assert (= 1 (count *demo* (ids) :test #'string=)))
(format t "~&CATALOG-WITH-DEMO ~D HyperBooks; ~A once.~%" (length (ids)) *demo*)
(finish-output)
(let ((stop (uiop:getenv "HYPERDOC_WITHOUT_DNS_STOP")))
  (loop until (and stop (probe-file stop)) do (sleep 0.2)))
(clog:shutdown)
(uiop:quit 0)
