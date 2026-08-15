# STATE.md — Architecture, Design Principles & Current State

> Last updated: 2026-08-15 · 43 nix files · post-bugfix refactor

---

## Design Principles

### 1. Declarative & Minimalistic
Every piece of system and user configuration is expressed in Nix — no imperative scripts, no hidden state. The configuration aims for the smallest surface area that delivers a complete, polished desktop experience.

### 2. Agnostic Top-Level
`flake.nix` knows nothing about specific hosts, users, or hardware. It wires inputs (nixpkgs, home-manager, noctalia, noctalia-greeter, sops-nix, nixvim, llm-agents) into a pure `lib`, and delegates host discovery to `hosts/default.nix` which auto-scans subdirectories. Adding a new machine means creating a directory under `hosts/` — zero changes to the flake.

### 3. Aspect-Oriented Modules & Modular Users
System, hardware, user, and home modules are organised as **aspects** — self-contained concerns that can be composed or removed per host or per persona:

| Namespace | Examples | What it owns |
|---|---|---|
| `aspects.{core,secrets,desktop,sound,power,fonts,gaming,ssh,virtualisation}` | System aspects | Nix settings, boot, locale, sound stack, gaming, KVM/virtiofs, … |
| `aspects.hardware.{amdRembrandt,network,storage,usb}` | Hardware aspects | Per-device drivers, kernel modules, quirks |
| `aspects.users.*` | User identity | OS-level user account declaration |
| `aspects.home.*` | Home-Manager toggles | Per-persona HM opt-ins (audio, theme, …) |
| `aspects.locale` | System cross-cutting | Keymap shared by console and greeter |
| `aspects.theme` | Home Manager cross-cutting | Font, cursor, mode, and accent values |

> Every aspect except Core is **off by default** and enabled per host (or per
> profile) through the `aspects.*` option tree. The naming convention is
> **camelCase options, kebab-case files** (`aspects.hardware.amdRembrandt`).

### 4. Pure Library Functions
All helpers in `lib/` are pure functions with no side effects:
- **`channels`** — builds `{ stable, unstable }` pkgs sets for a given system + overlays + config. The `unstable` set is attached to `stable` through a **real overlay** (`final: prev: { inherit unstable; }`) at construction. Unfree/licensing policy is passed in as data by each host; never embedded.
- **`mkHost`** — constructs a `nixosSystem` value from `{ system, channels, users, modules }`, auto-wiring Home Manager, sops-nix, and the noctalia-greeter NixOS modules (each inert until configured).

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
| `hosts/*/users.nix` | HM user → profile mapping | System-level config |
| `modules/system/hardware/*.nix` | Generic driver aspects | Machine-specific mounts |
| `modules/home/*.nix` | User-space programs & dotfiles | System services |
| `profiles/*.nix` | HM module composition + per-persona aspects | Implementation details |

### 8. Hybrid HM Gating
Only HM modules with real per-persona variation are gated:
- **Always-on:** `shell`, `editor`, `git`, `niri`, `wayland`
- **Gated via `aspects.home.*`:** `terminal`, `theme`, `noctalia`, `audio`, `agents`

A persona is a profile; `profiles/desktop.nix` is the only one today.

---

## Architecture

```
nixos/
├── flake.nix                              # Inputs, outputs, agnostic wiring
├── flake.lock                             # Pinned dependency hashes (committed)
│
├── lib/                                   # Pure helper functions
│   ├── default.nix                        # Public API: { channels, mkHost, nixpkgsLib }
│   ├── channels.nix                       # Pure channel builder: system+overlays+config → { stable, unstable }
│   └── mkHost.nix                         # nixosSystem constructor + HM/sops/greeter wiring
│
├── overlays/
│   └── core.nix                           # Global overlays (currently empty)
│
├── hosts/                                 # One subdirectory per machine
│   ├── default.nix                        # Auto-discovers host dirs → nixosConfigurations
│   └── thinkbook/                         # Lenovo ThinkBook 16 G7 ARP
│       ├── default.nix                    # Aspect selection + channels + module wiring
│       ├── hardware.nix                   # Filesystems, initrd (machine-unique)
│       ├── users.nix                      # HM user → profile mapping
│       └── overlays.nix                   # Host-specific overlays (empty)
│
├── modules/
│   ├── users/
│   │   └── sid.nix                        # sid OS user (aspects.users.sid.enable), sops password
│   │
│   ├── system/                            # NixOS system-level aspects
│   │   ├── default.nix                    # Index: imports core, desktop, ssh, sound, power,
│   │   │                                  #   fonts, gaming, virtualisation, hardware/* (Core on; rest opt-in)
│   │   ├── ssh.nix                        # Hardened OpenSSH (aspects.ssh.enable)
│   │   ├── gaming.nix                     # Steam, GameMode, Wine, MangoHud, Bottles
│   │   ├── virtualisation.nix             # KVM/QEMU + libvirt + virtiofs home sharing (aspects.virtualisation.*)
│   │   ├── sound.nix                      # PipeWire + ALSA + PulseAudio compat + rtkit
│   │   ├── power.nix                      # power-profiles-daemon + upower
│   │   ├── fonts.nix                      # System fonts + fontconfig defaults
│   │   ├── core/                          # Always-on fundamentals (aspects.core.enable)
│   │   │   ├── default.nix                # Index
│   │   │   ├── boot.nix                   # systemd-boot (limit 5), kernel, tmpfs, zram
│   │   │   ├── locale.nix                 # i18n, console keymap + earlySetup, aspects.locale.keyMap
│   │   │   ├── nix.nix                    # Flakes, GC, store optimisation, binary caches
│   │   │   ├── packages.nix               # Minimal CLI tools + nix-ld
│   │   │   └── secrets.nix                # sops-nix (aspects.secrets.enable)
│   │   ├── desktop/                       # Wayland desktop (aspects.desktop.enable)
│   │   │   ├── default.nix                # Index
│   │   │   ├── niri.nix                   # Niri compositor + uniform Wayland sessionVariables
│   │   │   ├── portals.nix                # XDG desktop portals (GTK fallback) + dconf backend
│   │   │   └── login.nix                  # noctalia-greeter (reads aspects.locale.keyMap)
│   │   └── hardware/                      # Device-specific driver aspects
│   │       ├── amd-rembrandt.nix          # AMD Ryzen 7 7735HS + Radeon 680M
│   │       ├── network.nix                # WiFi (MT7921e + aspmFix knob), BT, firewall
│   │       ├── storage.nix                # fstrim, udisks2, fwupd (manual LVFS updates)
│   │       └── usb.nix                    # USB + USB4/Thunderbolt (bolt, opt-in knob)
│   │
│   └── home/                              # Home Manager modules
│       ├── shell.nix                      # Zsh + fzf + eza + bat (always-on; flakePath option)
│       ├── editor.nix                     # Neovim via nixvim (always-on, sets EDITOR/VISUAL)
│       ├── git.nix                        # Git + Delta + lazygit (always-on)
│       ├── niri.nix                       # Niri user config.kdl: bezier overshoot easing, accent-keyed ring (always-on with desktop)
│       ├── wayland.nix                    # grim/slurp/wl-clipboard/xwayland-satellite/qt-wayland
│       ├── terminal.nix                   # Kitty, accent-keyed palette (aspects.home.terminal.enable)
│       ├── theme.nix                      # GTK/QT/cursor/dconf (aspects.home.theme.enable; aspects.theme)
│       ├── noctalia.nix                   # Noctalia v5 shell (aspects.home.noctalia.enable)
│       ├── audio.nix                      # EasyEffects DSP + presets option (aspects.home.audio.enable)
│       └── agents.nix                     # LLM agents from llm-agents.nix (aspects.home.agents.*)
│
├── profiles/
│   └── desktop.nix                        # Composes all HM modules + sets aspects.home.* defaults
│
└── assets/
    ├── easyeffects/
    │   └── dolby-approximation.json       # EE7 preset (ThinkBook ALC257) — wired by desktop profile
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
| Storage | `nvme0n1` Micron (root `e83c1c8c-…`, swap `4ac49bbd-…`, /boot `E06F-F08E` on `nvme1n1` SYSTEM_DRV) |
| WiFi | MediaTek MT7921e (`14c3:0616`, `disable_aspm`) |
| Bluetooth | Foxconn MediaTek (btusb), Blueman in desktop aspect |
| Audio | Realtek ALC257 (HDA) — no smart amps; DSP via EasyEffects profile preset |
| USB4 | Rembrandt USB4 router present → bolt enabled |

### Software Stack
| Component | Choice | Channel |
|---|---|---|
| Compositor | Niri | unstable |
| Shell + Login | Noctalia v5 + noctalia-greeter | flake input (cachix) |
| Secrets | sops-nix (age via SSH host ed25519) | flake input |
| Terminal | Kitty | stable (auto-sets TERMINAL) |
| File Editor | Neovim via nixvim (nixd LSP, sets EDITOR/VISUAL) | flake input |
| LLM Agents | opencode + grok via numtide/llm-agents.nix | flake input (own unstable pin, numtide cache) |
| Gaming Stack | Steam + GameMode + Wine + MangoHud + Bottles | stable |
| Virtualisation | KVM/QEMU (libvirt + virt-manager), virtiofs home sharing, virtio-gpu + Venus | stable |
| Audio | PipeWire + EasyEffects DSP | stable |
| Shell | Zsh (with autosuggestions & syntax highlighting) | stable |
| Theme | Monochrome (true-black) via `aspects.theme.accent`; Adwaita GTK/QT + dconf; Niri focus-ring/background follow the accent | stable |
| Fonts | Inter, JetBrains Mono, FiraCode Nerd Font | stable |
| Firmware | fwupd (LVFS, manual `fwupdmgr update`) | stable |

---

## Conventions

- **Single aspect tree.** Everything toggleable lives under `aspects.*`.
  Naming: camelCase options, kebab-case files.
- **User identity belongs in `modules/users/`** under `aspects.users.*`.
- **Profile owns persona.** `profiles/desktop.nix` is the only composition
  point for HM aspects; different persona = different profile.
- **One source of truth per value.** See AGENTS.md rule 8.
- **Hosts own policy, modules own intent.** `allowUnfree`, aspect selection,
  and user opt-in are host decisions, passed as data — never baked into `lib/`.

---

## Verification & Rollout

1. **First switch (one-time, on the ThinkBook):**
   - `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`
   - add the derived age recipient to an active `creation_rules` entry in
     `secrets/.sops.yaml`
   - `sops secrets/secrets.yaml` → set `users/sid/password` to
     `mkpasswd -m yescrypt` hash
   - `nix flake lock` (regenerates `flake.lock` — also picks up the new
     `nixvim` and `llm-agents` inputs)
2. **Static gate:** `nix eval .#nixosConfigurations.thinkbook.config.system.build.toplevel.drvPath`
3. **Full build:** `nixos-rebuild build --flake .#thinkbook` (then `switch`)
4. **Audio preset:** EasyEffects autoloads `dolby-approximation` on session start
   (oneshot unit installed by the desktop profile).
5. **Firmware:** `fwupdmgr refresh && fwupdmgr update` (manual, on demand).
6. **LLM agents:** `opencode --version && grok --version`; auth is
   imperative (`opencode auth login`, grok login) — nothing declarative.
7. **Virtualisation:** `systemctl status libvirtd && virsh version`, then
   follow `assets/virt/README.md`: `virt-disk ubuntu 64G`, create the
   Ubuntu VM (UEFI, virtio-blk tuned, virtiofs share), run
   `virtfs-setup-ubuntu` inside the guest, verify the shared home and
   `vulkaninfo` (Venus).
8. **Visual:** `niri validate` against the generated config, then check
   the bezier overshoot/settle, radius-4 corners, grayscale focus ring on
   true-black background, the flat macOS-style bar (workspaces/app icons
   left, clock center, stats + performance toggle right) and the
   top-center launcher.
