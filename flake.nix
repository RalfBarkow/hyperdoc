{
  description = "HyperDoc development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    html-inspector-views = {
      url = "git+https://codeberg.org/khinsen/html-inspector-views.git";
      flake = false;
    };

    plump-inspector-views = {
      url = "git+https://codeberg.org/khinsen/plump-inspector-views.git";
      flake = false;
    };

    clog-moldable-inspector = {
      url = "git+https://codeberg.org/khinsen/clog-moldable-inspector.git";
      flake = false;
    };

    lwcells = {
      url = "github:kchanqvq/lwcells";
      flake = false;
    };

    named-closure = {
      url = "github:BlueFlo0d/named-closure";
      flake = false;
    };

    njson = {
      url = "github:atlas-engineer/njson";
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

  outputs = {
    self,
    nixpkgs,
    html-inspector-views,
    plump-inspector-views,
    clog-moldable-inspector,
    lwcells,
    named-closure,
    njson,
    shop3,
    shop3-pddl-tools,
    shop3-fiveam-asdf,
    shop3-random-state,
    shop3-documentation-utils,
    shop3-trivial-indent,
    shop3-trivial-garbage,
    shop3-iterate,
    ...
  }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in {
          common-lisp-hyperspec =
            pkgs.callPackage ./nix/common-lisp-hyperspec.nix { };
        }
      );

      checks = forAllSystems (system: {
        common-lisp-hyperspec =
          self.packages.${system}.common-lisp-hyperspec;
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          commonLispHyperSpec =
            self.packages.${system}.common-lisp-hyperspec;

          sbcl = pkgs.sbcl.withPackages (
            ps:
            with ps; [
              alexandria
              ps.arrow-macros
              babel
              bordeaux-threads
              cffi
              ps."cl-base32"
              ps."cl-base64"
              ps."cl-slug"
              ps."clack-handler-hunchentoot"
              ps."clog-ace"
              cl-who
              clog
              ps."closer-mop"
              dissect
              ps."damn-fast-stable-priority-queue"
              drakma
              ps."eclector-concrete-syntax-tree"
              flexi-streams
              fset
              ps."local-time"
              lquery
              iterate
              jzon
              plump
              puri
              ps."s-graphviz"
              serapeum
              sha1
              shasht
              str
              swank
              ps."trivial-clipboard"
              ps."trivial-cltl2"
              ps."trivial-package-local-nicknames"
              usocket
              ps._3bmd
              ps._3bmd-ext-code-blocks
            ]
          );

          emacsPackages =
            pkgs.emacsPackagesFor pkgs.emacs;

          hyperdocEmacs =
            emacsPackages.emacsWithPackages (
              epkgs: [
                epkgs.sly
              ]
            );

          hyperdocSly =
            pkgs.writeShellApplication {
              name = "hyperdoc-sly";

              runtimeInputs = [
                pkgs.git
                sbcl
                hyperdocEmacs
              ];

              text =
                builtins.readFile
                  ./scripts/hyperdoc-sly.sh;
            };
        in {
          default = pkgs.mkShell {
            packages = [
              commonLispHyperSpec
              pkgs.git
              sbcl
              hyperdocEmacs
              hyperdocSly
            ];

            shellHook = ''
              export CL_SOURCE_REGISTRY="${clog-moldable-inspector}//:${html-inspector-views}//:${plump-inspector-views}//:${lwcells}//:${named-closure}//:${njson}//:${shop3}/shop3//:${shop3-pddl-tools}//:${shop3-fiveam-asdf}//:${shop3-random-state}//:${shop3-documentation-utils}//:${shop3-trivial-indent}//:${shop3-trivial-garbage}//:${shop3-iterate}//:$PWD//"
              export HYPERDOC_HYPERSPEC_ROOT="${commonLispHyperSpec}/share/common-lisp-hyperspec/HyperSpec"
            '';
          };
        }
      );
    };
}
