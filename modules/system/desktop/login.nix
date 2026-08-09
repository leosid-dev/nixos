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
  config = lib.mkIf config.aspects.desktop.enable {
    programs.noctalia-greeter = {
      enable = true;
      settings = {
        session.default = "niri";
        keyboard.layout = config.aspects.locale.keyMap;
      };
    };
  };
}
