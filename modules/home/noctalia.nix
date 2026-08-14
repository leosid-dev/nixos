# modules/home/noctalia.nix — Noctalia v5 shell (HM-level) with extra status/prompt knobs.
{ config, lib, noctalia, pkgs, ... }:
let
  cfg = config.aspects.home.noctalia;
in
{
  options.aspects.home.noctalia = {
    enable = lib.mkEnableOption "Noctalia v5 shell";
    theme = {
      mode = lib.mkOption {
        type = lib.types.enum [ "dark" "light" ];
        default = "dark";
      };
    };

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

    startup = {
      shortcuts = lib.mkOption {
        type = lib.types.listOf (lib.types.attrsOf lib.types.any);
        default = [ { key = "Mod+Enter"; command = "kitty"; description = "Terminal"; } ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    imports = [ noctalia.homeModules.default ];

    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      settings.theme.mode = cfg.theme.mode;
      # Map accent from global aspects.theme.accent (single source of truth)
      settings.theme.accent = config.aspects.theme.accent;
      settings.prompt.style = cfg.prompt.style;
    };

    # Simple status module wiring: enable widgets if the aspect says so.
    # Noctalia's module flags are illustrative; adapt if the upstream module
    # exposes different option names.
    programs.noctalia.settings.status = {
      clock = cfg.status.clock;
      battery = cfg.status.battery;
      network = cfg.status.network;
      media = cfg.status.media;
      workspaceIndicator = cfg.status.workspaceIndicator;
    };

    # Provide a small helper script that can be used to notify on theme changes.
    home.file."noctalia/theme-change-notify.sh".text = ''
#!/bin/sh
notify-send "Noctalia" "Theme changed to ${config.aspects.theme.accent}"
'';
    home.file."noctalia/theme-change-notify.sh".executable = true;

  };
}
