# modules/system/core/locale.nix — Locale, console keymap.
#
# The keyMap option (`aspects.locale.keyMap`) is the single source of truth
# shared with noctalia-greeter (login.nix) so the console and the login
# screen never disagree. Timezone and hostname are host facts, set in
# hosts/*/default.nix — not core defaults.
{ lib, config, ... }:
let
  cfg = config.aspects.locale;
in
{
  options.aspects.locale = {
    keyMap = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Console keymap (also drives the login screen layout).";
    };
  };

  config = lib.mkIf config.aspects.core.enable {
    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    };

    console = {
      keyMap = lib.mkDefault cfg.keyMap;
      earlySetup = true; # Apply the keymap in initrd (LUKS prompts, etc.)
    };
  };
}
