# modules/system/desktop/portals.nix — XDG Desktop Portals for Wayland.
{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config = {
      common.default = "gtk";
      niri.default = [ "gnome" "gtk" ];
    };
  };
}
