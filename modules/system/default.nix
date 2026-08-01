# modules/system/default.nix — System aspect index.
#
# Every system aspect is imported here. Hosts only need to import this single
# path and then enable the aspects they want via the `aspects.*` option tree.
# Core defaults to on; every other aspect is off until a host opts in.
{
  imports = [
    ./core
    ./desktop
    ./ssh.nix
    ./sound.nix
    ./power.nix
    ./fonts.nix
    ./gaming.nix
    ./hardware/amd-rembrandt.nix
    ./hardware/network.nix
    ./hardware/storage.nix
    ./hardware/usb.nix
  ];
}
