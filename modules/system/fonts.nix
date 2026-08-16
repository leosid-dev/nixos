# modules/system/fonts.nix — System font packages.
{ lib, config, pkgs, ... }:
{
  options.aspects.fonts.enable = lib.mkEnableOption "system font packages";

  config = lib.mkIf config.aspects.fonts.enable {
    fonts.packages = with pkgs; [
      inter
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      jetbrains-mono
      nerd-fonts.fira-code
    ];

  };
}
