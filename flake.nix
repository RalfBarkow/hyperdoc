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
  };

  outputs = {
    nixpkgs,
    html-inspector-views,
    plump-inspector-views,
    clog-moldable-inspector,
    lwcells,
    named-closure,
    njson,
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
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          sbcl = pkgs.sbcl.withPackages (ps: with ps; [
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
          ]);
        in {
          default = pkgs.mkShell {
            packages = [ pkgs.git sbcl ];
            shellHook = ''
              export CL_SOURCE_REGISTRY="${clog-moldable-inspector}//:${html-inspector-views}//:${plump-inspector-views}//:${lwcells}//:${named-closure}//:${njson}//:$PWD//"
            '';
          };
        });
    };
}
