# modules/system/virtualisation/storage.nix — Guest image creation tool (virt-disk).
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.virtualisation;

  # Optimised guest disk creator.
  # - qcow2 default: preallocation=metadata + 64k clusters (preserves sparse growth
  #   while avoiding metadata allocation latency during runtime).
  # - --raw flag: raw image creation for zero-overhead block translation.
  # Validates image name and size arguments with shell-safe patterns.
  virt-disk = pkgs.writeShellScriptBin "virt-disk" ''
    set -euo pipefail

    fmt="qcow2"
    raw_mode=0
    if [ "''${1:-}" = "--raw" ]; then
      fmt="raw"
      raw_mode=1
      shift
    fi

    if [ "''${1:-}" = "--help" ] || [ "''${1:-}" = "-h" ]; then
      echo "usage: virt-disk [--raw] <name> <size e.g. 64G>" >&2
      echo "  --raw   create raw image (default: qcow2 sparse)" >&2
      exit 0
    fi

    if [ $# -ne 2 ]; then
      echo "usage: virt-disk [--raw] <name> <size e.g. 64G>" >&2
      exit 1
    fi

    name="$1"
    size="$2"

    # Validate name: must start with alphanumeric, then alnum/dot/underscore/dash
    # Rejects leading dot/dash and bare ".." traversal.
    if ! echo "$name" | grep -Eq '^[a-zA-Z0-9][a-zA-Z0-9._-]*$'; then
      echo "error: invalid image name '$name'. Use only [a-zA-Z0-9._-], starting with alphanumeric." >&2
      exit 1
    fi

    # Validate size format (e.g. 10G, 64G, 512M)
    if ! echo "$size" | grep -Eq '^[0-9]+[KMGT]$'; then
      echo "error: invalid size '$size'. Format must be digits followed by K, M, G, or T (e.g. 64G)." >&2
      exit 1
    fi

    img="/var/lib/libvirt/images/$name.$fmt"

    if [ -e "$img" ]; then
      echo "error: image '$img' already exists." >&2
      exit 1
    fi

    sudo mkdir -p /var/lib/libvirt/images
    if [ "$raw_mode" -eq 1 ]; then
      sudo ${cfg.qemuPackage}/bin/qemu-img create -f raw "$img" "$size"
    else
      sudo ${cfg.qemuPackage}/bin/qemu-img create -f qcow2 -o preallocation=metadata,cluster_size=64k "$img" "$size"
    fi

    # Set the at-rest owner. libvirtd runs QEMU as root here (runAsRoot
    # default), and its dynamic ownership hands the image to root while a
    # domain runs and restores this owner when it stops. This owner is also
    # what unprivileged mode (qemu.runAsRoot = false) would require.
    sudo chown qemu-libvirtd:qemu-libvirtd "$img"
    sudo chmod 0600 "$img"

    echo "Created $img ($fmt, $size)"
    echo "Attach as virtio-blk with cache='none', io='native', discard='unmap' (+ 1 IOThread)."
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.diskTool.enable) {
    # qemu-img comes from cfg.qemuPackage inside the script; no separate
    # qemu-utils copy in the profile (single canonical source).
    environment.systemPackages = [ virt-disk ];
  };
}
