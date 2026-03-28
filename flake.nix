{
  description = "HyperDoc development environment (SBCL + ASDF registry, no Quicklisp)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    arrows-src = {
      url = "github:Harleqin/arrows";
      flake = false;
    };
    clog-moldable-inspector-src = {
      url = "git+https://codeberg.org/khinsen/clog-moldable-inspector.git";
      flake = false;
    };
    html-inspector-views-src = {
      url = "git+https://codeberg.org/khinsen/html-inspector-views.git";
      flake = false;
    };
    plump-inspector-views-src = {
      url = "git+https://codeberg.org/khinsen/plump-inspector-views.git";
      flake = false;
    };
    lwcells-src = {
      url = "github:kchanqvq/lwcells";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, arrows-src, clog-moldable-inspector-src, html-inspector-views-src, plump-inspector-views-src, lwcells-src }:
    let
      dreyeckHardwarePath = "${toString ./nix/hosts}/dreyeck-ch/hardware-configuration.nix";
      dreyeckHardwareModule =
        if builtins.pathExists dreyeckHardwarePath
        then builtins.toPath dreyeckHardwarePath
        else ./nix/hosts/dreyeck-ch-fallback-hardware.nix;
      perSystem = flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        namedClosurePkg = pkgs.callPackage ./nix/sbcl-named-closure.nix { };
        arrowsSrc = arrows-src;
        clogSrcPatched = pkgs.applyPatches {
          name = "clog-src-patched";
          src = pkgs.sbclPackages.clog.src;
          nativeBuildInputs = [ pkgs.python3 ];
          postPatch = ''
            python3 - <<'PY'
from pathlib import Path

boot = Path("static-files/boot.html")
p = Path("static-files/js/boot.js")
s = p.read_text()
empty_js = "'" + "'"
boot_html = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>HyperDoc</title>
  <script src="/js/jquery.min.js"></script>
  <script src="/js/boot.js"></script>
</head>
<body>
  <noscript>Your browser must support JavaScript and HTML5 to see this site.</noscript>
</body>
</html>
"""

original_debug = """if (typeof clog_debug == 'undefined') {
    clog_debug = false;
}
"""

replaced_debug = """if (typeof clog_debug == 'undefined') {
    clog_debug = false;
}

function Guard_empty_selector() {
    if (typeof jQuery == 'undefined' || !jQuery.find || !jQuery.find.error) {
        return;
    }

    var original = jQuery.find.error;
    jQuery.find.error = function (msg) {
        if (msg === "#") {
            console.warn("Ignoring empty jQuery selector \\"#\\"");
            return;
        }
        return original.call(this, msg);
    }
}

function Clog_set_connection_state(state) {
    clog['connection_state'] = state;
    if (document.documentElement) {
        document.documentElement.setAttribute('data-clog-connection-state', state);
    }
    if (document.body) {
        document.body.setAttribute('data-clog-connection-state', state);
    }
}

function Clog_disconnected_message(detail) {
    if (detail && detail.length > 0 && detail !== 'user') {
        return 'Disconnected from HyperDoc: ' + detail + '. Clicks will not open new panes until you reload to reconnect.';
    }
    return 'Disconnected from HyperDoc. Clicks will not open new panes until you reload to reconnect.';
}

function Clog_show_disconnected_state(detail) {
    var message = Clog_disconnected_message(detail);
    clog['disconnected_message'] = message;
    Clog_set_connection_state('disconnected');
    if (typeof clog['html_on_close'] === 'string' && clog['html_on_close'] !== "") {
        return message;
    }
    if (!document.body) {
        return message;
    }
    var banner = document.getElementById('clog-disconnected-banner');
    if (!banner) {
        banner = document.createElement('div');
        banner.id = 'clog-disconnected-banner';
        banner.setAttribute('role', 'status');
        banner.setAttribute('aria-live', 'polite');
        banner.style.cssText = 'position:fixed;top:0;left:0;right:0;z-index:2147483647;padding:8px 12px;background:#7a0018;color:#fff;font:14px/1.4 sans-serif;box-shadow:0 1px 4px rgba(0,0,0,.25)';
        document.body.appendChild(banner);
    }
    banner.textContent = message;
    return message;
}

function Clog_clear_disconnected_state() {
    clog['disconnected_message'] = "";
    Clog_set_connection_state('connected');
    var banner = document.getElementById('clog-disconnected-banner');
    if (banner) {
        banner.remove();
    }
}

function Clog_send(payload, options) {
    if (ws != null && ws.readyState == 1) {
        ws.send(payload);
        return true;
    }
    var context = options && options.context ? ' (' + options.context + ')' : "";
    var message = Clog_show_disconnected_state(options && options.reason ? options.reason : null);
    console.warn(message + context);
    return false;
}

function Clog_make_disconnected_socket(detail) {
    return {
        readyState: 3,
        send: function (payload) {
            return Clog_send(payload, {
                reason: detail,
                context: 'disconnected-session'
            });
        },
        close: function () {
            return false;
        }
    };
}
"""

original_error = """        } catch (e) {
            console.error (e.message);
        }
"""

replaced_error = """        } catch (e) {
            const payload = (event && typeof event.data === 'string')
                ? event.data
                : String(event && event.data);
            if (!window.__clog_eval_seq) window.__clog_eval_seq = 0;
            window.__clog_eval_seq += 1;
            const seq = window.__clog_eval_seq;
            window.__clog_last_eval_seq = seq;
            window.__clog_last_eval_payload = payload;
            console.error("[CLOG] eval error seq=", seq, e);
            console.error("[CLOG] eval error payload(first 800 chars)=", payload.slice(0, 800));
        }
"""

original_ready = """$( document ).ready(function() {
    if (ws == null) { Open_ws(); }
});
"""

replaced_ready = """$( document ).ready(function() {
    Guard_empty_selector();
    if (ws == null) { Open_ws(); }
});
"""

original_ping = """function Ping_ws() {
    if (ws.readyState == 1) {
        ws.send ('0');
    }
}
"""

replaced_ping = """function Ping_ws() {
    if (ws != null && ws.readyState == 1) {
        ws.send ('0');
    }
}
"""

original_shutdown = """function Shutdown_ws(event) {
    if (ws != null) {
\tws.onerror = null;
\tws.onclose = null;
\tws.close ();
\tws = null;
    }
    clearInterval (pingerid);
    if (clog['html_on_close'] != __EMPTY_JS__) {
        $(document.body).html(clog['html_on_close']);
    }
}
""".replace("__EMPTY_JS__", empty_js)

replaced_shutdown = """function Shutdown_ws(event) {
    if (ws != null) {
\tws.onerror = null;
\tws.onclose = null;
\tws.close ();
    }
    ws = Clog_make_disconnected_socket(event && event.reason ? event.reason : null);
    clearInterval (pingerid);
    Clog_show_disconnected_state(event && event.reason ? event.reason : null);
    if (typeof clog['html_on_close'] === 'string' && clog['html_on_close'] !== "") {
        $(document.body).html(clog['html_on_close']);
    }
}
"""

original_open = """    if (ws != null) {
\tws.onopen = function (event) {
            console.log ('connection successful');
            Setup_ws();
\t}
\tpingerid = setInterval (function () {Ping_ws ();}, 10000);
    } else {
\tdocument.writeln ('If you are seeing this your browser or your connection to the internet is blocking websockets.');
    }
}
"""

replaced_open = """    Clog_set_connection_state('connecting');
    if (ws != null) {
\tws.onopen = function (event) {
            console.log ('connection successful');
            Clog_clear_disconnected_state();
            Setup_ws();
\t}
\tpingerid = setInterval (function () {Ping_ws ();}, 10000);
    } else {
\tdocument.writeln ('If you are seeing this your browser or your connection to the internet is blocking websockets.');
    }
}
"""

original_reconnect_open = """        ws.onopen = function (event) {
            console.log ('reconnect successful');
            Setup_ws();
        }
"""

replaced_reconnect_open = """        ws.onopen = function (event) {
            console.log ('reconnect successful');
            Clog_clear_disconnected_state();
            Setup_ws();
        }
"""


if "function Guard_empty_selector()" not in s:
    if s.count(original_debug) != 1:
        raise SystemExit("Expected debug block exactly once")
    s = s.replace(original_debug, replaced_debug, 1)

if 'console.error("[CLOG] eval error seq=", seq, e);' not in s:
    if s.count(original_error) != 1:
        raise SystemExit("Expected eval error block exactly once")
    s = s.replace(original_error, replaced_error, 1)

if "Guard_empty_selector();" not in s:
    if s.count(original_ready) != 1:
        raise SystemExit("Expected document ready block exactly once")
    s = s.replace(original_ready, replaced_ready, 1)

if "function Ping_ws() {\n    if (ws != null && ws.readyState == 1)" not in s:
    if s.count(original_ping) != 1:
        raise SystemExit("Expected ping block exactly once")
    s = s.replace(original_ping, replaced_ping, 1)

if "Clog_show_disconnected_state(event && event.reason ? event.reason : null);" not in s:
    if s.count(original_shutdown) != 1:
        raise SystemExit("Expected shutdown block exactly once")
    s = s.replace(original_shutdown, replaced_shutdown, 1)

if "Clog_set_connection_state('connecting');" not in s:
    if s.count(original_open) != 1:
        raise SystemExit("Expected open block exactly once")
    s = s.replace(original_open, replaced_open, 1)

if "console.log ('reconnect successful');\n            Clog_clear_disconnected_state();" not in s:
    if s.count(original_reconnect_open) != 1:
        raise SystemExit("Expected reconnect-open block exactly once")
    s = s.replace(original_reconnect_open, replaced_reconnect_open, 1)

boot.write_text(boot_html)
p.write_text(s)
PY
          '';
        };
        clogMoldableInspectorSrc = clog-moldable-inspector-src;
        htmlInspectorViewsSrc = html-inspector-views-src;
        plumpInspectorViewsSrc = plump-inspector-views-src;
        lwcellsSrc = lwcells-src;
        clMarkupSrc = pkgs.sbclPackages."cl-markup".src;
        asdfSourceRegistryDefault = builtins.concatStringsSep ":" [
          "${clogSrcPatched}//"
          "${clogMoldableInspectorSrc}//"
          "${htmlInspectorViewsSrc}//"
          "${plumpInspectorViewsSrc}//"
          "${lwcellsSrc}//"
          "${arrowsSrc}//"
          "${clMarkupSrc}//"
          "$PWD//"
          "${namedClosurePkg}//"
        ];
        asdfSourceExports = ''
          export ARROWS_SRC="${arrowsSrc}"
          export CLOG_SRC="${clogSrcPatched}"
          export CLOG_MOLDABLE_INSPECTOR_SRC="${clogMoldableInspectorSrc}"
          export HTML_INSPECTOR_VIEWS_SRC="${htmlInspectorViewsSrc}"
          export PLUMP_INSPECTOR_VIEWS_SRC="${plumpInspectorViewsSrc}"
          export LWCELLS_SRC="${lwcellsSrc}"
          export CL_MARKUP_SRC="${clMarkupSrc}"
        '';

        sbclEnv = pkgs.sbcl.withPackages (ps: with ps; [
          alexandria
          ps.arrows
          ps.arrow-macros
          babel
          bordeaux-threads
          ps."cl-base32"
          ps."cl-base64"
          ps."cl-markup"
          ps."cl-slug"
          cl-who
          clack
          clack-handler-hunchentoot
          ps."closer-mop"
          ps."damn-fast-stable-priority-queue"
          drakma
          ps.dissect
          ps.eco
          ps.flexi-streams
          ps.fset
          hunchentoot
          ps."local-time"
          ps.lquery
          ps.plump
          ps.puri
          ps."s-graphviz"
          ps.sha1
          ps.shasht
          jzon
          ps.str
          ps.swank
          ps."trivial-clipboard"
          ps."trivial-package-local-nicknames"
          ps.usocket
          ps._3bmd
          ps._3bmd-ext-code-blocks
          ps.clog
          ps."clog-ace"
          ps."eclector-concrete-syntax-tree"
        ]);
        releaseRevision =
          if self ? dirtyShortRev then self.dirtyShortRev
          else if self ? shortRev then self.shortRev
          else if self ? dirtyRev then builtins.substring 0 12 self.dirtyRev
          else if self ? rev then builtins.substring 0 7 self.rev
          else "unknown";
        flakeLockSha256 = builtins.hashFile "sha256" ./flake.lock;
        releaseId = "${releaseRevision}-${builtins.substring 0 12 flakeLockSha256}";
        releasePackage = pkgs.callPackage ./nix/release/package.nix {
          releaseSource = self;
          inherit
            sbclEnv
            namedClosurePkg
            arrowsSrc
            clogSrcPatched
            clogMoldableInspectorSrc
            htmlInspectorViewsSrc
            plumpInspectorViewsSrc
            lwcellsSrc
            clMarkupSrc
            releaseId
            releaseRevision
            flakeLockSha256;
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            sbclEnv
            namedClosurePkg
            pkgs.python3
            pkgs.git
            pkgs.rlwrap
            pkgs.openssl
            pkgs.sqlite
            pkgs.pkg-config
          ];

          shellHook = ''
            export HYPERDOC_ROOT="$PWD"
            export HYPERDOC_DMX_IMPORT_BASE_URL="''${HYPERDOC_DMX_IMPORT_BASE_URL:-https://dmx.ralfbarkow.ch}"
            export PATH="${sbclEnv}/bin:$PATH"
            current_registry="''${CL_SOURCE_REGISTRY:-}"
            filtered_registry=""
            project_tree="$PWD//"
            deps_tree="$PWD/.flake-deps//"
            named_closure_tree="${namedClosurePkg}//"
            ${asdfSourceExports}
            clog_tree="$CLOG_SRC//"
            if [ -n "$current_registry" ]; then
              IFS=':' read -r -a _registry_parts <<< "$current_registry"
              for _part in "''${_registry_parts[@]}"; do
                case "$_part" in
                  *-sbcl-mgl-pax-bootstrap-*//|*-sbcl-mgl-pax-bootstrap-*/)
                    continue
                    ;;
                esac
                if [ -n "$filtered_registry" ]; then
                  filtered_registry="$filtered_registry:$_part"
                else
                  filtered_registry="$_part"
                fi
              done
              unset _registry_parts _part
            fi

            mkdir -p .flake-deps
            ln -snf "$HTML_INSPECTOR_VIEWS_SRC" .flake-deps/html-inspector-views
            ln -snf "$CLOG_SRC" .flake-deps/clog
            ln -snf "$PLUMP_INSPECTOR_VIEWS_SRC" .flake-deps/plump-inspector-views
            ln -snf "$CLOG_MOLDABLE_INSPECTOR_SRC" .flake-deps/clog-moldable-inspector
            ln -snf "$LWCELLS_SRC" .flake-deps/lwcells
            ln -snf "$ARROWS_SRC" .flake-deps/arrows
            ln -snf "$CL_MARKUP_SRC" .flake-deps/cl-markup

            if [ -n "$filtered_registry" ]; then
              export CL_SOURCE_REGISTRY="$clog_tree:$deps_tree:$project_tree:$filtered_registry:$named_closure_tree"
            else
              export CL_SOURCE_REGISTRY="$clog_tree:$deps_tree:$project_tree:$named_closure_tree"
            fi
            if [ -n "$filtered_registry" ]; then
              export HYPERDOC_ASDF_TREES="$clog_tree:$deps_tree:$project_tree:$filtered_registry:$named_closure_tree"
            else
              export HYPERDOC_ASDF_TREES="$clog_tree:$deps_tree:$project_tree:$named_closure_tree"
            fi
            unset clog_tree
            unset deps_tree
            unset filtered_registry
            unset named_closure_tree
            unset current_registry
            unset project_tree

            cat <<'EOF'
HyperDoc Nix dev shell ready.

Quick checks:
  sbcl --no-userinit --non-interactive \
    --eval '(require :asdf)' \
    --eval '(asdf:find-system :hyperbook/server)' \
    --eval '(format t "OK~%")' \
    --eval '(uiop:quit 0)'

Start server:
  sbcl --no-userinit \
    --eval '(require :asdf)' \
    --eval '(asdf:load-system :hyperbook/server)' \
    --eval '(hyperbook/server:serve-catalog)'

URL:
  http://localhost:8080/boot.html
EOF
          '';
        };

        packages = {
          hyperdoc-release = releasePackage;
          default = releasePackage;
        };

        apps.default = {
          type = "app";
          program = "${releasePackage}/bin/hyperdoc-release-start";
        };

        apps.mcp-release = {
          type = "app";
          program = "${releasePackage}/bin/hyperdoc-mcp-release-start";
        };

        apps.release-verify = {
          type = "app";
          program = "${releasePackage}/bin/hyperdoc-release-verify";
        };

        apps.release-info = {
          type = "app";
          program = "${releasePackage}/bin/hyperdoc-release-info";
        };

        apps.release-smoke = {
          type = "app";
          program = "${releasePackage}/bin/hyperdoc-release-verify";
        };

        checks = {
          hyperdoc-release = releasePackage;

          hyperdoc-runtime-consistency = pkgs.runCommand "hyperdoc-runtime-consistency" { } ''
            export HYPERDOC_VERIFY_PORT=19080
            ${releasePackage}/bin/hyperdoc-release-verify
            touch "$out"
          '';
        };
      });
    in
    perSystem // {
      nixosModules = {
        hyperdoc-release = import ./nix/modules/hyperdoc-release.nix;
        hyperdoc-mcp-release = import ./nix/modules/hyperdoc-mcp-release.nix;
        dreyeck-ch = import ./nix/hosts/dreyeck-ch.nix;
      };

      nixosConfigurations.dreyeck-ch = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit self; };
        modules = [
          dreyeckHardwareModule
          ./nix/hosts/dreyeck-ch.nix
          ({ lib, pkgs, ... }: {
            system.stateVersion = lib.mkDefault "24.11";
            networking.hostName = lib.mkDefault "dreyeck-ch";
            services.hyperdoc.package = self.packages.${pkgs.system}.hyperdoc-release;
            services.hyperdocMcp.package = self.packages.${pkgs.system}.hyperdoc-release;

            environment.systemPackages = with pkgs; [
              git
            ];
          })
        ];
      };
    };
}
