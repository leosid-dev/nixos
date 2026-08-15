# modules/home/terminal.nix — Kitty terminal emulator (HM-level).
#
# Generic Kitty configuration. Colors are derived from the central
# aspects.theme option tree (single source of truth — see theme.nix).
# Gated by aspects.home.terminal.enable.
{ config, lib, ... }:
let
  cfg = config.aspects.home.terminal;
  theme = config.aspects.theme;
  palette =
    if theme.mode == "dark" then
      {
        foreground = "#dedede";
        background = "#1e1e1e";
        cursor = "#8ab4f8";
      }
    else
      {
        foreground = "#303030";
        background = "#fafafa";
        cursor = "#1a73e8";
      };
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

        background_opacity = "0.95";
        confirm_os_window_close = 0;
        enable_audio_bell = false;

        foreground = palette.foreground;
        background = palette.background;
        selection_foreground = palette.background;
        selection_background = palette.cursor;
        cursor = palette.cursor;
        cursor_text_color = palette.background;
      };
    };
  };
}
