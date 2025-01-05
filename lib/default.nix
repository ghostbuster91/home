{ pkgs, ... }: {
  components = pkgs.callPackage ./components.nix { };
  boneio-dr-8ch-03-4023d = pkgs.callPackage ./boneio-dr-8ch-03-4023d { };
}
