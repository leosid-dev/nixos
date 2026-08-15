# modules/home/noctalia.nix — Noctalia v5 shell (HM-level).
#
# The upstream HM module is imported unconditionally (imports must live at
# module top level); it stays inert until `programs.noctalia.enable` is set,
# which happens only when aspects.home.noctalia.enable is on.
#
# Visual design (keys verified against the upstream config schema):
# - Bar: macOS-style — full-width straight rectangle (radius 0, zero margins,
#   no shadow, no capsules); workspaces + running-app icons (taskbar) left,
#   clock center, resource stats / battery rate / performance-mode toggle /
#   system icons right. The app launcher floats at top-center of the screen.
# - Theme: monochrome custom palette anchored at true black (deep black on
#   LCD). The palette follows aspects.theme.accent (single source of truth).
{ config, lib, noctalia, ... }:
let
  cfg = config.aspects.home.noctalia;
  theme = config.aspects.theme;

  # Palette source selection keyed by the global accent.
  noctaliaTheme =
    if theme.accent == "monochrome" then
      {
        source = "custom";
        custom_palette = "monochrome";
      }
    else if theme.accent == "catppuccin-mocha" then
      {
        source = "builtin";
        builtin = "Catppuccin";
      }
    else
      {
        source = "builtin";
        builtin = "Noctalia";
      };

  # Monochrome palette in the Noctalia custom-palette format (Material
  # tokens + terminal section per mode). Surfaces are true black.
  monochromePalette = {
    dark = {
      primary = "#e6e6e6";
      onPrimary = "#000000";
      secondary = "#b3b3b3";
      onSecondary = "#000000";
      tertiary = "#8c8c8c";
      onTertiary = "#000000";
      error = "#e6e6e6";
      onError = "#000000";
      surface = "#000000";
      onSurface = "#e6e6e6";
      surfaceVariant = "#141414";
      onSurfaceVariant = "#a3a3a3";
      outline = "#3d3d3d";
      shadow = "#000000";
      hover = "#1f1f1f";
      onHover = "#e6e6e6";
      terminal = {
        foreground = "#e6e6e6";
        background = "#000000";
        cursor = "#e6e6e6";
        cursorText = "#000000";
        selectionFg = "#000000";
        selectionBg = "#a3a3a3";
        normal = {
          black = "#000000";
          red = "#8c8c8c";
          green = "#999999";
          yellow = "#a3a3a3";
          blue = "#adadad";
          magenta = "#b3b3b3";
          cyan = "#bdbdbd";
          white = "#e6e6e6";
        };
        bright = {
          black = "#3d3d3d";
          red = "#999999";
          green = "#a3a3a3";
          yellow = "#b3b3b3";
          blue = "#bdbdbd";
          magenta = "#c4c4c4";
          cyan = "#d6d6d6";
          white = "#f5f5f5";
        };
      };
    };
  };
in
{
  imports = [ noctalia.homeModules.default ];

  options.aspects.home.noctalia = {
    enable = lib.mkEnableOption "Noctalia v5 shell";

    theme.mode = lib.mkOption {
      type = lib.types.enum [ "dark" "light" ];
      default = "dark";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;

      # Installed to ~/.config/noctalia/palettes/monochrome.json; inert
      # unless the accent selects it.
      customPalettes.monochrome = monochromePalette;

      settings = {
        shell = {
          # Font follows aspects.theme.font (single source of truth).
          font_family = theme.font.name;
          panel = {
            borders = true;
            shadow = false; # flat, macOS-style panels
            # App launcher floats at the top-center of the screen.
            launcher_placement = "floating";
            launcher_position = "top_center";
          };
        };

        theme = noctaliaTheme // {
          mode = cfg.theme.mode;
          pure_black_dark = true; # keep dark surfaces at true black (LCD)
        };

        # Straight rectangle, flush with the screen edges, no capsules.
        bar.main = {
          position = "top";
          radius = 0;
          margin_ends = 0;
          margin_edge = 0;
          shadow = false;
          capsule = false;
          reserve_space = true;
          start = [
            "workspaces"
            "taskbar" # running-app indicators (icons only, see widget.taskbar)
          ];
          center = [ "clock" ];
          end = [
            "cpu" # seeded sysmon instances: resource stats
            "temp"
            "ram"
            "battery" # power consumption (rate in W, see widget.battery)
            "power_profile" # performance-mode toggle
            "network"
            "bluetooth"
            "volume"
            "brightness"
            "tray"
            "notifications"
            "control-center"
            "session"
          ];
        };

        widget.taskbar.show_window_title = false; # icon-only app indicators
        widget.battery = {
          show_label = true;
          label_content = "rate"; # charge/discharge rate in watts
        };
      };
    };
  };
}
