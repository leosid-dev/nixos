# modules/system/gaming.nix — Gaming and Wine support aspect.
#
# Provides: Steam, GameMode, Wine GE/Proton dependencies, and gaming tweaks.
# The standalone Wine stack doubles the gaming closure, so it lives behind
# aspects.gaming.wine.enable (default off). Steam's own Proton covers most
# titles; enable wine for native-Wine games or Bottles workflows.
# Inbound firewall openings for Steam Remote Play and dedicated servers are
# explicit opt-in sub-options (default off).
# Gated by aspects.gaming.enable.
{ lib, config, pkgs, ... }:
let
  cfg = config.aspects.gaming;
in
{
  options.aspects.gaming = {
    enable = lib.mkEnableOption "gaming stack (Steam, GameMode)";

    wine = {
      enable = lib.mkEnableOption "standalone Wine stack (wineWow64, winetricks, Bottles, protonup-qt)";
    };

    remotePlay = {
      enable = lib.mkEnableOption "inbound firewall opening for Steam Remote Play";
    };

    dedicatedServer = {
      enable = lib.mkEnableOption "inbound firewall opening for Steam Dedicated Server";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── Steam & Gaming Services ──────────────────────────────────────
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = cfg.remotePlay.enable;
      dedicatedServer.openFirewall = cfg.dedicatedServer.enable;
      gamescopeSession = {
        enable = true;
        # The greeter-launched DRM session already has systemd-logind. Avoid
        # probing for an unused seatd socket before falling back to logind.
        env.LIBSEAT_BACKEND = "logind";
      };
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
    ] ++ lib.optionals cfg.wine.enable [
      wineWow64Packages.stable # WOW64 wine (wineWowPackages deprecated in 26.05)
      winetricks
      protonup-qt # Easy Proton-GE manager
      bottles # Wine bottle manager
    ];
  };
}
