# modules/home/desktop.nix — Wayland desktop environment (HM-level).
#
# Consolidates: niri user config, Wayland tooling, terminal emulator.
# Desktop-session environment variables are set at system level (desktop/niri)
# so they apply uniformly to every login method.
#
# NOTE: Home Manager ships no `programs.niri` module, and the nixpkgs NixOS
# module only handles the compositor/session. The niri user config is therefore
# written directly as the raw config.kdl below.
{ pkgs, ... }:
{
  # ── Niri compositor (user-level config) ─────────────────────────
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

  # ── Terminal emulator ───────────────────────────────────────────
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "JetBrains Mono";
      font_size = "11.0";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      background_opacity = "0.95";
      confirm_os_window_close = 0;
      enable_audio_bell = false;

      # Catppuccin Mocha colors preview/defaults
      foreground = "#cdd6f4";
      background = "#1e1e2e";
      selection_foreground = "#1e1e2e";
      selection_background = "#f5e0dc";
      cursor = "#f5e0dc";
      cursor_text_color = "#1e1e2e";
    };
  };

  # ── Wayland utilities & X11 compatibility ───────────────────────
  # xwayland-satellite gives niri X11 app support (niri has no built-in
  # XWayland). niri auto-detects and starts it when present in $PATH.
  home.packages = with pkgs; [
    xdg-utils
    wl-clipboard
    grim
    slurp
    xwayland-satellite

    # QT Wayland platform plugins (QT_QPA_PLATFORM=wayland;xcb is set at
    # system level; without these QT apps fall back to XWayland).
    qt6Packages.qtwayland
    qt5.qtwayland
  ];

  # Per-user preferences (desktop-session identity lives at system level)
  home.sessionVariables = {
    TERMINAL = "kitty";
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
