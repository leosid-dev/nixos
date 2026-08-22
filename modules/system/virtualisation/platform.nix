# modules/system/virtualisation/platform.nix — libvirtd, QEMU, virt-manager, virtiofsd.
# The libvirt default network and VM definitions remain operator-managed state.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.virtualisation;
in
{
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
        vhostUserPackages = lib.optionals cfg.virtiofs.enable [ pkgs.virtiofsd ];
      };
    };

    programs.virt-manager.enable = cfg.virtManager.enable;
    environment.systemPackages = lib.optionals cfg.virtManager.enable [ pkgs.virt-viewer ];

    security.polkit.enable = lib.mkDefault true;

    # Keep both the config generator and daemon off a missing libvirt mount.
    systemd.services.libvirtd-config.unitConfig.RequiresMountsFor = [ "/var/lib/libvirt" ];
    systemd.services.libvirtd.unitConfig.RequiresMountsFor = [ "/var/lib/libvirt" ];
  };
}
