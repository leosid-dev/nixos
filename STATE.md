# STATE.md — Architecture, Design Principles & Current State

> Last updated: 2026-08-01 · 36 nix files · 820 lines

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
| **Desktop** | `modules/system/desktop/` | Niri compositor, XDG portals, login |
| **Sound** | `modules/system/sound.nix` | PipeWire stack + rtkit |
| **Power** | `modules/system/power.nix` | Generic power management |
| **Fonts** | `modules/system/fonts.nix` | System font packages |
| **Gaming** | `modules/system/gaming.nix` | Steam, GameMode, Wine, MangoHud, Bottles |
| **Hardware** | `modules/system/hardware/*.nix` | Per-device drivers & kernel modules |
| **Users** | `modules/users/*.nix` | User accounts, groups, system-level shell identity |

> **User Separation Philosophy**: User declarations (groups, login shell, sudo rules) are user identity concerns, not host concerns. Therefore, they live in `modules/users/*.nix` to remain reusable across hosts, rather than being hardcoded into host directories.

### 4. Pure Library Functions
All helpers in `lib/` are pure functions with no side effects:
- **`channels`** — builds `{ stable, unstable }` pkgs sets for a given system + overlays
- **`mkHost`** — constructs a `nixosSystem` value from `{ system, channels, users, modules }`
- **`applyOverlays`** — applies a list of overlays to a nixpkgs input

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
│   ├── default.nix                        # Public API: { channels, mkHost, applyOverlays }
│   ├── channels.nix                       # Builds stable + unstable pkgs sets
│   ├── mkHost.nix                         # nixosSystem constructor + HM wiring
│   └── overlays.nix                       # Overlay combinator (applyOverlays)
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
│   │   └── sid.nix                        # sid OS user, wheel/audio/video/input groups, zsh
│   │
│   ├── system/                            # NixOS system-level aspects
│   │   ├── core/                          # ── Always-on fundamentals ──
│   │   │   ├── default.nix                # Index: imports boot, locale, nix, packages
│   │   │   ├── boot.nix                   # systemd-boot, kernel, tmpfs, zram
│   │   │   ├── locale.nix                 # i18n, timezone, console, hostname
│   │   │   ├── nix.nix                    # Flakes, GC, store optimisation, allowUnfree
│   │   │   └── packages.nix              # Minimal CLI tools, EDITOR, nix-ld
│   │   │
│   │   ├── desktop/                       # ── Wayland desktop aspect ──
│   │   │   ├── default.nix                # Index: imports niri, portals, login
│   │   │   ├── niri.nix                   # Niri compositor (system-level enable)
│   │   │   ├── portals.nix               # XDG desktop portals (GTK + GNOME)
│   │   │   └── login.nix                  # Login services (noctalia-managed)
│   │   │
│   │   ├── hardware/                      # ── Device-specific driver aspects ──
│   │   │   ├── amd-rembrandt.nix          # AMD Ryzen 7 7735HS + Radeon 680M
│   │   │   ├── network.nix               # WiFi (MT7921e), Ethernet, Bluetooth, firewall
│   │   │   ├── storage.nix               # NVMe SSD, fstrim
│   │   │   └── usb.nix                   # USB4/Thunderbolt, bolt
│   │   │
│   │   ├── gaming.nix                     # Steam, GameMode, Wine, MangoHud, Bottles, Proton
│   │   ├── sound.nix                      # PipeWire + ALSA + PulseAudio compat + rtkit
│   │   ├── power.nix                      # Generic power management (governor, upower)
│   │   └── fonts.nix                      # System fonts + fontconfig defaults
│   │
│   └── home/                              # Home Manager modules
│       ├── shell.nix                      # Zsh shell config + completion/autosuggest/aliases
│       ├── editor.nix                     # Neovim file editor + Nix LSPs + formatting
│       ├── theme.nix                      # GTK, QT, cursor, dconf theming
│       ├── desktop.nix                    # Niri user config, Wayland env vars, kitty, tools
│       ├── noctalia.nix                   # Noctalia v5 shell + login manager
│       └── audio.nix                      # EasyEffects DSP + Dolby-approximation preset
│
├── profiles/                              # Reusable HM module compositions
│   └── desktop.nix                        # Full desktop profile (all home modules)
│
└── assets/                                # Static resources
    └── easyeffects/
        └── dolby-approximation.json       # 14-band parametric EQ preset
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
| Storage | KIOXIA NVMe (NixOS) + Micron NVMe (Windows dual-boot) |
| WiFi | MediaTek MT7921e |
| Bluetooth | Foxconn (USB) |

### Software Stack
| Component | Choice | Channel |
|---|---|---|
| Compositor | Niri | unstable |
| Shell + Login | Noctalia v5 | flake input (cachix) |
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
