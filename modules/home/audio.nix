# modules/home/audio.nix — EasyEffects DSP for Dolby-like audio enhancement.
#
# Uses EasyEffects (PipeWire plugin host) with a preset that approximates the
# Windows Dolby/HARMAN tuning: harmonic bass synthesis + parametric EQ +
# limiter. This machine (ThinkBook 16 G7 ARP, Realtek ALC257, no smart amps)
# has no DSP on Linux, so this chain restores the missing bass/presence.
#
# The preset is loaded by a oneshot unit once the EasyEffects service is up;
# EasyEffects' own autoload-on-device matching is too fragile to rely on here.
{ pkgs, ... }:
let
  easyeffects = pkgs.unstable.easyeffects;
in
{
  home.packages = [
    easyeffects
    pkgs.helvum # PipeWire patchbay for debugging audio routing
  ];

  # Deploy the Dolby-approximation DSP chain preset
  xdg.configFile."easyeffects/output/dolby-approximation.json".source =
    ../../assets/easyeffects/dolby-approximation.json;

  # EasyEffects as a D-Bus activated service, tied to the graphical session
  systemd.user.services.easyeffects = {
    Unit = {
      Description = "EasyEffects — PipeWire audio DSP";
      After = [ "pipewire.service" ];
      Requires = [ "pipewire.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "com.github.wwmm.easyeffects";
      ExecStart = "${easyeffects}/bin/easyeffects --gapplication-service";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Load the Dolby-approximation preset once EasyEffects is running
  systemd.user.services.easyeffects-dolby-preset = {
    Unit = {
      Description = "Load the EasyEffects Dolby-approximation preset";
      After = [ "easyeffects.service" ];
      Requires = [ "easyeffects.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${easyeffects}/bin/easyeffects --load-preset dolby-approximation";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
