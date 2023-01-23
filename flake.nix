{
  description = "purescript-node-fs-temporary";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    purs-nix.url = "github:purs-nix/purs-nix";
    purs-nix.inputs.nixpkgs.follows = "nixpkgs";
    npmlock2nix.url = "github:nix-community/npmlock2nix";
    npmlock2nix.flake = false;
    treefmt-nix.url = "github:numtide/treefmt-nix";
    feedback.url = "github:norfairking/feedback";
  };

  outputs = inputs@{ self, flake-parts, treefmt-nix, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = [ "x86_64-linux" ];
      imports = [
        treefmt-nix.flakeModule
      ];
      perSystem = { config, self', inputs', system, pkgs, ... }:
        let
          npmlock2nix = import inputs.npmlock2nix { inherit pkgs; };
          # purescript
          purs-nix = inputs.purs-nix {
            inherit system;
            overlays = [
              (import ./purs-nix-overlay.nix npmlock2nix)
              (_: _: {
                node-fs-temporary = node-fs-temporary.package;
              })
            ];
          };

          node-fs-temporary = {
            dependencies = [
              "aff"
              "effect"
              "node-path"
              "node-fs"
              "node-fs-aff"
              "node-os"
              "prelude"
              "random"
            ];

            test-dependencies = [
              "spec"
            ];

            package = purs-nix.build {
              name = "node-fs-temporary";
              src.path = ./.;
              info = {
                version = "0.0.1";
                inherit (node-fs-temporary) dependencies test-dependencies;
              };
            };
            ps = purs-nix.purs {
              dir = ./.;
              inherit (node-fs-temporary) dependencies test-dependencies;
            };
          };
        in
        {
          devShells = {
            default = pkgs.mkShell {
              name = "default";
              buildInputs = (with pkgs; [
                nodejs-16_x
                (node-fs-temporary.ps.command { })
                purs-nix.purescript
                pkgs.nodePackages.purescript-language-server
                inputs'.feedback.packages.default
              ]);
            };
          };

          packages.node-fs-temporary = node-fs-temporary.package;

          checks = {
            node-fs-temporary-compile-check =
              pkgs.runCommand "node-fs-temporary-compile-check"
                { buildInputs = [ (node-fs-temporary.ps.command { output = "$out"; }) ]; }
                ''
                  set -euo pipefail
                  mkdir $out
                  cp -r ${node-fs-temporary.package} src
                  purs-nix compile 2>&1 | tee $out/build.log
                '';
            node-fs-temporary = node-fs-temporary.ps.test.check { };
          };

          treefmt = {
            projectRootFile = ".git/config";
            programs.nixpkgs-fmt.enable = true;
            programs.purs-tidy.enable = true;
          };
        };
    };
}
