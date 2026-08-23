# modules/system/hardware/amd-rembrandt.nix — AMD Rembrandt SoC (Zen 3+ / RDNA2).
#
# Hardware: Ryzen 7 7735HS CPU + Radeon 680M iGPU.
# Gated by aspects.hardware.amdRembrandt.enable.
{ lib, config, pkgs, ... }:
let
  cfg = config.aspects.hardware.amdRembrandt;
in
{
  options.aspects.hardware.amdRembrandt = {
    enable = lib.mkEnableOption "AMD Rembrandt SoC support";

    audio = {
      enable = lib.mkEnableOption "AMD HDA audio power-save tuning";
      powerSave = lib.mkOption {
        type = lib.types.ints.between 0 60;
        default = 0;
        description = "HDA codec runtime power-save timeout in seconds.";
      };
    };

    flickerFix = {
      enable = lib.mkEnableOption "the AMD panel self-refresh workaround";
    };

    perfTuning = {
      enable = lib.mkEnableOption "AMD Rembrandt performance and power tuning";
    };

    abmLevel = lib.mkOption {
      type = lib.types.nullOr (lib.types.ints.between (-1) 1);
      default = null;
      description = ''
        Adaptive Backlight Management level for the eDP panel
        (amdgpu.abmlevel, -1..1). Experiment: -1 disables ABM, 1 applies
        it (dimmer backlight saves battery but shifts perceived colors).
        Default null = driver default, no kernel param added.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # ── CPU Microcode & Driver Tuning ──────────────────────────────
    hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

    boot.kernelModules = [
      "amd_energy"   # Energy counters monitoring per-core/package power
      "k10temp"      # CPU temperature monitoring driver
      "amdgpu"
    ];

    boot.initrd.kernelModules = [ "amdgpu" ];

    boot.kernelParams =
      [
        "amd_pstate=active"        # Driver: amd-pstate-epp
        "amdgpu.gpu_recovery=1"    # Enable automatic GPU recovery on hangs
      ]
      ++ lib.optionals cfg.flickerFix.enable [ "amdgpu.dcdebugmask=0x10" ]
      ++ lib.optionals cfg.perfTuning.enable [
        "iommu=pt"    # Passthrough IOMMU: no host-device translation; enables VFIO
        "nowatchdog"  # No hardware-watchdog polling on laptops
      ]
      ++ lib.optionals (cfg.abmLevel != null) [ "amdgpu.abmlevel=${toString cfg.abmLevel}" ];

    # zram-friendly swap pressure: prefer compressed RAM over disk swap.
    boot.kernel.sysctl = lib.mkIf cfg.perfTuning.enable { "vm.swappiness" = 10; };

    # ── iGPU & VAAPI Hardware Acceleration ────────────────────────
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libva-vdpau-driver # VDPAU→VA-API translation (vaapiVdpau renamed in 26.05)
        libvdpau-va-gl
      ];
    };

    # ── Firmware ──────────────────────────────────────────────────
    # Note: hardware.enableRedistributableFirmware is declared once in
    # modules/system/hardware/network.nix (single canonical source).

    # HDA codec power management (0 = disabled to avoid wake pops)
    boot.extraModprobeConfig = lib.mkIf cfg.audio.enable ''
      options snd_hda_intel power_save=${toString cfg.audio.powerSave} power_save_controller=Y
    '';
  };
}
