#!/usr/bin/env bash
set -euo pipefail

# HyperDoc dev launcher:
# - runs inside nix develop
# - always enables development mode by default (playground eval)
# - chooses a free Swank port (unless SWANK_PORT is explicitly set)
# - optional --explorer loads hyperbook/explorer
#
# Usage:
#   ./dev.sh
#   ./dev.sh --explorer
#
# Env:
#   HYPERDOC_DEVELOPMENT=0|1   (default 1; informational banner only)
#   HYPERDOC_PORT=8080         (optional; if set and busy, we auto-pick another)
#   HYPERDOC_BIND_ADDRESS=127.0.0.1 (default 127.0.0.1)
#   SWANK_PORT=4005            (optional; if set and busy, we auto-pick another)
#   SWANK_INTERFACE=127.0.0.1  (default 127.0.0.1)

LOAD_EXPLORER=0
if [[ "${1-}" == "--explorer" ]]; then
  LOAD_EXPLORER=1
fi

export HYPERDOC_DEVELOPMENT="${HYPERDOC_DEVELOPMENT:-1}"
HYPERDOC_BIND_ADDRESS="${HYPERDOC_BIND_ADDRESS:-127.0.0.1}"
SWANK_INTERFACE="${SWANK_INTERFACE:-127.0.0.1}"

choose_free_port() {
  python3 - <<'PY'
import socket
with socket.socket() as s:
    s.bind(("127.0.0.1", 0))
    print(s.getsockname()[1])
PY
}

port_is_free() {
  local port="$1"
  python3 - "$port" <<'PY'
import socket, sys
port = int(sys.argv[1])
with socket.socket() as s:
    try:
        s.bind(("127.0.0.1", port))
        print("free")
    except OSError:
        print("busy")
PY
}

# Determine Swank port:
# - if SWANK_PORT set and free -> use it
# - if SWANK_PORT set and busy -> pick a free one
# - if not set -> pick a free one
if [[ -n "${SWANK_PORT:-}" ]]; then
  if [[ "$(port_is_free "$SWANK_PORT")" != "free" ]]; then
    SWANK_PORT="$(choose_free_port)"
  fi
else
  SWANK_PORT="$(choose_free_port)"
fi

export SWANK_PORT

# Determine HyperDoc port:
# - if HYPERDOC_PORT set and free -> use it
# - if HYPERDOC_PORT set and busy -> pick a free one
# - if not set -> default 8080 if free, else pick a free one
if [[ -n "${HYPERDOC_PORT:-}" ]]; then
  if [[ "$(port_is_free "$HYPERDOC_PORT")" != "free" ]]; then
    HYPERDOC_PORT="$(choose_free_port)"
  fi
else
  if [[ "$(port_is_free "8080")" == "free" ]]; then
    HYPERDOC_PORT="8080"
  else
    HYPERDOC_PORT="$(choose_free_port)"
  fi
fi

export HYPERDOC_PORT

cat <<EOF2
HyperDoc dev launcher

  HYPERDOC_DEVELOPMENT=${HYPERDOC_DEVELOPMENT} (1 enables Playground eval)
  HyperDoc: ${HYPERDOC_BIND_ADDRESS}:${HYPERDOC_PORT}
  Swank: ${SWANK_INTERFACE}:${SWANK_PORT}
  Emacs: M-x slime-connect  ${SWANK_INTERFACE}  ${SWANK_PORT}

URL (expected):
  http://${HYPERDOC_BIND_ADDRESS}:${HYPERDOC_PORT}/boot.html

EOF2

# Run SBCL inside nix develop so CL_SOURCE_REGISTRY etc. are correct.
unset ASDF_OUTPUT_TRANSLATIONS
exec nix develop --command sbcl --no-userinit \
  --eval '(require :asdf)' \
  --eval '(sb-sys:enable-interrupt
            sb-unix:sigint
            (lambda (signal code scp)
              (declare (ignore signal code scp))
              (format t "~&Stopping HyperDoc dev server (Ctrl-C).~%")
              (sb-ext:exit :code 130 :abort t)))' \
  --eval '(asdf:initialize-output-translations
            (list :output-translations
                  :ignore-inherited-configuration
                  (list t
                        (list (uiop:xdg-cache-home "common-lisp/asdf-fasl-cache/")
                              :implementation))))' \
  --eval '(setf *print-circle* t)' \
  --eval '(format t "~&ASDF ready.~%")' \
  --eval '(asdf:load-asd (truename "hyperbook.asd"))' \
  --eval '(asdf:load-system "swank")' \
  --eval "(swank:create-server :port ${SWANK_PORT} :interface \"${SWANK_INTERFACE}\" :dont-close t)" \
  --eval '(format t "~&Swank listening.~%")' \
  --eval '(asdf:load-system "hyperdoc")' \
  --eval '(asdf:load-system "hyperbook/server")' \
  --eval "(when (= ${LOAD_EXPLORER} 1)
            (asdf:load-system \"hyperbook/explorer\")
            (asdf:load-system \"hyperdoc/explorer\"))" \
  --eval "(hyperbook/server:serve-catalog :port ${HYPERDOC_PORT} :development t)" \
  --eval '(format t "~&HyperDoc up.~%")' \
  --eval '(handler-bind ((sb-sys:interactive-interrupt
                          (lambda (c)
                            (declare (ignore c))
                            (format t "~&Stopping HyperDoc dev server (Ctrl-C).~%")
                            (sb-ext:exit :code 130 :abort t))))
            (loop (sleep 3600)))'
