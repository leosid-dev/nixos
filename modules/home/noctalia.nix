# modules/home/noctalia.nix — Noctalia v5 shell (HM-level).
#
# Noctalia ships a Home Manager module; we wrap it with our own toggle so
# desktop users can disable the shell (e.g. terminal-only sessions).
{ config, lib, noctalia, ... }:
let
  cfg = config.aspects.home.noctalia;
in
{
  options.aspects.home.noctalia = {
    enable = lib.mkEnableOption "Noctalia v5 shell";
    theme.mode = lib.mkOption {
      type = lib.types.enum [ "dark" "light" ];
      default = "dark";
    };
  };

  config = lib.mkIf cfg.enable {
    imports = [ noctalia.homeModules.default ];

    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      settings.theme.mode = cfg.theme.mode;
    };
  };
}
