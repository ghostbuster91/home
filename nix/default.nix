{ formats
, lib
, writeShellScript
, pkgs
,
}:
let
  nix-uci = pkgs.python3.pkgs.callPackage ./nix-uci.nix { };
in
{
  writeUci =
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
      yaml = (formats.yaml { }).generate "uci.yaml" res.config.uci;
    in
    {
      json = yaml;
      command = writeShellScript "uci-commands" ''
        ${lib.getExe pkgs.esphome} compile "${yaml}"
      '';
    };
  inherit nix-uci;
}
