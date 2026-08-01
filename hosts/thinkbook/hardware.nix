# hosts/thinkbook/hardware.nix — Machine-specific hardware: filesystems, initrd, SoC.
#
# This file is the equivalent of `nixos-generate-config --show-hardware-config`
# but maintained declaratively. It contains ONLY things unique to this physical
# machine — no generic driver modules (those live in modules/system/hardware/).
#
# Hardware: Lenovo ThinkBook 16 G7 ARP
#   CPU:  AMD Ryzen 7 7735HS (Rembrandt, Zen 3+)
#   GPU:  AMD Radeon 680M (RDNA2 iGPU)
#   RAM:  16 GB DDR5
#   NVMe: Micron (nvme0n1, shared with Windows) + KIOXIA (nvme1n1, NixOS)
#   WiFi: MediaTek MT7921e
#   BT:   Foxconn (USB)
{ lib, ... }:
{
  # ── Initrd: modules needed to find and mount the root filesystem ─
  boot.initrd.availableKernelModules = [
    "nvme" # NVMe SSD (KIOXIA + Micron)
    "xhci_pci" # USB 3.x host controller
    "thunderbolt" # USB4/Thunderbolt controller
    "usb_storage" # USB mass storage (recovery)
    "sd_mod" # SD/MMC card reader (O2 Micro)
    "amdgpu" # Early KMS for display
  ];

  boot.kernelModules = [
    "kvm-amd" # KVM virtualisation
  ];

  # ── Filesystems ─────────────────────────────────────────────────
  # TODO: Replace UUIDs with your actual partition UUIDs.
  # Detected layout on nvme1n1:
  #   p1 = vfat (EFI)    → UUID from `blkid /dev/nvme1n1p1`
  #   p2 = swap           → UUID 4ac49bbd-8aa4-4bd1-829a-57f7e57cea13
  #   p3 = ext4 (Ubuntu)  → UUID 37510d25-8375-45d2-8c52-83f1ed86cc98
  #   p4 = ext4 (nixos)   → UUID e83c1c8c-ffd3-4750-a9d8-431ec065c6d1

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos"; # TODO: confirm or use by-uuid
    fsType = "ext4";
    options = [ "relatime" "errors=remount-ro" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/CHANGE-ME-BOOT-UUID"; # TODO: set your EFI partition UUID
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/4ac49bbd-8aa4-4bd1-829a-57f7e57cea13"; }
  ];

  # ── Platform ────────────────────────────────────────────────────
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
