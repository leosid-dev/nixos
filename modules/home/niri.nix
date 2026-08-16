# modules/home/niri.nix — Niri compositor user configuration with aspect knobs.
#
# Mandatory for the desktop profile. Tuning knobs (gaps, corner radius,
# animations, focus centering, terminal command) remain configurable.
# Colors are derived directly from aspects.theme.palette.focus.
{ config, lib, ... }:
let
  cfg = config.aspects.home.niri;
  palette = config.aspects.theme.palette;

  # One easing shared by every animation: cubic-bezier with y1 > 1 gives a
  # slight overshoot before settling at 1.0 (ease-out-back shape).
  anim = "duration-ms ${toString cfg.animationDuration}\n"
    + "        curve \"cubic-bezier\" 0.34 ${toString (1.0 + cfg.overshoot)} 0.64 1";
in
{
  options.aspects.home.niri = {
    gaps = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Gaps in pixels between windows and screen edges.";
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
  };

  config = {
    xdg.configFile."niri/config.kdl".text = ''
prefer-no-csd

layout {
    gaps ${toString cfg.gaps}
    center-focused-column "${cfg.centerFocused}"
    background-color "${palette.focus.background}"

    focus-ring {
        active-color "${palette.focus.active}"
        inactive-color "${palette.focus.inactive}"
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
    ${lib.optionalString (cfg.terminalCommand != null)
      ''Mod+Return { spawn "${cfg.terminalCommand}"; }''}
    Mod+q { close-window; }
    Mod+Shift+Escape { power-off-monitors; }

    # Focus (vim-style) and window movement
    Mod+h { focus-column-left; }
    Mod+j { focus-window-down; }
    Mod+k { focus-window-up; }
    Mod+l { focus-column-right; }

    Mod+Shift+h { move-column-left; }
    Mod+Shift+j { move-window-down; }
    Mod+Shift+k { move-window-up; }
    Mod+Shift+l { move-column-right; }

    # Screenshot + clipboard helpers
    Mod+Shift+S { spawn "sh" "-c" "grim - | wl-copy"; }
    Mod+Shift+Y { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }
}
'';
  };
}
