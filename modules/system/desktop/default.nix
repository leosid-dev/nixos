# modules/system/desktop/default.nix — Desktop environment aspect.
#
# Provides: Niri compositor, XDG portals, D-Bus, display login.
# This is a toggleable aspect — remove this import to get a headless server.
{
  imports = [
    ./niri.nix
    ./portals.nix
    ./login.nix
  ];
}
