;;; Executable adapter: ASDF owns loading, the application owns startup/lifetime.
(require :asdf)
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
(asdf:load-system "dreyeck/catalog-application")
(uiop:quit (uiop:symbol-call :dreyeck/catalog-application :main))
