# modules/system/hardware/usb.nix — USB / Thunderbolt / USB4 support.
#
# Plain USB support is always on with the aspect; Thunderbolt/USB4 is a
# separate enable sub-option. Probe the machine with `boltctl list` or
# `lspci -nn | grep -Ei 'usb4|thunderbolt'` to decide.
{ lib, config, pkgs, ... }:
let
  cfg = config.aspects.hardware.usb;
in
{
  options.aspects.hardware.usb = {
    enable = lib.mkEnableOption "USB support";

    thunderbolt = {
      enable = lib.mkEnableOption "Thunderbolt/USB4 support (kernel modules + bolt daemon)";
    };
  };

  config = lib.mkIf cfg.enable {
    # xHCI PCI host controller driver always; Thunderbolt/USB4 adds its
    # kernel module and bolt authorization daemon only when this machine
    # actually exposes a USB4 router. Probe: `boltctl list`.
    boot.kernelModules = [ "xhci_pci" ] ++ lib.optionals cfg.thunderbolt.enable [ "thunderbolt" ];

    # Bolt daemon for Thunderbolt/USB4 device authorization
    services.hardware.bolt.enable = cfg.thunderbolt.enable;
    environment.systemPackages = lib.mkIf cfg.thunderbolt.enable [ pkgs.bolt ];
  };
}
