# modules/system/gaming.nix — Gaming and Wine support aspect.
#
# Provides: Steam, GameMode, Wine GE/Proton dependencies, and gaming performance tweaks.
{ pkgs, ... }:
{
  # ── Steam & Gaming Services ──────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  # Feral GameMode for CPU/GPU performance optimization during gameplay
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode Started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode Ended'";
      };
    };
  };

  # ── Gaming & Compatibility Packages ──────────────────────────────
  environment.systemPackages = with pkgs; [
    # Wine & Proton helpers
    wineWowPackages.stable
    winetricks
    mangohud # Performance overlay (FPS, temperatures, usage)
    protonup-qt # Easy Proton-GE manager
    bottles # Wine bottle manager

    # Vulkan & Driver utilities
    vulkan-tools
    clinfo
  ];
}
