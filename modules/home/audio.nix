# modules/home/audio.nix — EasyEffects audio DSP (generic).
#
# Generic EasyEffects deployment: package, user systemd service, and
# zero-or-more preset files. Machine-specific tuning (EQ curve, codec
# quirks, etc.) lives in the consuming profile/host — never here.
#
# Enable via `aspects.home.audio.enable = true;` and supply preset
# definitions (name + source file). A oneshot unit loads the chosen
# preset once EasyEffects is running.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.home.audio;
in
{
  options.aspects.home.audio = {
    enable = lib.mkEnableOption "EasyEffects audio DSP with optional presets";

    presets = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Preset name (also the filename without .json).";
          };
          file = lib.mkOption {
            type = lib.types.path;
            description = "Path to the EasyEffects preset JSON.";
          };
          loadOnStart = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Load this preset via a oneshot unit on session start.";
          };
        };
      });
      default = [ ];
      description = "EasyEffects presets to deploy and (optionally) auto-load.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.easyeffects
      pkgs.helvum # PipeWire patchbay for debugging audio routing
    ];

    # Deploy each preset under EasyEffects' standard directory layout
    xdg.configFile = lib.listToAttrs (map
      (p: {
        name = "easyeffects/output/${p.name}.json";
        value = { source = p.file; };
      })
      cfg.presets);

    # EasyEffects as a GApplication service, tied to the graphical session.
    # Plain `simple` type: D-Bus activation races with Type=dbus caused
    # restart loops; the app registers its bus name itself.
    systemd.user.services.easyeffects = {
      Unit = {
        Description = "EasyEffects — PipeWire audio DSP";
        After = [ "pipewire.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # One oneshot per preset that wants to auto-load
    systemd.user.services = lib.listToAttrs (map
      (p: {
        name = "easyeffects-load-${p.name}";
        value = {
          Unit = {
            Description = "Load EasyEffects preset '${p.name}'";
            After = [ "easyeffects.service" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.easyeffects}/bin/easyeffects --load-preset ${p.name}";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      })
      (lib.filter (p: p.loadOnStart) cfg.presets));
  };
}
