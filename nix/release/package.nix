{ pkgs
, releaseSource
, sbclEnv
, namedClosurePkg
, arrowsSrc
, clogSrcPatched
, clogMoldableInspectorSrc
, htmlInspectorViewsSrc
, plumpInspectorViewsSrc
, lwcellsSrc
, clMarkupSrc
, releaseId
, releaseRevision
, flakeLockSha256
}:

let
  runtimeInit = ''
    SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
    RELEASE_PREFIX="$(cd -- "$SCRIPT_DIR/.." && pwd)"
    export HYPERDOC_RELEASE_ID="${releaseId}"
    export HYPERDOC_RELEASE_REV="${releaseRevision}"
    export HYPERDOC_RELEASE_FLAKE_LOCK_SHA256="${flakeLockSha256}"
    export HYPERDOC_ROOT="$RELEASE_PREFIX/share/hyperdoc/source"
    export ARROWS_SRC="${arrowsSrc}"
    export CLOG_SRC="${clogSrcPatched}"
    export CLOG_MOLDABLE_INSPECTOR_SRC="${clogMoldableInspectorSrc}"
    export HTML_INSPECTOR_VIEWS_SRC="${htmlInspectorViewsSrc}"
    export PLUMP_INSPECTOR_VIEWS_SRC="${plumpInspectorViewsSrc}"
    export LWCELLS_SRC="${lwcellsSrc}"
    export CL_MARKUP_SRC="${clMarkupSrc}"
    export HTML_INSPECTOR_VIEWS_ASD="${htmlInspectorViewsSrc}/html-inspector-views.asd"
    export CL_SOURCE_REGISTRY="${clogSrcPatched}//:${clogMoldableInspectorSrc}//:${htmlInspectorViewsSrc}//:${plumpInspectorViewsSrc}//:${lwcellsSrc}//:${arrowsSrc}//:${clMarkupSrc}//:$HYPERDOC_ROOT//:${namedClosurePkg}//"
    export HYPERDOC_ASDF_TREES="$CL_SOURCE_REGISTRY"
  '';

  startScript = pkgs.writeShellApplication {
    name = "hyperdoc-release-start";
    text = ''
      set -euo pipefail
      ${runtimeInit}

      export HYPERDOC_BIND_ADDRESS="''${HYPERDOC_BIND_ADDRESS:-127.0.0.1}"
      export HYPERDOC_PORT="''${HYPERDOC_PORT:-8080}"
      export HYPERDOC_DEVELOPMENT="''${HYPERDOC_DEVELOPMENT:-0}"
      export HYPERDOC_DEBUG="''${HYPERDOC_DEBUG:-0}"
      export HYPERDOC_USE_THREAD="''${HYPERDOC_USE_THREAD:-0}"

      echo "HyperDoc release: $HYPERDOC_RELEASE_ID"
      echo "HyperDoc revision: $HYPERDOC_RELEASE_REV"
      echo "HyperDoc flake.lock sha256: $HYPERDOC_RELEASE_FLAKE_LOCK_SHA256"
      echo "HyperDoc bind: $HYPERDOC_BIND_ADDRESS:$HYPERDOC_PORT"
      echo "HyperDoc development: $HYPERDOC_DEVELOPMENT"

      sbcl_base_args=(
        --no-userinit
        --non-interactive
        --disable-debugger
        --eval '(require :asdf)'
        --eval '(ignore-errors (require :sb-introspect))'
        --eval '(when (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD")
                  (ignore-errors (asdf:clear-system "html-inspector-views"))
                  (ignore-errors (asdf:clear-system "html-inspector-views/standard"))
                  (ignore-errors (asdf:clear-system "html-inspector-views/reactive"))
                  (load (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD")))'
        --eval '(asdf:load-system :html-inspector-views)'
        --eval '(when (uiop:getenv "HTML_INSPECTOR_VIEWS_THUNKS")
                  (load (uiop:getenv "HTML_INSPECTOR_VIEWS_THUNKS")))'
        --eval '(when (find-package :html-inspector-views)
                  (export (list (intern "THUNK" :html-inspector-views)
                                (intern "EVAL-THUNK" :html-inspector-views))
                          :html-inspector-views))'
      )

      exec ${sbclEnv}/bin/sbcl \
        "''${sbcl_base_args[@]}" \
        --eval '(asdf:load-system :hyperdoc/server)' \
        --eval '(let* ((port (or (ignore-errors (parse-integer (or (uiop:getenv "HYPERDOC_PORT") "8080")))
                                 8080))
                       (development (member (string-downcase (or (uiop:getenv "HYPERDOC_DEVELOPMENT") "0"))
                                            (list "1" "true" "yes" "on")
                                            :test #'"'"'string=)))
                  (hyperbook/server:serve-catalog
                   :port port
                   :development (not (null development)))
                  ;; serve-catalog initializes async server threads in this branch.
                  ;; Keep the process alive as systemd/runtime entrypoint.
                  (loop (sleep 3600)))'
    '';
  };

  infoScript = pkgs.writeShellApplication {
    name = "hyperdoc-release-info";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      set -euo pipefail
      SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
      RELEASE_PREFIX="$(cd -- "$SCRIPT_DIR/.." && pwd)"
      metadata="$RELEASE_PREFIX/share/hyperdoc/release.json"
      if [ ! -f "$metadata" ]; then
        echo "missing release metadata: $metadata" >&2
        exit 1
      fi
      cat "$metadata"
    '';
  };

  verifyScript = pkgs.writeShellApplication {
    name = "hyperdoc-release-verify";
    runtimeInputs = [ pkgs.coreutils pkgs.curl pkgs.gnugrep pkgs.findutils pkgs.gawk pkgs.python3 pkgs.which ];
    text = ''
      set -euo pipefail
      ${runtimeInit}

      host="''${HYPERDOC_VERIFY_HOST:-127.0.0.1}"
      port="''${HYPERDOC_VERIFY_PORT:-18080}"
      timeout_s="''${HYPERDOC_VERIFY_TIMEOUT:-60}"
      verify_home="$(mktemp -d /tmp/hyperdoc-release-verify-home.XXXXXX)"
      export HOME="$verify_home"
      export XDG_CACHE_HOME="$verify_home/.cache"
      mkdir -p "$XDG_CACHE_HOME"
      trap 'rm -rf "$verify_home"' EXIT

      sbcl_base_args=(
        --no-userinit
        --non-interactive
        --disable-debugger
        --eval '(require :asdf)'
        --eval '(ignore-errors (require :sb-introspect))'
        --eval '(when (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD")
                  (ignore-errors (asdf:clear-system "html-inspector-views"))
                  (ignore-errors (asdf:clear-system "html-inspector-views/standard"))
                  (ignore-errors (asdf:clear-system "html-inspector-views/reactive"))
                  (load (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD")))'
        --eval '(asdf:load-system :html-inspector-views)'
        --eval '(when (uiop:getenv "HTML_INSPECTOR_VIEWS_THUNKS")
                  (load (uiop:getenv "HTML_INSPECTOR_VIEWS_THUNKS")))'
        --eval '(when (find-package :html-inspector-views)
                  (export (list (intern "THUNK" :html-inspector-views)
                                (intern "EVAL-THUNK" :html-inspector-views))
                          :html-inspector-views))'
      )

      sbcl() {
        ${sbclEnv}/bin/sbcl "''${sbcl_base_args[@]}" "$@"
      }

      echo "[verify] release=$HYPERDOC_RELEASE_ID"
      echo "[verify] load hyperdoc/server and assert key symbols"
      sbcl \
        --eval '(asdf:load-system :hyperdoc/server :force t)' \
        --eval '(assert (fboundp (quote hyperdoc::official-rpi-tutorial-workflow)))' \
        --eval '(assert (fboundp (quote hyperdoc::official-rpi-tutorial-step)))' \
        --eval '(format t "DOC_RUNTIME_CONSISTENCY_OK~%")' \
        --eval '(uiop:quit 0)'

      echo "[verify] run shipped-pages expr consistency gate"
      sbcl --load "$HYPERDOC_ROOT/tools/check-release-doc-runtime.lisp"

      echo "[verify] derive canonical slug/page paths from runtime"
      key_info="$(
        sbcl \
          --eval '(asdf:load-system :hyperdoc/server :force t)' \
          --eval '(let* ((hb (hyperbook:find-hyperbook "hyperdoc"))
                         (slug (hyperbook/server::slug hb))
                         (official (hyperbook:find-page hb "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"))
                         (server-page (hyperbook:find-page hb "HyperDoc Server")))
                    (assert hb)
                    (assert official)
                    (assert server-page)
                    (let ((official-path (str:concat "/" slug "/" (tbnl:url-encode (hyperbook:path-item-of official))))
                          (server-path (str:concat "/" slug "/" (tbnl:url-encode (hyperbook:path-item-of server-page)))))
                      (assert (and (> (length official-path) 0) (char= (char official-path 0) #\/)))
                      (assert (and (> (length server-path) 0) (char= (char server-path 0) #\/)))
                      (format t "HYPERDOC_SLUG ~A~%" slug)
                      (format t "KEY_PAGE_PATH ~A~%" official-path)
                      (format t "KEY_PAGE_PATH ~A~%" server-path)))' \
          --eval '(uiop:quit 0)'
      )"
      slug="$(
        printf '%s\n' "$key_info" \
          | awk '{
              pos = index($0, "HYPERDOC_SLUG ");
              if (pos > 0) {
                print substr($0, pos + length("HYPERDOC_SLUG "));
                exit 0;
              }
            }'
      )"
      key_page_paths="$(
        printf '%s\n' "$key_info" \
          | awk '{
              pos = index($0, "KEY_PAGE_PATH ");
              if (pos > 0) {
                print substr($0, pos + length("KEY_PAGE_PATH "));
              }
            }'
      )"
      if [ -z "$slug" ] || [ -z "$key_page_paths" ]; then
        echo "[verify] failed to derive canonical key page paths" >&2
        printf '%s\n' "$key_info" >&2
        exit 1
      fi
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        case "$path" in
          "/$slug/"*|"/$slug") ;;
          *)
            echo "[verify] non-canonical page path returned by object-url: $path" >&2
            exit 1
            ;;
        esac
      done <<< "$key_page_paths"

      log_file="$(mktemp /tmp/hyperdoc-release-verify.XXXXXX.log)"
      echo "[verify] start production-like server on $host:$port (log=$log_file)"
      (
        HYPERDOC_BIND_ADDRESS="$host" \
        HYPERDOC_PORT="$port" \
        HYPERDOC_DEVELOPMENT=0 \
        HYPERDOC_DEBUG=0 \
        HYPERDOC_USE_THREAD=0 \
        timeout "$timeout_s" "$RELEASE_PREFIX/bin/hyperdoc-release-start" >"$log_file" 2>&1
      ) &
      server_pid=$!
      cleanup() {
        kill "$server_pid" 2>/dev/null || true
      }
      trap cleanup EXIT

      ready=0
      for _i in $(seq 1 60); do
        if curl -fsS "http://$host:$port/boot.html" -o /tmp/hyperdoc-release-boot.$$; then
          ready=1
          break
        fi
        sleep 1
      done
      if [ "$ready" -ne 1 ]; then
        echo "[verify] server did not become ready; log tail:" >&2
        tail -n 120 "$log_file" >&2 || true
        exit 1
      fi

      echo "[verify] HTTP boot check"
      curl -fsS -D /tmp/hyperdoc-release-boot-headers.$$ "http://$host:$port/boot.html" -o /tmp/hyperdoc-release-boot-body.$$
      head -n 1 /tmp/hyperdoc-release-boot-headers.$$

      echo "[verify] HTTP key-page checks"
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        curl -fsS -D /tmp/hyperdoc-release-page-headers.$$ "http://$host:$port$path" -o /tmp/hyperdoc-release-page-body.$$
        head -n 1 /tmp/hyperdoc-release-page-headers.$$
      done <<< "$key_page_paths"

      echo "[verify] URL helper asset checks"
      url_js_path="/tmp/hyperdoc-release-urljs.$$"
      url_js_code="$(curl -sS -o "$url_js_path" -w '%{http_code}' "http://$host:$port/hyperbook-server/js/url.js" || true)"
      if [ "$url_js_code" = "200" ]; then
        echo "HTTP/1.1 200 OK"
      else
        echo "[verify] /hyperbook-server/js/url.js returned code=$url_js_code; falling back to shipped asset file check"
        rm -f "$url_js_path"
        for candidate in \
          "$HYPERDOC_ROOT/hyperbook-server/assets/hyperbook-server/js/url.js" \
          "$HYPERDOC_ROOT/assets/hyperbook-server/js/url.js"
        do
          if [ -f "$candidate" ]; then
            cp "$candidate" "$url_js_path"
            break
          fi
        done
      fi
      if [ ! -f "$url_js_path" ]; then
        echo "[verify] missing url.js in both HTTP route and shipped assets" >&2
        exit 1
      fi
      grep -q 'new URL(' "$url_js_path"
      if grep -q "origin + '/' + slug.textContent" "$url_js_path"; then
        echo "[verify] url.js still contains naive slug URL construction" >&2
        exit 1
      fi

      echo "RELEASE_VERIFY_OK id=$HYPERDOC_RELEASE_ID slug=$slug"
    '';
  };
in
pkgs.symlinkJoin {
  name = "hyperdoc-release-${releaseId}";
  paths = [ startScript infoScript verifyScript ];
  postBuild = ''
    mkdir -p "$out/share/hyperdoc"
    ln -s ${releaseSource} "$out/share/hyperdoc/source"
    cat > "$out/share/hyperdoc/release.json" <<EOF
{
  "release_id": "${releaseId}",
  "git_revision": "${releaseRevision}",
  "flake_lock_sha256": "${flakeLockSha256}",
  "source_path": "${releaseSource}"
}
EOF
  '';
}
