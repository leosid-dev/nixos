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

    # VFIO modules must be available in initrd so vfio-pci.ids= can claim
    # devices before udev coldplug binds host drivers (xhci, r8169, ...);
    # stage-2 loading alone loses that race for onboard controllers.
    boot.initrd.availableKernelModules =
      lib.optionals cfg.vfio.enable [ "vfio_pci" "vfio_iommu_type1" ];
    boot.kernelModules =
      lib.optionals cfg.vfio.enable [ "vfio_pci" "vfio_iommu_type1" ];
    # AMD IOMMU is on by default; iommu=pt arrives via
    # aspects.hardware.amdRembrandt.perfTuning when enabled.
    boot.kernelParams = lib.optionals (cfg.vfio.enable && cfg.vfio.ids != [ ]) [
      "vfio-pci.ids=${lib.concatStringsSep "," cfg.vfio.ids}"
    ];
  };
}
