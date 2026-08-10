#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/../.." && pwd)
port=${1:-${HYPERDOC_DEMO_PORT:-8080}}

case "$port" in
  ''|*[!0-9]*)
    printf 'Port must be an integer between 1 and 65535: %s\n' "$port" >&2
    exit 2
    ;;
esac

if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
  printf 'Port must be an integer between 1 and 65535: %s\n' "$port" >&2
  exit 2
fi

cd "$repo_dir"

export HYPERDOC_DEMO_PORT=$port
export HYPERDOC_DEMO_SYSTEM=${HYPERDOC_DEMO_SYSTEM:-dreyeck/wiki-link}

printf 'Commit: %s\n' "$(git rev-parse HEAD)"
printf 'Port: %s\n' "$port"
printf 'Catalog system: %s\n' "$HYPERDOC_DEMO_SYSTEM"
printf 'Page: HyperBook Catalog\n'
printf 'URL: http://127.0.0.1:%s/\n' "$port"

exec sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system "hyperdoc")' \
  --eval '(asdf:load-system "hyperbook/server")' \
  --eval '(let ((system (uiop:getenv "HYPERDOC_DEMO_SYSTEM")))
            (when (and system (plusp (length system)))
              (format t "Loading catalog system: ~A~%" system)
              (asdf:load-system system)))' \
  --eval '(let ((port (parse-integer (uiop:getenv "HYPERDOC_DEMO_PORT"))))
            (format t "Invoking HYPERBOOK/SERVER:SERVE-CATALOG on port ~D~%" port)
            (finish-output)
            (hyperbook/server:serve-catalog :port port)
            (format t "HyperBook Catalog listening at http://127.0.0.1:~D/~%" port)
            (finish-output)
            (handler-case
                (loop (sleep 3600))
              (sb-sys:interactive-interrupt ()
                (format t "Stopping HyperBook Catalog~%")
                (clog:shutdown))))'
