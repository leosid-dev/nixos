# modules/system/power.nix — Power management aspect (generic).
#
# CPU frequency governor, power profiles daemon, TLP / PPD defaults, and battery controls.
{ lib, pkgs, ... }:
{
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "powersave";
  };

  # Power profiles daemon for desktop profile integration (performance / balanced / power-saver)
  services.power-profiles-daemon.enable = true;

  # Battery monitoring service
  services.upower = {
    enable = true;
    percentageLow = 15;
    percentageCritical = 5;
    percentageAction = 3;
    criticalPowerAction = "HybridSleep";
  };

  # Thermal monitoring service
  services.thermald.enable = lib.mkDefault false; # Disabled on AMD (Intel specific)
}
