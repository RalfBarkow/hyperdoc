#!/usr/bin/env bash
set -euo pipefail

# HyperDoc dev launcher:
# - runs inside nix develop
# - always enables development mode by default
# - chooses free ports unless explicitly set
# - supports both SLIME/Swank and SLY/Slynk
# - loads hyperdoc/server before serving
#
# Usage:
#   ./dev.sh
#   LISP_IDE=sly ./dev.sh
#   LISP_IDE=slime ./dev.sh
#
# Env:
#   LISP_IDE=slime|sly              default: slime
#   HYPERDOC_DEVELOPMENT=0|1        default: 1
#   HYPERDOC_PORT=8080              optional; if busy, auto-pick another
#   HYPERDOC_BIND_ADDRESS=127.0.0.1 default: 127.0.0.1
#   SWANK_PORT=4005                 optional; SLIME/Swank port
#   SWANK_INTERFACE=127.0.0.1       default: 127.0.0.1
#   SLYNK_PORT=4006                 optional; SLY/Slynk port
#   SLYNK_INTERFACE=127.0.0.1       default: 127.0.0.1
#
# Notes:
#   Swank is the Lisp-side server for SLIME.
#   Slynk is the Lisp-side server for SLY.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

export HYPERDOC_DEVELOPMENT="${HYPERDOC_DEVELOPMENT:-1}"
export HYPERDOC_BIND_ADDRESS="${HYPERDOC_BIND_ADDRESS:-127.0.0.1}"

LISP_IDE="${LISP_IDE:-slime}"

case "${LISP_IDE}" in
  slime|swank)
    LISP_IDE="slime"
    LISP_SERVER_SYSTEM="swank"
    LISP_SERVER_PACKAGE="swank"
    LISP_SERVER_LABEL="Swank"
    LISP_CONNECT_COMMAND="slime-connect"
    LISP_SERVER_INTERFACE="${SWANK_INTERFACE:-127.0.0.1}"
    LISP_SERVER_REQUESTED_PORT="${SWANK_PORT:-}"
    ;;
  sly|slynk)
    LISP_IDE="sly"
    LISP_SERVER_SYSTEM="slynk"
    LISP_SERVER_PACKAGE="slynk"
    LISP_SERVER_LABEL="Slynk"
    LISP_CONNECT_COMMAND="sly-connect"
    LISP_SERVER_INTERFACE="${SLYNK_INTERFACE:-${SWANK_INTERFACE:-127.0.0.1}}"
    LISP_SERVER_REQUESTED_PORT="${SLYNK_PORT:-${SWANK_PORT:-}}"
    ;;
  *)
    echo "Unsupported LISP_IDE=${LISP_IDE}; use 'slime' or 'sly'." >&2
    exit 2
    ;;
esac

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

select_port() {
  local requested="${1:-}"
  if [[ -n "${requested}" ]]; then
    if [[ "$(port_is_free "${requested}")" == "free" ]]; then
      echo "${requested}"
    else
      choose_free_port
    fi
  else
    choose_free_port
  fi
}

select_hyperdoc_port() {
  if [[ -n "${HYPERDOC_PORT:-}" ]]; then
    if [[ "$(port_is_free "${HYPERDOC_PORT}")" == "free" ]]; then
      echo "${HYPERDOC_PORT}"
    else
      choose_free_port
    fi
  else
    if [[ "$(port_is_free "8080")" == "free" ]]; then
      echo "8080"
    else
      choose_free_port
    fi
  fi
}

LISP_SERVER_PORT="$(select_port "${LISP_SERVER_REQUESTED_PORT}")"
HYPERDOC_PORT="$(select_hyperdoc_port)"

export HYPERDOC_PORT
export HYPERDOC_LISP_IDE="${LISP_IDE}"
export HYPERDOC_LISP_SERVER_SYSTEM="${LISP_SERVER_SYSTEM}"
export HYPERDOC_LISP_SERVER_PACKAGE="${LISP_SERVER_PACKAGE}"
export HYPERDOC_LISP_SERVER_LABEL="${LISP_SERVER_LABEL}"
export HYPERDOC_LISP_SERVER_INTERFACE="${LISP_SERVER_INTERFACE}"
export HYPERDOC_LISP_SERVER_PORT="${LISP_SERVER_PORT}"

case "${LISP_IDE}" in
  slime)
    export SWANK_INTERFACE="${LISP_SERVER_INTERFACE}"
    export SWANK_PORT="${LISP_SERVER_PORT}"
    ;;
  sly)
    export SLYNK_INTERFACE="${LISP_SERVER_INTERFACE}"
    export SLYNK_PORT="${LISP_SERVER_PORT}"
    ;;
esac

cat <<EOF2
HyperDoc dev launcher

  HYPERDOC_DEVELOPMENT=${HYPERDOC_DEVELOPMENT} (1 enables Playground eval)
  HyperDoc: ${HYPERDOC_BIND_ADDRESS}:${HYPERDOC_PORT}
  ${LISP_SERVER_LABEL}: ${LISP_SERVER_INTERFACE}:${LISP_SERVER_PORT}
  Emacs: M-x ${LISP_CONNECT_COMMAND}  ${LISP_SERVER_INTERFACE}  ${LISP_SERVER_PORT}

URL (expected):
  http://${HYPERDOC_BIND_ADDRESS}:${HYPERDOC_PORT}/boot.html

EOF2

# Run SBCL inside nix develop so CL_SOURCE_REGISTRY etc. are correct.
unset ASDF_OUTPUT_TRANSLATIONS

child_pid=""

terminate_dev() {
  echo "[dev] terminated"
  if [[ -n "${child_pid}" ]]; then
    kill -TERM "${child_pid}" 2>/dev/null || true
    sleep 1
    kill -KILL "${child_pid}" 2>/dev/null || true
    wait "${child_pid}" 2>/dev/null || true
  fi
  exit 130
}

trap terminate_dev INT TERM

nix develop --command sbcl --no-userinit --disable-debugger \
  --eval '(require :asdf)' \
  --eval '(let* ((root (uiop:ensure-directory-pathname (uiop:getcwd)))
                 (flake-deps (uiop:ensure-directory-pathname
                              (merge-pathnames ".flake-deps/" root)))
                 (extra-env (remove nil
                                    (list (uiop:getenv "CL_SOURCE_REGISTRY")
                                          (uiop:getenv "HYPERDOC_ASDF_TREES"))))
                 (extra-paths
                  (remove-duplicates
                   (loop for entry in extra-env append
                     (loop for s in (uiop:split-string entry :separator ":")
                           for p = (and (> (length s) 0)
                                        (ignore-errors
                                          (uiop:ensure-directory-pathname s)))
                           when p collect p))
                   :test (function equal))))
            ;; Keep the flake-injected source trees authoritative so patched CLOG Lisp
            ;; and static assets come from the same source, while still inheriting the
            ;; packaged dependency trees through CL_SOURCE_REGISTRY/HYPERDOC_ASDF_TREES.
            ;; The project ASDs are loaded explicitly below so we do not recurse through
            ;; the whole repo tree here.
            (asdf:initialize-source-registry
             (append (list :source-registry
                           (list :tree flake-deps))
                     (mapcar (lambda (p) (list :tree p)) extra-paths)
                     (list :ignore-inherited-configuration))))' \
  --eval '(sb-sys:enable-interrupt
            sb-unix:sigint
            (lambda (signal code scp)
              (declare (ignore signal code scp))
              (format t "~&Stopping HyperDoc dev server (Ctrl-C).~%")
              (finish-output)
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
  --eval '(asdf:load-asd (truename "hyperdoc.asd"))' \
  --eval '(let ((system (uiop:getenv "HYPERDOC_LISP_SERVER_SYSTEM")))
            (unless (asdf:find-system system nil)
              (format *error-output*
                      "~&[dev] ERROR: ASDF system ~S not found.~%~
                         If LISP_IDE=sly, add Slynk to the Nix Common Lisp inputs, or run LISP_IDE=slime ./dev.sh.~%"
                      system)
              (finish-output *error-output*)
              (uiop:quit 2)))' \
  --eval '(let* ((system (uiop:getenv "HYPERDOC_LISP_SERVER_SYSTEM"))
                 (package-name (uiop:getenv "HYPERDOC_LISP_SERVER_PACKAGE"))
                 (label (uiop:getenv "HYPERDOC_LISP_SERVER_LABEL"))
                 (interface (uiop:getenv "HYPERDOC_LISP_SERVER_INTERFACE"))
                 (port (parse-integer (uiop:getenv "HYPERDOC_LISP_SERVER_PORT"))))
            (asdf:load-system system)
            (let* ((pkg (or (find-package (string-upcase package-name))
                            (error "Package ~A not found after loading ~A."
                                   package-name system)))
                   (create-server (find-symbol "CREATE-SERVER" pkg)))
              (unless (and create-server (fboundp create-server))
                (error "CREATE-SERVER not found in package ~A." pkg))
              (funcall create-server
                       :port port
                       :interface interface
                       :dont-close t)
              (format t "~&~A listening.~%" label)
              (finish-output)))' \
  --eval '(let ((port (parse-integer (uiop:getenv "HYPERDOC_PORT"))))
            (format t "~&[dev] preflight port=~D development=~S debug=~S~%"
                    port
                    (uiop:getenv "HYPERDOC_DEVELOPMENT")
                    (uiop:getenv "HYPERDOC_DEBUG"))
            (finish-output))' \
  --eval '(handler-case
              (let ((port (parse-integer (uiop:getenv "HYPERDOC_PORT"))))
                (asdf:load-system :hyperdoc/server)
                (let* ((pkg (or (find-package "HYPERBOOK/SERVER")
                                (error "Package HYPERBOOK/SERVER not found.")))
                       (entry (find-symbol "SERVE-CATALOG" pkg)))
                  (unless (and entry (fboundp entry))
                    (error "SERVE-CATALOG not found in HYPERBOOK/SERVER."))
                  (format t "~&[dev] entrypoint=~S port=~D~%" entry port)
                  (finish-output)
                  (funcall entry :port port)
                  (format t "~&HyperDoc up.~%")
                  (finish-output)))
            (error (c)
              (format *error-output* "~&[dev] ERROR ~A~%~A~%"
                      (type-of c) c)
              (finish-output *error-output*)
              (uiop:quit 1)))' \
  --eval '(loop (sleep 3600))' &
child_pid=$!

if wait "${child_pid}"; then
  status=0
else
  status=$?
fi

trap - INT TERM
exit "${status}"

# Examples:
#
#   ./dev.sh
#   LISP_IDE=slime ./dev.sh
#   LISP_IDE=sly ./dev.sh
#
# Bounded startup check:
#
#   timeout --signal=TERM --kill-after=2s 45s ./dev.sh |& rg "^\[dev\] (preflight|entrypoint=|terminated)"