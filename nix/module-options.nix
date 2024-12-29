{ pkgs, lib, ... }:
{
  options.espConfig = lib.mkOption {
    default = { };
    inherit (pkgs.formats.yaml { }) type;
  };
}
