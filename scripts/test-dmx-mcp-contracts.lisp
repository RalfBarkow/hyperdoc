(require :asdf)
(asdf:load-system "hyperdoc/mcp")
(load (asdf:system-relative-pathname "hyperdoc" "tests/dmx-mcp-contracts.lisp"))
(setf hyperdoc::*hyperdoc-local-workspace-journal-write-files-p* nil
      hyperdoc::*hyperdoc-local-workspace-journal-streams* (make-hash-table :test #'equal)
      hyperdoc::*hyperdoc-local-workspace-journal-directory*
      (merge-pathnames "dmx-mcp-contract-journal/" (uiop:temporary-directory)))
(progn
  ;; Memory clients and synthetic Drakma replacements only. Never use the live-read entrypoint.
  (dolist (name '(hyperdoc/tests::run-dmx-workspace-note-http-single-content-type-smoke-test
                  hyperdoc/tests::run-dmx-import-delete-and-remove-contract-smoke-test
                  hyperdoc/tests::run-dmx-import-workspace-assignment-contract-smoke-test
                  hyperdoc/tests::run-dmx-import-explicit-basic-login-bootstrap-smoke-test
                  hyperdoc/tests::run-dmx-mcp-smoke-test
                  hyperdoc/tests::run-dmx-mcp-workspace-topic-lifecycle-smoke-test
                  hyperdoc/tests::run-dmx-mcp-workspace-journal-smoke-test
                  hyperdoc/tests::run-dmx-mcp-owned-topic-lifecycle-proof-smoke-test
                  hyperdoc/tests::run-dmx-mcp-workspace-assignment-repair-smoke-test
                  hyperdoc/tests::run-dmx-workspace-journal-assignment-repair-nonrecursive-smoke-test
                  hyperdoc/tests::run-dmx-mcp-http-error-surface-smoke-test))
    (funcall name)
    (format t "~&DMX-MCP-CONTRACT ~A PASS~%" name)))
