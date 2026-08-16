# Virtualisation runbook — KVM/QEMU + virtiofs home sharing

Operator notes for the `aspects.virtualisation` aspect
(`modules/system/virtualisation/`). Everything here is imperative by
nature (VMs are libvirt state, not Nix state); the module provides the
platform, tuned defaults, and reviewed integration artifacts.

Target: Ubuntu 22.04/24.04 LTS work VMs on the ThinkBook (Ryzen 7 7735HS,
Radeon 680M iGPU, 16 GB), with a dedicated host-backed home directory at
`/var/lib/libvirt/homes/ubuntu` (on the `vmdata` partition) mounted inside
the guest at `/home/sid`, and linked on the host at `/home/sid/VMs/ubuntu`.

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
  (`~/.cache/nixos-vm/nixos-vm.qcow2`, auto-created with metadata preallocation;
  delete it for a fresh start). Override with `CPUS=8 MEM=8G DISK_SIZE=64G`,
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
| virtiofsd | Rust vhost-user backend, auto-discovered via `/var/lib/qemu/vhost-user/` |
| virt-manager | GUI for VM lifecycle |
| swtpm | optional emulated TPM 2.0 (gated via `aspects.virtualisation.swtpm.enable`, default off) |
| SPICE USB redirection | optional USB passthrough (gated via `aspects.virtualisation.spiceUsbRedirection.enable`, default off) |
| KSM | optional memory deduplication (gated via `aspects.virtualisation.ksm.enable`, default off on laptops) |
| `virt-disk` | creates sparse qcow2 or raw guest disks (validates name & size arguments) |
| `/etc/virtfs/<guest>/` | reviewed XML fragments (`share.xml`, `memory-backing.xml`) & portable guest setup script (`setup-guest.sh`) |

## 1. Create the guest disk (sparse + resizable)

```bash
virt-disk ubuntu 64G          # qcow2, preallocation=metadata, cluster_size=64k
virt-disk --raw ubuntu 64G    # alternative: raw (zero overhead, no snapshots)
```

- `preallocation=metadata` allocates cluster metadata up front while
  preserving sparse growth — guest images only consume host disk space as
  data is written.
- Resize later (online with virtio-blk):
  `sudo qemu-img resize /var/lib/libvirt/images/ubuntu.qcow2 +16G`,
  then inside the guest: `sudo resize2fs /dev/vda1`.
- `fstrim -av` inside the guest returns freed space to the host file
  (requires `discard='unmap'` below).

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

## 3. Dedicated guest home via virtiofs

The module generates reviewed XML fragments for each guest defined in
`aspects.virtualisation.guests.<name>` under `/etc/virtfs/<name>/`.

Add the filesystem share into the VM's `<devices>` section (from
`/etc/virtfs/ubuntu/share.xml`):

```xml
<filesystem type="mount" accessmode="passthrough">
  <driver type="virtiofs" queue="1024"/>
  <source dir="/var/lib/libvirt/homes/ubuntu"/>
  <target dir="home_share"/>
</filesystem>
```

Add the shared memory backing directly under `<domain>` (from
`/etc/virtfs/ubuntu/memory-backing.xml`):

```xml
<memoryBacking>
  <source type="memfd"/>
  <access mode="shared"/>
</memoryBacking>
```

virtiofs provides coherent, inotify-compatible, file-locking shared storage
backed by the host's `vmdata` partition at `/var/lib/libvirt/homes/ubuntu`.

> **Important:** Libvirt VM snapshots do **NOT** include virtiofs contents.
> Back up `/var/lib/libvirt/homes/ubuntu` independently from the guest image.

## 4. Inside the guest (after Ubuntu install)

Run the portable guest setup script generated by NixOS under
`/etc/virtfs/ubuntu/setup-guest.sh`:

```bash
# Pipe from host to guest over SSH:
cat /etc/virtfs/ubuntu/setup-guest.sh | ssh ubuntu@<vm-ip> 'sudo sh -s'
```

The script:
- Installs and enables `/etc/systemd/system/home-sid.mount` mounting `home_share` at `/home/sid`.
- Aligns the guest user's UID/GID to `1000:1000`.
- Requires only standard POSIX `/bin/sh` and systemd (no Nix-store dependencies).

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

Per-session hugepages (avoids permanent host RAM reservation on a 16 GB laptop):

```bash
# Allocate 4 GB of 2M hugepages dynamically when needed:
sudo virsh allocpages 2048 2M
```

and add to the domain XML:

```xml
<memoryBacking>
  <hugepages/>
</memoryBacking>
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

VM disks live in `/var/lib/libvirt/images/` and guest homes in
`/var/lib/libvirt/homes/` — both on the dedicated `vmdata` partition.
Deleting a VM = delete its image and backing directory.
