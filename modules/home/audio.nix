# modules/home/audio.nix — EasyEffects audio DSP (generic).
#
# Generic EasyEffects deployment: package, user systemd service,
# zero-or-more preset files, and zero-or-more convolver impulse
# response files. Machine-specific tuning (EQ curve, convolution
# kernels, codec quirks, etc.) lives in the consuming profile/host —
# never here.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.home.audio;

  # Convolver presets reference kernels by stem (filename without the
  # .irs extension); deployment keeps the full filename.
  impulseStems = map (i: lib.removeSuffix ".irs" i.name) cfg.impulses;

  # kernel-name references declared by every convolver stage of a preset.
  presetKernels =
    p:
    let
      data = builtins.fromJSON (builtins.readFile p.file);
      out = data.output or { };
      convolvers = lib.filter (n: lib.hasPrefix "convolver#" n) (lib.attrNames out);
    in
    lib.filter (n: n != null) (map (n: out.${n}.kernel-name or null) convolvers);

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

  # graphical-session.target activates before the compositor's socket
  # accepts connections; Qt aborts (core-dump) without it. Poll for the
  # Wayland socket briefly before starting. Best effort: after the wait,
  # proceed anyway and let Restart=on-failure handle the rest.
  waitDisplayScript = pkgs.writeShellScript "easyeffects-wait-display" ''
      if [ -z "''${WAYLAND_DISPLAY:-}" ]; then exit 0; fi
      i=0
      while [ $i -lt 15 ]; do
        [ -S "''${XDG_RUNTIME_DIR:-}/''${WAYLAND_DISPLAY}" ] && exit 0
        sleep 1
        i=$((i + 1))
      done
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
      TimeoutStartSec = "90s";
      ExecStartPre = lib.optional (!cfg.service.headless.enable) "${waitDisplayScript}";
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

    impulses = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.strMatching "[a-zA-Z0-9][a-zA-Z0-9._-]*\\.irs";
            description = ''
              Impulse response filename (with .irs extension). Convolver
              stages reference it by the stem (name without extension).
            '';
          };
          file = lib.mkOption {
            type = lib.types.path;
            description = "Path to the impulse response file.";
          };
        };
      });
      default = [ ];
      description = "Convolver impulse response files deployed to EasyEffects' irs directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.easyeffects
    ] ++ lib.optional cfg.graphViewer.enable pkgs.crosspipe;

    # Deploy presets and impulse responses under EasyEffects' standard
    # directory layout ($XDG_DATA_HOME).
    xdg.dataFile = lib.listToAttrs (map
      (p: {
        name = "easyeffects/output/${p.name}.json";
        value = { source = p.file; };
      })
      cfg.presets) // lib.listToAttrs (map
      (i: {
        name = "easyeffects/irs/${i.name}";
        value = { source = i.file; };
      })
      cfg.impulses);

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
      {
        assertion =
          lib.length cfg.impulses
          == lib.length (lib.unique (map (i: i.name) cfg.impulses));
        message = "aspects.home.audio.impulses must not contain duplicate names.";
      }
      {
        assertion = lib.all (p: lib.all (k: builtins.elem k impulseStems) (presetKernels p)) cfg.presets;
        message = "every convolver kernel-name in aspects.home.audio.presets must match a deployed aspects.home.audio.impulses entry.";
      }
    ];

    # EasyEffects in service mode, tied to the graphical session.
    #
    # Runs display-connected by default: EasyEffects is single-instance
    # (lock file + local socket), so a GUI launch is forwarded to this
    # service and shows its window on demand. --service-mode alone does
    # NOT hide the window in the Qt rewrite; --hide-window keeps it
    # hidden until a launch requests it. (The headless option swaps the
    # display for an offscreen Qt platform and thereby locks the GUI —
    # only for hosts without a display.)
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
          ExecStartPre = lib.optional (!cfg.service.headless.enable) "${waitDisplayScript}";
          ExecStart = "${pkgs.easyeffects}/bin/easyeffects --service-mode --hide-window";
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
