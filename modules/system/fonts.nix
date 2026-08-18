# modules/system/fonts.nix — System font packages.
#
# Provides system fallback, emoji, and pre-login greeter UI font.
# User-space font packages and monospace preferences are owned by
# Home Manager's `aspects.theme.font`.
{ lib, config, pkgs, ... }:
let
  cfg = config.aspects.fonts;
in
{
  options.aspects.fonts = {
    enable = lib.mkEnableOption "system font packages";

    uiFont = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "SF Pro";
        description = ''
          System UI font family name. Documented as greeter-only requirement:
          noctalia-greeter runs pre-login as the `greeter` user before Home
          Manager fonts exist.
        '';
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.sf-pro;
        description = ''
          Package providing the system UI font. Apple SF Pro from the
          apple-fonts flake (requires the host's appleFontsOverlay).
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = [
      pkgs.noto-fonts
      pkgs.noto-fonts-color-emoji
      cfg.uiFont.package
    ];
  };
}
