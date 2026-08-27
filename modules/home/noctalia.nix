# modules/home/noctalia.nix — Noctalia v5 shell (HM-level).
#
# The upstream HM module is imported unconditionally (imports must live at
# module top level); it stays inert until `programs.noctalia.enable` is set,
# which happens only when aspects.home.noctalia.enable is on.
#
# Visual design (keys verified against the upstream config schema):
# - Bar: macOS-style menu bar. Left: workspace pills + taskbar.
#   Center: clock, notifications, privacy.
#   Right: telemetry capsule (cpu_temp + ram_pct; + cpu_power when
#   aspects.home.noctalia.cpuPower.enable — membership owned here, plugin
#   deploy in noctalia-cpu-power.nix) -> spacer -> network, bluetooth,
#   volume, battery, tray, session. Capsule members render at 0.9x bar
#   scale and share one left-click (Control Center System).
#   Launcher remains keyboard-driven. Privacy sits in center after notifications.
# - Theme: custom palette derived from aspects.theme.palette.noctalia
#   (single source of truth via aspects.theme.accent). Mode follows
#   aspects.theme.mode directly. No duplication: only the selected accent's
#   dark+light palette is emitted, bound to theme.custom_palette.
# - Only settings that deviate from upstream defaults are declared here.
#   Display density (aspects.home.noctalia.uiScale) is host policy, not
#   shell intent, so it is an option with the inert upstream default.
{
  config,
  lib,
  noctalia,
  ...
}:
let
  cfg = config.aspects.home.noctalia;
  theme = config.aspects.theme;

  # Telemetry capsule presentation: members render denser than the rest of
  # the bar (content scale relative to bar.main.scale). Applies to every
  # sysmon capsule member, including the plugin member when cpuPower is on.
  sysmonCapsuleScale = 0.9;
in
{
  imports = [ noctalia.homeModules.default ];

  options.aspects.home.noctalia = {
    enable = lib.mkEnableOption "Noctalia v5 shell";

    uiScale = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = ''
        UI scale multiplier, applied to accessibility.ui_scale and mirrored
        to bar.main.scale. Display-density policy owned by the host (e.g.
        1.15 on a 16" 1920x1200 panel running the compositor at scale 1.0).
        1.0 is the upstream default.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # The upstream unit binds After/PartOf/WantedBy to wayland.systemd.target.
    # Point it at niri.service (started by Niri's built-in systemd activation)
    # instead of graphical-session.target: the latter waits for
    # xdg-desktop-autostart.target, whose portal probing can delay shell
    # startup by tens of seconds. niri.service comes up as soon as the
    # compositor is ready.
    wayland.systemd.target = "niri.service";

    programs.noctalia = {
      enable = true;
      systemd.enable = true;

      # Single source of truth: emit the selected accent as a custom palette.
      # The palette data comes from aspects.theme.palette.noctalia (derived
      # from lib/palettes.nix), so adding a new accent only touches
      # lib/palettes.nix + theme.nix — no duplication here.
      customPalettes.${theme.accent} = {
        dark = theme.palette.noctalia.dark;
        light = theme.palette.noctalia.light;
      };

      settings = {
        accessibility.ui_scale = cfg.uiScale;

        shell = {
          # Font follows aspects.theme.font (single source of truth).
          font_family = theme.font.name;
          clipboard_enabled = false;
          offline_mode = true;

          # Noctalia's native polkit auth agent owns privilege prompts
          # (virt-manager, NetworkManager, package managers), theme-matched
          # and placed per shell.panel.polkit_placement.
          polkit_agent = true;
          panel = {
            borders = false; # outline on floating panel surfaces
            shadow = false; # cast the global [shell.shadow] from panel surfaces
            launcher_placement = "attached"; # attached | floating
            clipboard_placement = "attached"; # attached | floating
            session_placement = "floating"; # attached | floating
            open_near_click_control_center = true; # follow the bar click instead of bar-center
          };
          launcher = {
            categories = false;
            fetch_exchange_rates = false;
          };
          animation.speed = 1.25;
        };

        hot_corners.enabled = false;
        theme = {
          source = "custom";
          custom_palette = theme.accent;
          mode = theme.mode;
          pure_black_dark = true; # keep dark surfaces at true black (LCD)
        };

        # macOS-style bar: flat, flush, three lanes.
        # Left: workspaces + taskbar. Center: clock + notifications + privacy.
        # Right: group:sysmon -> spacer -> network, bluetooth, volume, battery,
        # tray, session. This module is the sole capsule_group writer: when
        # aspects.home.noctalia.cpuPower.enable is on, local/cpu-power:cpu_power
        # is prepended (plugin deploy lives in noctalia-cpu-power.nix).
        # Capsule left-click opens Control Center System (upstream sysmon
        # default; plugin declares the same via plugin.toml [widget.actions]).
        # Bar widgets inherit shell.font_family; no bar-level font needed.
        bar.main = {
          scale = cfg.uiScale;
          padding = 12;
          widget_spacing = 16;
          radius = 0;
          margin_ends = 0;
          margin_edge = 0;
          shadow = false;

          start = [
            "workspaces"
            "spacer"
            "taskbar"
          ];
          center = [
            "clock"
            "notifications"
            "privacy"
          ];
          end = [
            "group:sysmon"
            "spacer"
            "network"
            "bluetooth"
            "volume"
            "battery"
            "tray"
            "session"
          ];
          capsule_group = [
            {
              id = "sysmon";
              members = lib.optionals cfg.cpuPower.enable [ "local/cpu-power:cpu_power" ] ++ [
                "cpu_temp"
                "ram_used"
              ];
            }
          ];
        };

        control_center = {
          sidebar = "none";
          sidebar_section = "none";
          show_shortcut_labels = false;
        };

        # Telemetry capsule members share one presentation: content at
        # sysmonCapsuleScale, and one left-click action across the capsule
        # (sysmon type default; the plugin member declares the same via
        # plugin.toml [widget.actions] — capsule-level actions do not exist
        # upstream). The plugin member gets its scale only when cpuPower is
        # on, mirroring the capsule membership above.
        widget = {
          workspaces = {
            style = "minimal";
            show_labels = true;
            focused_color = "primary";
            occupied_color = "secondary";
            empty_color = "surface_variant";
          };
          taskbar = {
            icon_scale = cfg.uiScale;
            item_spacing = 8;
            group_by_workspace = false;
            show_all_outputs = true;
            only_active_workspace = false;
            show_workspace_label = false;
            hide_empty_workspaces = true;
            show_active_indicator = true;
            active_indicator_color = "primary";
            active_opacity = 1.0;
            inactive_opacity = 0.7;
            focused_color = "primary";
            occupied_color = "secondary";
            empty_color = "secondary";
            urgent_color = "error";
          };
          clock = {
            format = "{:%a %b %d  %H:%M}";
            tooltip_format = "{:%A, %B %d, %Y}";
          };
          tray = {
            hide_passive = true;
            drawer = true;
          };
          privacy = {
            hide_inactive = true;
          };
          network = {
            scale = cfg.uiScale;
            show_label = false;
            vpn_status = "replace";
          };
          bluetooth = {
            show_label = false;
            hide_when_no_connected_device = false;
          };
          volume = {
            show_label = false;
          };
          battery = {
            scale = cfg.uiScale;
            display_mode = "glyph";
            show_label = false;
            label_content = "rate";
            hide_when_full = false;
            hide_when_plugged = false;
          };
          notifications = {
            hide_when_no_unread = false;
          };
          spacer = {
            type = "spacer";
            length = 32;
          };
          spacer_64 = {
            type = "spacer";
            length = 64;
          };
          cpu_temp = {
            type = "sysmon";
            stat = "cpu_temp";
            visualization = "none";
            show_value = true;
            show_glyph = true;
            label_show_units = true;
            scale = sysmonCapsuleScale;
          };
          ram_used = {
            type = "sysmon";
            stat = "ram_used";
            visualization = "none";
            show_value = true;
            show_glyph = false;
            label_show_units = true;
            scale = sysmonCapsuleScale;
          };
        }
        // lib.optionalAttrs cfg.cpuPower.enable {
          "local/cpu-power:cpu_power" = {
            scale = sysmonCapsuleScale;
          };
        };
      };
    };
  };
}
