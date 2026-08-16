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
    opacity = lib.mkOption {
      type = lib.types.float;
      default = if theme.accent == "monochrome" then 1.0 else 0.95;
      defaultText = "1.0 for the monochrome accent, 0.95 otherwise";
      description = ''
        Kitty background opacity. Monochrome wants opaque true black;
        other accents float slightly by default.
      '';
    };
    fontSize = lib.mkOption {
      type = lib.types.int;
      default = theme.font.size;
      defaultText = lib.literalExpression "config.aspects.theme.font.size";
      description = "Terminal font size; follows the theme font by default.";
    };
    padding = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Window padding in pixels, applied to all four sides.";
    };
    scrollback = lib.mkOption {
      type = lib.types.int;
      default = 2000;
      description = "Scrollback buffer size in lines.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Canonical TERMINAL source (AGENTS.md rule 8); niri's terminal keybind
    # reads this instead of hardcoding a second reference.
    home.sessionVariables.TERMINAL = "kitty";

    programs.kitty = {
      enable = true;
      settings = {
        font_family = theme.font.monospace.name;
        font_size = toString cfg.fontSize;
        bold_font = "auto";
        italic_font = "auto";
        bold_italic_font = "auto";

        background_opacity = toString cfg.opacity;
        window_padding_width = toString cfg.padding;
        scrollback_lines = toString cfg.scrollback;
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
