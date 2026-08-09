# modules/home/terminal.nix — Kitty terminal emulator (HM-level).
#
# Generic Kitty configuration. Colors are derived from the central
# aspects.theme option tree (single source of truth — see theme.nix).
# Gated by aspects.home.terminal.enable.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.home.terminal;
  theme = config.aspects.theme;
in
{
  options.aspects.home.terminal = {
    enable = lib.mkEnableOption "Kitty terminal emulator";
  };

  config = lib.mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      settings = {
        font_family = "JetBrains Mono";
        font_size = "11.0";
        bold_font = "auto";
        italic_font = "auto";
        bold_italic_font = "auto";

        background_opacity = "0.95";
        confirm_os_window_close = 0;
        enable_audio_bell = false;

        # Accent: catppuccin-mocha when selected, else Adwaita-neutral.
        # (Kept inline for now; a richer palette lib can replace this.)
        foreground = if theme.accent == "catppuccin-mocha" then "#cdd6f4" else "#cdd6f4";
        background = if theme.accent == "catppuccin-mocha" then "#1e1e2e" else "#1e1e2e";
        selection_foreground = "#1e1e2e";
        selection_background = "#f5e0dc";
        cursor = "#f5e0dc";
        cursor_text_color = "#1e1e2e";
      };
    };
  };
}
