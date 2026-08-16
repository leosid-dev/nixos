# modules/system/virtualisation/platform.nix — libvirtd, QEMU, virt-manager, virtiofsd.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.virtualisation;
in
{
  options.aspects.virtualisation = {
    qemuPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.qemu_kvm;
      defaultText = lib.literalExpression "pkgs.qemu_kvm";
      description = ''
        QEMU package. qemu_kvm emulates only the host architecture (smaller);
        use pkgs.qemu for cross-architecture emulation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      # Clean ACPI shutdown of guests when the host shuts down.
      onShutdown = "shutdown";
      qemu = {
        package = cfg.qemuPackage;
        # virtiofsd (Rust) — its vhost-user JSON descriptor is linked into
        # /var/lib/qemu/vhost-user by the libvirtd module, so libvirt
        # auto-discovers it for <filesystem type="mount"> + virtiofs.
        vhostUserPackages = [ pkgs.virtiofsd ];
        # QEMU runs as root by default; don't chown disk images behind our
        # back (images are created root-owned by virt-disk anyway).
        verbatimConfig = ''
          remember_owner = 0
        '';
      };
    };

    programs.virt-manager.enable = true;
    environment.systemPackages = [ pkgs.virt-viewer ];
  };
}
