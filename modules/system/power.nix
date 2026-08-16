# modules/system/power.nix — Power management aspect (generic).
#
# CPU frequency governor, power profiles daemon, and battery controls.
# Gated by aspects.power.enable.
{ lib, config, ... }:
{
  options.aspects.power.enable = lib.mkEnableOption "power management (PPD, upower)";

  config = lib.mkIf config.aspects.power.enable {
    powerManagement.enable = true;

    # Power profiles daemon for desktop profile integration (performance / balanced / power-saver).
    # PPD owns the CPU governor/EPP itself (and with amd_pstate=active the
    # governor is a no-op), so no cpuFreqGovernor is set here — setting both
    # would have them fight at runtime.
    services.power-profiles-daemon.enable = true;

    # Battery monitoring service
    services.upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 5;
      percentageAction = 3;
      # Suspend at critical battery. HybridSleep needs hibernation plumbing
      # (boot.resumeDevice + swap >= RAM); revisit as a future aspect.
      # nixos-26.05 gates Suspend behind allowRiskyCriticalPowerAction
      # (risky = no hibernate state saved; unsaved work loss possible).
      allowRiskyCriticalPowerAction = true;
      criticalPowerAction = "Suspend";
    };
  };
}
