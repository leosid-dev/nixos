# modules/home/terminal.nix — Kitty terminal emulator (HM-level).
#
# Generic Kitty configuration. All colors come from the canonical
# structured palette in aspects.theme.palette (single source of truth).
# Gated by aspects.home.terminal.enable.
{ config, lib, ... }:
let
  cfg = config.aspects.home.terminal;
  theme = config.aspects.theme;
  palette = theme.palette;
in
{
  options.aspects.home.terminal = {
    enable = lib.mkEnableOption "Kitty terminal emulator";
    opacity = lib.mkOption {
      type = lib.types.float;
      default = palette.opacity;
      defaultText = lib.literalExpression "config.aspects.theme.palette.opacity";
      description = ''
        Kitty background opacity. Follows the active theme palette default.
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

        foreground = palette.terminal.foreground;
        background = palette.terminal.background;
        selection_foreground = palette.terminal.selectionFg;
        selection_background = palette.terminal.selectionBg;
        cursor = palette.terminal.cursor;
        cursor_text_color = palette.terminal.cursorText;
      };
    };
  };
}
