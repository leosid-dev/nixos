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

# Outbound-only user networking. Prefer slirp (-netdev user); fall back to
# passt, which ships with newer QEMU builds that omit slirp.
# Exact-line match: -w would falsely match 'vhost-user'.
netdev=()
if "$qemu" -netdev help 2>&1 | grep -qx user; then
  netdev=(-netdev user,id=net0)
elif "$qemu" -netdev help 2>&1 | grep -qx passt; then
  command -v passt >/dev/null || {
    echo "error: qemu supports passt but the 'passt' binary is not on PATH." >&2
    exit 1
  }
  netdev=(-netdev passt,id=net0)
else
  echo "error: this qemu has neither 'user' nor 'passt' networking compiled in." >&2
  echo "Ubuntu: sudo apt install qemu-system-x86 (distro build includes slirp)." >&2
  exit 1
fi

cpus="${CPUS:-4}"
mem="${MEM:-4G}"
disk="${DISK:-./nixvm/nixos-vm.qcow2}"

# Scratch disk, same optimised layout as virt-disk (falloc + 64k clusters).
if [ ! -f "$disk" ]; then
  mkdir -p "$(dirname "$disk")"
  qemu-img create -f qcow2 -o preallocation=falloc,cluster_size=64k "$disk" "${DISK_SIZE:-32G}"
fi

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
  if "$qemu" -display help 2>&1 | grep -qx "$d"; then
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
  "${netdev[@]}" -device virtio-net-pci,netdev=net0 \
  "${display[@]}"
