# modules/system/gaming.nix — Gaming and Wine support aspect.
#
# Provides: Steam, GameMode, Wine GE/Proton dependencies, and gaming tweaks.
# The standalone Wine stack doubles the gaming closure, so it lives behind
# aspects.gaming.wine.enable (default off). Steam's own Proton covers most
# titles; enable wine for native-Wine games or Bottles workflows.
# Gated by aspects.gaming.enable.
{ lib, config, pkgs, ... }:
{
  options.aspects.gaming = {
    enable = lib.mkEnableOption "gaming stack (Steam, GameMode)";

    wine = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Standalone Wine stack outside Steam's Proton: wineWow64,
          winetricks, Bottles, protonup-qt. Costs roughly 1.5–2 GB of
          runtime closure — Steam/Proton already covers most games.
        '';
      };
    };
  };

  config = lib.mkIf config.aspects.gaming.enable {
    # ── Steam & Gaming Services ──────────────────────────────────────
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
    };

    # Feral GameMode for CPU/GPU performance optimization during gameplay.
    # No custom.start/end notifications: those scripts run inside the root
    # gamemoded daemon, outside any user session, so desktop notifications
    # can never reach the compositor.
    programs.gamemode = {
      enable = true;
      settings.general.renice = 10;
    };

    # ── Gaming & Driver Utilities ──────────────────────────────────────
    environment.systemPackages = with pkgs; [
      mangohud # Performance overlay (FPS, temperatures, usage)

      # Vulkan & Driver utilities
      vulkan-tools
      clinfo
    ] ++ lib.optionals config.aspects.gaming.wine.enable [
      wineWow64Packages.stable # WOW64 wine (wineWowPackages deprecated in 26.05)
      winetricks
      protonup-qt # Easy Proton-GE manager
      bottles # Wine bottle manager
    ];
  };
}
