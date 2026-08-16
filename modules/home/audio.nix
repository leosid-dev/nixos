# modules/home/audio.nix — EasyEffects audio DSP (generic).
#
# Generic EasyEffects deployment: package, user systemd service, and
# zero-or-more preset files. Machine-specific tuning (EQ curve, codec
# quirks, etc.) lives in the consuming profile/host — never here.
#
# Enable via `aspects.home.audio.enable = true;` and supply preset
# definitions (name + source file). Each preset marked `loadOnStart`
# gets a oneshot unit that loads it once EasyEffects' D-Bus service
# is reachable (bounded retry — the service activates on demand).
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.home.audio;

  autoLoad = lib.filter (p: p.loadOnStart) cfg.presets;

  loadPresetScript = name:
    pkgs.writeShellScript "easyeffects-load-${name}" ''
      i=0
      while [ $i -lt 30 ]; do
        ${pkgs.easyeffects}/bin/easyeffects --load-preset ${lib.escapeShellArg name} && exit 0
        sleep 1
        i=$((i + 1))
      done
      echo "easyeffects-load: preset '${name}' did not load in time" >&2
      exit 1
    '';

  loaderService = p: {
    Unit = {
      Description = "Load EasyEffects preset '${p.name}'";
      After = [ "easyeffects.service" ];
      Wants = [ "easyeffects.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${loadPresetScript p.name}";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
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
      pkgs.crosspipe # PipeWire graph viewer (helvum removed in 26.05)
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
    # restart loops; the app registers its bus name itself. One oneshot
    # loader per loadOnStart preset is merged into the same binding.
    systemd.user.services = {
      easyeffects = {
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
    } // lib.listToAttrs (map
      (p: {
        name = "easyeffects-load-${p.name}";
        value = loaderService p;
      })
      autoLoad);
  };
}
