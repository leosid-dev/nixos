# modules/system/virtualisation/default.nix — KVM/QEMU virtualisation aspect.
#
# Composes libvirt platform, optional disk tooling, host-backed virtiofs shares,
# and optional performance/security features (KSM, swtpm, SPICE, VFIO).
# Single canonical options surface (AGENTS.md:6 — gaming/sound precedent).
# Gated by aspects.virtualisation.enable (default false).
{ lib, pkgs, ... }:
{
  options.aspects.virtualisation = {
    enable = lib.mkEnableOption "KVM/QEMU virtualisation (libvirt, virtiofs, virt-manager)";

    qemuPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.qemu_kvm;
      defaultText = lib.literalExpression "pkgs.qemu_kvm";
      description = ''
        QEMU package. qemu_kvm emulates only the host architecture (smaller);
        use pkgs.qemu for cross-architecture emulation.
      '';
    };

    virtManager = {
      enable = lib.mkEnableOption "virt-manager and virt-viewer GUI tools";
    };

    diskTool = {
      enable = lib.mkEnableOption "virt-disk convenience wrapper around qemu-img";
    };

    virtiofs = {
      enable = lib.mkEnableOption "virtiofs host-backed data shares";

      shares = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            hostPath = lib.mkOption {
              type = lib.types.str;
              description = "Host-backed share directory (absolute path).";
            };
            uid = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 1000;
              description = "Host UID that owns the share directory.";
            };
            gid = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 1000;
              description = "Host GID that owns the share directory.";
            };
          };
        });
        default = { };
        description = ''
          Host-backed data shares. Generates the host directory and a reviewed
          libvirt XML fragment under /etc/virtfs/<name>/; VM definitions and
          guest mount units remain operator-managed.
        '';
      };
    };

    ksm = {
      enable = lib.mkEnableOption ''
        Kernel Same-page Merging (KSM). Deduplicates identical memory pages between host
        and guests. Disabled by default because it consumes continuous CPU/battery and has
        side-channel implications on shared workstations.
      '';
    };

    swtpm = {
      enable = lib.mkEnableOption "emulated TPM 2.0 (swtpm) for guests requiring a TPM";
    };

    spiceUsbRedirection = {
      enable = lib.mkEnableOption ''
        SPICE USB device redirection helper (setuid). Disabled by default because it grants
        unprivileged users arbitrary USB device access.
      '';
    };

    vfio = {
      enable = lib.mkEnableOption ''
        VFIO device passthrough plumbing (eGPU / dedicated USB or NIC controllers).
        Not usable for the integrated GPU.
      '';

      ids = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "1022:14e0" "1022:14e1" ];
        description = ''
          PCI device IDs (vendor:device) to bind to vfio-pci at boot via
          vfio-pci.ids. Hardware-dependent operator choice: with an empty
          list the modules load but no device is bound, so passthrough
          stays inert until IDs are provided here.
        '';
      };
    };
  };

  imports = [
    ./platform.nix
    ./storage.nix
    ./shares.nix
    ./features.nix
  ];
}
