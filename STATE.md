# STATE.md — Architecture, Design Principles & Current State

> Last updated: 2026-08-01 · 36 nix files · 850 lines

---

## Design Principles

### 1. Declarative & Minimalistic
Every piece of system and user configuration is expressed in Nix — no imperative scripts, no hidden state. The configuration aims for the smallest surface area that delivers a complete, polished desktop experience.

### 2. Agnostic Top-Level
`flake.nix` knows nothing about specific hosts, users, or hardware. It wires inputs (nixpkgs, home-manager, noctalia) into a pure `lib`, and delegates host discovery to `hosts/default.nix` which auto-scans subdirectories. Adding a new machine means creating a directory under `hosts/` — zero changes to the flake.

### 3. Aspect-Oriented Modules & Modular Users
System modules are organised as **aspects** — self-contained concerns that can be composed or removed per host:

| Aspect | Path | What it owns |
|---|---|---|
| **Core** | `modules/system/core/` | Nix settings, boot, locale, base packages |
| **Desktop** | `modules/system/desktop/` | Niri compositor, XDG portals, login (noctalia-greeter) |
| **Sound** | `modules/system/sound.nix` | PipeWire stack + rtkit |
| **Power** | `modules/system/power.nix` | Generic power management |
| **Fonts** | `modules/system/fonts.nix` | System font packages |
| **Gaming** | `modules/system/gaming.nix` | Steam, GameMode, Wine, MangoHud, Bottles |
| **SSH** | `modules/system/ssh.nix` | Hardened OpenSSH server (key-only) |
| **Secrets** | `modules/system/core/secrets.nix` | sops-nix age decryption via SSH host keys |
| **Hardware** | `modules/system/hardware/*.nix` | Per-device drivers & kernel modules |
| **Users** | `modules/users/*.nix` | User accounts, groups, system-level shell identity |

> Every aspect except Core is **off by default** and enabled per host through the
> `aspects.*` option tree (declared in `modules/system/default.nix`). Hosts only
> import that single index and select the aspects they want.

> **User Separation Philosophy**: User declarations (groups, login shell, sudo rules) are user identity concerns, not host concerns. Therefore, they live in `modules/users/*.nix` to remain reusable across hosts, rather than being hardcoded into host directories.

### 4. Pure Library Functions
All helpers in `lib/` are pure functions with no side effects:
- **`channels`** — builds `{ stable, unstable }` pkgs sets for a given system + overlays. The `unstable` set is attached to `stable` through a **real overlay** (`final: prev: { inherit unstable; }`) at construction — the canonical pure way to extend a pkgs set. Unfree/licensing policy is passed in as `config` data by each host; never embedded here.
- **`mkHost`** — constructs a `nixosSystem` value from `{ system, channels, users, modules }`, auto-wiring Home Manager, sops-nix and the noctalia-greeter NixOS modules (each inert until configured).
- `lib/overlays.nix` (the old `applyOverlays` combinator) was **removed** — no package set is ever mutated; overlays are passed straight into `import nixpkgs`.

### 5. Stable/Unstable Version Pinning
- `nixpkgs` → `nixos-26.05` (stable, primary)
- `nixpkgs-unstable` → `nixos-unstable` (bleeding edge)
- Individual packages opt into unstable explicitly (e.g. `pkgs.unstable.niri`, `pkgs.unstable.easyeffects`)
- The `channels.nix` builder injects `pkgs.unstable.*` as a namespace on the stable set

### 6. Home Manager via Flakes
User-space configuration flows through Home Manager, integrated as a NixOS module:
- `mkHost` wires `home-manager.nixosModules.home-manager` automatically
- `useGlobalPkgs = true` — HM uses the system's nixpkgs (no separate pin)
- Users are defined as attrsets in `hosts/*/users.nix`, each importing a profile

### 7. Separation of Concerns
| Layer | Owns | Does NOT own |
|---|---|---|
| `hosts/*/hardware.nix` | Filesystems, initrd, SoC-specific initrd modules | Generic drivers |
| `modules/users/*.nix` | OS user accounts, groups, system shell | User-space dotfiles or host config |
| `hosts/*/users.nix` | HM user → profile mapping | System-level config |
| `modules/system/hardware/*.nix` | Generic driver aspects | Machine-specific mounts |
| `modules/home/*.nix` | User-space programs & dotfiles (zsh, kitty, nvim, theme) | System services |
| `profiles/*.nix` | HM module composition for a persona | Implementation details |

---

## Architecture

```
nixos/
├── flake.nix                              # Inputs, outputs, agnostic wiring
├── flake.lock                             # Pinned dependency hashes
│
├── lib/                                   # Pure helper functions
│   ├── default.nix                        # Public API: { channels, mkHost } (+ third-party wiring)
│   ├── channels.nix                       # Pure channel builder: system+overlays+config → { stable, unstable }
│   └── mkHost.nix                         # nixosSystem constructor + HM/sops/greeter wiring
│
├── overlays/
│   └── core.nix                           # Global overlays (currently empty sentinel)
│
├── hosts/                                 # One subdirectory per machine
│   ├── default.nix                        # Auto-discovers host dirs → nixosConfigurations
│   └── thinkbook/                         # Lenovo ThinkBook 16 G7 ARP
│       ├── default.nix                    # Host composition: selects aspects + wires channels
│       ├── hardware.nix                   # Filesystems, initrd, SoC modules (machine-unique)
│       ├── users.nix                      # HM user → profile mapping
│       └── overlays.nix                   # Host-specific overlays (empty)
│
├── modules/
│   ├── users/                             # Reusable system user declarations
│   │   └── sid.nix                        # sid OS user (gated usersDef.sid.enable), sops password
│   │
│   ├── system/                            # NixOS system-level aspects
│   │   ├── default.nix                    # Aspect index: imports core, desktop, ssh, sound, power,
│   │   │                                  #   fonts, gaming, hardware/*  (Core on; rest opt-in)
│   │   ├── ssh.nix                        # Hardened OpenSSH aspect (aspects.ssh.enable)
│   │   ├── gaming.nix                     # Steam, GameMode, Wine, MangoHud, Bottles, Proton
│   │   ├── sound.nix                      # PipeWire + ALSA + PulseAudio compat + rtkit
│   │   ├── power.nix                      # Generic power management (governor, upower)
│   │   └── fonts.nix                      # System fonts + fontconfig defaults
│   │
│   │   ├── core/                          # ── Always-on fundamentals (aspects.core.enable) ──
│   │   │   ├── default.nix                # Index + aspects.core.enable option
│   │   │   ├── boot.nix                   # systemd-boot, kernel, tmpfs, zram
│   │   │   ├── locale.nix                 # i18n, timezone, console, hostname (default)
│   │   │   ├── nix.nix                    # Flakes, GC, store optimisation (unfree policy in channels)
│   │   │   ├── packages.nix              # Minimal CLI tools + nix-ld
│   │   │   └── secrets.nix                # sops-nix aspect (aspects.secrets.enable)
│   │   │
│   │   ├── desktop/                       # ── Wayland desktop aspect (aspects.desktop.enable) ──
│   │   │   ├── default.nix                # Index + aspects.desktop.enable option
│   │   │   ├── niri.nix                   # Niri compositor + uniform Wayland sessionVariables
│   │   │   ├── portals.nix               # XDG desktop portals (GTK fallback)
│   │   │   └── login.nix                  # noctalia-greeter (greetd-based login)
│   │   │
│   │   └── hardware/                      # ── Device-specific driver aspects (aspects.hardware.*) ──
│   │       ├── amd-rembrandt.nix          # AMD Ryzen 7 7735HS + Radeon 680M (+ audioPowerSave knob)
│   │       ├── network.nix               # WiFi (MT7921e + aspmFix knob), Bluetooth, firewall
│   │       ├── storage.nix               # NVMe SSD, fstrim
│   │       └── usb.nix                   # USB + USB4/Thunderbolt (bolt, opt-in knob)
│   │
│   └── home/                              # Home Manager modules (composed via profiles/)
│       ├── shell.nix                      # Zsh shell config + completion/autosuggest/aliases
│       ├── editor.nix                     # Neovim file editor + Nix LSPs + formatting
│       ├── git.nix                        # Git + Delta + lazygit
│       ├── theme.nix                      # GTK, QT, cursor, dconf theming
│       ├── desktop.nix                    # Niri user config, kitty, Wayland tools (xwayland-satellite)
│       ├── noctalia.nix                   # Noctalia v5 shell (systemd-managed)
│       └── audio.nix                      # EasyEffects DSP + Dolby-approximation preset autoload
│
├── profiles/                              # Reusable HM module compositions
│   └── desktop.nix                        # Full desktop profile (all home modules)
│
└── assets/                                # Static resources
    └── easyeffects/
        └── dolby-approximation.json       # EE7 preset: bass enhancer + 14-band EQ + limiter
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
| Storage | `nvme0n1` Micron — Linux/NixOS (root `e83c1c8c-…`, swap `4ac49bbd-…`, /boot `E06F-F08E` on `nvme1n1` SYSTEM_DRV) |
| WiFi | MediaTek MT7921e (`14c3:0616`, `disable_aspm`) |
| Bluetooth | Foxconn MediaTek (btusb) |
| Audio | Realtek ALC257 (HDA) — no smart amps; DSP via EasyEffects |
| USB4 | Rembrandt USB4 router present (`1022:15d6/15d7/162f`) → bolt enabled |

### Software Stack
| Component | Choice | Channel |
|---|---|---|
| Compositor | Niri | unstable |
| Shell + Login | Noctalia v5 shell + noctalia-greeter | flake input (cachix) |
| Secrets | sops-nix (age via SSH host ed25519) | flake input |
| Terminal | Kitty | stable |
| File Editor | Neovim (`nvim`) | stable (`nixd` + `nixfmt`) |
| Gaming Stack | Steam + GameMode + Wine + MangoHud + Bottles | stable |
| Audio | PipeWire + EasyEffects DSP | stable / unstable |
| Shell | Zsh (with autosuggestions & syntax highlighting) | stable |
| Theme | Adwaita dark (GTK + QT + dconf) | stable |
| Fonts | Inter, JetBrains Mono, FiraCode Nerd Font | stable |

---

## Conventions

- **User identity belongs in `modules/users/`.** User accounts, system shells, and sudo policies are user modules.
- **Aspect-Oriented System Modules.** Modular toggles like `gaming.nix`, `sound.nix`, and `hardware/*.nix` allow hosts to selectively assemble features.
- **Declarative Editor.** Neovim is configured at the user profile level with standard aliases (`vi`, `vim`), clipboard support, and Nix LSP capabilities.
- **Hosts own policy, modules own intent.** `allowUnfree`, aspect selection and user opt-in (`usersDef.*`) are host decisions, passed as data — never baked into `lib/`.

---

## Verification & Rollout

1. **Static gate (no build):**
   `nix eval .#nixosConfigurations.thinkbook.config.system.build.toplevel.drvPath`
2. **Full build:** `nixos-rebuild build --flake .#thinkbook` (then `switch` when ready).
3. **Sops bootstrap (one-time, before first switch):**
   - `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`
   - author `secrets/.sops.yaml` with that age key
   - `sops secrets/secrets.yaml` → key `users/sid/password` = `mkpasswd -m yescrypt` hash
4. **Audio preset:** after boot, `easyeffects --load-preset dolby-approximation` to live-validate the EE7 schema (also done by a oneshot unit).
