# modules/system/core/boot.nix — Boot loader and kernel configuration.
{ lib, config, pkgs, ... }:
{
  config = lib.mkIf config.aspects.core.enable {
    boot.loader = {
      systemd-boot = {
        enable = true;
        # Bound /boot usage — the EFI partition is shared with Windows.
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
    };

    boot.kernelParams = [ "quiet" ];
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Tmpfs for /tmp (faster, auto-cleaned)
    boot.tmp.useTmpfs = true;

    # Systemd in initrd for faster, more reliable boot
    boot.initrd.systemd.enable = true;

    # Zram swap (compressed in-memory swap)
    zramSwap.enable = true;
  };
}
