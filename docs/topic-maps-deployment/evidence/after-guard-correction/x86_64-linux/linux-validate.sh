#!/bin/sh
# Inside the Linux builder, with PKG the built hyperdoc-catalog-topic-maps: the reading's suites in its runtime, then the packaged
# executable with the reading as its catalog system, loopback binding, and clean shutdown.
set -u
PKG=${1:?package}; PORT=${2:-18781}
export HOME=$(mktemp -d); export XDG_CACHE_HOME=$HOME/cache
wrapper=$PKG/bin/hyperdoc-catalog-topic-maps
echo "package $PKG"; echo "wrapper $(head -c 0 $wrapper)"; 
# 1. the reading's suites: the wrapper's environment, another entry script.
while IFS= read -r line; do
  case "$line" in
    *--script*catalog-topic-maps-main.lisp*) echo "  --non-interactive --load /tmp/linux/reading-suites.lisp" ;;
    *) printf '%s\n' "$line" ;;
  esac
done < $wrapper > /tmp/linux/suites-wrapper.sh
grep -q 'reading-suites.lisp' /tmp/linux/suites-wrapper.sh || { echo "could not derive the suites wrapper"; exit 3; }
chmod +x /tmp/linux/suites-wrapper.sh
HYPERDOC_EXPECTED_TOPIC_MAPS_SOURCE=nix-store-snapshot /tmp/linux/suites-wrapper.sh > /tmp/linux/reading-suites.log 2>&1; echo "reading suites exit $?"
grep -a -E 'PASS|FAILED|RUN-STARTED|Project Workspace loaded' /tmp/linux/reading-suites.log | cut -c1-240
# 2. the packaged executable with the reading
HYPERDOC_CATALOG_SYSTEM=topic-maps-deployment-review-asdf-collision HYPERDOC_FEDWIKI_SITE_ROOT=/tmp/linux/site/ $wrapper $PORT > /tmp/linux/serve.log 2>&1 &
pid=$!; n=0
until grep -a -q 'listening on' /tmp/linux/serve.log 2>/dev/null || [ $n -gt 900 ]; do sleep 1; n=$((n+1)); kill -0 $pid 2>/dev/null || break; done
echo "seconds to listening: $n"; grep -a -E 'Topic Maps|listening|refused|failed' /tmp/linux/serve.log | cut -c1-200
echo "-- listening sockets for the port (hex address:port; 0100007F is 127.0.0.1)"
hex=$(printf '%04X' $PORT)
while read -r sl local remote state rest; do [ "$state" = 0A ] && case "$local" in *:$hex) echo "$local";; esac; done < /proc/net/tcp
while read -r sl local remote state rest; do [ "$state" = 0A ] && case "$local" in *:$hex) echo "ipv6 $local";; esac; done < /proc/net/tcp6
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:$PORT/ ; curl -s http://127.0.0.1:$PORT/ | grep -c 'boot.js'
kill -TERM $pid; wait $pid; echo "shutdown exit status $?"; grep -a -E 'Stopping' /tmp/linux/serve.log
