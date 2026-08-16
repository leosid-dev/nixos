# modules/system/virtualisation/default.nix — KVM/QEMU virtualisation aspect.
#
# Composes libvirt platform, disk storage tooling, host-backed virtiofs shares,
# and optional performance/security features (KSM, swtpm, SPICE, VFIO).
# Gated by aspects.virtualisation.enable (default false).
{ lib, ... }:
{
  options.aspects.virtualisation = {
    enable = lib.mkEnableOption "KVM/QEMU virtualisation (libvirt, virtiofs, virt-manager)";
  };

  imports = [
    ./platform.nix
    ./storage.nix
    ./shares.nix
    ./features.nix
  ];
}
