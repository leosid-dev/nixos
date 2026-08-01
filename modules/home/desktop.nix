# modules/home/desktop.nix — Wayland desktop environment (HM-level).
#
# Consolidates: niri user config, environment variables, Wayland tooling.
{ pkgs, ... }:
{
  # ── Wayland environment variables ───────────────────────────────
  home.sessionVariables = {
    # Desktop session identity
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";

    # Toolkit Wayland backends
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1"; # Electron apps (VS Code, Discord, etc.)
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";

    # Portal / Java integration
    GTK_USE_PORTAL = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    
    # Terminal
    TERMINAL = "kitty";
  };

  # ── Niri compositor (user-level settings) ───────────────────────
  programs.niri = {
    settings = {
      prefer-no-csd = true;

      layout = {
        gaps = 8;
        center-focused-column = "always";
      };

      spawn-at-startup = [
        { command = [ "noctalia" ]; }
      ];

      binds = let
        kitty = "${pkgs.kitty}/bin/kitty";
        grim = "${pkgs.grim}/bin/grim";
        slurp = "${pkgs.slurp}/bin/slurp";
      in {
        "Mod+Return".action.spawn = [ kitty ];
        "Mod+q".action.close-window = [ ];
        "Mod+Shift+P".action.spawn = [ "sh" "-c" "${grim} -g \"$(${slurp})\" - | wl-copy" ];
        "Mod+Shift+Escape".action.power-off-monitors = [ ];
      };
    };
  };

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

  # ── Wayland utilities ───────────────────────────────────────────
  home.packages = with pkgs; [
    xdg-utils
    wl-clipboard
    grim
    slurp
  ];
}
