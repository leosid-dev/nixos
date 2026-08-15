# modules/home/terminal.nix — Kitty terminal emulator (HM-level).
#
# Generic Kitty configuration. Colors come from a small palette keyed by
# aspects.theme.accent (single source of truth — see theme.nix).
# Gated by aspects.home.terminal.enable.
{ config, lib, ... }:
let
  cfg = config.aspects.home.terminal;
  theme = config.aspects.theme;

  # Palettes keyed by accent; unknown accents fall back to the neutral dark.
  palettes = {
    monochrome = {
      foreground = "#e6e6e6";
      background = "#000000"; # true black (deep on LCD)
      cursor = "#e6e6e6";
      selection = "#a3a3a3";
    };
    catppuccin-mocha = {
      foreground = "#cdd6f4";
      background = "#1e1e2e";
      cursor = "#f5e0dc";
      selection = "#f5e0dc";
    };
    adwaita = {
      foreground = "#f2f2f2";
      background = "#1e1e1e";
      cursor = "#ffffff";
      selection = "#3584e4";
    };
  };
  palette = palettes.${theme.accent} or palettes.adwaita;
in
{
  options.aspects.home.terminal = {
    enable = lib.mkEnableOption "Kitty terminal emulator";
  };

  config = lib.mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      settings = {
        font_family = theme.font.name;
        font_size = toString theme.font.size;
        bold_font = "auto";
        italic_font = "auto";
        bold_italic_font = "auto";

        # Monochrome wants opaque true black; other palettes may float.
        background_opacity = if theme.accent == "monochrome" then "1.0" else "0.95";
        confirm_os_window_close = 0;
        enable_audio_bell = false;

        foreground = palette.foreground;
        background = palette.background;
        selection_foreground = palette.background;
        selection_background = palette.selection;
        cursor = palette.cursor;
        cursor_text_color = palette.background;
      };
    };
  };
}
