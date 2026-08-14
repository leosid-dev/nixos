# modules/system/desktop/login.nix — Login / greeter service.
#
# Uses Noctalia Greeter (greetd-based) for a login screen matching the
# Noctalia shell. Greeters run pre-login as the `greeter` user, so they are
# inherently a system concern — Home Manager cannot manage them.
#
# The keyboard layout comes from `aspects.locale.keyMap` (declared in
# modules/system/core/locale.nix) so console + login never disagree.
{ lib, config, ... }:
{
  # Determine whether greeter should be enabled: prefer explicit aspects.greeter.enable
  let
    greeterEnable = if config.aspects.greeter ? enable then config.aspects.greeter.enable else config.aspects.desktop.enable;
  in
  config = lib.mkIf greeterEnable {
    programs.noctalia-greeter = {
      enable = greeterEnable;
      settings = {
        session.default = "niri";
        keyboard.layout = config.aspects.locale.keyMap;
      };
    };
  };
}
