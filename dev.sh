#!/usr/bin/env bash
set -euo pipefail

# HyperDoc dev launcher:
# - runs inside nix develop
# - always enables development mode by default (playground eval)
# - chooses a free Swank port (unless SWANK_PORT is explicitly set)
# - always loads hyperdoc/server (includes explorer systems)
#
# Usage:
#   ./dev.sh
#
# Env:
#   HYPERDOC_DEVELOPMENT=0|1   (default 1; informational banner only)
#   HYPERDOC_PORT=8080         (optional; if set and busy, we auto-pick another)
#   HYPERDOC_BIND_ADDRESS=127.0.0.1 (default 127.0.0.1)
#   SWANK_PORT=4005            (optional; if set and busy, we auto-pick another)
#   SWANK_INTERFACE=127.0.0.1  (default 127.0.0.1)

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

child_pid=""
terminate_dev() {
  echo "[dev] terminated"
  if [[ -n "${child_pid}" ]]; then
    kill -KILL "${child_pid}" 2>/dev/null || true
    wait "${child_pid}" 2>/dev/null || true
  fi
  exit 124
}
trap terminate_dev INT TERM

nix develop --command sbcl --no-userinit --disable-debugger \
  --eval '(require :asdf)' \
  --eval '(let* ((root (uiop:ensure-directory-pathname (uiop:getcwd)))
                 (flake-deps (uiop:ensure-directory-pathname
                              (merge-pathnames ".flake-deps/" root))))
            ;; Keep project trees first, but inherit Nix/ASDF defaults so packaged
            ;; systems (e.g. alexandria) remain discoverable at runtime.
            (asdf:initialize-source-registry
             (list :source-registry
                   (list :tree root)
                   (list :tree flake-deps)
                   :inherit-configuration)))' \
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
  --eval "(let ((port ${HYPERDOC_PORT}))
           (format t \"~&[dev] preflight port=~D development=~S debug=~S~%\"
                   port
                   (uiop:getenv \"HYPERDOC_DEVELOPMENT\")
                   (uiop:getenv \"HYPERDOC_DEBUG\"))
           (finish-output))" \
  --eval "(let* ((port ${HYPERDOC_PORT})
                (entry nil))
           (handler-case
               (progn
                 (asdf:load-system :hyperdoc/server)
                 (flet ((maybe-load (sys)
                          (handler-case
                              (if (asdf:find-system sys nil)
                                  (progn
                                    (asdf:load-system sys)
                                    (format t \"~&[dev] optional ~S loaded~%\" sys))
                                  (format t \"~&[dev] optional ~S skipped (not found)~%\" sys))
                            (error (c)
                              (format t \"~&[dev] optional ~S failed: ~A~%\" sys c)))))
                   (let* ((names
                           (sort
                            (remove-duplicates
                             (handler-case
                                 (loop for s in (asdf:registered-systems)
                                       for n = (string-downcase (string s))
                                       when (and (<= (length \"hyperbook/\") (length n))
                                                 (string= \"hyperbook/\" n :end2 (length \"hyperbook/\")))
                                         collect n)
                               (error () '()))
                             :test #'string=)
                            #'string<)))
                     (dolist (n names)
                       (unless (string= n \"hyperbook/server\")
                         (maybe-load (intern (string-upcase n) :keyword))))))
                 (let* ((pkg (or (find-package :hyperbook/server)
                                 (error \"Package HYPERBOOK/SERVER not found\")))
                        (preferred '(\"SERVE-CATALOG\" \"SERVE\")))
                   (setf entry
                         (or
                          (loop for name in preferred
                                for sym = (find-symbol name pkg)
                                when (and sym (fboundp sym))
                                return sym)
                          (let* ((candidates
                                  (loop for sym being the symbols of pkg
                                        for sname = (symbol-name sym)
                                        when (and (fboundp sym)
                                                  (<= 6 (length sname))
                                                  (string= \"SERVE-\" sname :end2 6))
                                        collect sym))
                                 (sorted (sort candidates #'string< :key #'symbol-name)))
                            (or (first sorted)
                                (error \"No SERVE-* entrypoint found in ~A\" (package-name pkg)))))))
                 (format t \"~&[dev] entrypoint=~S port=~D~%\" entry port)
                 (finish-output)
                 (funcall entry :port port))
             (error (c)
               (format *error-output* \"~&[dev] ERROR ~A~%~A~%\"
                       (type-of c) c)
               (finish-output *error-output*)
               (uiop:quit 1))))" \
  --eval '(format t "~&HyperDoc up.~%")' \
  --eval '(handler-bind ((sb-sys:interactive-interrupt
                          (lambda (c)
                            (declare (ignore c))
                            (format t "~&Stopping HyperDoc dev server (Ctrl-C).~%")
                            (sb-ext:exit :code 130 :abort t))))
            (loop (sleep 3600)))' &
child_pid=$!
wait "${child_pid}"
status=$?
trap - INT TERM
exit "${status}"

# Minimal reproduction template (copy/paste):
# sbcl --no-userinit --disable-debugger --non-interactive \
#   --eval '(require :asdf)' \
#   --eval '(handler-case
#              (progn
#                (asdf:load-system :hyperbook/server)
#                (format t "~&MR: load ok~%")
#                (uiop:quit 0))
#            (error (c)
#              (format *error-output* "~&MR ERROR ~A~%~A~%"
#                      (type-of c) c)
#              (uiop:quit 1)))'
#
# Bounded startup check (startup witness, teardown ignored):
# timeout --signal=TERM --kill-after=2s 45s ./dev.sh |& rg '^\[dev\] (preflight|entrypoint=|terminated)'
