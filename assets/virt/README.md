# Virtualisation runbook — KVM/QEMU + virtiofs home sharing

Operator notes for the `aspects.virtualisation` aspect
(`modules/system/virtualisation.nix`). Everything here is imperative by
nature (VMs are libvirt state, not Nix state); the module provides the
platform, tuned defaults, and helper scripts.

Target: Ubuntu 22.04/24.04 LTS work VMs on the ThinkBook (Ryzen 7 7735HS,
Radeon 680M iGPU, 16 GB), with the host's `/home/sid` mounted inside the
guest at the same path.

## Quick spin of the NixOS ISO

`assets/virt/run-nixos-iso.sh` boots an ISO in a throwaway KVM guest —
no libvirt involved. Works on any KVM host (Ubuntu 22.04, NixOS, ...);
it probes the QEMU binary for slirp/display support and fails with
actionable hints instead of cryptic errors.

```bash
./assets/virt/run-nixos-iso.sh ./nixos.iso
```

- Host prerequisites (Ubuntu 22.04):
  `sudo apt install qemu-system-x86 qemu-utils ovmf` and KVM access
  (`sudo usermod -aG kvm $USER`, then re-login). The distro QEMU build
  includes slirp, so user-mode networking works out of the box.
- Defaults: 4 vCPUs (host model), 4 GiB RAM, 32 GiB scratch disk
  (`/media/sid/nixvm/nixos-vm.qcow2`, auto-created and reused; delete it
  for a fresh start). Override with `CPUS=8 MEM=8G DISK_SIZE=64G`,
  `DISK=/path/to/disk.qcow2`, or `QEMU=` to point at a specific
  `qemu-system-x86_64` binary.
- Networking is outbound-only user-mode: slirp (`-netdev user`) when the
  QEMU build includes it, else `passt` (ships with newer builds). Either
  way, outbound works (git clone / `nix flake` fetch inside the guest),
  inbound does not.
- Boots UEFI via OVMF when present (`/usr/share/OVMF/` on Ubuntu,
  `/run/libvirt/nix-ovmf/` on NixOS), falling back to SeaBIOS.
- To boot from the installed disk afterwards, drop the `-cdrom` line in
  the script (or change `-boot order=d` to `order=c`).

## What the aspect gives you

| Piece | Detail |
|---|---|
| libvirtd | root-mode QEMU, `onShutdown = "shutdown"` (clean ACPI stop of guests) |
| QEMU | `qemu_kvm` (host-arch only, virgl/Venus 3D built in); OVMF UEFI firmware auto-listed from `/run/libvirt/nix-ovmf/` |
| virtiofsd | Rust vhost-user backend, auto-discovered via `/var/lib/qemu/vhost-user/50-virtiofsd.json` |
| virt-manager | GUI for VM lifecycle |
| swtpm | emulated TPM 2.0 for guests |
| SPICE USB redirection | pass USB devices into VMs (note: grants users arbitrary USB access) |
| KSM | on — dedups identical host/guest memory pages |
| Hugepages | off by default (16 GB laptop); per-VM allocation still possible |
| `virt-disk` | creates optimised guest disks (see below) |
| `virtfs-setup-<guest>` | guest-side bootstrap per `aspects.virtualisation.guests` entry |

## 1. Create the guest disk (minimal overhead + resizable)

```bash
virt-disk ubuntu 64G          # qcow2, preallocation=falloc, cluster_size=64k
virt-disk --raw ubuntu 64G    # alternative: raw (zero translation, no snapshots)
```

- `preallocation=falloc` reserves space up front → within ~1–3% of raw,
  while keeping snapshots and on-demand growth.
- Resize later (online with virtio-blk):
  `sudo qemu-img resize /var/lib/libvirt/images/ubuntu.qcow2 +16G`,
  then inside the guest: `sudo resize2fs /dev/vda1`.
- `fstrim -av` inside the guest returns freed space to the host file
  (requires `discard='unmap'` below).

**Advanced:** an LVM logical volume as the guest disk is the true
zero-overhead option (real block device, `lvextend`-resizable) — at the
cost of thin provisioning and snapshot ergonomics.

## 2. Create the VM (virt-manager)

1. New VM → install from the Ubuntu LTS ISO.
2. Firmware: **UEFI** (auto-listed from `/run/libvirt/nix-ovmf/`).
3. Disk: attach the image created above as **virtio-blk**.
4. Network: default NAT (`virbr0`) is fine; guest gets internet out of the box.
5. CPU: set model to **host-passthrough** (Copy host CPU configuration).

Then edit the XML (`virsh edit ubuntu` or virt-manager → XML) for the
block-layer tuning:

```xml
<disk type="file" device="disk">
  <driver name="qemu" type="qcow2" cache="none" io="native" discard="unmap"/>
  <source file="/var/lib/libvirt/images/ubuntu.qcow2"/>
  <target dev="vda" bus="virtio"/>
  <iothread>1</iothread>
</disk>
```

and declare the iothread:

```xml
<iothreads>1</iothreads>
```

## 3. Share the host home (virtiofs)

Add to the VM's `<devices>` section (the tag `home_share` must match the
guest mount unit's `What=`):

```xml
<filesystem type="mount" accessmode="passthrough">
  <driver type="virtiofs"/>
  <source dir="/home/sid"/>
  <target dir="home_share"/>
</filesystem>
```

virtiofs requires **shared memory** — QEMU refuses to start the device
without it. Add this top-level stanza (anywhere directly under
`<domain>`):

```xml
<memoryBacking>
  <source type="memfd"/>
  <access mode="shared"/>
</memoryBacking>
```

virtiofs over 9p: coherent, DAX-capable, supports inotify/file locks —
dev tools (watchers, LSP, git) behave normally on the share.

## 4. Inside the guest (after Ubuntu install)

```bash
virtfs-setup-ubuntu
```

The generated script (from `aspects.virtualisation.guests.ubuntu`):
- installs + enables a systemd mount unit named after the mount point
  (systemd requires the `.mount` filename to match the escaped
  `Where=` path: `/home/sid` → `home-sid.mount`) that mounts the share,
- aligns the guest user's UID/GID to the host (1000:1000) so file
  ownership is seamless across the share. Log out/in afterwards.

Then move dotfiles onto the share or symlink `~` pieces as preferred.
Ubuntu's first user is created as UID 1000, so the alignment is usually a
no-op.

## 5. GPU: virtio-gpu + Venus (not passthrough)

The Radeon 680M is an **iGPU** — it cannot be detached from the host, so
classic VFIO GPU passthrough does not apply. Use:

- Video model: **virtio** (virtio-gpu) with 3D acceleration enabled.
- Guest Vulkan runs on the host's real driver via **Venus** (`vn` driver,
  ships in Ubuntu 24.04's Mesa). Verify inside the guest:
  `sudo apt install vulkan-tools && vulkaninfo | grep -i venus`.
- Works for Wayland sessions and XWayland apps.

If you later attach an **eGPU** or want to pass through a dedicated USB/NIC
controller: enable `aspects.virtualisation.vfio.enable = true` (loads
`vfio_pci` + `vfio_iommu_type1`), then bind the device before starting the
VM:

```bash
echo "1022 1234" | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id   # vendor device
# or, for a specific device:
echo 0000:01:00.0 | sudo tee /sys/bus/pci/devices/0000:01:00.0/driver/unbind
echo vfio-pci | sudo tee /sys/bus/pci/devices/0000:01:00.0/driver_override
echo 0000:01:00.0 | sudo tee /sys/bus/pci/drivers/vfio-pci/bind
```

## 6. Optional tuning for dedicated work sessions

Hugepages (per VM, avoids host-wide reservation):

```xml
<memoryBacking>
  <hugepages/>
</memoryBacking>
```

plus host-side reservation before booting the VM:

```bash
echo 4096 | sudo tee /proc/sys/vm/nr_hugepages   # 4096 * 2M = 8G
```

vCPU pinning (keep cores 0–1 for the host):

```xml
<vcpu placement="static">8</vcpu>
<cputune>
  <vcpupin vcpu="0" cpuset="2"/>
  <vcpupin vcpu="1" cpuset="3"/>
  <!-- ... -->
</cputune>
```

## Clean slate

VM disks are fresh images in `/var/lib/libvirt/images/` — no existing
partitions or OSes are reused. Deleting a VM = delete its image; nothing
else to clean up.
