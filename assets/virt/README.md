# Virtualisation runbook - KVM/QEMU and virtiofs data sharing

Operator notes for the `aspects.virtualisation` aspect
(`modules/system/virtualisation/`). NixOS manages the host platform and
share directories. VM definitions, libvirt networks, and guest mount units
remain mutable operator-managed state.

The ThinkBook configuration provides an Ubuntu work VM with:

- VM images under `/var/lib/libvirt/images/`
- A host-backed data share at `/var/lib/libvirt/shares/ubuntu`
- The same share mounted inside the guest at `/mnt/ubuntu-share`
- The virtiofs tag `ubuntu_share`

The share is intentionally not the guest home directory. Keep guest dotfiles,
caches, locks, and machine-specific state on the guest filesystem.

## 1. Apply the Host Configuration

The host enables libvirt, QEMU, virtiofsd, and virt-manager through
`hosts/thinkbook/default.nix`:

```bash
sudo nixos-rebuild switch --flake /home/sid/nixos#thinkbook
```

Verify the platform and data filesystem:

```bash
systemctl status libvirtd
virsh version
findmnt /var/lib/libvirt
```

The host creates the share directory declaratively:

```bash
ls -ld /var/lib/libvirt/shares/ubuntu
```

The directory is owned by UID/GID `1000:1000` and is not recursively
rewritten during later activations.

## 2. Activate the Default Libvirt Network

The default NAT network is libvirt state, not a NixOS domain definition. Check
its status:

```bash
sudo virsh net-list --all
```

Start and persist it if necessary:

```bash
sudo virsh net-start default
sudo virsh net-autostart default
```

The guest should use the default NAT network, normally exposed as `virbr0`.
Verify guest connectivity after the VM is running:

```bash
ip addr
ip route
ping -c 3 1.1.1.1
```

## 3. Create the Guest Disk

`virt-disk` is a convenience wrapper around `qemu-img`:

```bash
virt-disk ubuntu 64G
```

This creates a sparse qcow2 image with metadata preallocation:

```text
/var/lib/libvirt/images/ubuntu.qcow2
```

For a raw image instead:

```bash
virt-disk --raw ubuntu 64G
```

This creates `/var/lib/libvirt/images/ubuntu.raw`. Raw images do not provide
qcow2 internal snapshots; external/libvirt snapshot support depends on the
storage and snapshot mode.

The helper refuses invalid names and existing images:

```bash
virt-disk --help
```

## 4. Create the VM

Open virt-manager:

```bash
virt-manager
```

Create a VM from the Ubuntu 22.04 or 24.04 ISO:

1. Select UEFI firmware when available.
2. Attach the qcow2 or raw image from `/var/lib/libvirt/images/`.
3. Use a virtio disk bus.
4. Attach the default NAT network.
5. Use `host-passthrough` CPU mode when the VM will remain on this host.
6. Enable virtio-gpu 3D acceleration if using a graphical guest.

For the qcow2 image, the optional disk tuning is:

```xml
<disk type="file" device="disk">
  <driver name="qemu" type="qcow2"
          cache="none" io="native" discard="unmap"/>
  <source file="/var/lib/libvirt/images/ubuntu.qcow2"/>
  <target dev="vda" bus="virtio"/>
  <iothread>1</iothread>
</disk>
```

Declare the thread at domain level:

```xml
<iothreads>1</iothreads>
```

For the raw image, change the driver type and source path:

```xml
<driver name="qemu" type="raw"
        cache="none" io="native" discard="unmap"/>
<source file="/var/lib/libvirt/images/ubuntu.raw"/>
```

Edit persistent domain XML with:

```bash
virsh edit ubuntu
```

## 5. Add the Virtiofs Data Share

The host generates the reviewed share fragment from the configured
`virtiofs.shares.ubuntu` definition:

```bash
cat /etc/virtfs/ubuntu/share.xml
```

Add its `<filesystem>` element inside the VM's `<devices>` section:

```xml
<filesystem type="mount" accessmode="passthrough">
  <driver type="virtiofs" queue="1024"/>
  <source dir="/var/lib/libvirt/shares/ubuntu"/>
  <target dir="ubuntu_share"/>
</filesystem>
```

The tag is generated as `<share-name>_share`. It must match the `What=` value
in the guest mount unit. The host path and guest target are independent:

```text
Host:  /var/lib/libvirt/shares/ubuntu
Guest: /mnt/ubuntu-share
Tag:   ubuntu_share
```

Virtiofs contents are not included in libvirt VM snapshots. Back up the host
share independently from the guest disk.

## 6. Configure the Guest Mount

Install Ubuntu normally and create the intended guest user during installation.
No host-side script changes guest users or their UID/GID. The share directory
is owned by `1000:1000`, so the guest account that uses the share should have
matching numeric IDs.

Inside the guest, create the mount unit as root:

```bash
sudo systemd-escape -p --suffix=mount /mnt/ubuntu-share
```

Use the resulting unit name when creating
`/etc/systemd/system/<unit-name>.mount`:

```ini
[Unit]
Description=Ubuntu virtiofs data share
Before=systemd-user-sessions.service multi-user.target

[Mount]
What=ubuntu_share
Where=/mnt/ubuntu-share
Type=virtiofs
Options=defaults,noatime

[Install]
WantedBy=multi-user.target
```

Enable it:

```bash
sudo mkdir -p /mnt/ubuntu-share
sudo systemctl daemon-reload
sudo systemctl enable --now <unit-name>.mount
```

Verify the mount:

```bash
findmnt /mnt/ubuntu-share
```

Test both directions:

```bash
touch /mnt/ubuntu-share/guest-test
```

On the host:

```bash
ls -l /var/lib/libvirt/shares/ubuntu/guest-test
```

## 7. Optional Shared Memory Backing

The host also generates a memory-backing reference:

```bash
cat /etc/virtfs/ubuntu/memory-backing.xml
```

If the domain needs shared memfd backing for virtiofs DAX, merge it into the
domain's existing `<memoryBacking>` element. Do not add a second
`<memoryBacking>` element:

```xml
<memoryBacking>
  <source type="memfd"/>
  <access mode="shared"/>
</memoryBacking>
```

## 8. Optional GPU Acceleration

The Radeon 680M is the host's integrated GPU and should not be detached with
VFIO. Use virtio-gpu with 3D acceleration for the guest.

Ubuntu 24.04 can use Venus when its Mesa stack supports it:

```bash
sudo apt install vulkan-tools
vulkaninfo | grep -i venus
```

VFIO is intended for a separate device, such as an eGPU, dedicated USB
controller, or dedicated NIC. Enable the host option first:

```nix
aspects.virtualisation.vfio.enable = true;
```

Then bind the specific device before starting the VM. Do not attempt to bind
the integrated Radeon GPU.

## 9. Optional Performance Tuning

Allocate hugepages for a dedicated VM session:

```bash
sudo virsh allocpages 2048 2M
```

Merge hugepages into the existing memory backing rather than adding a second
element:

```xml
<memoryBacking>
  <source type="memfd"/>
  <access mode="shared"/>
  <hugepages/>
</memoryBacking>
```

Optional vCPU pinning example:

```xml
<vcpu placement="static">8</vcpu>
<cputune>
  <vcpupin vcpu="0" cpuset="2"/>
  <vcpupin vcpu="1" cpuset="3"/>
</cputune>
```

## 10. Resize and Back Up

Resize the qcow2 image on the host:

```bash
sudo qemu-img resize /var/lib/libvirt/images/ubuntu.qcow2 +16G
```

Then inspect the guest layout:

```bash
lsblk
```

Grow the relevant partition first, then the filesystem. For an ext4 filesystem
directly on `/dev/vda1`, the final step would be:

```bash
sudo resize2fs /dev/vda1
```

The actual partition may differ, especially for a UEFI installation.

Back up both mutable data locations separately:

```bash
sudo rsync -aHAX \
  /var/lib/libvirt/images/ \
  /path/to/backup/images/

sudo rsync -aHAX \
  /var/lib/libvirt/shares/ubuntu/ \
  /path/to/backup/ubuntu-share/
```

Deleting a VM does not automatically delete its share. Remove the disk and
share separately only when their data is no longer needed.
