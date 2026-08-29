# STATE.md — Architecture, Design Principles & Current State

> Last updated: 2026-08-29 · Greeter fingerprint wake: login.nix wires
> auth.allow_empty_password to aspects.hardware.fingerprint — the greeter
> only starts the greetd/PAM conversation on submit and pam_fprintd is the
> first (sufficient) module of the greetd stack, so empty-submit allowance
> makes the sensor wake on Enter (fprintd's "Place finger" shown as a
> status hint) instead of only after a password attempt; typed passwords
> still work (armed and auto-posted to the pam_unix try_first_pass prompt
> once fprintd fails or times out). Zero-keypress wake is not possible with
> greeter 1.2.1: no auto-start hook, and greetd's sequential PAM protocol
> cannot claim the reader concurrently with the password prompt.
> Prior: Greeter appearance pass: the noctalia-greeter
> is now declaratively synced with the Noctalia shell — login.nix ships a
> complete 16-key [appearance.palette] derived from lib/palettes.nix via a
> system-side accent/mode mirror (modules/system/theme.nix; defaults must
> stay aligned with the HM profile's aspects.theme selection), plus
> scheme=Synced, theme_mode, hide_logo, and the uiFont family; no
> wallpaper key, so the backdrop paints from the shipped palette (true
> black in dark mode, matching niri's). hover/on_hover mirror the runtime
> hover=tertiary mapping; a complete declarative palette wins over the
> shell-written sync.toml, making the look deterministic from first boot.
> Prior: Virtualisation aspect audit pass: removed the
> redundant security.polkit.enable from platform.nix (the libvirtd module
> owns polkit), VFIO modules now also load in initrd so vfio-pci.ids= claims
> devices before udev coldplug binds host drivers, virtiofs hostPaths must
> be whitespace-free (tmpfiles field-splitting corrupts such rules), and
> virt-disk/README now describe the default root-mode reality — qemu-libvirtd
> is the at-rest owner libvirt's dynamic ownership restores, not the runtime
> user; run-nixos-iso.sh is documented as a pre-install helper for hosts with
> direct /dev/kvm access.
> Prior: Fingerprint auth added via
> aspects.hardware.fingerprint: the ThinkBook's Goodix 27c6:659a reader runs
> on upstream libfprint goodixmoc (match-on-chip, no TOD blob); enabling
> fprintd flips the per-service fprintAuth default on for every PAM stack
> (greetd, sudo, su, polkit-1, …) while `login` (Noctalia's lock screen
> claims the reader itself over D-Bus) and `sshd` are explicitly carved out.
> Enrollment is imperative (`fprintd-enroll`, persisted in /var/lib/fprintd).
> Prior: webtorrent-mpv-hook now carries a patch
> (modules/home/patches/webtorrent-mpv-hook-sanitize-magnet.patch) that
> normalises Torrentio/Stremio magnets — their trackers ship as
> `tracker:udp://...`, a scheme bittorrent-tracker rejects, which
> degraded discovery to DHT-only and stalled playback on "Info hash"
> forever; the hook rewrites the tr= list to plain udp/https schemes
> before webtorrent sees the magnet (verified: the previously stuck
> magnet streams end-to-end).
> Prior: Enhanced speaker preset tightened: the exciter
> ceiling is now active, bounding its 2nd harmonics to 5.5–16 kHz (the band
> the small drivers can actually voice) instead of up to Nyquist — the only
> deviation from the upstream mister2d enhanced stage values; the 48 kHz
> kernel ↔ graph-rate invariant (LSP's convolver does not resample kernels)
> is documented in assets/easyeffects/README.md. A movie-enhanced variant
> (thinkbook-speakers-movie-enhanced) applies the same enhanced stages to
> the DolbyMovie kernel for video content.
> Prior: Media playback moved from VLC to mpv: a new
> gated home module (aspects.home.mpv) owns the player — gpu-next render
> pipeline on a Wayland context, VA-API hardware decoding, demuxer
> caching, save-position-on-quit, a curated script catalog (uosc, which
> takes over the OSC and borders; sponsorblock-minimal for YouTube
> sponsor segments), a yt-dlp streaming sub-option, torrent streaming
> via webtorrent-mpv-hook, and video/audio MIME defaults pinned to
> mpv.desktop. VLC is gone from packages.nix. A shortcuts cheatsheet
> lives at assets/mpv/CHEATSHEET.md.
> Prior: ThinkBook speaker DSP rebuilt on convolution:
> the hand-tuned EQ "Dolby approximation" preset (v1) is replaced by presets
> that convolve vendor-captured Dolby impulse responses of a ThinkBook 16 G7
> (WASAPI loopback, shuhaowu/linux-thinkpad-speaker-improvements @ 92410d6,
> vendored under assets/easyeffects/irs/ with verified blob SHAs) behind a
> brickwall limiter with threshold boost; a convolver → exciter → autogain →
> limiter enhanced variant follows the stage design of mister2d/
> thinkpad-linux-audio (classifier-dependent multiband compression dropped).
> The generic audio HM module gained an impulses deployment option plus
> eval-time kernel-name resolution assertions; the ThinkBook audio profile
> autoloads thinkbook-speakers-dolby-music and deploys a movie variant for
> manual selection. The EasyEffects service runs display-connected again
> (service.headless off on ThinkBook): an offscreen instance holds the
> app's single-instance lock on an invisible display and the GUI launch
> gets forwarded into the void, while niri already imports the session
> env (WAYLAND_DISPLAY, QT_QPA_PLATFORM) into the systemd user manager
> for the service to use. The service starts with --service-mode
> --hide-window: in the Qt rewrite --service-mode alone does not hide
> the window (it only persists a settings flag), while --hide-window
> creates the window hidden and a plain app launch forwards to the
> service and shows it on demand. A best-effort display-wait
> ExecStartPre (poll the Wayland socket ≤15s) protects both the service
> and the preset loader from the graphical-session.target-races-the-
> compositor-socket startup coredump; loader TimeoutStartSec raised to
> match.
> Prior: cpu-power widget hardened to production grade
> (Luau sampler: source pinning with baseline reset, paired max-range index,
> suspend/clock-step discontinuity guards, maxWatts as sanity gate instead of
> display clamp, tooltip enriched via systemStats() to match the sibling
> sysmon widgets; Nix: eval-time assertions for source presence + parallel
> path lists, charset-constrained path/glyph types) + sysmon capsule members
> scaled 0.9x bar scale; prior: noctalia contract sweep (display density
> externalized as aspects.home.noctalia.uiScale; mkForce service overrides
> replaced by wayland.systemd.target = niri.service; settings equal to
> upstream defaults pruned, incl. the duplicated bar font and the whole
> system.monitor block; dead mHover/mOnHover palette tokens removed;
> ricing cheat sheet bar/palette descriptions fixed) + cpu-power fix
> (inert udev MODE rule replaced by event-driven chmod — RAPL devices are
> sysfs-only; cpuPower gained pollIntervalMs and maxWatts tunables;
> sysmon capsule left-click → Control Center System via member defaults /
> plugin.toml [widget.actions]; capsule membership owned solely by
> noctalia.nix, cpu-power module is deploy-only)

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
| `aspects.{core,secrets,desktop,sound,power,fonts,gaming,ssh,virtualisation}` | System aspects | Nix settings, boot, locale, sound stack, gaming (+wine/firewall), KVM/virtiofs, … |
| `aspects.hardware.{amdRembrandt,network,storage,usb}` | Hardware aspects | Per-device drivers, kernel modules, quirks |
| `aspects.users.*` | User identity | OS-level user account declaration |
| `aspects.home.*` | Home-Manager toggles | Per-persona HM opt-ins (audio, theme, …) |
| `aspects.locale` | System cross-cutting | Keymap shared by console and greeter |
| `aspects.theme` | Home Manager cross-cutting | Font, cursor, mode, accent, and structured palette; system-side accent/mode mirror (`modules/system/theme.nix`) feeds the pre-login greeter |

> Every aspect except Core is **off by default** and enabled per host (or per
> profile) through the `aspects.*` option tree. The naming convention is
> **camelCase options, kebab-case files** (`aspects.hardware.amdRembrandt`).
> Boolean subfeatures strictly use `<feature>.enable` with conservative inert defaults.

### 4. Pure Library Functions
All helpers in `lib/` are pure functions with no side effects:
- **`channels`** — builds `{ stable, unstable }` pkgs sets for a given system + overlays + config. The `unstable` set is attached to `stable` through a **real overlay** (`final: prev: { inherit unstable; }`) at construction. Unfree/licensing policy is passed in as data by each host; never embedded.
- **`mkHost`** — constructs a `nixosSystem` value from `{ system, channels, users, modules }`, auto-wiring Home Manager, sops-nix, and the noctalia-greeter NixOS modules (each inert until configured).
- **`palettes`** — pure color token table (accent → mode → palette record) consumed across Noctalia, Kitty, and Niri. Neovim is a deliberate exception with a fixed TokyoNight colorscheme.

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
- **Always-on with desktop profile:** `shell`, `editor`, `git`, `packages`, `niri`, `wayland`
- **Gated via `aspects.home.*`:** `terminal`, `theme`, `noctalia`, `nautilus`, `mpv`, `audio`, `agents`

A persona is a profile; `profiles/desktop.nix` is the only one today.

---

## Architecture

```
nixos/
├── flake.nix                              # Inputs, outputs, agnostic wiring
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
│   │   ├── fonts.nix                      # System font packages (Noto, Noto Emoji, Inter for greeter)
│   │   ├── theme.nix                        # System-side accent/mode mirror for the pre-login
│   │   │                                  #   greeter (colors always derived from lib/palettes.nix)
│   │   ├── core/                          # Always-on fundamentals (aspects.core.enable)
│   │   │   ├── default.nix                # Index
│   │   │   ├── boot.nix                   # systemd-boot (limit 3), kernelPackages option, tmpfs, zram
│   │   │   ├── locale.nix                 # i18n, console keymap + earlySetup, aspects.locale.keyMap
│   │   │   ├── nix.nix                    # Flakes, GC, store optimisation, binary caches
│   │   │   ├── packages.nix               # Minimal CLI tools + nix-ld
│   │   │   └── secrets.nix                # sops-nix (aspects.secrets.{enable,file,sshKeyPaths})
│   │   ├── desktop/                       # Wayland desktop (aspects.desktop.enable)
│   │   │   ├── default.nix                # Index (niri, portals, login, browser)
│   │   │   ├── niri.nix                   # Niri compositor + uniform Wayland sessionVariables (SDL fallback)
│   │   │   ├── portals.nix                # XDG desktop portals (GTK fallback) + dconf + Secret portal provider
│   │   │   ├── browser.nix                # Firefox (system-level, native Wayland)
│   │   │   └── login.nix                  # noctalia-greeter: declarative synced appearance
│   │   │                                  #   (palette from lib/palettes.nix via the aspects.theme
│   │   │                                  #   mirror, theme_mode, hide_logo, uiFont family, keyMap)
│   │   ├── virtualisation/                # KVM/QEMU virtualisation aspect
│   │   │   ├── default.nix                # Index (aspects.virtualisation.enable)
│   │   │   ├── platform.nix               # libvirtd (root mode), QEMU, virt-manager, virtiofsd
│   │   │   ├── storage.nix                # virt-disk image creation tool (metadata sparse qcow2, raw)
│   │   │   ├── shares.nix                 # Host-backed virtiofs shares, tmpfiles dirs, /etc/virtfs/ artifacts
│   │   │   └── features.nix               # Optional knobs (ksm, swtpm, spiceUsbRedirection, vfio)
│   │   └── hardware/                      # Device-specific driver aspects
│   │       ├── amd-rembrandt.nix          # AMD Ryzen 7 7735HS + Radeon 680M
│   │       ├── fingerprint.nix            # fprintd + pam_fprintd (goodixmoc; login/sshd carve-outs)
│   │       ├── network.nix                # WiFi (MT7921e + aspmFix knob), BT (+bluetooth.enable), firmware
│   │       ├── storage.nix                # fstrim, udisks2, fwupd (manual LVFS updates)
│   │       └── usb.nix                    # USB + USB4/Thunderbolt (+thunderbolt.enable)
│   │
│   └── home/                              # Home Manager modules
│       ├── shell.nix                      # Zsh + fzf + eza + bat (always-on; flakePath required)
│       ├── editor.nix                     # Neovim via nixvim (always-on, sets EDITOR/VISUAL, fixed TokyoNight)
│       ├── git.nix                        # Git + Delta + lazygit (always-on; identity in host user data)
│       ├── packages.nix                   # Shared user applications (always-on)
│       ├── mpv.nix                         # mpv player: gpu-next/VA-API, caching,
│       │                                  #   uosc, yt-dlp/torrent streaming,
│       │                                  #   sponsorblock-minimal, media MIME pins
│       ├── patches/                        # Carried upstream patches
│       │   └── webtorrent-mpv-hook-sanitize-magnet.patch
│       │                                  #   rewrites Torrentio "tracker:udp://"
│       │                                  #   trackers (bittorrent-tracker rejects
│       │                                  #   the scheme → DHT-only stall) to plain
│       │                                  #   udp/https before client.add
│       ├── niri.nix                       # Niri user config.kdl (always-on with desktop profile, palette-derived rings)
│       ├── wayland.nix                    # grim/slurp/wl-clipboard/xwayland-satellite/qt-wayland
│       ├── terminal.nix                   # Kitty, structured palette, sets TERMINAL; opacity/fontSize/padding knobs
│       ├── theme.nix                      # GTK/QT/cursor/dconf (accent enum, mode, font defaults, palette + noctalia material)
│       ├── noctalia.nix                   # Noctalia v5 shell (uiScale, bar layout + sole
│       │                                  #   sysmon capsule_group writer, custom palette)
│       ├── noctalia-cpu-power.nix         # CPU power plugin deploy only (RAPL/hwmon paths,
│       │                                  #   eval assertions; no bar layout overrides)
│       ├── nautilus.nix                   # Nautilus file manager + dconf defaults (aspects.home.nautilus)
│       ├── audio.nix                      # Generic EasyEffects DSP service + preset/impulse
│       │                                  #   deployment (kernel-name assertions; hide-window
│       │                                  #   startup + display-wait ExecStartPre)
│       └── agents.nix                     # LLM agents from llm-agents.nix (packages default [])
│
├── profiles/
│   ├── desktop.nix                        # Reusable desktop persona and generic HM aspects
│   ├── thinkbook-audio.nix                # ThinkBook convolution speaker presets + headphone preset policy
│   └── thinkbook-noctalia.nix             # ThinkBook Noctalia policy (uiScale, CPU power RAPL paths)
│
└── assets/
    ├── easyeffects/
    │   ├── README.md                       # Approach, preset guide, IRS provenance + caveats
    │   ├── thinkbook-speakers-dolby-music.json     # Convolver (DolbyMusic IRS) → limiter (autoloaded)
    │   ├── thinkbook-speakers-dolby-movie.json     # Convolver (DolbyMovie IRS) → limiter
    │   ├── thinkbook-speakers-enhanced.json        # Convolver (DolbyMusic IRS) → exciter → autogain → limiter
    │   ├── thinkbook-speakers-movie-enhanced.json  # Convolver (DolbyMovie IRS) → exciter → autogain → limiter
    │   ├── headphones-neutral.json        # Neutral headphone preset (safety limiter only)
    │   └── irs/
    │       └── thinkbook16-g7/             # Dolby IRS captured from ThinkBook 16 G7 (community)
    ├── ricing/
    │   └── README.md                      # Ricing cheat sheet: aspect knobs, examples, checks
    ├── mpv/
    │   └── CHEATSHEET.md                  # mpv shortcuts: defaults + uosc/sponsorblock/webtorrent keys
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
| Storage | `nvme0n1` Micron: ESP "boot" (2 GiB) + swap (8 GiB) + root "nixos" (plain ext4 without LUKS — accepted design); `nvme1n1` KIOXIA: "vmdata" (150 GiB → `/var/lib/libvirt` for images + virtiofs data shares) + "media" (rest → `/home/sid/media`). Label-based refs; layout created by WALKTHROUGH.md |
| WiFi | MediaTek MT7921e (`14c3:0616`, `disable_aspm`) |
| Bluetooth | Foxconn MediaTek (btusb), Noctalia control-center Bluetooth service (Blueman applet removed) |
| Audio | Realtek ALC257 (HDA) — no smart amps; DSP via EasyEffects profile preset |
| USB4 | Rembrandt USB4 router present → bolt enabled |
| Fingerprint | Goodix `27c6:659a` — libfprint `goodixmoc` match-on-chip (no TOD driver) |

### Software Stack
| Component | Choice | Channel |
|---|---|---|
| Compositor | Niri | unstable |
| Shell + Login | Noctalia v5 + noctalia-greeter | flake input (cachix) |
| Secrets | sops-nix (age via SSH host ed25519) | flake input |
| Terminal | Kitty | stable (auto-sets TERMINAL) |
| Browser | Firefox (system-level, native Wayland via MOZ_ENABLE_WAYLAND) | stable |
| Media player | mpv (gpu-next + VA-API, uosc, yt-dlp + torrent streaming, sponsorblock) | stable |
| File Editor | Neovim via nixvim (nixd LSP, sets EDITOR/VISUAL) | flake input |
| LLM Agents | opencode + grok via numtide/llm-agents.nix | flake input (own unstable pin, numtide cache) |
| Gaming Stack | Steam + GameMode + Wine + MangoHud + Bottles | stable |
| Virtualisation | KVM/QEMU (libvirt + virt-manager), host-backed virtiofs data share, virtio-gpu + Venus | stable |
| Privilege prompts | Noctalia's native polkit agent (`shell.polkit_agent`) | flake input |
| Audio | PipeWire + EasyEffects DSP | stable |
| Shell | Zsh (with autosuggestions & syntax highlighting) | stable |
| Theme | Monochrome (true-black) via `aspects.theme.accent`; Adwaita GTK/QT + dconf; structured `aspects.theme.palette` | stable |
| Fonts | Inter (GUI) + JetBrains Mono (TUI), Noto Fonts, Noto Color Emoji | stable |
| Firmware | fwupd (LVFS, manual `fwupdmgr update`) | stable |
| Fingerprint auth | fprintd + pam_fprintd (every service; `login`/`sshd` carved out) | stable |

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
   - `ssh-to-age -i /etc/ssh/thinkbook_ed25519.pub`
   - add the derived age recipient to an active `creation_rules` entry in
     `secrets/.sops.yaml`
   - `sops secrets/secrets.yaml` → set `users/sid/password` to
     `mkpasswd -m yescrypt` hash
2. **Flake check:** `nix flake check` (evaluates the flake outputs; no feature-specific asset checks are defined)
3. **Static gate:** `nix eval .#nixosConfigurations.thinkbook.config.system.build.toplevel.drvPath`
4. **Full build:** `nixos-rebuild build --flake .#thinkbook` (then `switch`)
5. **Audio preset:** The ThinkBook Home Manager audio profile autoloads
   `thinkbook-speakers-dolby-music` (convolver, Dolby IRS) on session start.
   `thinkbook-speakers-dolby-movie`, `thinkbook-speakers-enhanced`, and
   `thinkbook-speakers-movie-enhanced` are deployed for manual selection, as
   is `headphones-neutral` — select it before using headphones.
6. **Firmware:** `fwupdmgr refresh && fwupdmgr update` (manual, on demand).
7. **LLM agents:** `opencode --version && grok --version`; auth is
   imperative (`opencode auth login`, grok login) — nothing declarative.
8. **Virtualisation:** `systemctl status libvirtd && virsh version`, then
   follow `assets/virt/README.md`: `virt-disk ubuntu 64G`, activate the
   default libvirt network, create the Ubuntu VM (UEFI, virtio-blk tuned),
   add the virtiofs data share from `/var/lib/libvirt/shares/ubuntu`, and
   verify the guest mount and `vulkaninfo` (Venus).
9. **Visual:** reboot to the greeter first: the login card paints from the
    declarative synced palette (true-black backdrop in dark mode, no
    brand logo, Inter UI font — identical tokens to the shell's bar).
    Then `niri validate` against the generated config, then check
    the bezier overshoot/settle, radius-8 corners, grayscale focus ring on
    true-black background, and the flat macOS-style bar: workspaces + taskbar
    left, clock + notifications + privacy center, sysmon capsule (cpu_temp +
    ram_pct, + cpu_power plugin; members at 0.9x bar scale; left-click →
    Control Center System) -> spacer
   -> network, bluetooth, volume, battery, tray, session right.
10. **Media player:** `mpv --version`; play a video and open the stats
    overlay (`i`) to confirm `hwdec: vaapi` and `vo=gpu-next`; the uosc
    UI renders, `mpv <youtube-url>` streams, `mpv <magnet-url>` streams a
    torrent while downloading (Torrentio/Stremio magnets with
    `tracker:`-prefixed trackers included — the sanitize-magnet patch
    normalises them), YouTube sponsor segments auto-skip, and
    Nautilus "Open with" defaults to mpv for video/audio files.
    Shortcut reference: `assets/mpv/CHEATSHEET.md`.
11. **Fingerprint:** `fprintd-enroll sid` (imperative — templates persist in
    `/var/lib/fprintd`), then verify `sudo -k && sudo -v` offers the reader
    and the Noctalia lock screen unlocks with a finger. At the greeter:
    Enter on the empty field wakes the sensor ("Place finger" hint) and a
    finger logs in; a typed password still logs in after the fprintd
    timeout/failure.

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
| `aspects.hardware.fingerprint.enable` | hardware/fingerprint.nix | `false` | fprintd + pam_fprintd on every PAM service; `login` (Noctalia lock screen claims the reader over D-Bus) and `sshd` excluded; eval assertion: `unixAuth` must stay on wherever `fprintAuth` is on (password fallback invariant); the greeter gains empty-submit wake-on-Enter (login.nix) |
| `aspects.home.noctalia.uiScale` | home/noctalia.nix | `1.0` | UI scale multiplier (ui_scale + bar scale); 1.15 on ThinkBook |
| noctalia-greeter appearance | desktop/login.nix | synced | Declarative `[appearance]`: scheme=Synced, 16-key palette from `lib/palettes.nix` via the `aspects.theme` system mirror, theme_mode, hide_logo, `aspects.fonts.uiFont.name`; no wallpaper key (palette-driven backdrop) |
| `aspects.home.noctalia.cpuPower.enable` | home/noctalia-cpu-power.nix | `false` | CPU package power widget (RAPL/hwmon paths are host data) |
| `aspects.home.noctalia.cpuPower.pollIntervalMs` | home/noctalia-cpu-power.nix | `2000` | Plugin sampling cadence (Δenergy/Δt); also the discontinuity window (`max(4x, 10s)` → drop + re-baseline) |
| `aspects.home.noctalia.cpuPower.maxWatts` | home/noctalia-cpu-power.nix | `500` | Sanity gate: higher readings are dropped and re-baselined, never clamped for display |
| `aspects.home.noctalia.cpuPower.glyph` | home/noctalia-cpu-power.nix | `"bolt"` | Material glyph beside the watt reading |
| `aspects.home.audio.graphViewer.enable` | home/audio.nix | `false` | PipeWire graph viewer tool (crosspipe) |
| `aspects.virtualisation.ksm.enable` | virt/features.nix | `false` | Memory deduplication (off on laptops to save CPU/battery) |
| `aspects.virtualisation.swtpm.enable` | virt/features.nix | `false` | Emulated TPM 2.0 |
| `aspects.virtualisation.spiceUsbRedirection.enable` | virt/features.nix | `false` | SPICE USB device redirection |
| `aspects.virtualisation.vfio.ids` | virt/features.nix | `[]` | PCI IDs (`vendor:device`) bound to vfio-pci via `vfio-pci.ids`; empty list = modules loaded, nothing bound (hardware-dependent operator choice) |
| `documentation.nixos.enable` | core/default.nix | `false` | drops NixOS HTML/manual generation |
| `aspects.hardware.amdRembrandt.perfTuning.enable` | amd-rembrandt.nix | `false` | iommu=pt, nowatchdog, vm.swappiness=10 |
| `aspects.hardware.amdRembrandt.audio.enable` | amd-rembrandt.nix | `false` | Explicit host-selected HDA power-save tuning |
| `aspects.hardware.amdRembrandt.abmLevel` | amd-rembrandt.nix | `null` | Adaptive Backlight Management knob |
| `lazytime` on ext4 mounts | hosts/thinkbook/hardware.nix | on | journal write reduction |
| `nix.settings.{auto-optimise-store,max-jobs,cores}` | core/nix.nix | — | store dedup on write + full parallelism |
| `configurationLimit = 3` | core/boot.nix | 3 | bounds /boot + store-level generation prune |
