;;; Executable adapter: ASDF owns loading, the application owns startup/lifetime. The startup is the Catalog's own MAIN
;;; behind dreyeck/catalog-topic-maps: the Topic Maps snapshot is verified and the Project Workspace refused before it runs.
(require :asdf)
;; An unset host is loopback: the Catalog listens beyond it only where the service names that host. An explicit host is kept as given.
(when (member (uiop:getenv "HYPERDOC_CATALOG_HOST") '(nil "") :test #'equal)
  (setf (uiop:getenv "HYPERDOC_CATALOG_HOST") "127.0.0.1"))
;; Nix's SBCL wrapper separates registry prefixes with an empty entry, which
;; ASDF otherwise treats as inheritance of personal source-registry files.
;; Resolve only the supplied dependency/application trees for this executable.
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
