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
, shop3Src
, shop3PddlToolsSrc
, shop3FiveamAsdfSrc
, shop3RandomStateSrc
, shop3DocumentationUtilsSrc
, shop3TrivialIndentSrc
, shop3TrivialGarbageSrc
, shop3IterateSrc
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
    export SHOP3_SRC="${shop3Src}"
    export SHOP3_PDDL_TOOLS_SRC="${shop3PddlToolsSrc}"
    export SHOP3_FIVEAM_ASDF_SRC="${shop3FiveamAsdfSrc}"
    export SHOP3_RANDOM_STATE_SRC="${shop3RandomStateSrc}"
    export SHOP3_DOCUMENTATION_UTILS_SRC="${shop3DocumentationUtilsSrc}"
    export SHOP3_TRIVIAL_INDENT_SRC="${shop3TrivialIndentSrc}"
    export SHOP3_TRIVIAL_GARBAGE_SRC="${shop3TrivialGarbageSrc}"
    export SHOP3_ITERATE_SRC="${shop3IterateSrc}"
    export CL_MARKUP_SRC="${clMarkupSrc}"
    export HTML_INSPECTOR_VIEWS_ASD="${htmlInspectorViewsSrc}/html-inspector-views.asd"
    export CL_SOURCE_REGISTRY="${clogSrcPatched}//:${clogMoldableInspectorSrc}//:${htmlInspectorViewsSrc}//:${plumpInspectorViewsSrc}//:${lwcellsSrc}//:${shop3Src}/shop3//:${shop3PddlToolsSrc}//:${shop3FiveamAsdfSrc}//:${shop3RandomStateSrc}//:${shop3DocumentationUtilsSrc}//:${shop3TrivialIndentSrc}//:${shop3TrivialGarbageSrc}//:${shop3IterateSrc}//:${arrowsSrc}//:${clMarkupSrc}//:$HYPERDOC_ROOT//:${namedClosurePkg}//"
    export HYPERDOC_ASDF_TREES="$CL_SOURCE_REGISTRY"
    export HYPERDOC_GIT_PROGRAM="''${HYPERDOC_GIT_PROGRAM:-${pkgs.git}/bin/git}"
  '';

  startScript = pkgs.writeShellApplication {
    name = "hyperdoc-release-start";
    runtimeInputs = [
      pkgs.git
    ];
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

  mcpStartScript = pkgs.writeShellApplication {
    name = "hyperdoc-mcp-release-start";
    runtimeInputs = [
      pkgs.git
    ];
    text = ''
      set -euo pipefail
      ${runtimeInit}

      export HYPERDOC_MCP_BIND_ADDRESS="''${HYPERDOC_MCP_BIND_ADDRESS:-127.0.0.1}"
      export HYPERDOC_MCP_PORT="''${HYPERDOC_MCP_PORT:-8787}"
      export HYPERDOC_MCP_ENABLE_LIVE_WRITES="''${HYPERDOC_MCP_ENABLE_LIVE_WRITES:-0}"
      export HYPERDOC_MCP_WORKSPACE_TOPICMAP_ID="''${HYPERDOC_MCP_WORKSPACE_TOPICMAP_ID:-919822}"

      echo "HyperDoc MCP release: $HYPERDOC_RELEASE_ID"
      echo "HyperDoc MCP revision: $HYPERDOC_RELEASE_REV"
      echo "HyperDoc MCP flake.lock sha256: $HYPERDOC_RELEASE_FLAKE_LOCK_SHA256"
      echo "HyperDoc MCP bind: $HYPERDOC_MCP_BIND_ADDRESS:$HYPERDOC_MCP_PORT"
      echo "HyperDoc MCP workspace topicmap: $HYPERDOC_MCP_WORKSPACE_TOPICMAP_ID"
      if [ -n "''${HYPERDOC_DMX_IMPORT_WORKSPACE_ID:-}" ]; then
        echo "HyperDoc DMX workspace assignment: $HYPERDOC_DMX_IMPORT_WORKSPACE_ID"
      fi
      echo "HyperDoc MCP live writes: $HYPERDOC_MCP_ENABLE_LIVE_WRITES"

      exec ${sbclEnv}/bin/sbcl \
        --no-userinit \
        --non-interactive \
        --disable-debugger \
        --eval '(require :asdf)' \
        --eval '(asdf:load-system :hyperdoc/mcp)' \
        --eval '(sb-sys:enable-interrupt
                   sb-unix:sigint
                   (lambda (signal code scp)
                     (declare (ignore signal code scp))
                     (format t "~&Stopping DMX MCP server (Ctrl-C).~%")
                     (finish-output)
                     (sb-ext:exit :code 130 :abort t)))' \
        --eval '(let* ((port (or (ignore-errors (parse-integer (or (uiop:getenv "HYPERDOC_MCP_PORT") "8787")))
                                 8787))
                       (address (or (uiop:getenv "HYPERDOC_MCP_BIND_ADDRESS")
                                    "127.0.0.1")))
                  (hyperdoc:serve-dmx-mcp-server
                   :port port
                   :address address)
                  (format t "DMX_MCP_SERVER_READY~%")
                  (finish-output)
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
    runtimeInputs = [ pkgs.coreutils pkgs.curl pkgs.gnugrep pkgs.findutils pkgs.gawk pkgs.python3 pkgs.which pkgs.git ];
    text = ''
      set -euo pipefail
      ${runtimeInit}

      host="''${HYPERDOC_VERIFY_HOST:-127.0.0.1}"
      requested_port="''${HYPERDOC_VERIFY_PORT:-}"
      default_port="18080"
      timeout_s="''${HYPERDOC_VERIFY_TIMEOUT:-60}"
      curl_connect_timeout_s="''${HYPERDOC_VERIFY_CONNECT_TIMEOUT:-2}"
      curl_max_time_s="''${HYPERDOC_VERIFY_MAX_TIME:-8}"
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

      choose_free_port() {
        ${pkgs.python3}/bin/python3 - <<'PY'
import socket
with socket.socket() as s:
    s.bind(("0.0.0.0", 0))
    print(s.getsockname()[1])
PY
      }

      port_is_free() {
        local port="$1"
        ${pkgs.python3}/bin/python3 - "$port" <<'PY'
import socket, sys
port = int(sys.argv[1])
with socket.socket() as s:
    try:
        s.bind(("0.0.0.0", port))
        print("free")
    except OSError:
        print("busy")
PY
      }

      warning_count=0
      if [ -n "$requested_port" ]; then
        port="$requested_port"
        if [ "$(port_is_free "$port")" != "free" ]; then
          selected_port="$(choose_free_port)"
          echo "[verify][warn] requested verify port $port busy; selected free port $selected_port"
          port="$selected_port"
          warning_count=$((warning_count + 1))
        fi
      else
        port="$default_port"
        if [ "$(port_is_free "$port")" != "free" ]; then
          selected_port="$(choose_free_port)"
          echo "[verify][warn] default verify port $port busy; selected free port $selected_port"
          port="$selected_port"
          warning_count=$((warning_count + 1))
        fi
      fi
      echo "[verify] selected endpoint http://$host:$port/boot.html"

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
                         (drawing (hyperbook:find-page hb "Drawing Automation and review materialization"))
                         (official (hyperbook:find-page hb "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"))
                         (server-page (hyperbook:find-page hb "HyperDoc Server")))
                    (assert hb)
                    (assert drawing)
                    (assert official)
                    (assert server-page)
                    (let ((drawing-path (str:concat "/" slug "/" (tbnl:url-encode (hyperbook:path-item-of drawing))))
                          (official-path (str:concat "/" slug "/" (tbnl:url-encode (hyperbook:path-item-of official))))
                          (server-path (str:concat "/" slug "/" (tbnl:url-encode (hyperbook:path-item-of server-page)))))
                      (assert (and (> (length drawing-path) 0) (char= (char drawing-path 0) #\/)))
                      (assert (and (> (length official-path) 0) (char= (char official-path 0) #\/)))
                      (assert (and (> (length server-path) 0) (char= (char server-path 0) #\/)))
                      (format t "HYPERDOC_SLUG ~A~%" slug)
                      (format t "KEY_PAGE_PATH ~A~%" drawing-path)
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
        wait "$server_pid" 2>/dev/null || true
      }
      trap cleanup EXIT

      curl_common_args=(
        --retry 0
        --connect-timeout "$curl_connect_timeout_s"
        --max-time "$curl_max_time_s"
      )

      show_server_log_tail() {
        echo "[verify] server log tail:" >&2
        tail -n 120 "$log_file" >&2 || true
      }

      server_alive() {
        kill -0 "$server_pid" 2>/dev/null
      }

      http_probe() {
        local url="$1"
        local output="$2"
        curl "''${curl_common_args[@]}" -fsS "$url" -o "$output"
      }

      http_fetch() {
        local label="$1"
        local url="$2"
        local headers="$3"
        local body="$4"
        if ! curl "''${curl_common_args[@]}" -fsS -D "$headers" "$url" -o "$body"; then
          echo "[verify] HTTP fetch failed for $label: $url" >&2
          show_server_log_tail
          exit 1
        fi
      }

      http_status_fetch() {
        local label="$1"
        local url="$2"
        local output="$3"
        local status
        if ! status="$(curl "''${curl_common_args[@]}" -sS -o "$output" -w '%{http_code}' "$url")"; then
          echo "[verify] HTTP fetch failed for $label: $url" >&2
          show_server_log_tail
          exit 1
        fi
        printf '%s\n' "$status"
      }

      ready=0
      ready_attempts=0
      for _i in $(seq 1 60); do
        ready_attempts=$((ready_attempts + 1))
        if ! server_alive; then
          echo "[verify] server process exited before readiness probe succeeded" >&2
          show_server_log_tail
          wait "$server_pid" 2>/dev/null || true
          exit 1
        fi
        if http_probe "http://$host:$port/boot.html" /tmp/hyperdoc-release-boot.$$ \
          >/dev/null 2>&1; then
          ready=1
          break
        fi
        sleep 1
      done
      if [ "$ready" -ne 1 ]; then
        echo "[verify] server did not become ready after $ready_attempts bounded probes" >&2
        show_server_log_tail
        exit 1
      fi
      if [ "$ready_attempts" -gt 1 ]; then
        warning_count=$((warning_count + 1))
        echo "[verify][warn] server became ready after $ready_attempts probes"
      fi

      check_html_shell() {
        local file="$1"
        local label="$2"

        if grep -q '<%=' "$file"; then
          echo "[verify] raw template marker leaked in $label" >&2
          exit 1
        fi
        if ! grep -Eqi '<html[^>]+lang=' "$file"; then
          echo "[verify] missing html lang attribute in $label" >&2
          exit 1
        fi
        if ! grep -Eqi '<title[^>]*>[^<]+</title>' "$file"; then
          echo "[verify] missing document title in $label" >&2
          exit 1
        fi
        if grep -Eqi '<meta[^>]+http-equiv=["'"'"'](Cache-Control|Pragma|Expires)["'"'"']' "$file"; then
          echo "[verify] invalid cache-control meta tag present in $label" >&2
          exit 1
        fi
      }

      echo "[verify] HTTP boot check"
      http_fetch /boot.html "http://$host:$port/boot.html" /tmp/hyperdoc-release-boot-headers.$$ /tmp/hyperdoc-release-boot-body.$$
      head -n 1 /tmp/hyperdoc-release-boot-headers.$$
      check_html_shell /tmp/hyperdoc-release-boot-body.$$ /boot.html

      echo "[verify] HTTP key-page checks"
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        http_fetch "$path" "http://$host:$port$path" /tmp/hyperdoc-release-page-headers.$$ /tmp/hyperdoc-release-page-body.$$
        head -n 1 /tmp/hyperdoc-release-page-headers.$$
        check_html_shell /tmp/hyperdoc-release-page-body.$$ "$path"
      done <<< "$key_page_paths"

      echo "[verify] URL helper asset checks"
      url_js_path="/tmp/hyperdoc-release-urljs.$$"
      url_js_code="$(http_status_fetch /hyperbook-server/js/url.js "http://$host:$port/hyperbook-server/js/url.js" "$url_js_path")"
      if [ "$url_js_code" = "200" ]; then
        echo "HTTP/1.1 200 OK"
      else
        warning_count=$((warning_count + 1))
        echo "[verify][warn] /hyperbook-server/js/url.js returned code=$url_js_code; verified shipped asset file instead"
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

      if [ "$warning_count" -gt 0 ]; then
        echo "RELEASE_VERIFY_PASS_WITH_WARNINGS warnings=$warning_count id=$HYPERDOC_RELEASE_ID slug=$slug"
      else
        echo "RELEASE_VERIFY_OK id=$HYPERDOC_RELEASE_ID slug=$slug"
      fi
    '';
  };
in
pkgs.symlinkJoin {
  name = "hyperdoc-release-${releaseId}";
  paths = [ startScript mcpStartScript infoScript verifyScript ];
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
