# modules/system/hardware/usb.nix — USB / Thunderbolt / USB4 support.
#
# Plain USB support is always on with the aspect; Thunderbolt/USB4 is a
# separate toggle (probe the machine with `lspci | grep -i usb4` to decide).
{ lib, config, pkgs, ... }:
let
  cfg = config.aspects.hardware.usb;
in
{
  options.aspects.hardware.usb = {
    enable = lib.mkEnableOption "USB support";

    thunderbolt = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable Thunderbolt/USB4 support (kernel modules + bolt authorization
        daemon). Only enable on machines that actually expose a USB4 router.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [
      "thunderbolt"
      "xhci_pci"
    ];

    # Bolt daemon for Thunderbolt/USB4 device authorization
    services.hardware.bolt.enable = cfg.thunderbolt;
    environment.systemPackages = lib.mkIf cfg.thunderbolt [ pkgs.bolt ];
  };
}
