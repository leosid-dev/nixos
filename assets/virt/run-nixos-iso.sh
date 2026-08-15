#!/usr/bin/env bash
# Boot the NixOS ISO in a throwaway KVM guest.
#
#   ./run-nixos-iso.sh [path/to/nixos.iso]
#
# Defaults: 4 vCPUs (host model), 4 GiB RAM, 32 GiB scratch disk
# (auto-created, reused on later runs), user-mode networking.
# Override: CPUS=8 MEM=8G DISK_SIZE=64G ./run-nixos-iso.sh
#
# To boot from the installed disk afterwards, drop the -cdrom line below
# (or change -boot order=d to order=c).
set -euo pipefail

iso="${1:-./nixos.iso}"
[ -f "$iso" ] || { echo "ISO not found: $iso" >&2; exit 1; }

cpus="${CPUS:-4}"
mem="${MEM:-4G}"
disk="${DISK:-nixos-vm.qcow2}"

# Scratch disk, same optimised layout as virt-disk (falloc + 64k clusters).
[ -f "$disk" ] || qemu-img create -f qcow2 -o preallocation=falloc,cluster_size=64k "$disk" "${DISK_SIZE:-32G}"

# UEFI where the host exposes OVMF (our libvirtd links it here);
# SeaBIOS fallback — the NixOS ISO boots either way.
firmware=()
for ovmf in /run/libvirt/nix-ovmf/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE.fd; do
  if [ -r "$ovmf" ]; then
    firmware=(-bios "$ovmf")
    break
  fi
done

exec qemu-system-x86_64 \
  -enable-kvm \
  -cpu host -smp "$cpus" -m "$mem" \
  "${firmware[@]}" \
  -drive file="$disk",if=virtio,format=qcow2,cache=none,discard=unmap \
  -cdrom "$iso" \
  -boot order=d \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -display gtk
