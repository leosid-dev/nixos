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

    audioPowerSave = lib.mkOption {
      type = lib.types.ints.between 0 60;
      default = 0;
      description = ''
        HDA codec runtime power-save timeout (seconds). 0 disables it.
        On this machine power-save causes audible pops/crackle when the
        Realtek ALC257 codec wakes (see Lenovo/Ubuntu bug reports), so it
        defaults to off.
      '';
    };

    flickerFix = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Disable Panel Self Refresh via amdgpu.dcdebugmask=0x10. Toggle this
        if you observe screen flicker or external-monitor freezes (a known
        DCN 3.1.4 issue on Rembrandt laptops).
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
      ++ lib.optionals cfg.flickerFix [ "amdgpu.dcdebugmask=0x10" ];

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
    # Redistributable firmware only (AMD/amdgpu + mediaTek blobs); avoiding
    # enableAllFirmware keeps the closure lean and licensing clean.
    hardware.enableRedistributableFirmware = true;

    # HDA codec power management (0 = disabled to avoid wake pops)
    boot.extraModprobeConfig = ''
      options snd_hda_intel power_save=${toString cfg.audioPowerSave} power_save_controller=Y
    '';
  };
}
