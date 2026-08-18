# modules/home/noctalia.nix — Noctalia v5 shell (HM-level).
#
# The upstream HM module is imported unconditionally (imports must live at
# module top level); it stays inert until `programs.noctalia.enable` is set,
# which happens only when aspects.home.noctalia.enable is on.
#
# Visual design (keys verified against the upstream config schema):
# - Bar: macOS-style full-width rectangle with grouped capsules inside;
#   unlabeled workspace pills + running-app icons left, date center, and one
#   compact system-status capsule right. Launcher remains keyboard-driven.
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
          animation = {
            enabled = true;
            speed = 1.25;
          };
        };

        theme = noctaliaTheme // {
          mode = theme.mode;
          pure_black_dark = true; # keep dark surfaces at true black (LCD)
        };

        # The bar stays square and flush; capsules only group its contents.
        bar.main = {
          position = "top";
          thickness = 32;
          padding = 12;
          widget_spacing = 8;
          radius = 0;
          margin_ends = 0;
          margin_edge = 0;
          background_opacity = 1.0;
          border_width = 0;
          shadow = false;
          capsule = false;
          reserve_space = true;
          start = [ "group:desktop" ];
          center = [ "clock" ];
          end = [ "group:status" ];
          capsule_group = [
            {
              id = "desktop";
              members = [
                "workspaces"
                "taskbar"
              ];
              fill = "surface_variant";
              padding = 6.0;
              opacity = 0.9;
              widget_spacing = 6;
              enabled = true;
            }
            {
              id = "status";
              members = [
                "system_monitor"
                "power_profile"
                "battery"
                "session"
              ];
              fill = "surface_variant";
              padding = 6.0;
              opacity = 0.9;
              widget_spacing = 8;
              enabled = true;
            }
          ];
        };

        system.monitor = {
          enabled = true;
          cpu_poll_seconds = 2.0;
          gpu_poll_seconds = 5.0;
          memory_poll_seconds = 2.0;
          network_poll_seconds = 3.0;
          disk_poll_seconds = 10.0;
        };

        control_center = {
          sidebar = "compact";
          sidebar_section = "compact";
          show_shortcut_labels = false;
        };

        widget.workspaces = {
          style = "regular";
          show_labels = false;
          focused_color = "primary";
          occupied_color = "secondary";
          empty_color = "surface_variant";
        };
        widget.taskbar = {
          show_window_title = false;
          item_spacing = 6;
          icon_scale = 0.95;
          show_active_indicator = true;
          group_single_icon_per_app = true;
        };
        widget.clock = {
          format = "{:%a, %d %b}";
          tooltip_format = "{:%A, %B %d, %Y - %H:%M}";
        };
        widget.system_monitor = {
          type = "sysmon";
          stat = "cpu_usage";
          visualization = "none";
          show_value = false;
          show_glyph = true;
          actions.left = "panel-toggle control-center system";
        };
        widget.battery = {
          display_mode = "glyph";
          show_label = false;
        };
      };
    };

    # The graphical-session target waits for desktop portals, which can spend
    # tens of seconds probing backends. Start the shell as soon as Niri is up.
    systemd.user.services.noctalia = {
      Unit = {
        After = lib.mkForce [ "niri.service" ];
        PartOf = lib.mkForce [ "niri.service" ];
      };
      Install.WantedBy = lib.mkForce [ "niri.service" ];
    };
  };
}
