# modules/home/niri.nix — Niri compositor user configuration with aspect knobs.
{ config, lib, ... }:
let
  cfg = config.aspects.home.niri;
in
{
  options.aspects.home.niri = {
    enable = lib.mkEnableOption "Niri compositor tweaks";
    gaps = lib.mkOption {
      type = lib.types.int;
      default = 8;
    };
    centerFocused = lib.mkOption {
      type = lib.types.enum [ "never" "always" "smart" ];
      default = "always";
    };
    showIndicators = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."niri/config.kdl".text = ''
prefer-no-csd true

layout {
    gaps ${toString cfg.gaps}
    center-focused-column "${cfg.centerFocused}"
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

${lib.optionalString cfg.showIndicators ''
window-indicators { style "dot"; }
''}
'';
  };
}
