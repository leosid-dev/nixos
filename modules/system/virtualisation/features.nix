# modules/system/virtualisation/features.nix — Optional virtualisation features (KSM, swtpm, SPICE, VFIO).
{ config, lib, ... }:
let
  cfg = config.aspects.virtualisation;
in
{
  options.aspects.virtualisation = {
    ksm = {
      enable = lib.mkEnableOption ''
        Kernel Same-page Merging (KSM). Deduplicates identical memory pages between host
        and guests. Disabled by default because it consumes continuous CPU/battery and has
        side-channel implications on shared workstations.
      '';
    };

    swtpm = {
      enable = lib.mkEnableOption "emulated TPM 2.0 (swtpm) for guests requiring a TPM";
    };

    spiceUsbRedirection = {
      enable = lib.mkEnableOption ''
        SPICE USB device redirection helper (setuid). Disabled by default because it grants
        unprivileged users arbitrary USB device access.
      '';
    };

    vfio = {
      enable = lib.mkEnableOption ''
        VFIO device passthrough plumbing (eGPU / dedicated USB or NIC controllers).
        Not usable for the integrated GPU.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.ksm.enable = cfg.ksm.enable;
    virtualisation.libvirtd.qemu.swtpm.enable = cfg.swtpm.enable;
    virtualisation.spiceUSBRedirection.enable = cfg.spiceUsbRedirection.enable;

    boot.kernelModules =
      lib.optionals cfg.vfio.enable [ "vfio_pci" "vfio_iommu_type1" ];
  };
}
