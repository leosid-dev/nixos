# modules/home/audio.nix — EasyEffects DSP for Dolby-like audio enhancement.
#
# Uses EasyEffects (PipeWire plugin host) with a custom parametric EQ preset
# that approximates Dolby Atmos' frequency response curve. The preset is
# auto-loaded at login via a systemd user service.
{ pkgs, ... }:
let
  easyeffects = pkgs.unstable.easyeffects;
in
{
  home.packages = [
    easyeffects
    pkgs.helvum # PipeWire patchbay for debugging audio routing
  ];

  # Deploy the Dolby-approximation EQ preset
  xdg.configFile."easyeffects/output/dolby-approximation.json".source =
    ../../assets/easyeffects/dolby-approximation.json;

  # Auto-start EasyEffects as a D-Bus activated service
  systemd.user.services.easyeffects = {
    Unit = {
      Description = "EasyEffects — PipeWire audio DSP";
      After = [ "pipewire.service" ];
      Requires = [ "pipewire.service" ];
    };
    Service = {
      Type = "dbus";
      BusName = "com.github.wwmm.easyeffects";
      ExecStart = "${easyeffects}/bin/easyeffects --gapplication-service";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Auto-load the preset once EasyEffects is running
  xdg.configFile."easyeffects/autoload/output/dolby-approximation.json".text =
    builtins.toJSON {
      device = "";
      "device-description" = "";
      "device-profile" = "";
      preset-name = "dolby-approximation";
    };
}
