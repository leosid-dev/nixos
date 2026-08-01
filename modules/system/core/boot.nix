# modules/system/core/boot.nix — Boot loader and kernel configuration.
{ pkgs, ... }:
{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  boot.kernelParams = [ "quiet" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Tmpfs for /tmp (faster, auto-cleaned)
  boot.tmp.useTmpfs = true;
  boot.tmp.cleanOnBoot = true;

  # Systemd in initrd for faster, more reliable boot
  boot.initrd.systemd.enable = true;

  # Zram swap (compressed in-memory swap)
  zramSwap.enable = true;
}
