#!/usr/bin/env bash
# Boot the NixOS ISO in a throwaway KVM guest.
#
#   ./run-nixos-iso.sh [path/to/nixos.iso]
#
# Defaults: 4 vCPUs (host model), 4 GiB RAM, 32 GiB scratch disk
# (auto-created, reused on later runs), user-mode networking.
# Override: CPUS=8 MEM=8G DISK_SIZE=64G QEMU=/path/to/qemu-system-x86_64
#
# To boot from the installed disk afterwards, drop the -cdrom line below
# (or change -boot order=d to order=c).
set -euo pipefail

iso="${1:-./nixos.iso}"
[ -f "$iso" ] || { echo "ISO not found: $iso" >&2; exit 1; }

qemu="${QEMU:-qemu-system-x86_64}"
command -v "$qemu" >/dev/null || {
  echo "error: $qemu not on PATH (Ubuntu: sudo apt install qemu-system-x86)" >&2
  exit 1
}
command -v qemu-img >/dev/null || {
  echo "error: qemu-img not on PATH (Ubuntu: sudo apt install qemu-utils)" >&2
  exit 1
}
[ -w /dev/kvm ] || {
  echo "error: no access to /dev/kvm (Ubuntu: sudo usermod -aG kvm \$USER, then re-login)" >&2
  exit 1
}

# User-mode networking needs slirp compiled in; some builds omit it.
"$qemu" -netdev help 2>&1 | grep -qw user || {
  echo "error: this qemu lacks user-mode networking (-netdev user)." >&2
  echo "Ubuntu: sudo apt install qemu-system-x86 (the distro build includes slirp)." >&2
  echo "Or point QEMU= at a full build (e.g. nixpkgs qemu_full)." >&2
  exit 1
}

cpus="${CPUS:-4}"
mem="${MEM:-4G}"
disk="${DISK:-nixos-vm.qcow2}"

# Scratch disk, same optimised layout as virt-disk (falloc + 64k clusters).
[ -f "$disk" ] || qemu-img create -f qcow2 -o preallocation=falloc,cluster_size=64k "$disk" "${DISK_SIZE:-32G}"

# UEFI where OVMF is available; SeaBIOS fallback — the ISO boots either way.
firmware=()
for ovmf in /usr/share/OVMF/OVMF_CODE.fd /run/libvirt/nix-ovmf/OVMF_CODE.fd; do
  if [ -r "$ovmf" ]; then
    firmware=(-bios "$ovmf")
    break
  fi
done

# Prefer a graphical display that is actually compiled in.
display=()
for d in gtk sdl curses; do
  if "$qemu" -display help 2>&1 | grep -qw "$d"; then
    display=(-display "$d")
    break
  fi
done

exec "$qemu" \
  -enable-kvm \
  -cpu host -smp "$cpus" -m "$mem" \
  "${firmware[@]}" \
  -drive file="$disk",if=virtio,format=qcow2,cache=none,discard=unmap \
  -cdrom "$iso" \
  -boot order=d \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  "${display[@]}"
