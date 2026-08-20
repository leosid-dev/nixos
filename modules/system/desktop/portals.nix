# modules/system/desktop/portals.nix — XDG Desktop Portal additions.
#
# Standard Niri portal stack:
# - GNOME portal handles ScreenCast, Screenshot, RemoteDesktop, Access.
# - GTK portal handles FileChooser, AppChooser, Print.
# - Secrets route to gnome-keyring.
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

    # dconf backend — required for Home Manager `dconf.settings` writes
    # (theme.nix) to actually apply.
    programs.dconf.enable = true;
  };
}
