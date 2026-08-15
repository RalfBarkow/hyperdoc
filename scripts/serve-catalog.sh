#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
port=${1:-${HYPERDOC_CATALOG_PORT:-8080}}

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

export HYPERDOC_CATALOG_PORT=$port
export HYPERDOC_CATALOG_SYSTEM=${HYPERDOC_CATALOG_SYSTEM:-dreyeck/catalog}

printf 'Commit: %s\n' "$(git rev-parse HEAD)"
printf 'Port: %s\n' "$port"
printf 'Catalog system: %s\n' "$HYPERDOC_CATALOG_SYSTEM"
printf 'FedWiki site root: %s\n' "${HYPERDOC_FEDWIKI_SITE_ROOT:-$HOME/.wiki/dreyeck.ch/}"
printf 'Page: HyperBook Catalog\n'
printf 'URL: http://127.0.0.1:%s/\n' "$port"
printf 'FedWiki view: http://127.0.0.1:%s/view/<slug>\n' "$port"

exec sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system "hyperdoc")' \
  --eval '(asdf:load-system "hyperbook/server")' \
  --eval '(asdf:load-system "dreyeck/local-fedwiki-view")' \
  --eval '(let ((system (uiop:getenv "HYPERDOC_CATALOG_SYSTEM")))
            (format t "Loading catalog system: ~A~%" system)
            (asdf:load-system system))' \
  --eval '(let ((port (parse-integer (uiop:getenv "HYPERDOC_CATALOG_PORT"))))
            (format t "Invoking DREYECK/LOCAL-FEDWIKI-VIEW:SERVE-CATALOG-WITH-LOCAL-FEDWIKI-VIEW on port ~D~%" port)
            (finish-output)
            (dreyeck/local-fedwiki-view:serve-catalog-with-local-fedwiki-view
             :port port)
            (format t "HyperBook Catalog listening at http://127.0.0.1:~D/~%" port)
            (format t "Local FedWiki /view route installed from ~A~%"
                    (dreyeck/local-fedwiki-view:configured-site-root))
            (finish-output)
            (handler-case
                (loop (sleep 3600))
              (sb-sys:interactive-interrupt ()
                (format t "Stopping HyperBook Catalog~%")
                (clog:shutdown))))'
