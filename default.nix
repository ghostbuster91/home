{ pkgs, lib, config, ... }:
let
  # pkgs = import <nixpkgs> {};
  result = lib.evalModules {
    modules = [
      ({ config, ... }: { config._module.args = { inherit pkgs; }; })
      ./dsl-module.nix
      ./appConfig.nix
      (_: {
        appConfig.name = "kasep";
      })
    ];
  };
in
result.config.appConfig
