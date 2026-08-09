# modules/home/niri.nix — Niri compositor user configuration.
#
# Home Manager has no `programs.niri` module, and the nixpkgs NixOS module
# only manages the compositor process. User configuration is therefore
# written directly as raw config.kdl.
#
# This module is always-on when imported by a desktop profile; disabling
# the compositor entirely is a profile-level decision (just don't import).
{ pkgs, ... }:
{
  xdg.configFile."niri/config.kdl".text = ''
    prefer-no-csd true

    layout {
        gaps 8
        center-focused-column "always"
    }

    # Noctalia is started via its own systemd user unit
    # (programs.noctalia.systemd.enable), not spawned here — spawning it
    # twice races the singleton instance.

    binds {
        Mod+Return { spawn "kitty"; }
        Mod+q { close-window; }
        Mod+Shift+P { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }
        Mod+Shift+Escape { power-off-monitors; }
    }
  '';

  # EDITOR, VISUAL, TERMINAL are set by `programs.neovim.defaultEditor`
  # and `programs.kitty` respectively — no need to redeclare here.
}
