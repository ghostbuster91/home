{
  description = "Generate YAML files with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    {
      packages.x86_64-linux =
        let
          inherit (nixpkgs) lib;
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        {
          toYAML = pkgs.runCommand "toYAML"
            {
              buildInputs = with pkgs; [ yj ];
              json = builtins.toJSON (pkgs.callPackage ./default.nix {});
              passAsFile = [ "json" ]; # will be available as `$jsonPath`
            } ''
            mkdir -p $out
            yj -jy < "$jsonPath" > $out/go.yaml
          '';
        };
    };

}
