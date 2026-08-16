# modules/system/virtualisation/shares.nix — Dedicated host-backed virtiofs shares and guest artifacts.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.virtualisation;

  # Reviewed XML fragment for domain <devices> filesystem passthrough
  shareXml = name: g: pkgs.writeText "virtfs-${name}-share.xml" ''
    <!-- Domain XML fragment: place inside <devices> -->
    <filesystem type="mount" accessmode="passthrough">
      <driver type="virtiofs" queue="1024"/>
      <source dir="${g.hostPath}"/>
      <target dir="home_share"/>
    </filesystem>
  '';

  # Reviewed XML fragment for domain <domain> memoryBacking shared memfd
  memBackingXml = name: g: pkgs.writeText "virtfs-${name}-memory-backing.xml" ''
    <!-- Domain XML fragment: place inside <domain> -->
    <memoryBacking>
      <source type="memfd"/>
      <access mode="shared"/>
    </memoryBacking>
  '';

  # Portable guest setup script (POSIX sh): installs systemd mount unit and aligns UID/GID.
  # Can be piped over SSH or copied manually: cat /etc/virtfs/<name>/setup-guest.sh | ssh guest 'sudo sh -s'
  guestSetupScript = name: g:
    pkgs.writeText "virtfs-${name}-setup-guest.sh" ''
      #!/bin/sh
      set -eu

      TARGET="${g.target}"
      UID_TARGET="${toString g.uid}"
      GID_TARGET="${toString g.gid}"

      echo "==> Setting up virtiofs mount at $TARGET (tag: home_share)"
      mkdir -p "$TARGET"

      # Generate systemd mount unit
      UNIT_NAME="$(systemd-escape -p --suffix=mount "$TARGET")"
      cat <<EOF > "/etc/systemd/system/$UNIT_NAME"
      [Unit]
      Description=virtiofs home share (tag: home_share)
      After=network.target

      [Mount]
      What=home_share
      Where=$TARGET
      Type=virtiofs
      Options=defaults,noatime

      [Install]
      WantedBy=multi-user.target
      EOF

      systemctl daemon-reload
      systemctl enable --now "$UNIT_NAME"

      # Align current non-root user UID/GID if needed
      TARGET_USER="''${SUDO_USER:-$USER}"
      if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
        CURRENT_UID="$(id -u "$TARGET_USER" 2>/dev/null || echo "")"
        CURRENT_GID="$(id -g "$TARGET_USER" 2>/dev/null || echo "")"

        if [ "$CURRENT_GID" != "$GID_TARGET" ]; then
          groupmod -g "$GID_TARGET" -o "$TARGET_USER" 2>/dev/null || true
        fi
        if [ "$CURRENT_UID" != "$UID_TARGET" ]; then
          usermod -u "$UID_TARGET" -o "$TARGET_USER" 2>/dev/null || true
        fi
      fi

      echo "==> Done. virtiofs share mounted at $TARGET."
      echo "==> Note: libvirt VM snapshots do NOT include virtiofs contents. Back up $TARGET independently."
    '';
in
{
  options.aspects.virtualisation = {
    guests = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          hostPath = lib.mkOption {
            type = lib.types.str;
            description = "Host-backed backing directory shared into the guest via virtiofs.";
          };
          target = lib.mkOption {
            type = lib.types.str;
            description = "Mount point inside the guest.";
          };
          uid = lib.mkOption {
            type = lib.types.int;
            default = 1000;
            description = "Host UID the guest user is aligned to.";
          };
          gid = lib.mkOption {
            type = lib.types.int;
            default = 1000;
            description = "Host GID the guest user is aligned to.";
          };
          hostLink = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional host-side convenience symlink pointing to hostPath.";
          };
        };
      });
      default = { };
      description = ''
        Guest definitions (host data). Generates declarative directories,
        reviewed libvirt XML fragments, and portable guest setup scripts under /etc/virtfs/<name>/.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Declarative host directory creation with explicit ownership and permissions
    systemd.tmpfiles.rules = [
      "d /var/lib/libvirt 0755 root root -"
      "d /var/lib/libvirt/images 0755 root root -"
      "d /var/lib/libvirt/homes 0755 root root -"
    ] ++ lib.concatLists (lib.mapAttrsToList (name: g: [
      "d ${g.hostPath} 0750 ${toString g.uid} ${toString g.gid} -"
    ] ++ lib.optional (g.hostLink != null) "L+ ${g.hostLink} - ${toString g.uid} ${toString g.gid} - ${g.hostPath}"
    ) cfg.guests);

    # Export reviewed XML fragments and portable guest setup scripts under /etc/virtfs/<name>/
    environment.etc = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (name: g: [
      {
        name = "virtfs/${name}/share.xml";
        value = { source = shareXml name g; };
      }
      {
        name = "virtfs/${name}/memory-backing.xml";
        value = { source = memBackingXml name g; };
      }
      {
        name = "virtfs/${name}/setup-guest.sh";
        value = {
          source = guestSetupScript name g;
          mode = "0755";
        };
      }
    ]) cfg.guests));
  };
}
