# modules/system/hardware/usb.nix — USB / Thunderbolt / USB4 support.
{ pkgs, ... }:
{
  boot.kernelModules = [
    "thunderbolt"
    "xhci_pci"
  ];

  # Bolt daemon for Thunderbolt/USB4 device authorization
  environment.systemPackages = [ pkgs.bolt ];
  services.hardware.bolt.enable = true;
}
