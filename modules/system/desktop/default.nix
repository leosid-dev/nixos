# modules/system/desktop/default.nix — Desktop environment aspect.
#
# Provides: Niri compositor, XDG portals, noctalia-greeter login, Firefox.
# Gated by aspects.desktop.enable — leave off for a headless server.
{ lib, ... }:
{
  options.aspects.desktop.enable = lib.mkEnableOption "desktop environment (niri, portals, greeter)";

  imports = [
    ./niri.nix
    ./portals.nix
    ./login.nix
    ./browser.nix
  ];
}
