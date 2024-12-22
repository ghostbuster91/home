{ pkgs, lib, ... }:
{
  options.uci = lib.mkOption {
    default = { };
    inherit (pkgs.formats.json { }) type;
  };
}
