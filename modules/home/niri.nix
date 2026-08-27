# modules/home/niri.nix — Niri compositor user configuration with aspect knobs.
#
# Mandatory for the desktop profile. Host-specific output details and the few
# visual tuning knobs remain configurable; input and bindings are explicit so
# the generated KDL is a complete, usable configuration.
{ config, lib, ... }:
let
  cfg = config.aspects.home.niri;
  theme = config.aspects.theme;
  palette = theme.palette;

  # One short ease-out shared by every animation keeps motion coherent without
  # delaying interaction.
  anim = "duration-ms ${toString cfg.animationDuration}\n"
    + "        curve \"cubic-bezier\" 0.34 ${toString (1.0 + cfg.overshoot)} 0.64 1";

  outputConfig = lib.optionalString (cfg.output.name != null) ''
    output "${cfg.output.name}" {
        ${lib.optionalString (cfg.output.mode != null) ''mode "${cfg.output.mode}"''}
        ${lib.optionalString (cfg.output.scale != null) ''scale ${toString cfg.output.scale}''}
    }
  '';
in
{
  options.aspects.home.niri = {
    output = {
      name = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Output connector name configured by the host.";
      };
      mode = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Output mode, including refresh rate when explicitly required.";
      };
      scale = lib.mkOption {
        type = lib.types.nullOr lib.types.float;
        default = null;
        description = "Logical output scale configured by the host.";
      };
    };
    gaps = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Gaps in pixels between windows and screen edges.";
    };
    cornerRadius = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Window corner radius applied to every window.";
    };
    animationDuration = lib.mkOption {
      type = lib.types.int;
      default = 170;
      description = "Duration in ms of the shared bezier animation easing.";
    };
    overshoot = lib.mkOption {
      type = lib.types.float;
      default = 0.2;
      description = ''
        Animation overshoot: the bezier control point y1 is 1 + overshoot,
        so animations slightly overshoot their target before settling.
        0 settles without overshoot.
      '';
    };
    centerFocused = lib.mkOption {
      type = lib.types.enum [ "never" "always" "on-overflow" ];
      default = "on-overflow";
      description = "Focus centering behavior for columns.";
    };
    terminalCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = config.home.sessionVariables.TERMINAL or null;
      defaultText = lib.literalExpression "config.home.sessionVariables.TERMINAL or null";
      description = ''
        Command spawned by the terminal keybind (Mod+Return). Defaults to
        the canonical TERMINAL session variable set by the terminal aspect
        (single source of truth — AGENTS.md rule 8); null (no terminal
        aspect enabled) omits the keybind.
      '';
    };
    noctaliaWindowSize = {
      width = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = ''
          Fixed column width for floating Noctalia shell windows (launcher,
          control center, settings). null allows Noctalia to manage its own size.
        '';
      };
      height = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = ''
          Fixed height for floating Noctalia shell windows (launcher,
          control center, settings). null allows Noctalia to manage its own size.
        '';
      };
    };
  };

  config = {
    xdg.configFile."niri/config.kdl".text = ''
${outputConfig}
input {
    keyboard {
        xkb {}
        repeat-delay 600
        repeat-rate 25
        track-layout "global"
    }

    touchpad {
        tap
        dwt
        drag true
        natural-scroll
        scroll-method "two-finger"
        click-method "clickfinger"
    }

    mouse {
        natural-scroll
        accel-profile "adaptive"
    }

    mod-key "Super"
}

prefer-no-csd
screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

cursor {
    xcursor-theme "${theme.cursor.name}"
    xcursor-size ${toString theme.cursor.size}
    hide-when-typing
    hide-after-inactive-ms 3000
}

hotkey-overlay {
    hide-not-bound
}

overview {
    backdrop-color "${palette.focus.background}"
    workspace-shadow {
        off
    }
}

xwayland-satellite {
    path "xwayland-satellite"
}

blur {
    off
}

layout {
    gaps ${toString cfg.gaps}
    center-focused-column "${cfg.centerFocused}"
    background-color "${palette.focus.background}"

    preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
    }
    default-column-width { proportion 0.5; }

    focus-ring {
        width 2
        active-color "${palette.focus.active}"
        inactive-color "${palette.focus.inactive}"
    }

    border {
        off
    }
    shadow {
        off
    }
}

animations {
    workspace-switch {
        ${anim}
    }
    horizontal-view-movement {
        ${anim}
    }
    window-movement {
        ${anim}
    }
    window-resize {
        ${anim}
    }
    window-open {
        ${anim}
    }
    window-close {
        ${anim}
    }
    overview-open-close {
        ${anim}
    }
    recent-windows-close {
        ${anim}
    }
}

window-rule {
    geometry-corner-radius ${toString cfg.cornerRadius}
    clip-to-geometry true
}

window-rule {
    match app-id="dev.noctalia.Noctalia"
    open-floating true
    ${lib.optionalString (cfg.noctaliaWindowSize.width != null)
      "default-column-width { fixed ${toString cfg.noctaliaWindowSize.width}; }"}
    ${lib.optionalString (cfg.noctaliaWindowSize.height != null)
      "default-window-height { fixed ${toString cfg.noctaliaWindowSize.height}; }"}
}

window-rule {
    match app-id=r#"firefox$"# title="^Picture-in-Picture$"
    open-floating true
}

debug {
    honor-xdg-activation-with-invalid-serial
}

    // Desktop-persona bindings live here deliberately: the desktop profile
    // always enables the Noctalia shell and Nautilus, and `wpctl` comes from
    // the system sound aspect. If any of those ever become persona-gated,
    // move the corresponding binds out of this module.
    binds {
    Mod+Shift+Slash { show-hotkey-overlay; }

    ${lib.optionalString (cfg.terminalCommand != null)
      ''Mod+Return hotkey-overlay-title="Open Terminal" { spawn "${cfg.terminalCommand}"; }''}
    Mod+E repeat=false hotkey-overlay-title="Open File Manager" { spawn "nautilus" "--new-window"; }
    Mod+O repeat=false { toggle-overview; }
    Mod+D repeat=false hotkey-overlay-title="Open Launcher" { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
    Mod+S repeat=false hotkey-overlay-title="Open Control Center" { spawn "noctalia" "msg" "panel-toggle" "control-center"; }
    Mod+Comma repeat=false hotkey-overlay-title="Open Settings" { spawn "noctalia" "msg" "settings-toggle"; }
    Alt+Tab repeat=false hotkey-overlay-title="Window Switcher" { spawn "noctalia" "msg" "window-switcher"; }
    Super+Alt+L repeat=false hotkey-overlay-title="Lock Screen" { spawn "noctalia" "msg" "session" "lock"; }
    Mod+Q repeat=false { close-window; }

    // Audio, media and display controls remain available while locked.
    XF86AudioRaiseVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-up"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-down"; }
    XF86AudioMute allow-when-locked=true { spawn "noctalia" "msg" "volume-mute"; }
    XF86AudioMicMute allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }
    XF86AudioPlay allow-when-locked=true { spawn "noctalia" "msg" "media" "play-pause"; }
    XF86AudioPause allow-when-locked=true { spawn "noctalia" "msg" "media" "play-pause"; }
    XF86AudioStop allow-when-locked=true { spawn "noctalia" "msg" "media" "stop"; }
    XF86AudioPrev allow-when-locked=true { spawn "noctalia" "msg" "media" "previous"; }
    XF86AudioNext allow-when-locked=true { spawn "noctalia" "msg" "media" "next"; }
    XF86MonBrightnessUp allow-when-locked=true { spawn "noctalia" "msg" "brightness-up"; }
    XF86MonBrightnessDown allow-when-locked=true { spawn "noctalia" "msg" "brightness-down"; }

    // Focus and movement.
    Mod+Left { focus-column-left; }
    Mod+Down { focus-window-down; }
    Mod+Up { focus-window-up; }
    Mod+Right { focus-column-right; }
    Mod+H { focus-column-left; }
    Mod+J { focus-window-down; }
    Mod+K { focus-window-up; }
    Mod+L { focus-column-right; }
    Mod+Ctrl+Left { move-column-left; }
    Mod+Ctrl+Down { move-window-down; }
    Mod+Ctrl+Up { move-window-up; }
    Mod+Ctrl+Right { move-column-right; }
    Mod+Ctrl+H { move-column-left; }
    Mod+Ctrl+J { move-window-down; }
    Mod+Ctrl+K { move-window-up; }
    Mod+Ctrl+L { move-column-right; }
    Mod+Home { focus-column-first; }
    Mod+End { focus-column-last; }
    Mod+Ctrl+Home { move-column-to-first; }
    Mod+Ctrl+End { move-column-to-last; }

    // Monitor navigation.
    Mod+Shift+Left { focus-monitor-left; }
    Mod+Shift+Down { focus-monitor-down; }
    Mod+Shift+Up { focus-monitor-up; }
    Mod+Shift+Right { focus-monitor-right; }
    Mod+Shift+H { focus-monitor-left; }
    Mod+Shift+J { focus-monitor-down; }
    Mod+Shift+K { focus-monitor-up; }
    Mod+Shift+L { focus-monitor-right; }
    Mod+Ctrl+Shift+Left { move-column-to-monitor-left; }
    Mod+Ctrl+Shift+Down { move-column-to-monitor-down; }
    Mod+Ctrl+Shift+Up { move-column-to-monitor-up; }
    Mod+Ctrl+Shift+Right { move-column-to-monitor-right; }
    Mod+Ctrl+Shift+H { move-column-to-monitor-left; }
    Mod+Ctrl+Shift+J { move-column-to-monitor-down; }
    Mod+Ctrl+Shift+K { move-column-to-monitor-up; }
    Mod+Ctrl+Shift+L { move-column-to-monitor-right; }

    // Workspace navigation.
    Mod+Page_Down { focus-workspace-down; }
    Mod+Page_Up { focus-workspace-up; }
    Mod+U { focus-workspace-down; }
    Mod+I { focus-workspace-up; }
    Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
    Mod+Ctrl+Page_Up { move-column-to-workspace-up; }
    Mod+Ctrl+U { move-column-to-workspace-down; }
    Mod+Ctrl+I { move-column-to-workspace-up; }
    Mod+Shift+Page_Down { move-workspace-down; }
    Mod+Shift+Page_Up { move-workspace-up; }
    Mod+Shift+U { move-workspace-down; }
    Mod+Shift+I { move-workspace-up; }
    Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
    Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
    Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
    Mod+Ctrl+WheelScrollUp cooldown-ms=150 { move-column-to-workspace-up; }
    Mod+WheelScrollRight { focus-column-right; }
    Mod+WheelScrollLeft { focus-column-left; }
    Mod+Ctrl+WheelScrollRight { move-column-right; }
    Mod+Ctrl+WheelScrollLeft { move-column-left; }
    Mod+Shift+WheelScrollDown { focus-column-right; }
    Mod+Shift+WheelScrollUp { focus-column-left; }
    Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
    Mod+Ctrl+Shift+WheelScrollUp { move-column-left; }

    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+4 { focus-workspace 4; }
    Mod+5 { focus-workspace 5; }
    Mod+6 { focus-workspace 6; }
    Mod+7 { focus-workspace 7; }
    Mod+8 { focus-workspace 8; }
    Mod+9 { focus-workspace 9; }
    Mod+Ctrl+1 { move-column-to-workspace 1; }
    Mod+Ctrl+2 { move-column-to-workspace 2; }
    Mod+Ctrl+3 { move-column-to-workspace 3; }
    Mod+Ctrl+4 { move-column-to-workspace 4; }
    Mod+Ctrl+5 { move-column-to-workspace 5; }
    Mod+Ctrl+6 { move-column-to-workspace 6; }
    Mod+Ctrl+7 { move-column-to-workspace 7; }
    Mod+Ctrl+8 { move-column-to-workspace 8; }
    Mod+Ctrl+9 { move-column-to-workspace 9; }

    // Layout controls.
    Mod+BracketLeft { consume-or-expel-window-left; }
    Mod+BracketRight { consume-or-expel-window-right; }
    Mod+Semicolon { consume-window-into-column; }
    Mod+Apostrophe { expel-window-from-column; }
    Mod+R { switch-preset-column-width; }
    Mod+Shift+R { switch-preset-column-width-back; }
    Mod+Ctrl+Shift+R { switch-preset-window-height; }
    Mod+Ctrl+R { reset-window-height; }
    Mod+F { maximize-column; }
    Mod+Shift+F { fullscreen-window; }
    Mod+M { maximize-window-to-edges; }
    Mod+Ctrl+F { expand-column-to-available-width; }
    Mod+C { center-column; }
    Mod+Ctrl+C { center-visible-columns; }
    Mod+Minus { set-column-width "-10%"; }
    Mod+Equal { set-column-width "+10%"; }
    Mod+Shift+Minus { set-window-height "-10%"; }
    Mod+Shift+Equal { set-window-height "+10%"; }
    Mod+V { toggle-window-floating; }
    Mod+Shift+V { switch-focus-between-floating-and-tiling; }
    Mod+W { toggle-column-tabbed-display; }

    // Screenshots use Niri's native UI and clipboard integration.
    Print { screenshot; }
    Ctrl+Print { screenshot-screen; }
    Alt+Print { screenshot-window; }

    Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
    Mod+Shift+E { quit; }
    Ctrl+Alt+Delete { quit; }
    Mod+Shift+P { power-off-monitors; }
}
'';
  };
}
