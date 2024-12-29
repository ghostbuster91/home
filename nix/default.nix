{ formats
, lib
, writeShellScript
, pkgs
,
}:
{
  compileEsphome =
    configuration:
    let
      res = lib.evalModules {
        modules = [
          {
            _module.args = {
              inherit pkgs;
            };
          }
          ./module-options.nix
          configuration
        ];
      };
      generateCmd = config: (formats.yaml { }).generate "config.yaml" config;
    in
    lib.attrsets.mapAttrs
      (deviceId: config: {
        generate = generateCmd config;
      })
      res.config.espConfig;
}
