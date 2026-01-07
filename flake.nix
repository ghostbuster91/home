{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = [
        inputs.treefmt-nix.flakeModule
      ];
      perSystem = { system, config, pkgs, ... }:
        {
          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.esphome
              pkgs.clang-tools # daje clangd
              pkgs.gcc
              pkgs.gnumake
              pkgs.python3
            ];
            inputsFrom = [
              config.treefmt.build.devShell
            ];
          };

          treefmt.config = {
            projectRootFile = "flake.nix";

            programs = {
              nixpkgs-fmt.enable = true;
              # yamlls uses prettier under the hood but it might change https://github.com/redhat-developer/yaml-language-server/issues/933
              prettier.enable = true;
            };
          };
        };
    };
}

