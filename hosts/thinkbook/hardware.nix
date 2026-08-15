# hosts/thinkbook/hardware.nix — Machine-specific hardware: filesystems, initrd.
#
# This file is the equivalent of `nixos-generate-config --show-hardware-config`
# but maintained declaratively. It contains ONLY things unique to this physical
# machine — generic driver aspects live in modules/system/hardware/.
#
# Hardware: Lenovo ThinkBook 16 G7 ARP
#   CPU:  AMD Ryzen 7 7735HS (Rembrandt, Zen 3+)
#   GPU:  AMD Radeon 680M (RDNA2 iGPU)
#   RAM:  16 GB DDR5
#   Storage:
#     nvme0n1 (Micron) — Linux/NixOS side
#       p1 = vfat EFI (Ubuntu leftovers)        UUID 1D56-ABDB
#       p2 = swap                                UUID 4ac49bbd-…
#       p3 = ext4 Ubuntu /                       UUID 37510d25-…
#       p4 = ext4 NixOS root (label "nixos")     UUID e83c1c8c-…  ← this system
#     nvme1n1 (KIOXIA) — Windows side
#       p1 = SYSTEM_DRV vfat (shared EFI)        UUID E06F-F08E   ← used as /boot
#       p2 = MSR
#       p3 = Windows-SSD ntfs                    UUID C66C704F-…
#       p4 = WINRE_DRV ntfs                      UUID 800A70D2-…
#   WiFi: MediaTek MT7921e (14c3:0616)
#   BT:   Foxconn MediaTek (btusb)
#   NIC:  none onboard (USB-C/RJ45 dongles only; r8169/asix/cdc_ncm drivers in-kernel)
#   Audio: Realtek ALC257 (HDA) + AMD ACP — no CS35L41 smart amps
#   USB4: Rembrandt USB4 router present (1022:15d6/15d7/162f)
{
  # ── Initrd: modules needed to find and mount the root filesystem ─
  boot.initrd.availableKernelModules = [
    "nvme" # NVMe SSD (KIOXIA + Micron)
    "xhci_pci" # USB 3.x host controller
    "usb_storage" # USB mass storage (recovery)
    "usbhid" # USB keyboards during initrd
    "sd_mod" # SD/MMC card reader (O2 Micro)
  ];

  boot.kernelModules = [
    "kvm-amd" # KVM virtualisation
    "ideapad_laptop" # Lenovo WMI/ACPI hotkeys and platform profile
  ];

  # ── Filesystems ─────────────────────────────────────────────────
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/e83c1c8c-ffd3-4750-a9d8-431ec065c6d1";
    fsType = "ext4";
    options = [ "relatime" "errors=remount-ro" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E06F-F08E";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/4ac49bbd-8aa4-4bd1-829a-57f7e57cea13"; }
  ];
}
