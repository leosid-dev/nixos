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
        default = "Inter";
        description = ''
          System UI font family name. Documented as greeter-only requirement:
          noctalia-greeter runs pre-login as the `greeter` user before Home
          Manager fonts exist. Parallel to HM's `aspects.theme.font` (which
          cannot reach pre-login); keep the defaults aligned manually.
        '';
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.inter;
        description = ''
          Package providing the system UI font for the pre-login greeter.
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
