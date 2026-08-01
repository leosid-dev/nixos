# modules/system/hardware/storage.nix — NVMe SSD + SD card support.
{ ... }:
{
  # Periodic TRIM for SSD longevity
  services.fstrim.enable = true;

  boot.kernelModules = [ "nvme" ];
  boot.initrd.availableKernelModules = [ "nvme" ];
}
