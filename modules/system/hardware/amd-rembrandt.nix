# modules/system/hardware/amd-rembrandt.nix — AMD Rembrandt SoC (Zen 3+ / RDNA2).
#
# Covers: Ryzen 7 7735HS CPU + Radeon 680M iGPU.
{ lib, pkgs, ... }:
{
  # ── CPU & Microcode ─────────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  boot.kernelParams = [
    "amd_pstate=active" # AMD P-State EPP driver (efficient frequency scaling)
  ];

  # ── iGPU & Hardware Acceleration (RDNA2 — Radeon 680M) ────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmpackages-runtime.amdgpu-pro-unfree # Optional VAAPI/OpenCL runtimes if needed
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  boot.kernelModules = [ "amdgpu" ];
  boot.initrd.kernelModules = [ "amdgpu" ];

  # ── Firmware ────────────────────────────────────────────────────
  hardware.enableRedistributableFirmware = true;

  # ── Audio & Audio DSP ACPI / Kernel parameters ──────────────────
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=1 power_save_controller=Y
    options snd_soc_sof_toplevel perf_debug=0
  '';
}
