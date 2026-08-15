# modules/system/hardware/storage.nix — Storage device support.
#
# NVMe/USB initrd modules are host-owned (hosts/*/hardware.nix); PCI drivers
# autoload, so no kernel module lists here. This aspect owns the services.
{ lib, config, ... }:
{
  options.aspects.hardware.storage.enable = lib.mkEnableOption "storage hardware (NVMe, removable media)";

  config = lib.mkIf config.aspects.hardware.storage.enable {
    # Periodic TRIM for SSD longevity
    services.fstrim.enable = true;

    # Removable media (USB drives, etc.)
    services.udisks2.enable = true;

    # LVFS firmware updates (UEFI, NVMe, ...). Manual only — run
    # `fwupdmgr refresh && fwupdmgr update` explicitly; no auto timer.
    services.fwupd.enable = true;
  };
}
