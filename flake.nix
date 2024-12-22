{
  description = "A free and open source 3D creation suite (upstream binaries)";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs =
    { self
    , nixpkgs
    , flake-utils
    ,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      uci = pkgs.callPackage ./nix { };
    in
    {
      packages.${system} = {
        inherit (uci) nix-uci writeUci esphome;
      };
      # `nix run .#example` will output uci configuration
      apps.${system}.example = {
        type = "app";
        program = toString (self.packages.${system}.writeUci ./example.nix).command;
      };
      defaultPackage = self.packages.${system}.nix-uci;
      devShell = pkgs.mkShell {
        buildInputs = [
          pkgs.just
          pkgs.sops
          pkgs.esphome
        ];
      };
    };
}
