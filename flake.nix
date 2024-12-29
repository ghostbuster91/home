{
  description = "A free and open source 3D creation suite (upstream binaries)";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , systems
    , treefmt-nix
    , ...
    }:
    let
      # Small tool to iterate over each systems
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});

      # Eval the treefmt modules from ./treefmt.nix
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      esp = pkgs.callPackage ./nix { };
    in
    {
      # for `nix fmt`
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      # for `nix flake check`
      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });
      packages.${system} = {
        inherit (pkgs) esphome;
      };
      # `nix run .#example` will output generated configuration
      apps.${system}.example = {
        type = "app";
        program = toString (esp.compileEsphome ./example.nix).command;
      };
      devShells.${system} = {
        default = pkgs.mkShell {
          buildInputs = [
            pkgs.esphome
          ];
        };
      };
    };
}
