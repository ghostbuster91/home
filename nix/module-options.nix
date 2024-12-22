{ pkgs, lib, ... }:
{
  options.uci = {
    settings = lib.mkOption {
      default = { };
      inherit (pkgs.formats.json { }) type;
    };
  };
}
