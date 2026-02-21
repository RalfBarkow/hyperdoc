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
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        arrowsSrc = arrows-src;
        clogMoldableInspectorSrc = clog-moldable-inspector-src;
        htmlInspectorViewsSrc = html-inspector-views-src;
        plumpInspectorViewsSrc = plump-inspector-views-src;
        lwcellsSrc = lwcells-src;

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
          ps.jzon
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
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            sbclEnv
            pkgs.python3
            pkgs.git
            pkgs.rlwrap
            pkgs.openssl
            pkgs.sqlite
            pkgs.pkg-config
          ];

          shellHook = ''
            export HYPERDOC_ROOT="$PWD"
            export PATH="${sbclEnv}/bin:$PATH"
            current_registry="''${CL_SOURCE_REGISTRY:-}"
            project_tree="$PWD//"
            export ARROWS_SRC="${arrowsSrc}"
            export CLOG_MOLDABLE_INSPECTOR_SRC="${clogMoldableInspectorSrc}"
            export HTML_INSPECTOR_VIEWS_SRC="${htmlInspectorViewsSrc}"
            export PLUMP_INSPECTOR_VIEWS_SRC="${plumpInspectorViewsSrc}"
            export LWCELLS_SRC="${lwcellsSrc}"

            CL_MARKUP_SRC=""
            if [ -n "$current_registry" ]; then
              IFS=':' read -r -a _registry_parts <<< "$current_registry"
              for _part in "''${_registry_parts[@]}"; do
                case "$_part" in
                  *-sbcl-cl-markup-*//|*-sbcl-cl-markup-*/)
                    CL_MARKUP_SRC="''${_part%/}"
                    CL_MARKUP_SRC="''${CL_MARKUP_SRC%/}"
                    break
                    ;;
                esac
              done
              unset _registry_parts _part
            fi
            export CL_MARKUP_SRC

            mkdir -p .flake-deps
            ln -snf "$HTML_INSPECTOR_VIEWS_SRC" .flake-deps/html-inspector-views
            ln -snf "$PLUMP_INSPECTOR_VIEWS_SRC" .flake-deps/plump-inspector-views
            ln -snf "$CLOG_MOLDABLE_INSPECTOR_SRC" .flake-deps/clog-moldable-inspector
            ln -snf "$LWCELLS_SRC" .flake-deps/lwcells
            ln -snf "$ARROWS_SRC" .flake-deps/arrows
            if [ -n "$CL_MARKUP_SRC" ]; then
              ln -snf "$CL_MARKUP_SRC" .flake-deps/cl-markup
            fi

            if [ -n "$current_registry" ]; then
              export CL_SOURCE_REGISTRY="$project_tree:$current_registry"
            else
              export CL_SOURCE_REGISTRY="$project_tree"
            fi
            if [ -n "$current_registry" ]; then
              export HYPERDOC_ASDF_TREES="$project_tree:$current_registry"
            else
              export HYPERDOC_ASDF_TREES="$project_tree"
            fi
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

        apps.default = {
          type = "app";
          program = toString (pkgs.writeShellScript "hyperdoc-start" ''
            set -euo pipefail
            export HTML_INSPECTOR_VIEWS_ASD="${htmlInspectorViewsSrc}/html-inspector-views.asd"
            exec ${sbclEnv}/bin/sbcl --no-userinit \
              --eval '(require :asdf)' \
              --eval '(ignore-errors (require :sb-introspect))' \
              --eval '(when (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD")
                        (ignore-errors (asdf:clear-system "html-inspector-views"))
                        (ignore-errors (asdf:clear-system "html-inspector-views/standard"))
                        (ignore-errors (asdf:clear-system "html-inspector-views/reactive"))
                        (load (uiop:getenv "HTML_INSPECTOR_VIEWS_ASD")))' \
              --eval '(asdf:load-system :html-inspector-views)' \
              --eval '(when (uiop:getenv "HTML_INSPECTOR_VIEWS_THUNKS") (load (uiop:getenv "HTML_INSPECTOR_VIEWS_THUNKS")))' \
              --eval '(when (find-package :html-inspector-views)
                        (export (list (intern "THUNK" :html-inspector-views)
                                      (intern "EVAL-THUNK" :html-inspector-views))
                                :html-inspector-views))' \
              --eval '(asdf:load-system :hyperbook/server)' \
              --eval '(hyperbook/server:serve-catalog)'
          '');
        };
      });
}
