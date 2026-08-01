# modules/system/hardware/storage.nix — NVMe SSD + removable media support.
{ lib, config, ... }:
{
  options.aspects.hardware.storage.enable = lib.mkEnableOption "storage hardware (NVMe, removable media)";

  config = lib.mkIf config.aspects.hardware.storage.enable {
    # Periodic TRIM for SSD longevity
    services.fstrim.enable = true;

    boot.kernelModules = [ "nvme" ];
    boot.initrd.availableKernelModules = [ "nvme" ];

    # Removable media (USB drives, etc.)
    services.udisks2.enable = true;
  };
}
