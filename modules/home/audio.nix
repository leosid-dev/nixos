# modules/home/audio.nix — EasyEffects audio DSP (generic).
#
# Generic EasyEffects deployment: package, one user service, preset files,
# and convolver impulse responses. Machine-specific tuning (EQ curve,
# convolution kernels, codec quirks, etc.) lives in the consuming
# profile/host — never here.
#
# Startup DAG is a single unit (no loader service):
#   niri.service → easyeffects.service (+ ExecStartPost loads activePreset)
# The compositor anchor is canonical wayland.systemd.target (owned by
# wayland.nix). Headless hosts anchor to default.target (no compositor,
# no graphical target required).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.aspects.home.audio;

  ee = "${pkgs.easyeffects}/bin/easyeffects";
  timeout = "${pkgs.coreutils}/bin/timeout";

  # Canonical session anchor comes from wayland.nix: niri.service is ready
  # as soon as the compositor accepts connections, while
  # graphical-session.target waits on xdg-desktop-autostart portal probing
  # and can lag by tens of seconds. Headless hosts have no compositor, so
  # they follow default.target instead of any graphical target.
  sessionTarget = if cfg.headless.enable then "default.target" else config.wayland.systemd.target;

  namePattern = "[a-zA-Z0-9][a-zA-Z0-9._-]*";
  presetNames = builtins.attrNames cfg.presets;
  impulseStems = builtins.attrNames cfg.impulses;

  # Preset load after the service forks: wait for the local-server socket,
  # then load exactly once. Fail loudly so Restart=on-failure retries the
  # whole unit in 2s. Both load and unbypass are required when configured —
  # a silent no-DSP start is worse than a visible retry.
  loadPost = pkgs.writeShellScript "easyeffects-load-preset" ''
    runtimeDir="''${XDG_RUNTIME_DIR:-}"
    if [ -z "$runtimeDir" ]; then
      runtimeDir="/run/user/$(id -u)"
    fi
    sock="$runtimeDir/EasyEffectsServer"
    i=0
    while [ "$i" -lt 200 ]; do
      [ -S "$sock" ] && break
      sleep 0.1
      i=$((i + 1))
    done
    if [ ! -S "$sock" ]; then
      echo "easyeffects: server socket $sock did not appear" >&2
      exit 1
    fi
    if ! ${timeout} 15s ${ee} --load-preset ${lib.escapeShellArg cfg.activePreset}; then
      echo "easyeffects: preset '${cfg.activePreset}' did not load" >&2
      exit 1
    fi
    ${lib.optionalString cfg.startup.unbypass.enable ''
      if ! ${timeout} 15s ${ee} --bypass 2; then
        echo "easyeffects: unbypass failed" >&2
        exit 1
      fi
    ''}
  '';
in
{
  options.aspects.home.audio = {
    enable = lib.mkEnableOption "EasyEffects audio DSP with optional presets";

    graphViewer = {
      enable = lib.mkEnableOption "PipeWire graph inspection tool (crosspipe)";
    };

    headless = {
      enable = lib.mkEnableOption ''
        run EasyEffects with an offscreen Qt platform (no display server
        connection). The service anchors to default.target instead of the
        compositor.
      '';
    };

    startup = {
      unbypass = {
        enable = lib.mkEnableOption "disable EasyEffects global bypass after loading the active preset (easyeffects --bypass 2), ensuring DSP is active";
      };
    };

    activePreset = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The one preset to load when the session starts; must name an entry of presets.";
    };

    presets = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "EasyEffects presets to deploy under easyeffects/output/ (attribute name becomes the filename without .json); activePreset controls startup loading.";
    };

    impulses = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Convolver impulse responses deployed to easyeffects/irs/ (attribute name becomes the filename without .irs); convolver stages reference them by that stem as kernel-name.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.easyeffects
    ]
    ++ lib.optional cfg.graphViewer.enable pkgs.crosspipe;

    # Deploy presets and impulse responses under EasyEffects' standard
    # directory layout ($XDG_DATA_HOME).
    xdg.dataFile =
      lib.mapAttrs' (
        name: path: lib.nameValuePair "easyeffects/output/${name}.json" { source = path; }
      ) cfg.presets
      // lib.mapAttrs' (
        stem: path: lib.nameValuePair "easyeffects/irs/${stem}.irs" { source = path; }
      ) cfg.impulses;

    assertions = [
      {
        assertion = cfg.activePreset == null || builtins.hasAttr cfg.activePreset cfg.presets;
        message = "aspects.home.audio.activePreset must name one of aspects.home.audio.presets.";
      }
      {
        assertion = lib.all (n: builtins.match namePattern n != null) (presetNames ++ impulseStems);
        message = "aspects.home.audio.presets/impulses attribute names must match [a-zA-Z0-9._-] with a leading alnum (impulses omit the .irs extension).";
      }
      {
        assertion = !cfg.startup.unbypass.enable || cfg.activePreset != null;
        message = "aspects.home.audio.startup.unbypass.enable requires aspects.home.audio.activePreset.";
      }
    ];

    # Kernel cross-check at switch time, not eval time: every convolver
    # kernel-name referenced by a preset must have a deployed impulse, so a
    # typo surfaces as a switch failure instead of silent no-DSP.
    home.activation.easyeffectsImpulseCheck = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      ${lib.concatMapStringsSep "\n" (
        name:
        ''
          for k in $(${pkgs.jq}/bin/jq -r '[(.output // {}) | to_entries[] | select(.key | startswith("convolver#")) | .value."kernel-name" // empty] | .[]' ${lib.escapeShellArg cfg.presets.${name}}); do
            case " ${lib.concatStringsSep " " impulseStems} " in
              *" $k "*) ;;
              *) echo "easyeffects: preset '${name}' references missing impulse kernel '$k'" >&2; exit 1 ;;
            esac
          done
        ''
      ) presetNames}
    '';

    # EasyEffects in service mode, tied to the compositor.
    #
    # Runs display-connected by default: EasyEffects is single-instance
    # (lock file + local socket), so a GUI launch is forwarded to this
    # service and shows its window on demand. --service-mode alone does
    # NOT hide the window in the Qt rewrite; --hide-window keeps it
    # hidden until a launch requests it. (The headless option swaps the
    # display for an offscreen Qt platform and thereby locks the GUI —
    # only for hosts without a display.)
    systemd.user.services.easyeffects = {
      Unit = {
        Description = "EasyEffects — PipeWire audio DSP";
        After = [
          "pipewire.service"
          sessionTarget
        ];
        PartOf = [ sessionTarget ];
      };
      Service = {
        Type = "simple";
        Environment = lib.optional cfg.headless.enable "QT_QPA_PLATFORM=offscreen";
        ExecStart = "${ee} --service-mode --hide-window";
        ExecStartPost = lib.optional (cfg.activePreset != null) "${loadPost}";
        ExecStop = "${ee} --quit";
        KillMode = "mixed";
        TimeoutStartSec = "60s";
        TimeoutStopSec = "10s";
        Restart = "on-failure";
        RestartSec = "2s";
      };
      Install.WantedBy = [ sessionTarget ];
    };
  };
}
