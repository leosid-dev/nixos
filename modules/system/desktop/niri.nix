# modules/system/desktop/niri.nix — Niri Wayland compositor (system-level).
#
# Also owns the desktop-session environment variables so they are uniform
# across login methods (greeter session, TTY, SSH) rather than only in
# Home-Manager shells — required for a consistent Wayland experience.
{ lib, config, pkgs, ... }:
{
  config = lib.mkIf config.aspects.desktop.enable {
    # Enable niri compositor from unstable (latest features)
    programs.niri = {
      enable = true;
      package = pkgs.unstable.niri;
    };

    # D-Bus is required for Wayland compositors
    services.dbus.enable = true;

    # Uniform Wayland environment for every session (AGENTS.md: uniform UX)
    environment.sessionVariables = {
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
    };
  };
}
