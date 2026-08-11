#!/usr/bin/env sh
set -eu

# Historical filename retained for compatibility. This root-level launcher
# serves the explicit Dreyeck catalog. The isolated Wiki-link demo remains at
# dreyeck/scripts/serve-wiki-link-contract-demo.sh.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
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
export HYPERDOC_CATALOG_SYSTEM=${HYPERDOC_CATALOG_SYSTEM:-dreyeck/catalog}

printf 'Commit: %s\n' "$(git rev-parse HEAD)"
printf 'Port: %s\n' "$port"
printf 'Catalog system: %s\n' "$HYPERDOC_CATALOG_SYSTEM"
printf 'Page: HyperBook Catalog\n'
printf 'URL: http://127.0.0.1:%s/\n' "$port"

exec sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system "hyperdoc")' \
  --eval '(asdf:load-system "hyperbook/server")' \
  --eval '(let ((system (uiop:getenv "HYPERDOC_CATALOG_SYSTEM")))
            (format t "Loading catalog system: ~A~%" system)
            (asdf:load-system system))' \
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
