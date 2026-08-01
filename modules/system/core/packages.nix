# modules/system/core/packages.nix — Minimal system-wide packages and env vars.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    neovim
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

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Allow running dynamically-linked binaries (e.g. downloaded AppImages)
  programs.nix-ld.enable = true;
}
