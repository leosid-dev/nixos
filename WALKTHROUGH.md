# WALKTHROUGH.md — Clean-slate install of the ThinkBook

Step-by-step setup from a blank machine to a working NixOS environment:
USB boot → partitioning → install → secrets bootstrap → flake check →
rebuild. Written for the Lenovo ThinkBook 16 G7 ARP (`hosts/thinkbook`);
machine-specific values are flagged where they appear.

> Companion docs: `AGENTS.md` (contract), `STATE.md` (architecture +
> verification checklist), `secrets/README.md` (sops playbook),
> `assets/ricing/README.md` (ricing knobs), `assets/virt/README.md`
> (KVM runbook).

---

## 0. What you need

- USB stick ≥ 4 GB (installer) and a second USB stick (BIOS recovery
  backup, step 3).
- The NixOS 26.05 **minimal** ISO (matches the `nixos-26.05` pin in
  `flake.nix`):

      https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso

  Verify the checksum against the `.sha256` file on the same channel page.
- Network access (WiFi works from the live ISO; the MT7921e driver is
  in-kernel).
- Optional dry run: boot the ISO in a throwaway KVM guest first with
  `assets/virt/run-nixos-iso.sh ./nixos.iso` (see `assets/virt/README.md`).

The minimal ISO already enables `nix-command` and `flakes`, so
`nixos-install --flake` works directly from it.

## 1. Write the USB and boot it

From any Linux machine:

```bash
lsblk                                  # find the stick (e.g. /dev/sdX) — be sure!
sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M status=progress oflag=direct
sync
```

On the ThinkBook:

1. Power on → **F2** (BIOS setup) → Security → **disable Secure Boot**.
2. **F12** (boot menu) → select the UEFI USB entry.

## 2. Live environment

Log in as `nixos` (no password), then:

```bash
sudo -i
nmtui            # connect to WiFi (or plug an Ethernet dongle)
ping -c2 nixos.org
```

## 3. Partition and format — clean slate on both disks

**This wipes everything on both NVMe drives.** Re-verify device identity
before every destructive command:

```bash
lsblk -o NAME,SIZE,MODEL
# nvme0n1 = Micron  (system disk)
# nvme1n1 = KIOXIA  (data disk)
```

### 3a. Back up the Lenovo BIOS recovery image

The current ESP on `nvme0n1` also carries Lenovo's BIOS recovery image.
Save it to the second USB stick before wiping:

```bash
mkdir -p /mnt/oldesp /mnt/backup
mount -o ro /dev/nvme0n1p1 /mnt/oldesp        # adjust partition number if needed
mount /dev/sdY1 /mnt/backup                   # the backup stick
cp -a /mnt/oldesp/. /mnt/backup/esp-backup/
umount /mnt/oldesp /mnt/backup
```

Keep that stick somewhere safe — it is the only way back if a BIOS update
ever bricks the machine.

### 3b. Disk 1 (`nvme0n1`) — ESP + swap + root

```bash
wipefs -a /dev/nvme0n1
sgdisk -Z /dev/nvme0n1 \
  -n 1:0:+2G  -t 1:ef00 -c 1:boot \
  -n 2:0:+8G  -t 2:8200 -c 2:swap \
  -n 3:0:0    -t 3:8300 -c 3:nixos

mkfs.vfat -F32 -n boot /dev/nvme0n1p1
mkswap -L swap /dev/nvme0n1p2
mkfs.ext4 -L nixos /dev/nvme0n1p3
```

Filesystem choices: FAT32 is mandatory for the ESP (2 GiB is generous —
systemd-boot with `configurationLimit = 3` fits easily); ext4 for root
keeps things simple and fsck-friendly (plain ext4 without LUKS is the
accepted design for this machine; secrets are protected by sops-nix age
encryption); 8 GiB swap complements the zram swap enabled by
`modules/system/core/boot.nix` on this 16 GB machine.

### 3c. Disk 2 (`nvme1n1`) — VM data + media/games

```bash
wipefs -a /dev/nvme1n1
sgdisk -Z /dev/nvme1n1 \
  -n 1:0:+150G -t 1:8300 -c 1:vmdata \
  -n 2:0:0     -t 2:8300 -c 2:media

mkfs.ext4 -L vmdata /dev/nvme1n1p1
mkfs.ext4 -L media  /dev/nvme1n1p2
```

Both are ext4 with `noatime` (declared in `hosts/thinkbook/hardware.nix`).
The VM partition mounts at `/var/lib/libvirt` — housing both sparse disk
images (`/var/lib/libvirt/images`) and dedicated virtiofs data shares
(`/var/lib/libvirt/shares`). The media partition mounts at `/home/sid/media`
(add a Steam library folder inside it later).

### 3d. Mount everything

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot /mnt/var/lib/libvirt /mnt/home/sid/media
mount /dev/disk/by-label/boot /mnt/boot
mount /dev/disk/by-label/vmdata /mnt/var/lib/libvirt
mount /dev/disk/by-label/media /mnt/home/sid/media
swapon /dev/disk/by-label/swap
```

The labels are the contract with `hosts/thinkbook/hardware.nix` (it uses
`/dev/disk/by-label/*` placeholders), so no UUID editing is needed after
formatting.

## 4. Pre-generate the host SSH keys (sops prerequisite)

sops-nix decrypts secrets with the **installed** system's host key
(`modules/system/core/secrets.nix`), so the key must exist before install:

```bash
mkdir -p /mnt/etc/ssh
ssh-keygen -t ed25519 -f /mnt/etc/ssh/thinkbook_ed25519 -N ""
```

`nixos-install` preserves these instead of generating new ones.

## 5. Pull the codebase

```bash
git clone https://github.com/leosid-dev/nixos.git /mnt/etc/nixos
```

HTTPS because the live ISO has no GitHub credentials. If the repo is
private, use a personal access token:
`git clone https://<token>@github.com/leosid-dev/nixos.git /mnt/etc/nixos`.

## 6. Realize the secrets placeholder (one-time)

`secrets/secrets.yaml` ships as a plaintext placeholder and
`nixos-rebuild switch` fails until it is replaced — intentionally.

```bash
cd /mnt/etc/nixos
nix-shell -p sops ssh-to-age age mkpasswd

# 1. Derive the age recipient from the sops identity key generated in step 4
#    (-i converts a PUBLIC key; without it ssh-to-age expects a private key)
ssh-to-age -i /mnt/etc/ssh/thinkbook_ed25519.pub

# 2. Put that recipient into secrets/.sops.yaml (replace the commented
#    example block):
#      creation_rules:
#        - path_regex: secrets\.yaml$
#          age: >-
#            age1...

# 3. Create the password hash, then encrypt the store
mkpasswd -m yescrypt          # type the password for user `sid`
sops secrets/secrets.yaml     # set users/sid/password to the hash, save+quit

# 4. Commit the encrypted store (never commit plaintext)
git add secrets/.sops.yaml secrets/secrets.yaml
git commit -m "secrets: bootstrap sops store for thinkbook"
```

## 7. Install

```bash
cd /mnt/etc/nixos
nixos-install --flake .#thinkbook
```

The install uses the committed `flake.lock` (AGENTS.md rule 1). sops-nix
decrypts the store during activation using the host SSH key from step 4.

When prompted for a root password: **just press Enter to skip it**. Root
is locked by design (`users.mutableUsers = false`, no declarative root
password); `sid` is in `wheel` and is the admin path.

```bash
reboot
```

Remove the USB stick when the machine powers down.

## 8. First boot

The noctalia greeter comes up with the console keymap (`us`), the synced
monochrome palette (true-black backdrop, no logo), and defaults to the
niri session. Log in as `sid` with the password you hashed in
step 6.

## 9. Relocate the flake and commit the lock

The `rebuild` shell alias expects the checkout at `~/nixos`
(`aspects.home.shell.flakePath`):

```bash
sudo mv /etc/nixos /home/sid/nixos
sudo chown -R sid:users /home/sid/nixos
cd ~/nixos
git add flake.lock
git commit -m "lock: pin flake inputs"
git push
```

Committing `flake.lock` is a hard rule of this repo (AGENTS.md rule 1).

## 10. Flake check and rebuild

```bash
cd ~/nixos
nix flake check
nix eval .#nixosConfigurations.thinkbook.config.system.build.toplevel.drvPath
rebuild    # zsh alias → sudo nixos-rebuild switch --flake ~/nixos#thinkbook
```

The rebuild is a no-op build-wise (you just installed this exact config)
but proves the relocated checkout works end to end.

## 11. Verify the working environment

- **Greeter:** reboot once; login screen uses the `us` keymap, paints the
  synced palette (true-black backdrop, no logo, Inter), and starts
  niri.
- **Compositor:** `Mod+Return` opens Kitty; window animations overshoot
  slightly then settle; `Mod+Shift+Y` screenshots a region to clipboard
  (`Mod+Shift+S` for fullscreen).
- **Firefox:** launches from the launcher; check `about:support` →
  "Window Protocol" says `wayland` (native, via the system-wide
  `MOZ_ENABLE_WAYLAND=1`).
- **Network:** `nmcli device` shows WiFi connected; Bluetooth pairs.
- **Audio:** play something; the ThinkBook audio profile autoloads
  `thinkbook-speakers-dolby-music`. The `thinkbook-speakers-dolby-movie` /
  `thinkbook-speakers-enhanced` / `thinkbook-speakers-movie-enhanced` /
  `headphones-neutral` presets are available for manual selection (use
  `headphones-neutral` when using headphones).
- **Mounts:** `findmnt /var/lib/libvirt /home/sid/media` shows the
  two data partitions.
- **Firmware:** `fwupdmgr refresh && fwupdmgr update` (manual, on demand).
- **Agents:** `opencode --version && grok --version` (auth is imperative:
  `opencode auth login`, grok login).

Full checklist: STATE.md → "Verification & Rollout".

## 12. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Activation fails mentioning sops/secrets | Step 6 not done — the placeholder store is still in place. |
| WiFi stalls / DMA timeouts | MT7921e quirk — `aspects.hardware.network.wifi.aspmFix` is already on for this host. |
| Audio pops on codec wake | ALC257 quirk — the ThinkBook explicitly selects `aspects.hardware.amdRembrandt.audio.powerSave = 0`. |
| Screen flicker / external monitor freeze | Set `aspects.hardware.amdRembrandt.flickerFix.enable = true` and rebuild. |
| `/boot` full on rebuild | `configurationLimit = 3` bounds generations; `nix-collect-garbage -d` if needed. |
