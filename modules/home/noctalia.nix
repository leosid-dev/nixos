# modules/home/noctalia.nix — Noctalia v5 shell (HM-level) with extra status/prompt knobs.
{ config, lib, noctalia, ... }:
let
  cfg = config.aspects.home.noctalia;
in
{
  imports = [ noctalia.homeModules.default ];

  options.aspects.home.noctalia = {
    enable = lib.mkEnableOption "Noctalia v5 shell";
    status = {
      clock = lib.mkOption { type = lib.types.bool; default = true; };
      battery = lib.mkOption { type = lib.types.bool; default = true; };
      network = lib.mkOption { type = lib.types.bool; default = true; };
      media = lib.mkOption { type = lib.types.bool; default = true; };
      workspaceIndicator = lib.mkOption { type = lib.types.bool; default = true; };
    };

    prompt = {
      style = lib.mkOption { type = lib.types.enum [ "minimal" "informative" ]; default = "informative"; };
    };

  };

  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      settings = {
        # Theme mode and accent are shared with the rest of the HM profile.
        theme = {
          mode = config.aspects.theme.mode;
          accent = config.aspects.theme.accent;
        };
        prompt.style = cfg.prompt.style;
        status = {
          clock = cfg.status.clock;
          battery = cfg.status.battery;
          network = cfg.status.network;
          media = cfg.status.media;
          workspaceIndicator = cfg.status.workspaceIndicator;
        };
      };
    };
  };
}
