# modules/system/power.nix — Power management aspect (generic).
#
# CPU frequency governor, power profiles, battery monitoring.
# Hardware-specific power params (e.g. amd_pstate) belong in
# modules/system/hardware/amd-rembrandt.nix, not here.
{ lib, ... }:
{
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  services.power-profiles-daemon.enable = true;

  services.upower.enable = true;
}
