# modules/system/virtualisation/features.nix — Optional virtualisation features (KSM, swtpm, SPICE, VFIO).
# Options are canonical in default.nix; this leaf only wires config.
{ config, lib, ... }:
let
  cfg = config.aspects.virtualisation;
in
{
  config = lib.mkIf cfg.enable {
    hardware.ksm.enable = cfg.ksm.enable;
    virtualisation.libvirtd.qemu.swtpm.enable = cfg.swtpm.enable;
    virtualisation.spiceUSBRedirection.enable = cfg.spiceUsbRedirection.enable;

    boot.kernelModules =
      lib.optionals cfg.vfio.enable [ "vfio_pci" "vfio_iommu_type1" ];
    boot.initrd.kernelModules =
      lib.optionals cfg.vfio.enable [ "vfio_pci" "vfio_iommu_type1" ];
  };
}
