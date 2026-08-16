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
# - Theme: custom monochrome palette (m* Material schema) anchored at true
#   black (LCD), with full dark and light variants from lib/palettes.nix.
#   Mode follows aspects.theme.mode directly.
{ config, lib, noctalia, ... }:
let
  cfg = config.aspects.home.noctalia;
  theme = config.aspects.theme;
  palettes = import ../../lib/palettes.nix;

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

  # Extract Noctalia v5 custom palette schema (m* Material roles + terminal)
  extractNoctalia = p: {
    inherit (p)
      mPrimary
      mOnPrimary
      mSecondary
      mOnSecondary
      mTertiary
      mOnTertiary
      mError
      mOnError
      mSurface
      mOnSurface
      mSurfaceVariant
      mOnSurfaceVariant
      mOutline
      mShadow
      mHover
      mOnHover
      terminal
      ;
  };

  monochromePalette = {
    dark = extractNoctalia palettes.monochrome.dark;
    light = extractNoctalia palettes.monochrome.light;
  };
in
{
  imports = [ noctalia.homeModules.default ];

  options.aspects.home.noctalia = {
    enable = lib.mkEnableOption "Noctalia v5 shell";
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
          # Noctalia's native polkit auth agent owns privilege prompts
          # (virt-manager, NetworkManager, package managers), theme-matched
          # and placed per shell.panel.polkit_placement.
          polkit_agent = true;
          panel = {
            borders = true;
            shadow = false; # flat, macOS-style panels
            # App launcher floats at the top-center of the screen.
            launcher_placement = "floating";
            launcher_position = "top_center";
          };
        };

        theme = noctaliaTheme // {
          mode = theme.mode;
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
