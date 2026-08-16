# modules/system/core/boot.nix — Boot loader and kernel configuration.
{ lib, config, pkgs, ... }:
let
  cfg = config.aspects.core;
in
{
  options.aspects.core = {
    kernelPackages = lib.mkOption {
      type = lib.types.raw;
      default = pkgs.linuxPackages_latest;
      defaultText = lib.literalExpression "pkgs.linuxPackages_latest";
      description = "Linux kernel package set used by the host.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      systemd-boot = {
        enable = true;
        # Keep the last 3 generations only — /boot usage stays bounded
        # (the EFI partition is shared with Windows). Also the single
        # source of truth for store-level generation pruning (see the
        # generation-limit service in nix.nix).
        configurationLimit = 3;
      };
      efi.canTouchEfiVariables = true;
    };

    boot.kernelParams = [ "quiet" ];
    boot.kernelPackages = cfg.kernelPackages;

    # Tmpfs for /tmp (faster, auto-cleaned)
    boot.tmp.useTmpfs = true;

    # Systemd in initrd for faster, more reliable boot
    boot.initrd.systemd.enable = true;

    # Zram swap (compressed in-memory swap)
    zramSwap.enable = true;
  };
}
