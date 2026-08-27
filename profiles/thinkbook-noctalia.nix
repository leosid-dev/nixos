# profiles/thinkbook-noctalia.nix — ThinkBook-specific Noctalia policy.
#
# Display density: the 16" 1920x1200 panel runs Niri at scale 1.0 (see
# hosts/thinkbook/users.nix), so the shell gets a 1.15 readability boost.
#
# Enables the optional CPU package power widget with explicit RAPL paths for
# the ThinkBook 16 G7 ARP (AMD Rembrandt). No hwmon fallback: the hwmon
# power1_input scan is generic and can misreport GPU or other rails as CPU
# power, so we disable it unless a verified per-sensor path is supplied.
{ ... }:
{
  aspects.home.noctalia = {
    uiScale = 1.15;

    cpuPower = {
      enable = true;
      raplEnergyPaths = [
        "/sys/class/powercap/intel-rapl:0/energy_uj"
        "/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj"
      ];
      raplMaxPaths = [
        "/sys/class/powercap/intel-rapl:0/max_energy_range_uj"
        "/sys/class/powercap/intel-rapl/intel-rapl:0/max_energy_range_uj"
      ];
      hwmonPath = null;
    };
  };
}
