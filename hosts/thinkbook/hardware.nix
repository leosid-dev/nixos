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
#   Storage (clean-slate layout, created by WALKTHROUGH.md):
#     nvme0n1 (Micron) — NixOS system disk
#       p1 = vfat ESP (label "boot", 2 GiB)      ← /boot
#       p2 = swap      (label "swap", 8 GiB)
#       p3 = ext4 root (label "nixos", rest)     ← /
#     nvme1n1 (KIOXIA) — data disk
#       p1 = ext4 VM images (label "vmdata", 150 GiB) ← /var/lib/libvirt/images
#       p2 = ext4 media/games (label "media", rest)   ← /home/sid/media
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
  # PLACEHOLDER: disk layout (clean-slate install). The labels below are
  # created by the partitioning steps in WALKTHROUGH.md. If you deviate
  # from that layout, update the labels here (or switch to
  # /dev/disk/by-uuid/<UUID> once the disks are formatted).
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "relatime" "errors=remount-ro" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # VM images live on their own partition so qcow2 growth never competes
  # with the root filesystem. libvirt's default pool and the `virt-disk`
  # helper both write here — no module changes needed.
  fileSystems."/var/lib/libvirt/images" = {
    device = "/dev/disk/by-label/vmdata";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  # Media + game libraries (Steam library folder lives inside).
  fileSystems."/home/sid/media" = {
    device = "/dev/disk/by-label/media";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];
}
