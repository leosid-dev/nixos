# modules/system/theme.nix — System-side theme selection mirror.
#
# Home Manager owns the full `aspects.theme` option tree (declared in
# modules/home/theme.nix, selected in profiles/*.nix). The pre-login
# noctalia-greeter runs as the `greeter` user and cannot read Home Manager
# options, so this module mirrors the two *selection* enums the greeter
# needs. Colors are never duplicated: both trees derive every token from
# lib/palettes.nix, the single color source of truth.
#
# Alignment contract: these defaults MUST match the HM profile's
# `aspects.theme` selection (same pattern as `aspects.fonts.uiFont`, which
# is kept aligned with HM's `aspects.theme.font`). If a profile changes
# accent or mode, change the defaults here (or set them per host) too.
{ lib, ... }:
{
  options.aspects.theme = {
    accent = lib.mkOption {
      type = lib.types.enum [
        "monochrome"
        "catppuccin-mocha"
        "adwaita"
      ];
      default = "monochrome";
      description = ''
        Accent palette name, mirroring HM's `aspects.theme.accent` for the
        pre-login greeter. Keep aligned with the HM profile selection.
      '';
    };

    mode = lib.mkOption {
      type = lib.types.enum [
        "dark"
        "light"
      ];
      default = "dark";
      description = ''
        Theme mode (dark or light surfaces), mirroring HM's
        `aspects.theme.mode` for the pre-login greeter. Keep aligned with
        the HM profile selection.
      '';
    };
  };
}
