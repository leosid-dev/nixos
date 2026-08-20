# modules/system/desktop/niri.nix — Niri Wayland compositor (system-level).
#
# Owns the graphical compositor and toolkit defaults. Session identity is
# established by the graphical session rather than by every login method.
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
    services.gvfs.enable = true;

    # Toolkit defaults are useful in graphical and terminal sessions alike.
    # Session identity variables are deliberately left to the graphical
    # session so SSH and TTY logins are not reported as Wayland sessions.
    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1"; # Electron apps (VS Code, Discord, etc.)
      QT_QPA_PLATFORM = "wayland;xcb";
      GDK_BACKEND = "wayland,x11";
      SDL_VIDEODRIVER = "wayland,x11";
      CLUTTER_BACKEND = "wayland";

      # Portal / Java integration
      GTK_USE_PORTAL = "1";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };
  };
}
