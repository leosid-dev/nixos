# modules/home/wayland.nix — Wayland tooling & X11 compatibility (HM-level).
#
# Always-on with a desktop profile: provides xwayland-satellite (niri spawns
# it on demand from PATH — no manual autostart needed), screenshot tools,
# clipboard, and qt-wayland plugins. Privilege prompts are owned by
# Noctalia's built-in polkit agent (aspects.home.noctalia).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    xdg-utils
    wl-clipboard
    grim
    slurp
    xwayland-satellite
    libnotify

    # QT Wayland platform plugins (QT_QPA_PLATFORM=wayland;xcb is set at
    # system level; without these QT apps fall back to XWayland).
    qt6.qtwayland
    libsForQt5.qtwayland
  ];
}
