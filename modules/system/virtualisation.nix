# modules/system/virtualisation.nix — KVM/QEMU virtualisation aspect.
#
# libvirt + virt-manager + virtiofs home sharing, tuned for laptop hosts.
# Generic: which directories to share (and where guests mount them) is host
# data, supplied via the `guests` option. Per-VM details (CPU pinning, XML)
# are imperative and documented in assets/virt/README.md.
# Gated by aspects.virtualisation.enable.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.virtualisation;

  # One-shot bootstrap for a guest: mounts the host's virtiofs share and
  # aligns the guest user's UID/GID with the host so file ownership is
  # seamless across the share. Run inside the guest after install.
  guestScript = name: g: pkgs.writeShellScriptBin "virtfs-setup-${name}" ''
    set -euo pipefail
    echo "Mounting host share ${g.hostPath} at ${g.target} (tag: home_share)"
    sudo mkdir -p ${g.target}
    cat <<'UNIT' | sudo tee /etc/systemd/system/home-share.mount >/dev/null
    [Unit]
    Description=virtiofs home share (tag home_share)

    [Mount]
    What=home_share
    Where=${g.target}
    Type=virtiofs
    Options=defaults,noatime

    [Install]
    WantedBy=multi-user.target
    UNIT
    sudo systemctl daemon-reload
    sudo systemctl enable --now home-share.mount
    # Align guest user with host UID/GID (no-op if already ${toString g.uid}:${toString g.gid})
    sudo groupmod -g ${toString g.gid} -o "$USER" 2>/dev/null || true
    sudo usermod -u ${toString g.uid} -o "$USER" 2>/dev/null || true
    echo "Done. Log out/in for the UID change to take full effect."
  '';

  # Optimised guest disk creator. qcow2 + falloc preallocation + 64k
  # clusters: near-raw performance, still resizable and snapshotable.
  # `virt-disk --raw <name> <size>` for zero-overhead raw instead.
  virt-disk = pkgs.writeShellScriptBin "virt-disk" ''
    set -euo pipefail
    fmt="qcow2"; opts="-o preallocation=falloc,cluster_size=64k"
    if [ "''${1:-}" = "--raw" ]; then fmt="raw"; opts=""; shift; fi
    [ $# -eq 2 ] || { echo "usage: virt-disk [--raw] <name> <size e.g. 64G>"; exit 1; }
    img="/var/lib/libvirt/images/$1.$fmt"
    sudo ${cfg.qemuPackage}/bin/qemu-img create -f "$fmt" $opts "$img" "$2"
    echo "created $img"
    echo "attach as virtio-blk with cache='none', io='native', discard='unmap' (+ iothread)"
  '';
in
{
  options.aspects.virtualisation = {
    enable = lib.mkEnableOption "KVM/QEMU virtualisation (libvirt, virtiofs)";

    qemuPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.qemu_kvm;
      defaultText = lib.literalExpression "pkgs.qemu_kvm";
      description = ''
        QEMU package. qemu_kvm emulates only the host architecture (smaller);
        use pkgs.qemu for cross-architecture emulation.
      '';
    };

    ksm = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Kernel Same-page Merging: deduplicates identical memory pages between
        host and guests. Near-zero cost, useful on RAM-constrained laptops.
      '';
    };

    hugepages = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Reserve 2M default hugepages for guest memory. Reduces TLB pressure
        but pins host RAM up front — off by default on a 16 GB laptop.
        Per-VM allocation is still possible via the VM XML (see runbook).
      '';
    };

    swtpm = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable swtpm so guests can use an emulated TPM 2.0.";
    };

    spiceUsbRedirection = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        SPICE USB redirection helper (setuid): lets unprivileged users pass
        USB devices into VMs. Note: grants users arbitrary USB device access.
      '';
    };

    vfio = {
      enable = lib.mkEnableOption ''
        VFIO device passthrough plumbing (eGPU / dedicated USB or NIC
        controllers). Not usable for the integrated GPU — it cannot be
        detached from the host. Bind devices via their sysfs driver_override
        before starting the VM (see runbook).
      '';
    };

    guests = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          hostPath = lib.mkOption {
            type = lib.types.str;
            description = "Host directory shared into this guest via virtiofs.";
          };
          target = lib.mkOption {
            type = lib.types.str;
            description = "Mount point of the share inside the guest.";
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
        };
      });
      default = { };
      description = ''
        Guest definitions (host data). Each entry generates a
        virtfs-setup-<name> bootstrap script that mounts the share and
        aligns the guest user's UID/GID with the host.
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
        swtpm.enable = cfg.swtpm;
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

    virtualisation.spiceUSBRedirection.enable = cfg.spiceUsbRedirection;
    programs.virt-manager.enable = true;

    hardware.ksm.enable = cfg.ksm;

    boot.kernelModules =
      lib.optionals cfg.vfio.enable [ "vfio_pci" "vfio_iommu_type1" ];
    boot.kernelParams =
      lib.optionals cfg.hugepages [ "default_hugepagesz=2M" ];

    environment.systemPackages =
      [ pkgs.virt-viewer virt-disk ]
      ++ lib.mapAttrsToList guestScript cfg.guests;
  };
}
