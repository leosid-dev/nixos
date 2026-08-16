# modules/system/fonts.nix — System font packages.
{ lib, config, pkgs, ... }:
let
  cfg = config.aspects.fonts;
in
{
  options.aspects.fonts = {
    enable = lib.mkEnableOption "system font packages";

    cjk = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Install noto-fonts-cjk-sans (Chinese/Japanese/Korean). Large
        (~100 MB) — enable only when CJK text must render in the
        browser/terminal.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.packages =
      with pkgs;
      [
        inter
        noto-fonts
        noto-fonts-color-emoji
        jetbrains-mono
        nerd-fonts.fira-code
      ]
      ++ lib.optionals cfg.cjk [ noto-fonts-cjk-sans ];
  };
}
