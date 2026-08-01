# modules/system/core/locale.nix — Locale, timezone, console, hostname defaults.
{ lib, config, ... }:
{
  config = lib.mkIf config.aspects.core.enable {
    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    };

    time.timeZone = lib.mkDefault "UTC";

    console.keyMap = lib.mkDefault "us";

    networking.hostName = lib.mkDefault "nixos";
  };
}
