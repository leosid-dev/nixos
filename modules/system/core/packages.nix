# modules/system/core/packages.nix — Minimal system-wide packages and env vars.
{ lib, config, pkgs, ... }:
{
  config = lib.mkIf config.aspects.core.enable {
    environment.systemPackages = with pkgs; [
      git
      curl
      wget
      htop
      jq
      ripgrep
      fd
      unzip
      file
      tree
      pciutils
      usbutils
      nix-index
    ];

    # Allow running dynamically-linked binaries (e.g. downloaded AppImages)
    programs.nix-ld.enable = true;
  };
}
