# modules/system/desktop/niri.nix — Niri Wayland compositor (system-level).
{ pkgs, ... }:
{
  # Enable niri compositor from unstable (latest features)
  programs.niri = {
    enable = true;
    package = pkgs.unstable.niri;
  };

  # D-Bus is required for Wayland compositors
  services.dbus.enable = true;
}
