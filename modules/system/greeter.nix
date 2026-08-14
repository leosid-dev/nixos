# modules/system/greeter.nix — Wrapper for noctalia-greeter exposing aspects.greeter
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.greeter;
in
{
  options.aspects.greeter = {
    enable = lib.mkEnableOption "Noctalia greeter (system-level enable)";
    themeSync = lib.mkOption { type = lib.types.bool; default = true; };
    avatarPath = lib.mkOption { type = lib.types.str; default = "/var/lib/greeter/avatar.png"; };
    timeout = lib.mkOption { type = lib.types.int; default = 120; };
  };

  config = lib.mkIf cfg.enable {
    programs.noctalia-greeter = {
      enable = true;
      settings = {
        palette = {
          accent = (if cfg.themeSync then config.aspects.theme.accent else null);
        };
        avatar = cfg.avatarPath;
        timeout = cfg.timeout;
      };
    };
  };
}
