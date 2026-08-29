## NixOS declarative config — contract

A minimalistic, aspect-oriented, multi-host NixOS configuration.

### Source of truth

- **AGENTS.md** (this file) — the *contract*: rules the repo must honour.
- **STATE.md** — the *snapshot*: current tree, target machine, software stack.

If they conflict, AGENTS.md wins; STATE.md is updated to match after a refactor.

### Hard rules

1. **Flakes, no exceptions.** `flake.nix` is the entry point. `flake.lock` is
   committed (do not add `*.lock` to `.gitignore`).
2. **Stable + unstable pinning.** `nixpkgs` → `nixos-26.05`; `nixpkgs-unstable`
   → `nixos-unstable`. Channels are constructed in `lib/channels.nix` and
   exposed as `pkgs` (stable) + `pkgs.unstable` (unstable). Package policy
   (`allowUnfree`, etc.) is *host data*, never embedded in modules.
3. **Home Manager via flakes.** Wired in `lib/mkHost.nix`; users declare their
   HM profile in `hosts/*/users.nix`. `useGlobalPkgs = true`.
4. **Agnostic toplevel.** `flake.nix` and `lib/` must NOT mention any host,
   user, or machine-specific fact. Host discovery is `hosts/default.nix`'s
   `readDir` job.
5. **Pure functions in `lib/`.** Every helper takes data in, returns data
   out. No side effects, no `builtins.currentSystem`, no I/O.
6. **One aspect tree.** Everything toggleable lives under `aspects.*`. System
   aspects (`aspects.{core,secrets,desktop,sound,power,fonts,gaming,ssh,virtualisation}`),
   hardware aspects (`aspects.hardware.{amdRembrandt,fingerprint,network,storage,usb}`),
   user aspects (`aspects.users.*`), and home aspects (`aspects.home.*`) all
   share the same shape: `aspects.X = { enable = mkEnableOption ...; ... }`.
   Single-leaf aspects use `mkEnableOption` directly; multi-leaf aspects use
   nested-attrset style with `let cfg = config.aspects.X; in {...}`.
   Boolean subfeatures use `<feature>.enable` with conservative inert defaults.
7. **Aspect-oriented, layered.** Modules own *one* concern. Split when a
   module bundles >1 concern (e.g. `desktop.nix` was decomposed into
   `niri.nix` + `terminal.nix` + `wayland.nix`). Layer purity: generic
   modules never hardcode machine-specific facts (codec, NIC, EQ curve).
8. **No duplication.** Each value has exactly one canonical source:
   - `EDITOR` / `VISUAL` → `programs.neovim.defaultEditor`
   - `TERMINAL`         → `programs.kitty` (HM sets it)
   - keymap             → `aspects.locale.keyMap` (console + greeter share)
   - font family/cursor → `aspects.theme.font` / `aspects.theme.cursor`
    - accent palette     → `aspects.theme.palette` (derived from canonical
                           `aspects.theme.accent`; Noctalia, Kitty, and
                           Niri focus-ring/background all read it — Neovim
                           is a deliberate exception with a fixed TokyoNight
                           colorscheme)
   - cachix key         → `modules/system/core/nix.nix`
9. **Compositor + shell.** Niri (unstable) is the Wayland compositor;
   Noctalia v5 shell via Home Manager; noctalia-greeter via greetd (system
   module — greeters run pre-login, HM cannot manage them).
10. **Ask before sensible selections.** When a choice has real tradeoffs,
    surface them — do not silently pick.

### HM gating model (hybrid)

Home-Manager modules are **gated only when they have real per-persona
variation**:

| Module | Gate | Rationale |
|---|---|---|
| `shell.nix`     | always-on | CLI tools, no variation |
| `editor.nix`    | always-on | Editor choice is profile-level |
| `git.nix`       | always-on | Git config is profile-level (identity in host user data) |
| `packages.nix`  | always-on | Shared user applications, no variation |
| `niri.nix`      | always-on (with desktop profile) | Compositor is required |
| `wayland.nix`   | always-on (with desktop profile) | Required for the session |
| `terminal.nix`  | `aspects.home.terminal.enable`  | Terminal choice varies |
| `theme.nix`     | `aspects.home.theme.enable`     | Theme choice varies |
| `noctalia.nix`  | `aspects.home.noctalia.enable`  | Shell choice varies |
| `nautilus.nix`  | `aspects.home.nautilus.enable`  | File-manager choice varies |
| `mpv.nix`       | `aspects.home.mpv.enable`       | Media player choice varies (hwdec/scripts/streaming/torrent knobs) |
| `audio.nix`     | `aspects.home.audio.enable`     | DSP choice varies (presets option too) |
| `agents.nix`    | `aspects.home.agents.enable`    | Agent selection varies (`packages` option) |

`profiles/desktop.nix` is the only composition point that sets these
aspects. To make a different persona, write a new profile.

### Hardware aspects are opt-in

Generic driver aspects live in `modules/system/hardware/` (fingerprint, network,
storage, usb). Machine-specific quirks (MT7921e ASPM, AMD Rembrandt audio power-save)
live in the same files but are gated behind sub-options. Hosts enable only
the aspects their hardware needs.

### Phase-1 deliverables

- niri + noctalia + noctalia-greeter via the right layers
- uniform Wayland session env at system level
- minimal sensible core packages (CLI tools, no bloat)
- font stack + GTK/QT/cursor theme at HM level
- sops-nix age-via-SSH for secrets

### Phase-2 deliverables

- hardware coverage for the target machine (Ryzen 7 7735HS + Radeon 680M)
- WiFi (MT7921e), BT, NVMe, USB4 drivers + sub-options
- audio DSP via PipeWire + EasyEffects (convolution presets built from
  Dolby impulse responses captured on the machine, for the Realtek ALC257
  analog path; preset and impulse paths are profile options, not hardcoded
  in the generic module)
