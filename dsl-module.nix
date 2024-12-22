# dsl-module.nix
{ lib, config, ... }:

with lib;

{
  options = {
    appConfig = {
      name = mkOption {
        type = types.str;
        description = "The name of the application.";
      };
    };
    rendererdYaml = mkOption {
      type = types.anything;
      description = "render me";
    };
  };

}

