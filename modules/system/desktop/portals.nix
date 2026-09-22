# modules/system/desktop/portals.nix — XDG Desktop Portal additions.
#
# Standard Niri portal stack:
# - GNOME portal handles ScreenCast, Screenshot, RemoteDesktop, Access.
# - GTK portal handles FileChooser, AppChooser, Print.
# - Secrets route to gnome-keyring (auto-unlocked at login via PAM).
{ lib, config, pkgs, ... }:
{
  config = lib.mkIf config.aspects.desktop.enable {
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
      config = {
        niri = {
          default = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.Print" = [ "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
        common = {
          default = [ "gtk" ];
        };
      };
    };

    # Secret-service provider + auto-unlock. The NixOS module owns the full
    # stack (D-Bus activation, portal backend, cap_ipc_lock wrapper,
    # login-stack PAM); the extra line covers our actual login path —
    # nixpkgs only wires `login`, but this host logs in through greetd.
    # Password logins unlock silently; fingerprint logins carry no authtok,
    # so the first secret access prompts once per session (accepted).
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;

    # dconf backend — required for Home Manager `dconf.settings` writes
    # (theme.nix) to actually apply.
    programs.dconf.enable = true;
  };
}
