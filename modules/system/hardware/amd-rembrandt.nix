# modules/system/hardware/amd-rembrandt.nix — AMD Rembrandt SoC (Zen 3+ / RDNA2).
#
# Hardware: Ryzen 7 7735HS CPU + Radeon 680M iGPU.
{ lib, pkgs, ... }:
{
  # ── CPU Microcode & Driver Tuning ──────────────────────────────
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  boot.kernelModules = [
    "amd_energy"   # Energy counters monitoring per-core/package power
    "k10temp"      # CPU temperature monitoring driver
    "ideapad_laptop" # Lenovo WMI/ACPI hotkeys & thermal profile mode controls
    "amdgpu"
  ];

  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.kernelParams = [
    "amd_pstate=active"        # Driver: amd-pstate-epp
    "amdgpu.ppfeaturemask=0xffffffff" # Enable full OverDrive GPU power, fan, clock & voltage control
    "amdgpu.gpu_recovery=1"    # Enable automatic GPU recovery on hangs
  ];

  # ── iGPU & VAAPI Hardware Acceleration ────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # ── Firmware & Kernel Parameters ──────────────────────────────
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=10 power_save_controller=Y
    options snd_soc_sof_toplevel perf_debug=0
  '';

  # ── Power & Performance Management Tools ──────────────────────
  environment.systemPackages = with pkgs; [
    ryzenadj          # Power/TDP/temperature limit tuning for mobile AMD APUs
    corectrl          # GUI control for AMD GPU/CPU clock, power profiles, and fan curves
    lm_sensors        # Hardware monitoring utilities
  ];

  # Allow CoreCtrl to adjust hardware controls without manual password prompts
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if ((action.id == "org.corectrl.helper.init" ||
             action.id == "org.corectrl.helper me.init") &&
            subject.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    });
  '';
}
