{
  description = "HyperDoc development environments and Catalog application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    html-inspector-views = {
      url = "git+https://codeberg.org/khinsen/html-inspector-views.git";
      flake = false;
    };

    workflow-source-editor = {
      url = "https://codeberg.org/rgb/html-inspector-views/archive/38afb02d79838d4098589c2e203ba39799a44853.tar.gz";
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
    workflow-source-editor,
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
  }@inputs:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
      runtimeFor = system: import ./nix/lisp-runtime.nix {
        pkgs = import nixpkgs { inherit system; };
        sources = inputs;
        commonLispHyperSpec = self.packages.${system}.common-lisp-hyperspec;
      };
    in {
      # Opt-in staging of hyperdoc-catalog-topic-maps on a NixOS host: loopback only, not enabled by default.
      nixosModules.hyperdoc-catalog-topic-maps-staging = ./nix/nixos-staging.nix;

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in {
          # The one production Catalog, with the pinned Topic Maps snapshot (nix/catalog.nix).
          hyperdoc-catalog = pkgs.callPackage ./nix/catalog.nix {
            runtime = runtimeFor system;
            source = pkgs.lib.cleanSource self.outPath;
            topicMaps = self.packages.${system}.topic-maps-source;
            d2-tala = self.packages.${system}.d2-tala;
            revision = self.rev or self.dirtyRev or "";
          };
          topic-maps-source = pkgs.callPackage ./nix/topic-maps-source.nix { };
          # Separate from hyperdoc-catalog: the Catalog with the pinned Topic Maps snapshot, loopback only.
          # Retired from production by hyperdoc-catalog itself (docs/one-catalog); kept only because the deployment review
          # reading quotes it, and to be removed with that reading.
          hyperdoc-catalog-topic-maps = pkgs.callPackage ./nix/catalog-topic-maps.nix {
            runtime = runtimeFor system;
            source = pkgs.lib.cleanSource self.outPath;
            topicMaps = self.packages.${system}.topic-maps-source;
            d2-tala = self.packages.${system}.d2-tala;
            revision = self.rev or self.dirtyRev or "";
          };
          d2-tala = pkgs.callPackage ./nix/d2-tala.nix { };
          common-lisp-hyperspec =
            pkgs.callPackage ./nix/common-lisp-hyperspec.nix { };
        }
      );

      apps = forAllSystems (system: {
        catalog = {
          type = "app";
          inherit (self.packages.${system}.hyperdoc-catalog) meta;
          program = "${self.packages.${system}.hyperdoc-catalog}/bin/hyperdoc-catalog";
        };
      });

      checks = forAllSystems (system: {
        common-lisp-hyperspec =
          self.packages.${system}.common-lisp-hyperspec;
        catalog = let pkgs = import nixpkgs { inherit system; }; in
          pkgs.callPackage ./nix/catalog-check.nix {
            catalog = self.packages.${system}.hyperdoc-catalog;
            runtime = runtimeFor system;
            source = pkgs.lib.cleanSource self.outPath;
            topicMaps = self.packages.${system}.topic-maps-source;
            revision = self.rev or self.dirtyRev or "";
          };
        catalog-topic-maps = let pkgs = import nixpkgs { inherit system; }; in
          pkgs.callPackage ./nix/catalog-topic-maps-check.nix {
            catalog = self.packages.${system}.hyperdoc-catalog-topic-maps;
            runtime = runtimeFor system;
            source = pkgs.lib.cleanSource self.outPath;
            topicMaps = self.packages.${system}.topic-maps-source;
            revision = self.rev or self.dirtyRev or "";
          };
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          runtime = runtimeFor system;
          inherit (runtime) sbcl;

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
                pkgs.python3
                sbcl
                hyperdocEmacs
              ];

              text =
                builtins.readFile
                  ./scripts/hyperdoc-sly.sh;
            };
        in {
          workflow-authoring = pkgs.mkShell {
            inputsFrom = [ self.devShells.${system}.default ];
            shellHook = ''
              export HYPERDOC_RUNTIME_SOURCE_REGISTRY="$CL_SOURCE_REGISTRY"
              export HYPERDOC_WORKFLOW_EDITOR_SOURCE="${workflow-source-editor}"
              export HYPERDOC_WORKFLOW_EDITOR_COMMIT="38afb02d79838d4098589c2e203ba39799a44853"
              export CL_SOURCE_REGISTRY="${workflow-source-editor}//:$CL_SOURCE_REGISTRY"
            '';
          };
          tala = pkgs.mkShell {
            inputsFrom = [ self.devShells.${system}.default ];
            packages = [ self.packages.${system}.d2-tala ];
          };
          default = pkgs.mkShell {
            packages = [
              self.packages.${system}.common-lisp-hyperspec
              pkgs.git
              sbcl
              hyperdocEmacs
              hyperdocSly
              self.packages.${system}.hyperdoc-catalog
            ];

            shellHook = ''
              export CL_SOURCE_REGISTRY="${runtime.sourceRegistry}:$PWD//"
              export HYPERDOC_HYPERSPEC_ROOT="${runtime.hyperspecRoot}"
            '';
          };
        }
      );
    };
}
