# modules/home/audio.nix — EasyEffects audio DSP (generic).
#
# Generic EasyEffects deployment: package, user systemd service, and
# zero-or-more preset files. Machine-specific tuning (EQ curve, codec
# quirks, etc.) lives in the consuming profile/host — never here.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.home.audio;

  loadPresetScript = pkgs.writeShellScript "easyeffects-load-preset" ''
      i=0
      while [ $i -lt 15 ]; do
        if ${lib.optionalString cfg.service.headless.enable "QT_QPA_PLATFORM=offscreen"} ${pkgs.coreutils}/bin/timeout 3s ${pkgs.easyeffects}/bin/easyeffects --load-preset "$1" 2>/dev/null; then
          ${lib.optionalString cfg.startup.disableBypass "${lib.optionalString cfg.service.headless.enable "QT_QPA_PLATFORM=offscreen"} ${pkgs.coreutils}/bin/timeout 3s ${pkgs.easyeffects}/bin/easyeffects --bypass 2 2>/dev/null || true"}
          exit 0
        fi
        sleep 1
        i=$((i + 1))
      done
      echo "easyeffects-load: preset '$1' did not load in time" >&2
      exit 0
    '';

  loaderService = {
    Unit = {
      Description = "Load EasyEffects preset '${cfg.activePreset}'";
      After = [ "easyeffects.service" ];
      Wants = [ "easyeffects.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "25s";
      ExecStart = "${loadPresetScript} ${lib.escapeShellArg cfg.activePreset}";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
in
{
  options.aspects.home.audio = {
    enable = lib.mkEnableOption "EasyEffects audio DSP with optional presets";

    graphViewer = {
      enable = lib.mkEnableOption "PipeWire graph inspection tool (crosspipe)";
    };

    service.headless = {
      enable = lib.mkEnableOption ''
        run EasyEffects with an offscreen Qt platform (no display server
        connection). The services still require and follow the graphical
        session target.
      '';
    };

    startup = {
      disableBypass = lib.mkEnableOption "disable EasyEffects bypass after loading the active preset";
    };

    activePreset = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The one preset to load when the graphical session starts.";
    };

    presets = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.strMatching "[a-zA-Z0-9][a-zA-Z0-9._-]*";
            description = ''
              Preset name; also the deployed filename (without .json) and part
              of the loader unit name, so only [a-zA-Z0-9._-] is allowed.
            '';
          };
          file = lib.mkOption {
            type = lib.types.path;
            description = "Path to the EasyEffects preset JSON.";
          };
        };
      });
      default = [ ];
      description = "EasyEffects presets to deploy; activePreset controls startup loading.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.easyeffects
    ] ++ lib.optional cfg.graphViewer.enable pkgs.crosspipe;

    # Deploy each preset under EasyEffects' standard directory layout ($XDG_DATA_HOME)
    xdg.dataFile = lib.listToAttrs (map
      (p: {
        name = "easyeffects/output/${p.name}.json";
        value = { source = p.file; };
      })
      cfg.presets);

    assertions = [
      {
        assertion = cfg.activePreset == null || lib.any (p: p.name == cfg.activePreset) cfg.presets;
        message = "aspects.home.audio.activePreset must name one of aspects.home.audio.presets.";
      }
      {
        assertion =
          lib.length cfg.presets
          == lib.length (lib.unique (map (p: p.name) cfg.presets));
        message = "aspects.home.audio.presets must not contain duplicate names.";
      }
    ];

    # EasyEffects in service mode, tied to the graphical session.
    systemd.user.services = {
      easyeffects = {
        Unit = {
          Description = "EasyEffects — PipeWire audio DSP";
          After = [ "pipewire.service" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          Environment = lib.optional cfg.service.headless.enable "QT_QPA_PLATFORM=offscreen";
          ExecStart = "${pkgs.easyeffects}/bin/easyeffects --service-mode";
          Restart = "on-failure";
          RestartSec = "2s";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    } // lib.optionalAttrs (cfg.activePreset != null) {
      "easyeffects-load-${cfg.activePreset}" = loaderService;
    };
  };
}
