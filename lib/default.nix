{ pkgs, ... }: {
  components = pkgs.callPackage ./components.nix { };
  boneio-dr-8ch = pkgs.callPackage ./boneio-dr-8ch { };
  helpers = pkgs.callPackage ./helpers.nix { };
}
