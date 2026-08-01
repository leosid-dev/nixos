# modules/system/gaming.nix — Gaming and Wine support aspect.
#
# Provides: Steam, GameMode, Wine GE/Proton dependencies, and gaming tweaks.
# Gated by aspects.gaming.enable.
{ lib, config, pkgs, ... }:
{
  options.aspects.gaming.enable = lib.mkEnableOption "gaming stack (Steam, GameMode, Wine)";

  config = lib.mkIf config.aspects.gaming.enable {
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
      wineWowPackages.stable
      winetricks
      mangohud # Performance overlay (FPS, temperatures, usage)
      protonup-qt # Easy Proton-GE manager
      bottles # Wine bottle manager

      # Vulkan & Driver utilities
      vulkan-tools
      clinfo
    ];
  };
}
