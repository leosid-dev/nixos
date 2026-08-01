# modules/system/desktop/portals.nix — XDG Desktop Portal additions.
#
# The nixpkgs niri module already wires the gnome portal, per-interface niri
# routing (Access/FileChooser/Notification/Secret) and gnome-keyring. We only
# add the GTK portal as a general fallback here.
{ lib, config, pkgs, ... }:
{
  config = lib.mkIf config.aspects.desktop.enable {
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "gtk";
    };
  };
}
