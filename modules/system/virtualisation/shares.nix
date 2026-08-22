# modules/system/virtualisation/shares.nix — Host-backed virtiofs data shares.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.virtualisation;

  tagFor = name: "${name}_share";

  shareXml = name: share: pkgs.writeText "virtfs-${name}-share.xml" ''
    <!-- Domain XML fragment: place inside <devices> -->
    <filesystem type="mount" accessmode="passthrough">
      <driver type="virtiofs" queue="1024"/>
      <source dir="${lib.escapeXML share.hostPath}"/>
      <target dir="${tagFor name}"/>
    </filesystem>
  '';

  memoryBackingXml = name: pkgs.writeText "virtfs-${name}-memory-backing.xml" ''
    <!-- Merge this into the domain's existing <memoryBacking>, if needed. -->
    <memoryBacking>
      <source type="memfd"/>
      <access mode="shared"/>
    </memoryBacking>
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.virtiofs.enable) {
    assertions = lib.flatten (lib.mapAttrsToList (name: share: [
      {
        assertion = builtins.match "^[A-Za-z0-9][A-Za-z0-9_-]*$" name != null;
        message = "aspects.virtualisation.virtiofs.shares.${name} must use only alphanumeric characters, underscores, and dashes, starting with alphanumeric";
      }
      {
        assertion = lib.hasPrefix "/" share.hostPath && share.hostPath != "/";
        message = "aspects.virtualisation.virtiofs.shares.${name}.hostPath must be an absolute non-root path: ${share.hostPath}";
      }
      {
        assertion = share.uid >= 0 && share.gid >= 0;
        message = "aspects.virtualisation.virtiofs.shares.${name} uid and gid must be non-negative";
      }
    ]) cfg.virtiofs.shares);

    # Only the share root is managed. Do not recursively rewrite permissions
    # inside a live tree owned by the guest.
    systemd.tmpfiles.rules = [
      "d /var/lib/libvirt 0755 root root -"
      "d /var/lib/libvirt/images 0755 root root -"
      "d /var/lib/libvirt/shares 0755 root root -"
    ] ++ lib.concatLists (lib.mapAttrsToList (name: share: [
      "d ${share.hostPath} 0750 ${toString share.uid} ${toString share.gid} -"
    ]) cfg.virtiofs.shares);

    # VM definitions and guest mount units are intentionally not generated:
    # they are mutable libvirt/guest state and must be configured together.
    environment.etc = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (name: share: [
      {
        name = "virtfs/${name}/share.xml";
        value = { source = shareXml name share; };
      }
      {
        name = "virtfs/${name}/memory-backing.xml";
        value = { source = memoryBackingXml name; };
      }
    ]) cfg.virtiofs.shares));
  };
}
