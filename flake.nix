{
  description = "A free and open source 3D creation suite (upstream binaries)";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
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
        let
          pkgs = nixpkgs.legacyPackages.${system};
          esp = pkgs.callPackage ./nix { };
          inherit ((esp.compileEsphome ./config.nix)) dimmer1;
        in
        {
          devShells.default = pkgs.mkShell {
            packages = [ pkgs.esphome ];
            inputsFrom = [
              config.treefmt.build.devShell
            ];
          };

          packages = {
            inherit (pkgs) esphome;
            dimmer1 = dimmer1.generate;
          };
          # `nix run .#example` will output generated configuration
          apps.example = {
            type = "app";
            program = toString dimmer1.validate;
          };

          treefmt.config = {
            projectRootFile = "flake.nix";

            programs = {
              nixpkgs-fmt.enable = true;
            };
          };
        };
    };
}
