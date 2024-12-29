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
      yaml = (formats.yaml { }).generate "config.yaml" res.config.espConfig;
    in
    {
      command = writeShellScript "validate-esphome" ''
        ${lib.getExe pkgs.esphome} config "${yaml}"
      '';
    };
}
