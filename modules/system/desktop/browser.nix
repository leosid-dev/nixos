# modules/system/desktop/browser.nix — Firefox (system-level).
#
# Ships with the desktop aspect: a browser is part of the desktop
# experience, not a per-persona choice (no aspect of its own).
# MOZ_ENABLE_WAYLAND is set by the desktop aspect (niri.nix), so Firefox
# runs native Wayland without extra configuration.
{ lib, config, ... }:
{
  config = lib.mkIf config.aspects.desktop.enable {
    programs.firefox.enable = true;
  };
}
