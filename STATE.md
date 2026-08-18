# STATE.md — Architecture, Design Principles & Current State

> Last updated: 2026-08-17 · visual polish pass (tap-to-click + natural scroll,
> snappy Niri bindings/animations, rectangular Noctalia bar with desktop and
> status capsule groups, date-only clock, single sysmon pill, no Blueman applet)

---

## Design Principles

### 1. Declarative & Minimalistic
Every piece of system and user configuration is expressed in Nix — no imperative scripts, no hidden state. The configuration aims for the smallest surface area that delivers a complete, polished desktop experience.

### 2. Agnostic Top-Level
`flake.nix` knows nothing about specific hosts, users, or hardware. It wires inputs (nixpkgs, home-manager, noctalia, noctalia-greeter, sops-nix, nixvim, llm-agents, apple-fonts) into a pure `lib`, and delegates host discovery to `hosts/default.nix` which auto-scans subdirectories. Adding a new machine means creating a directory under `hosts/` — zero changes to the flake.

### 3. Aspect-Oriented Modules & Modular Users
System, hardware, user, and home modules are organised as **aspects** — self-contained concerns that can be composed or removed per host or per persona:

| Namespace | Examples | What it owns |
|---|---|---|
| `aspects.{core,secrets,desktop,sound,power,fonts,gaming,ssh,virtualisation}` | System aspects | Nix settings, boot, locale, sound stack, gaming (+wine/firewall), KVM/virtiofs, … |
| `aspects.hardware.{amdRembrandt,network,storage,usb}` | Hardware aspects | Per-device drivers, kernel modules, quirks |
| `aspects.users.*` | User identity | OS-level user account declaration |
| `aspects.home.*` | Home-Manager toggles | Per-persona HM opt-ins (audio, theme, …) |
| `aspects.locale` | System cross-cutting | Keymap shared by console and greeter |
| `aspects.theme` | Home Manager cross-cutting | Font, cursor, mode, accent, and structured palette |

> Every aspect except Core is **off by default** and enabled per host (or per
> profile) through the `aspects.*` option tree. The naming convention is
> **camelCase options, kebab-case files** (`aspects.hardware.amdRembrandt`).
> Boolean subfeatures strictly use `<feature>.enable` with conservative inert defaults.

### 4. Pure Library Functions
All helpers in `lib/` are pure functions with no side effects:
- **`channels`** — builds `{ stable, unstable }` pkgs sets for a given system + overlays + config. The `unstable` set is attached to `stable` through a **real overlay** (`final: prev: { inherit unstable; }`) at construction. Unfree/licensing policy is passed in as data by each host; never embedded.
- **`mkHost`** — constructs a `nixosSystem` value from `{ system, channels, users, modules }`, auto-wiring Home Manager, sops-nix, and the noctalia-greeter NixOS modules (each inert until configured).
- **`palettes`** — pure color token table (accent → mode → palette record) consumed across Noctalia, Kitty, Niri, and Neovim.

### 5. Stable/Unstable Version Pinning
- `nixpkgs` → `nixos-26.05` (stable, primary)
- `nixpkgs-unstable` → `nixos-unstable` (bleeding edge)
- Individual packages opt into unstable explicitly (currently `pkgs.unstable.niri`)
- The `channels.nix` builder injects `pkgs.unstable.*` as a namespace on the stable set

### 6. Home Manager via Flakes
User-space configuration flows through Home Manager, integrated as a NixOS module:
- `mkHost` wires `home-manager.nixosModules.home-manager` automatically
- `useGlobalPkgs = true` — HM uses the system's nixpkgs (no separate pin)
- Users are defined in `hosts/*/users.nix`, each importing a profile
- The profile (`profiles/desktop.nix`) sets `aspects.home.*` per persona

### 7. Separation of Concerns
| Layer | Owns | Does NOT own |
|---|---|---|
| `hosts/*/hardware.nix` | Filesystems, initrd, SoC-specific initrd modules | Generic drivers |
| `modules/users/*.nix` | OS user accounts, groups, system shell | User-space dotfiles or host config |
| `hosts/*/users.nix` | HM user → profile mapping, host user data (flakePath) | System-level config |
| `modules/system/hardware/*.nix` | Generic driver aspects | Machine-specific mounts |
| `modules/home/*.nix` | User-space programs & dotfiles | System services |
| `profiles/*.nix` | HM module composition + persona choices | Implementation details |

### 8. Hybrid HM Gating
Home-Manager modules are gated only when they have real per-persona variation:
- **Always-on with desktop profile:** `shell`, `editor`, `git`, `niri`, `wayland`
- **Gated via `aspects.home.*`:** `terminal`, `theme`, `noctalia`, `audio`, `agents`

A persona is a profile; `profiles/desktop.nix` is the only one today.

---

## Architecture

```
nixos/
├── flake.nix                              # Inputs, outputs, checks, agnostic wiring
├── flake.lock                             # Pinned dependency hashes (committed)
│
├── lib/                                   # Pure helper functions & data
│   ├── default.nix                        # Public API: { channels, mkHost, nixpkgsLib, palettes }
│   ├── channels.nix                       # Pure channel builder: system+overlays+config → { stable, unstable }
│   ├── mkHost.nix                         # nixosSystem constructor + HM/sops/greeter wiring
│   └── palettes.nix                       # Pure canonical color token table (accent -> mode -> tokens)
│
├── overlays/
│   └── core.nix                           # Global overlays (currently empty extension point)
│
├── hosts/                                 # One subdirectory per machine
│   ├── default.nix                        # Auto-discovers host dirs → nixosConfigurations
│   └── thinkbook/                         # Lenovo ThinkBook 16 G7 ARP
│       ├── default.nix                    # Aspect selection + channels + module wiring
│       ├── hardware.nix                   # Filesystems, initrd (machine-unique)
│       ├── users.nix                      # HM user → profile mapping (sid, flakePath)
│       └── overlays.nix                   # Host-specific overlays (empty extension point)
│
├── modules/
│   ├── users/
│   │   └── sid.nix                        # sid OS user (aspects.users.sid.enable), sops password
│   │
│   ├── system/                            # NixOS system-level aspects
│   │   ├── default.nix                    # Index: imports core, desktop, ssh, sound, power,
│   │   │                                  #   fonts, gaming, virtualisation, hardware/* (Core on; rest opt-in)
│   │   ├── ssh.nix                        # Hardened OpenSSH (aspects.ssh.enable)
│   │   ├── gaming.nix                     # Steam, GameMode, Wine, MangoHud (+remotePlay/dedicatedServer sub-options)
│   │   ├── sound.nix                      # PipeWire + ALSA + PulseAudio compat (+jack sub-option)
│   │   ├── power.nix                      # power-profiles-daemon + upower
│   │   ├── fonts.nix                      # System font packages (Noto, Noto Emoji, SF Pro UI for greeter)
│   │   ├── core/                          # Always-on fundamentals (aspects.core.enable)
│   │   │   ├── default.nix                # Index
│   │   │   ├── boot.nix                   # systemd-boot (limit 3), kernelPackages option, tmpfs, zram
│   │   │   ├── locale.nix                 # i18n, console keymap + earlySetup, aspects.locale.keyMap
│   │   │   ├── nix.nix                    # Flakes, GC, store optimisation, binary caches
│   │   │   ├── packages.nix               # Minimal CLI tools + nix-ld
│   │   │   └── secrets.nix                # sops-nix (aspects.secrets.{enable,file,sshKeyPaths})
│   │   ├── desktop/                       # Wayland desktop (aspects.desktop.enable)
│   │   │   ├── default.nix                # Index (niri, portals, login, bluetooth, browser)
│   │   │   ├── niri.nix                   # Niri compositor + uniform Wayland sessionVariables (SDL fallback)
│   │   │   ├── portals.nix                # XDG desktop portals (GTK fallback) + dconf backend
│   │   │   ├── bluetooth.nix              # Blueman (gated on desktop + network.bluetooth)
│   │   │   ├── browser.nix                # Firefox (system-level, native Wayland)
│   │   │   └── login.nix                  # noctalia-greeter (reads aspects.locale.keyMap)
│   │   ├── virtualisation/                # KVM/QEMU virtualisation aspect
│   │   │   ├── default.nix                # Index (aspects.virtualisation.enable)
│   │   │   ├── platform.nix               # libvirtd (root mode), QEMU, virt-manager, virtiofsd
│   │   │   ├── storage.nix                # virt-disk image creation tool (metadata sparse qcow2, raw)
│   │   │   ├── shares.nix                 # Host-backed virtiofs shares, tmpfiles dirs, /etc/virtfs/ artifacts
│   │   │   └── features.nix               # Optional knobs (ksm, swtpm, spiceUsbRedirection, vfio)
│   │   └── hardware/                      # Device-specific driver aspects
│   │       ├── amd-rembrandt.nix          # AMD Ryzen 7 7735HS + Radeon 680M
│   │       ├── network.nix                # WiFi (MT7921e + aspmFix knob), BT (+bluetooth.enable), firmware
│   │       ├── storage.nix                # fstrim, udisks2, fwupd (manual LVFS updates)
│   │       └── usb.nix                    # USB + USB4/Thunderbolt (+thunderbolt.enable)
│   │
│   └── home/                              # Home Manager modules
│       ├── shell.nix                      # Zsh + fzf + eza + bat (always-on; flakePath required)
│       ├── editor.nix                     # Neovim via nixvim (always-on, sets EDITOR/VISUAL, base16 palette)
│       ├── git.nix                        # Git + Delta + lazygit (always-on)
│       ├── niri.nix                       # Niri user config.kdl (always-on with desktop profile, palette-derived rings)
│       ├── wayland.nix                    # grim/slurp/wl-clipboard/xwayland-satellite/qt-wayland
│       ├── terminal.nix                   # Kitty, structured palette, sets TERMINAL; opacity/fontSize/padding knobs
│       ├── theme.nix                      # GTK/QT/cursor/dconf (accent enum, mode, SF Pro/SF Mono default, palette)
│       ├── noctalia.nix                   # Noctalia v5 shell (m* custom palette dark+light, reads theme.mode)
│       ├── audio.nix                      # EasyEffects DSP + presets option + graphViewer.enable
│       └── agents.nix                     # LLM agents from llm-agents.nix (packages default [])
│
├── profiles/
│   └── desktop.nix                        # Composes all HM modules + sets explicit persona aspect choices
│
└── assets/
    ├── easyeffects/
    │   └── dolby-approximation.json       # EE7 preset (plugins_order + blocklist) — wired by desktop profile
    ├── ricing/
    │   └── README.md                      # Ricing cheat sheet: aspect knobs, examples, checks
    └── virt/
        └── README.md                      # KVM runbook: VM creation, virtiofs XML, Venus, tuning
```

---

## Current State

### Target Machine
| Spec | Value |
|---|---|
| Model | Lenovo ThinkBook 16 G7 ARP |
| CPU | AMD Ryzen 7 7735HS (Rembrandt, Zen 3+, 8C/16T) |
| GPU | AMD Radeon 680M (RDNA2 iGPU, integrated) |
| RAM | 16 GB DDR5 |
| Storage | `nvme0n1` Micron: ESP "boot" (2 GiB) + swap (8 GiB) + root "nixos" (plain ext4 without LUKS — accepted design); `nvme1n1` KIOXIA: "vmdata" (150 GiB → `/var/lib/libvirt` for images + guest homes) + "media" (rest → `/home/sid/media`). Label-based refs; layout created by WALKTHROUGH.md |
| WiFi | MediaTek MT7921e (`14c3:0616`, `disable_aspm`) |
| Bluetooth | Foxconn MediaTek (btusb), Noctalia control-center Bluetooth service (Blueman applet removed) |
| Audio | Realtek ALC257 (HDA) — no smart amps; DSP via EasyEffects profile preset |
| USB4 | Rembrandt USB4 router present → bolt enabled |

### Software Stack
| Component | Choice | Channel |
|---|---|---|
| Compositor | Niri | unstable |
| Shell + Login | Noctalia v5 + noctalia-greeter | flake input (cachix) |
| Secrets | sops-nix (age via SSH host ed25519) | flake input |
| Terminal | Kitty | stable (auto-sets TERMINAL) |
| Browser | Firefox (system-level, native Wayland via MOZ_ENABLE_WAYLAND) | stable |
| File Editor | Neovim via nixvim (nixd LSP, sets EDITOR/VISUAL) | flake input |
| LLM Agents | opencode + grok via numtide/llm-agents.nix | flake input (own unstable pin, numtide cache) |
| Gaming Stack | Steam + GameMode + Wine + MangoHud + Bottles | stable |
| Virtualisation | KVM/QEMU (libvirt + virt-manager), dedicated guest home via virtiofs, virtio-gpu + Venus | stable |
| Privilege prompts | Noctalia's native polkit agent (`shell.polkit_agent`) | flake input |
| Audio | PipeWire + EasyEffects DSP | stable |
| Shell | Zsh (with autosuggestions & syntax highlighting) | stable |
| Theme | Monochrome (true-black) via `aspects.theme.accent`; Adwaita GTK/QT + dconf; structured `aspects.theme.palette` | stable |
| Fonts | SF Pro (UI) + SF Mono (code) via apple-fonts flake, Noto Fonts, Noto Color Emoji | stable + flake input |
| Firmware | fwupd (LVFS, manual `fwupdmgr update`) | stable |

---

## Conventions

- **Single aspect tree.** Everything toggleable lives under `aspects.*`.
  Naming: camelCase options, kebab-case files.
- **Sub-options use `.enable`.** Multi-leaf aspects use structured `.enable` booleans.
- **Conservative defaults.** Generic modules use inert defaults; hosts explicitly declare policy.
- **User identity belongs in `modules/users/`** under `aspects.users.*`.
- **Profile owns persona.** `profiles/desktop.nix` is the only composition
  point for HM aspects; different persona = different profile.
- **One source of truth per value.** See AGENTS.md rule 8.
- **Hosts own policy, modules own intent.** `allowUnfree`, aspect selection,
  and user opt-in are host decisions, passed as data — never baked into `lib/`.

---

## Verification & Rollout

> Full clean-slate install procedure: `WALKTHROUGH.md`.

1. **First switch (one-time, on the ThinkBook):**
   - `ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub`
   - add the derived age recipient to an active `creation_rules` entry in
     `secrets/.sops.yaml`
   - `sops secrets/secrets.yaml` → set `users/sid/password` to
     `mkpasswd -m yescrypt` hash
2. **Flake check:** `nix flake check` (evaluates flake outputs, validates EasyEffects preset JSON schema)
3. **Static gate:** `nix eval .#nixosConfigurations.thinkbook.config.system.build.toplevel.drvPath`
4. **Full build:** `nixos-rebuild build --flake .#thinkbook` (then `switch`)
5. **Audio preset:** EasyEffects autoloads `dolby-approximation` on session start
   (oneshot unit installed by the desktop profile).
6. **Firmware:** `fwupdmgr refresh && fwupdmgr update` (manual, on demand).
7. **LLM agents:** `opencode --version && grok --version`; auth is
   imperative (`opencode auth login`, grok login) — nothing declarative.
8. **Virtualisation:** `systemctl status libvirtd && virsh version`, then
   follow `assets/virt/README.md`: `virt-disk ubuntu 64G`, create the
   Ubuntu VM (UEFI, virtio-blk tuned, virtiofs share from `/var/lib/libvirt/homes/ubuntu`),
   run `cat /etc/virtfs/ubuntu/setup-guest.sh | ssh guest 'sudo sh -s'`, verify the shared home and
   `vulkaninfo` (Venus).
9. **Visual:** `niri validate` against the generated config, then check
   the bezier overshoot/settle, radius-4 corners, grayscale focus ring on
   true-black background, the flat macOS-style bar and top-center launcher.

---

## Optimisation & Policy Summary

| Knob | Where | Default | Effect |
|---|---|---|---|
| `aspects.gaming.wine.enable` | gaming.nix | `false` | wineWow64+winetricks+bottles+protonup-qt gated; Steam+GameMode+MangoHud always on |
| `aspects.gaming.remotePlay.enable` | gaming.nix | `false` | Inbound firewall port opening for Steam Remote Play |
| `aspects.gaming.dedicatedServer.enable` | gaming.nix | `false` | Inbound firewall port opening for Steam Dedicated Server |
| `aspects.sound.jack.enable` | sound.nix | `false` | JACK audio emulation layer via PipeWire |
| `aspects.hardware.network.bluetooth.enable` | network.nix | `false` | Bluetooth hardware controller and daemon |
| `aspects.hardware.usb.thunderbolt.enable` | usb.nix | `false` | Thunderbolt / USB4 router and bolt daemon |
| `aspects.home.audio.graphViewer.enable` | home/audio.nix | `false` | PipeWire graph viewer tool (crosspipe) |
| `aspects.virtualisation.ksm.enable` | virt/features.nix | `false` | Memory deduplication (off on laptops to save CPU/battery) |
| `aspects.virtualisation.swtpm.enable` | virt/features.nix | `false` | Emulated TPM 2.0 |
| `aspects.virtualisation.spiceUsbRedirection.enable` | virt/features.nix | `false` | SPICE USB device redirection |
| `documentation.nixos.enable` | core/default.nix | `false` | drops NixOS HTML/manual generation |
| `aspects.hardware.amdRembrandt.perfTuning` | amd-rembrandt.nix | `true` | iommu=pt, nowatchdog, vm.swappiness=10 |
| `aspects.hardware.amdRembrandt.abmLevel` | amd-rembrandt.nix | `null` | Adaptive Backlight Management knob |
| `lazytime` on ext4 mounts | hosts/thinkbook/hardware.nix | on | journal write reduction |
| `nix.settings.{auto-optimise-store,max-jobs,cores}` | core/nix.nix | — | store dedup on write + full parallelism |
| `configurationLimit = 3` | core/boot.nix | 3 | bounds /boot + store-level generation prune |
