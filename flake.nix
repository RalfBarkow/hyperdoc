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
    shop3 = {
      url = "github:shop-planner/shop3";
      flake = false;
    };
    shop3-pddl-tools = {
      url = "github:rpgoldman/pddl-tools";
      flake = false;
    };
    shop3-fiveam-asdf = {
      url = "github:rpgoldman/fiveam-asdf";
      flake = false;
    };
    shop3-random-state = {
      url = "github:rpgoldman/random-state";
      flake = false;
    };
    shop3-documentation-utils = {
      url = "github:Shinmera/documentation-utils";
      flake = false;
    };
    shop3-trivial-indent = {
      url = "github:Shinmera/trivial-indent";
      flake = false;
    };
    shop3-trivial-garbage = {
      url = "github:shop-planner/trivial-garbage";
      flake = false;
    };
    shop3-iterate = {
      url = "git+https://gitlab.common-lisp.net/iterate/iterate.git";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, arrows-src, clog-moldable-inspector-src, html-inspector-views-src, plump-inspector-views-src, lwcells-src, shop3, shop3-pddl-tools, shop3-fiveam-asdf, shop3-random-state, shop3-documentation-utils, shop3-trivial-indent, shop3-trivial-garbage, shop3-iterate }:
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
            python3 ${./nix/scripts/apply-clog-source-overrides.py} \
              --overlay-root ${./nix/vendor/clog}
          '';
        };
        clogMoldableInspectorSrc = clog-moldable-inspector-src;
        htmlInspectorViewsSrcPatched = pkgs.applyPatches {
          name = "html-inspector-views-src-patched";
          src = html-inspector-views-src;
          nativeBuildInputs = [ pkgs.python3 ];
          postPatch = ''
            python3 ${./nix/scripts/apply-html-inspector-views-overrides.py} \
              --overlay-root ${./nix/vendor/html-inspector-views}
          '';
        };
        htmlInspectorViewsSrc = htmlInspectorViewsSrcPatched;
        plumpInspectorViewsSrc = plump-inspector-views-src;
        lwcellsSrc = lwcells-src;
        shop3Src = shop3;
        shop3PddlToolsSrc = shop3-pddl-tools;
        shop3FiveamAsdfSrc = shop3-fiveam-asdf;
        shop3RandomStateSrc = shop3-random-state;
        shop3DocumentationUtilsSrc = shop3-documentation-utils;
        shop3TrivialIndentSrc = shop3-trivial-indent;
        shop3TrivialGarbageSrc = shop3-trivial-garbage;
        shop3IterateSrc = shop3-iterate;
        clMarkupSrc = pkgs.sbclPackages."cl-markup".src;
        asdfSourceRegistryDefault = builtins.concatStringsSep ":" [
          "${clogSrcPatched}//"
          "${clogMoldableInspectorSrc}//"
          "${htmlInspectorViewsSrc}//"
          "${plumpInspectorViewsSrc}//"
          "${lwcellsSrc}//"
          "${shop3Src}/shop3//"
          "${shop3PddlToolsSrc}//"
          "${shop3FiveamAsdfSrc}//"
          "${shop3RandomStateSrc}//"
          "${shop3DocumentationUtilsSrc}//"
          "${shop3TrivialIndentSrc}//"
          "${shop3TrivialGarbageSrc}//"
          "${shop3IterateSrc}//"
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
          export SHOP3_SRC="${shop3Src}"
          export SHOP3_PDDL_TOOLS_SRC="${shop3PddlToolsSrc}"
          export SHOP3_FIVEAM_ASDF_SRC="${shop3FiveamAsdfSrc}"
          export SHOP3_RANDOM_STATE_SRC="${shop3RandomStateSrc}"
          export SHOP3_DOCUMENTATION_UTILS_SRC="${shop3DocumentationUtilsSrc}"
          export SHOP3_TRIVIAL_INDENT_SRC="${shop3TrivialIndentSrc}"
          export SHOP3_TRIVIAL_GARBAGE_SRC="${shop3TrivialGarbageSrc}"
          export SHOP3_ITERATE_SRC="${shop3IterateSrc}"
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
          ps.slynk
          ps."trivial-clipboard"
          ps."trivial-package-local-nicknames"
          ps.usocket
          ps._3bmd
          ps._3bmd-ext-code-blocks
          ps.clog
          ps."clog-ace"
          ps."eclector-concrete-syntax-tree"
        ]);

        hyperdocEmacs = pkgs.emacs.pkgs.withPackages (epkgs: with epkgs; [
          slime
          sly
          paredit
          rainbow-delimiters
          magit
        ]);

        hyperdocSlimeConnect = pkgs.writeShellScriptBin "hyperdoc-slime-connect" ''
          host="''${1:-127.0.0.1}"
          port="''${2:-''${SWANK_PORT:-4005}}"
          exec ${hyperdocEmacs}/bin/emacs -Q \
            --eval "(progn (require 'slime) (setq slime-net-coding-system 'utf-8-unix) (slime-connect \"$host\" $port))"
        '';

        hyperdocSlyConnect = pkgs.writeShellScriptBin "hyperdoc-sly-connect" ''
          host="''${1:-127.0.0.1}"
          port="''${2:-''${SLYNK_PORT:-''${SWANK_PORT:-4006}}}"
          exec ${hyperdocEmacs}/bin/emacs -Q \
            --eval "(progn (require 'sly) (sly-connect \"$host\" $port))"
        '';

        lispfmt = pkgs.writeShellApplication {
          name = "lispfmt";
          runtimeInputs = [ pkgs.emacs-nox pkgs.findutils ];
          text = ''
            set -euo pipefail

            if [ "$#" -eq 0 ]; then
              mapfile -t files < <(
                find . \
                  -path './.git' -prune -o \
                  -path './.direnv' -prune -o \
                  -type f \( -name '*.lisp' -o -name '*.asd' \) \
                  -print
              )
            else
              files=("$@")
            fi

            for file in "''${files[@]}"; do
              emacs -Q --batch "$file" \
                --eval "(progn
                          (require 'cl-indent)
                          (lisp-mode)
                          (setq indent-tabs-mode nil)
                          (setq lisp-indent-function 'common-lisp-indent-function)
                          (indent-region (point-min) (point-max))
                          (delete-trailing-whitespace)
                          (save-buffer))"
            done
          '';
        };

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
            shop3Src
            shop3PddlToolsSrc
            shop3FiveamAsdfSrc
            shop3RandomStateSrc
            shop3DocumentationUtilsSrc
            shop3TrivialIndentSrc
            shop3TrivialGarbageSrc
            shop3IterateSrc
            clMarkupSrc
            releaseId
            releaseRevision
            flakeLockSha256;
        };
        runtimeWrapperPackage = pkgs.callPackage ./nix/hyperdoc-runtime-wrapper.nix { };
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            sbclEnv
            namedClosurePkg
            hyperdocEmacs
            hyperdocSlimeConnect
            hyperdocSlyConnect
            lispfmt
            pkgs.python3
            pkgs.git
            pkgs.nodejs
            pkgs.rlwrap
            pkgs.openssl
            pkgs.sqlite
            pkgs.pkg-config
          ];

          shellHook = ''
            export HYPERDOC_ROOT="$PWD"
            export HYPERDOC_DMX_IMPORT_BASE_URL="''${HYPERDOC_DMX_IMPORT_BASE_URL:-https://dmx.ralfbarkow.ch}"
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
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
            ln -snf "$SHOP3_SRC/shop3" .flake-deps/shop3
            ln -snf "$SHOP3_PDDL_TOOLS_SRC" .flake-deps/shop3-pddl-tools
            ln -snf "$SHOP3_FIVEAM_ASDF_SRC" .flake-deps/shop3-fiveam-asdf
            ln -snf "$SHOP3_RANDOM_STATE_SRC" .flake-deps/shop3-random-state
            ln -snf "$SHOP3_DOCUMENTATION_UTILS_SRC" .flake-deps/shop3-documentation-utils
            ln -snf "$SHOP3_TRIVIAL_INDENT_SRC" .flake-deps/shop3-trivial-indent
            ln -snf "$SHOP3_TRIVIAL_GARBAGE_SRC" .flake-deps/shop3-trivial-garbage
            ln -snf "$SHOP3_ITERATE_SRC" .flake-deps/shop3-iterate
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

Check system:
  sbcl --no-userinit --non-interactive \
    --eval '(require :asdf)' \
    --eval '(asdf:find-system :hyperbook/server)' \
    --eval '(format t "OK~%")' \
    --eval '(uiop:quit 0)'

Start server:
  LISP_IDE=slime ./dev.sh
  LISP_IDE=sly   ./dev.sh

Matching editor clients:
  hyperdoc-slime-connect 127.0.0.1 <printed-swank-port>
  hyperdoc-sly-connect   127.0.0.1 <printed-slynk-port>

URL:
  http://localhost:8080/boot.html
EOF
          '';
        };

        packages = {
          inherit lispfmt;
          clogframe = pkgs.callPackage ./nix/clogframe.nix { };
          hyperdoc-release = releasePackage;
          hyperdoc-runtime-wrapper = runtimeWrapperPackage;
          default = releasePackage;
        };

        apps.default = {
          type = "app";
          program = "${releasePackage}/bin/hyperdoc-release-start";
        };

        apps.hyperdoc-runtime-server = {
          type = "app";
          program = "${runtimeWrapperPackage}/bin/hyperdoc-runtime-server";
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

      # Keep dreyeck's host wiring as reusable modules, not as a checked
      # nixosConfiguration. The live host owns activation in /etc/nixos, and
      # the repo-side dreyeck profile is historical rather than an activation
      # target. Exporting it under nixosConfigurations makes `nix flake check`
      # evaluate host-owned ACME/nginx assumptions that are intentionally not
      # present in this repo checkout.
    };
}
