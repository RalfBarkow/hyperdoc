#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCP_PORT="${HYPERDOC_MCP_PORT:-8787}"
MCP_BIND_ADDRESS="${HYPERDOC_MCP_BIND_ADDRESS:-127.0.0.1}"

cat <<EOF
DMX MCP server launcher

  URL: http://${MCP_BIND_ADDRESS}:${MCP_PORT}/mcp
  Workspace topicmap: ${HYPERDOC_MCP_WORKSPACE_TOPICMAP_ID:-919822}
  Live writes: ${HYPERDOC_MCP_ENABLE_LIVE_WRITES:-0}

EOF

cd "${ROOT}"

exec nix develop --command sbcl --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system :hyperdoc/mcp :force t)' \
  --eval '(sb-sys:enable-interrupt
             sb-unix:sigint
             (lambda (signal code scp)
               (declare (ignore signal code scp))
               (format t "~&Stopping DMX MCP server (Ctrl-C).~%")
               (finish-output)
               (sb-ext:exit :code 130 :abort t)))' \
  --eval "(hyperdoc:serve-dmx-mcp-server :port ${MCP_PORT} :address \"${MCP_BIND_ADDRESS}\")" \
  --eval '(format t "DMX_MCP_SERVER_READY~%")' \
  --eval '(finish-output)' \
  --eval '(loop (sleep 3600))'
