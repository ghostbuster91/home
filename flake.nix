{
  description = "A free and open source 3D creation suite (upstream binaries)";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs =
    { self
    , nixpkgs
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      esp = pkgs.callPackage ./nix { };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      packages.${system} = {
        inherit (pkgs) esphome;
      };
      # `nix run .#example` will output uci configuration
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
