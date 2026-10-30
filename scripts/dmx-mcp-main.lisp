;;;; Trusted application startup only; never loaded by an HTTP request.
(require :asdf)
(let ((root (truename (merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*)))))
  (asdf:initialize-source-registry
   `(:source-registry (:directory ,root) :inherit-configuration))
  (asdf:load-asd (merge-pathnames "hyperbook.asd" root))
  (asdf:load-asd (merge-pathnames "hyperdoc.asd" root)))
(asdf:load-system "hyperdoc/mcp")
(let ((args (uiop:command-line-arguments)))
  (cond
    ((equal args '("--check"))
     (assert (not (asdf:component-loaded-p "hyperdoc/explorer")))
     (assert (not (find-package :hyperdoc/tmdm-mcp)))
     (format t "DMX-MCP-ASDF-CHECK PASS~%"))
    ((equal args '("--version"))
     (format t "hyperdoc-dmx-mcp source=~A repair=f512aa847eab05cc2bdf2e78ef0bd1b516a11926~%"
             (or (uiop:getenv "HYPERDOC_SOURCE_REVISION") "unrecorded-local-source")))
    ((null args)
     ;; Environment values are supplied by the operator, not by MCP arguments.
     (unless (hyperdoc::dmx-non-empty-string-p (uiop:getenv "HYPERDOC_DMX_IMPORT_BASE_URL"))
       (error "The application requires HYPERDOC_DMX_IMPORT_BASE_URL"))
     (let* ((state (uiop:getenv "HYPERDOC_MCP_STATE_DIRECTORY"))
            (port (parse-integer (or (uiop:getenv "HYPERDOC_MCP_PORT") "8787"))))
       (unless (and state (uiop:absolute-pathname-p state) (uiop:directory-exists-p state))
         (error "HYPERDOC_MCP_STATE_DIRECTORY must name an existing absolute directory"))
       (unless (<= 1024 port 65535) (error "Invalid MCP port"))
       (setf hyperdoc::*hyperdoc-local-workspace-journal-directory*
             (uiop:ensure-directory-pathname state))
       (hyperdoc::restore-hyperdoc-local-workspace-journal-streams)
       (unwind-protect
            (progn
              (hyperdoc::serve-dmx-mcp-server :address "127.0.0.1" :port port)
              (loop (sleep 1)))
         (hyperdoc::stop-dmx-mcp-server))))
    (t (error "Usage: hyperdoc-dmx-mcp [--check | --version]"))))
