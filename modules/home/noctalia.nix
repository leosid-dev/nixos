# modules/home/noctalia.nix — Noctalia v5 shell (HM-level).
#
# The upstream HM module is imported unconditionally (imports must live at
# module top level); it stays inert until `programs.noctalia.enable` is set,
# which happens only when aspects.home.noctalia.enable is on.
#
# Visual design (keys verified against the upstream config schema):
# - Bar: macOS-style menu bar. Left: workspace pills + active app name/title.
#   Center: date and time. Right: dynamic status menus (media, tray, privacy,
#   network, bluetooth, volume, battery), control center, notification center.
#   Launcher remains keyboard-driven.
# - Theme: custom monochrome palette (m* Material schema) anchored at true
#   black (LCD), with full dark and light variants from lib/palettes.nix.
#   Mode follows aspects.theme.mode directly.
{
  config,
  lib,
  noctalia,
  ...
}:
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
  # from lib/palettes.nix. mHover/mOnHover are omitted on purpose: the runtime
  # hardcodes hover = tertiary (mapGeneratedPaletteMode), so shipping them
  # would be dead configuration.
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
        accessibility = {
          ui_scale = 1.15;
        };

        shell = {
          # Font follows aspects.theme.font (single source of truth).
          font_family = theme.font.name;
          # Noctalia's native polkit auth agent owns privilege prompts
          # (virt-manager, NetworkManager, package managers), theme-matched
          # and placed per shell.panel.polkit_placement.
          polkit_agent = true;
          panel = {
            transparency_mode = "solid"; # solid | soft | glass; controls floating panel opacity and card translucency
            borders = false; # outline on floating panel surfaces
            shadow = false; # cast the global [shell.shadow] from panel surfaces
            list_item_background = false; # filled rounded background behind launcher and clipboard list items
            floating_layer = "overlay"; # overlay | top; applies to floating interactive panels
            launcher_placement = "attached"; # attached | floating
            clipboard_placement = "attached"; # attached | floating
            control_center_placement = "attached"; # attached | floating
            wallpaper_placement = "attached"; # attached | floating
            session_placement = "floating"; # attached | floating
            polkit_placement = "floating"; # attached | floating
            #launcher_position = "center"; # auto | center | top_left | … (floating only)
            #clipboard_position = "auto"; # auto | center | top_left | … (floating only)
            polkit_position = "center"; # auto | center | top_left | … (floating only)
            floating_offset = 8; # px gap between a floating panel and the bar edge
            open_near_click_control_center = true; # attached/floating: follow the bar click instead of bar-center
            open_near_click_launcher = false; # attached/floating: follow the bar click instead of bar-center
            open_near_click_clipboard = false; # attached/floating: follow the bar click instead of bar-center
            open_near_click_wallpaper = false; # attached/floating: follow the bar click instead of bar-center
            open_near_click_session = false; # attached/floating: follow the bar click instead of bar-center
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

        # macOS-style bar: flat, flush, three lanes replicating macOS HIG.
        bar.main = {
          position = "top";
          thickness = 34;
          scale = 1.15;
          padding = 12;
          widget_spacing = 14;
          radius = 0;
          margin_ends = 0;
          margin_edge = 0;
          background_opacity = 1.0;
          border_width = 0;
          shadow = false;
          capsule = false;
          reserve_space = true;
          font_weight = 500;
          font_family = theme.font.name;

          start = [
            "workspaces"
            "active_window"
          ];
          center = [ "clock" ];
          end = [
            "media"
            "tray"
            "privacy"
            "network"
            "bluetooth"
            "volume"
            "battery"
            "control-center"
            "notifications"
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
          sidebar = "none";
          sidebar_section = "none";
          show_shortcut_labels = false;
        };

        widget.workspaces = {
          style = "minimal";
          show_labels = false;
          focused_color = "primary";
          occupied_color = "secondary";
          empty_color = "surface_variant";
        };
        widget.active_window = {
          display = "icon_and_text";
          title_scroll = "on_hover";
          max_length = 300.0;
          show_empty_label = false;
        };
        widget.clock = {
          format = "{:%a %b %d  %H:%M}";
          tooltip_format = "{:%A, %B %d, %Y}";
        };
        widget.media = {
          hide_when_no_media = true;
          album_art_only = false;
          hide_album_art = false;
          hide_artist = false;
          art_size = 18.0;
          max_length = 180.0;
          title_scroll = "on_hover";
        };
        widget.tray = {
          hide_passive = true;
          drawer = true;
        };
        widget.privacy = {
          hide_inactive = true;
        };
        widget.network = {
          scale = 1.1;
          show_label = false;
          vpn_status = "replace";
        };
        widget.bluetooth = {
          show_label = false;
          hide_when_no_connected_device = true;
        };
        widget.volume = {
          show_label = false;
        };
        widget.battery = {
          scale = 1.1;
          display_mode = "glyph";
          show_label = false;
          label_content = "rate";
          hide_when_full = false;
          hide_when_plugged = false;
        };
        widget.control-center = {
          glyph = "adjustments-horizontal";
        };
        widget.notifications = {
          hide_when_no_unread = false;
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
