# modules/home/niri.nix — Niri compositor user configuration with aspect knobs.
#
# Visual design: radius-4 window corners, one shared bezier easing with a
# slight overshoot before settling (ease-out-back shape), and a focus
# ring / workspace background keyed by aspects.theme.accent so the
# compositor matches the shell and terminal (single source of truth).
{ config, lib, ... }:
let
  cfg = config.aspects.home.niri;
  theme = config.aspects.theme;

  # Focus-ring + background palettes keyed by accent; unknown accents fall
  # back to the neutral dark set.
  rings = {
    monochrome = {
      active = "#e6e6e6";
      inactive = "#3d3d3d";
      background = "#000000"; # true black (deep on LCD)
    };
    catppuccin-mocha = {
      active = "#89b4fa";
      inactive = "#45475a";
      background = "#1e1e2e";
    };
    adwaita = {
      active = "#78aeed";
      inactive = "#4d4d4d";
      background = "#1e1e1e";
    };
  };
  ring = rings.${theme.accent} or rings.adwaita;

  # One easing shared by every animation: cubic-bezier with y1 > 1 gives a
  # slight overshoot before settling at 1.0 (ease-out-back shape).
  anim = "duration-ms ${toString cfg.animationDuration}\n"
    + "        curve \"cubic-bezier\" 0.34 ${toString (1.0 + cfg.overshoot)} 0.64 1";
in
{
  options.aspects.home.niri = {
    enable = lib.mkEnableOption "Niri compositor tweaks";
    gaps = lib.mkOption {
      type = lib.types.int;
      default = 8;
    };
    cornerRadius = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Window corner radius applied to every window.";
    };
    animationDuration = lib.mkOption {
      type = lib.types.int;
      default = 250;
      description = "Duration in ms of the shared bezier animation easing.";
    };
    overshoot = lib.mkOption {
      type = lib.types.float;
      default = 0.3;
      description = ''
        Animation overshoot: the bezier control point y1 is 1 + overshoot,
        so animations slightly overshoot their target before settling.
        0 settles without overshoot.
      '';
    };
    centerFocused = lib.mkOption {
      type = lib.types.enum [ "never" "always" "on-overflow" ];
      default = "always";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."niri/config.kdl".text = ''
prefer-no-csd true

layout {
    gaps ${toString cfg.gaps}
    center-focused-column "${cfg.centerFocused}"
    background-color "${ring.background}"

    focus-ring {
        active-color "${ring.active}"
        inactive-color "${ring.inactive}"
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

binds {
    Mod+Return { spawn "kitty"; }
    Mod+q { close-window; }
    Mod+Shift+P { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }
    Mod+Shift+Escape { power-off-monitors; }

    # Workspace focus (vim-style) and window movement
    Mod+h { focus left; }
    Mod+j { focus down; }
    Mod+k { focus up; }
    Mod+l { focus right; }

    Mod+Shift+h { move left; }
    Mod+Shift+j { move down; }
    Mod+Shift+k { move up; }
    Mod+Shift+l { move right; }

    # Screenshot + clipboard helpers
    Mod+Shift+S { spawn "sh" "-c" "grim - | wl-copy"; }
    Mod+Shift+Y { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }
}
'';
  };
}
