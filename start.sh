#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Optional: allow flake to inject extra trees (colon-separated absolute paths)
# e.g. export HYPERDOC_ASDF_TREES="/nix/store/...-html-inspector-views:/nix/store/...-clog-moldable-inspector"
HYPERDOC_ASDF_TREES="${HYPERDOC_ASDF_TREES:-}"

# Local dev defaults (the "simple development switch" is :development)
HYPERDOC_PORT="${HYPERDOC_PORT:-8080}"
HYPERDOC_BIND_ADDRESS="${HYPERDOC_BIND_ADDRESS:-127.0.0.1}"
HYPERDOC_DEVELOPMENT="${HYPERDOC_DEVELOPMENT:-1}"

export HYPERDOC_ASDF_TREES HYPERDOC_PORT HYPERDOC_BIND_ADDRESS HYPERDOC_DEVELOPMENT

echo "HyperDoc bind: ${HYPERDOC_BIND_ADDRESS}:${HYPERDOC_PORT}"
if [[ "${HYPERDOC_DEVELOPMENT}" == "1" ]]; then
  echo "Development mode: ON (Playground eval enabled)"
else
  echo "Development mode: OFF (Playground eval disabled)"
fi

sbcl --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval "(let* ((root (uiop:ensure-directory-pathname \"${ROOT}/\"))
                (deps (uiop:ensure-directory-pathname \"${ROOT}/deps/\"))
                (flake-deps (uiop:ensure-directory-pathname
                              (merge-pathnames \".flake-deps/\" root)))
                (extra-env (remove nil
                                   (list (uiop:getenv \"CL_SOURCE_REGISTRY\")
                                         (uiop:getenv \"HYPERDOC_ASDF_TREES\"))))
                (extra-paths
                  (loop for entry in extra-env append
                    (loop for s in (uiop:split-string entry :separator \":\")
                          for p = (and (> (length s) 0)
                                       (ignore-errors (uiop:ensure-directory-pathname s)))
                          when p collect p))))
           (asdf:initialize-source-registry
            (append (list :source-registry
                          ;; Project trees first
                          (list :tree root)
                          (list :tree deps)
                          (list :tree flake-deps))
                    ;; Any extra trees injected by flake/env
                    (mapcar (lambda (p) (list :tree p)) extra-paths)
                    ;; Critical bit: ignore ~/.config/common-lisp/* and any inherited config
                    (list :ignore-inherited-configuration))))" \
  --eval '(format t "CL_SOURCE_REGISTRY=~s~%" (uiop:getenv "CL_SOURCE_REGISTRY"))' \
  --eval '(format t "HYPERDOC_ASDF_TREES=~s~%" (uiop:getenv "HYPERDOC_ASDF_TREES"))' \
  --eval '(format t "ASDF source-registry initialized.~%")' \
  --eval "(progn
            (format *error-output* \"~&Forcing ASDF output-translations (ignore inherited) ...~%\")
            (let* ((root (uiop:ensure-directory-pathname \"${ROOT}/\"))
                   (cache (uiop:ensure-directory-pathname
                           (merge-pathnames \".cache/asdf/\" root)))
                   (src-pattern (list root #P\"**/*.*\"))
                   (dst-pattern (list cache #P\"**/*.*\")))
              (ensure-directories-exist cache)
              (asdf:initialize-output-translations
               (list :output-translations
                     (list src-pattern dst-pattern)
                     :ignore-inherited-configuration))
              (format *error-output* \"  ASDF fasls -> ~a~%\" cache)
              (finish-output *error-output*)))" \
  --eval '(progn
            (format *error-output* "~&Setting SBCL compile failure behavior to :ERROR...~%")
            (flet ((maybe-set (pkg sym value)
                     (multiple-value-bind (s status) (find-symbol sym pkg)
                       (when (and s status (boundp s))
                         (set s value)
                         (format *error-output* "  ~a::~a = ~s~%" pkg sym value)))))
              (maybe-set "SB-C"   "*COMPILE-FILE-FAILURE-BEHAVIOUR*" :error)
              (maybe-set "SB-C"   "*COMPILE-FILE-ERROR-BEHAVIOUR*"   :error)
              (maybe-set "SB-C"   "*COMPILE-FILE-FAILURE-BEHAVIOR*"  :error)
              (maybe-set "SB-C"   "*COMPILE-FILE-ERROR-BEHAVIOR*"    :error)
              (maybe-set "SB-EXT" "*COMPILE-FILE-FAILURE-BEHAVIOUR*" :error)
              (maybe-set "SB-EXT" "*COMPILE-FILE-ERROR-BEHAVIOUR*"   :error)
              (maybe-set "SB-EXT" "*COMPILE-FILE-FAILURE-BEHAVIOR*"  :error)
              (maybe-set "SB-EXT" "*COMPILE-FILE-ERROR-BEHAVIOR*"    :error)
              ;; ASDF/UIOP controls these in modern SBCL builds.
              (maybe-set "UIOP/LISP-BUILD" "*COMPILE-FILE-FAILURE-BEHAVIOUR*" :error)
              (maybe-set "UIOP/LISP-BUILD" "*COMPILE-FILE-WARNINGS-BEHAVIOUR*" :warn)
              (maybe-set "UIOP/LISP-BUILD" "*COMPILE-FILE-FAILURE-BEHAVIOR*" :error)
              (maybe-set "UIOP/LISP-BUILD" "*COMPILE-FILE-WARNINGS-BEHAVIOR*" :warn))
            (setf *compile-verbose* t
                  *compile-print* t)
            (finish-output *error-output*))' \
  --eval '(progn
            (format *error-output* "~&Disabling UIOP/LISP-BUILD compiler muffling (if present)...~%")
            (flet ((maybe-set (pkg sym value)
                     (multiple-value-bind (s status) (find-symbol sym pkg)
                       (when (and s status (boundp s))
                         (set s value)
                         (format *error-output* "  ~a::~a = ~s~%" pkg sym value)))))
              (maybe-set "UIOP/LISP-BUILD" "*MUFFLED-COMPILER-CONDITIONS*" nil)
              (maybe-set "UIOP/LISP-BUILD" "*MUFFLE-COMPILER-CONDITIONS*" nil)
              (maybe-set "UIOP/LISP-BUILD" "*MUFFLE-CONDITIONS*" nil)
              (maybe-set "UIOP/LISP-BUILD" "*SUPPRESS-COMPILER-NOTES*" nil)
              (maybe-set "ASDF" "*SUPPRESS-COMPILER-WARNINGS*" nil))
            (finish-output *error-output*))' \
  --eval '(progn
            ;; Print unhandled conditions from any thread, then exit non-zero.
            (defun cl-user::hyperdoc-panic (condition hook)
              (declare (ignore hook))
              (let ((out *error-output*))
                (format out "~&~%=== HYPERDOC PANIC ===~%")
                (ignore-errors
                  (format out "Thread: ~a~%"
                          (or (ignore-errors (sb-thread:thread-name sb-thread:*current-thread*))
                              sb-thread:*current-thread*)))
                (format out "Condition: ~a~%~%" condition)
                (ignore-errors
                  (uiop:print-condition-backtrace condition :stream out))
                (finish-output out)
                (ignore-errors (sb-ext:exit :code 1))
                (uiop:quit 1)))
            (setf sb-ext:*invoke-debugger-hook* (function cl-user::hyperdoc-panic))
            (setf *debugger-hook* (function cl-user::hyperdoc-panic))
            (setf *compile-verbose* t
                  *compile-print* t))' \
  --eval '(progn
            (defparameter cl-user::*hyperdoc-saw-error* nil)
            (defun cl-user::hyperdoc-report-signal (c)
              (when (typep c (quote error))
                (setf cl-user::*hyperdoc-saw-error* t)
                (let ((out *error-output*))
                  (format out "~&~%=== HYPERDOC SIGNAL ===~%")
                  (ignore-errors
                    (format out "Thread: ~a~%"
                            (or (ignore-errors (sb-thread:thread-name sb-thread:*current-thread*))
                                sb-thread:*current-thread*)))
                  (format out "Condition class: ~s~%" (type-of c))
                  (format out "Condition: ~a~%~%" c)
                  (ignore-errors (uiop:print-condition-backtrace c :stream out))
                  (finish-output out))))
            (format *error-output* "~&Installing ERROR signal tracer...~%")
            (format *error-output* "~&Leaving *BREAK-ON-SIGNALS* disabled during system load (set HYPERDOC_BREAK_ON_SIGNALS=1 for late enable).~%")
            (finish-output *error-output*))' \
  --eval '(require :sb-introspect)' \
  --eval '(unless (asdf:find-system "html-inspector-views/standard" nil)
            (error "ASDF cannot find html-inspector-views/standard. Registry not pointing at its .asd."))' \
  --eval '(flet ((truthy (s)
                   (and s (member (string-downcase s)
                                  (quote ("1" "true" "yes" "on"))
                                  :test (function string=))))
                 (load-or-die (sys)
                   (handler-case
                       (asdf:load-system sys)
                     (error (c)
                       (format *error-output* "~&FATAL while loading ~a: ~a~%" sys c)
                       (uiop:print-condition-backtrace c :stream *error-output*)
                       (uiop:quit 1)))))
            (handler-bind ((error (function cl-user::hyperdoc-report-signal)))
              (load-or-die :html-inspector-views/standard)
              (load-or-die :hyperdoc/explorer)
              (load-or-die :hyperbook/server)
              (when (uiop:getenv "HYPERDOC_BREAK_ON_SIGNALS")
                (format *error-output* "~&Enabling *BREAK-ON-SIGNALS* (late) for ERROR...~%")
                (setf sb-ext::*break-on-signals* (quote (and error (not file-error)))))
              (handler-case
                  (progn
                      (let* ((port (parse-integer (or (uiop:getenv "HYPERDOC_PORT") "8080")))
                             (host (or (uiop:getenv "HYPERDOC_BIND_ADDRESS") "127.0.0.1"))
                             (development (truthy (uiop:getenv "HYPERDOC_DEVELOPMENT"))))
                        (format t "HyperDoc server: ~a:~d~%" host port)
                        (format t "Development mode: ~a~%" (if development "ON" "OFF"))
                        ;; NOTE: On this upstream base, serve-catalog has no :host argument.
                        ;; Playground evaluation is controlled by the existing :development switch.
                        (funcall (read-from-string "hyperbook/server:serve-catalog")
                                 :port port
                                 :development development))
                    ;; Keep the process alive; serve-catalog starts async server threads.
                    (loop (sleep 3600)))
                (error (c)
                  (format *error-output* "~&FATAL while starting server: ~a~%" c)
                  (uiop:print-condition-backtrace c :stream *error-output*)
                  (uiop:quit 1)))))'
