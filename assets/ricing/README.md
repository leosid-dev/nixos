Ricing cheat sheet — Niri, Noctalia, Greeter, Neovim, LLM agents

Overview
- This document explains the ricing knobs under `aspects.*` and gives quick
  examples for overriding them per-profile or per-host.
- Canonical accent: `aspects.theme.accent`. Noctalia, Kitty (palette) and
  Niri (focus ring + workspace background) all read from
  `aspects.theme.palette`. Neovim is a deliberate exception: a fixed
  TokyoNight colorscheme (persona-level IDE look, not theme-driven).
- Default fonts: `Inter` for graphical interfaces and `JetBrains Mono` for
  terminal applications, both from the pinned nixpkgs. The desktop profile
  selects both families explicitly under `aspects.theme.font`.

Quick start (what to enable)
- The desktop persona (`profiles/desktop.nix`) explicitly enables home
  aspects (terminal, theme, noctalia, mpv, audio, agents); override per host in
  `hosts/<host>/users.nix` or in a new profile. Niri is mandatory for the
  desktop profile.

Example: configure the host output and tune Niri layout (host-level)

  aspects.home.niri = {
    output = {
      name = "eDP-1";
      mode = "1920x1200@60.002";
      scale = 1.0;
    };
    gaps = 12;
    cornerRadius = 6;        # window corner radius
    animationDuration = 300; # ms for the shared bezier easing
    overshoot = 0.2;         # 0 = no overshoot; higher = more bounce
  };

Example: change the UI / monospace fonts (profile-level)

  aspects.theme.font = {
    name = "Inter";
    package = pkgs.inter;
    monospace = {
      name = "JetBrains Mono";
      package = pkgs.jetbrains-mono;
    };
  };

Example: tune the Kitty terminal

  aspects.home.terminal = {
    enable = true;
    opacity = 0.9;      # default: follows aspects.theme.palette.opacity
    fontSize = 12;      # default: follows aspects.theme.font.size
    padding = 8;        # px on all sides; default 0
    scrollback = 5000;  # lines; default 2000
  };

Example: rebind the terminal keybind (default follows TERMINAL)

  aspects.home.niri.terminalCommand = "foot"; # null omits Mod+Return

Example: tune the mpv player

  aspects.home.mpv = {
    enable = true;
    hwdec = "vaapi";          # "auto-safe" probes; "no" forces software decode
    streaming.enable = true;  # yt-dlp playback for URLs
    torrents.enable = true;   # webtorrent hook: mpv <magnet-url> streams
    scripts = [               # curated catalog
      "uosc"                  # modern OSC (replaces mpv's built-in one)
      "sponsorblock-minimal"  # auto-skip YouTube sponsor segments
    ];
  };

Example: change the theme mode (dark / light)

  aspects.theme.mode = "light";

Example: switch the accent palette (drives Kitty + Noctalia + Niri; Neovim stays TokyoNight)

  aspects.theme.accent = "catppuccin-mocha";

Example: pick different LLM coding agents (or drop one)

  aspects.home.agents.packages = [ "opencode" ];

LLM agents
- `modules/home/agents.nix` installs agents from the
  `numtide/llm-agents.nix` flake input (own unstable pin, substituted from
  cache.numtide.com). Default in desktop profile: `opencode` + `grok`.
- Selection is persona data: override `aspects.home.agents.packages` with
  any names from the upstream catalog (updated daily); unknown names fail
  evaluation with a clear error. Auth is imperative (`opencode auth
  login`, grok login) — nothing declarative to configure.

Greeter
- The greeter is a system concern (`modules/system/desktop/login.nix`),
  enabled with `aspects.desktop.enable`. It reads the keyboard layout from
  `aspects.locale.keyMap` and defaults the session to niri. There are no
  per-user knobs — greeters run pre-login.

Neovim
- Configured declaratively via nixvim (`modules/home/editor.nix`): LSP
  (nixd), treesitter, telescope, cmp, which-key, gitsigns. No runtime
  plugin manager, no downloads.
- Colorscheme is a fixed persona choice: TokyoNight (dark) — it does NOT
  follow `aspects.theme.accent` or `mode` (see AGENTS.md rule 8: Neovim is
  the documented palette exception). The editor inherits the terminal's
  monospace font from the emulator it runs in.
- Key mappings: `<leader>ff` find files, `<leader>fg` live grep,
  `<leader>fb` buffers, `<leader>fs` document symbols.

What the config files provide
- Niri: `xdg.configFile."niri/config.kdl"` is generated from
  `aspects.home.niri` (host output mode/scale, gaps, corner radius, one shared
  cubic-bezier easing with a slight overshoot before settling,
  center-focused-column, workspace navigation and hotkeys) plus a focus ring
  and workspace background keyed by `aspects.theme.palette.focus`.
  The Mod+Return spawn command comes from
  `aspects.home.niri.terminalCommand`, which defaults to the canonical
  `TERMINAL` session variable set by the terminal aspect.
- Noctalia: `programs.noctalia.settings` receives the theme mode (from
  `aspects.theme.mode`), a custom palette emitted from
  `aspects.theme.palette.noctalia` (driven by `aspects.theme.accent`, m*
  Material schema with dark and light variants), and the bar layout — a
  flat macOS-style top bar with three flush lanes: workspaces + taskbar
  left, clock + notifications + privacy center, and a sysmon telemetry
  capsule (CPU temp + RAM %, joined by the CPU package power widget when
  `aspects.home.noctalia.cpuPower.enable` is on; members render denser than
  the bar at 0.9x scale, left-click anywhere in it opens Control Center
  System) followed by network,
  bluetooth, volume, battery, tray and session right. The launcher is
  keyboard-driven (Mod+D toggles it). Display density is host policy via
  `aspects.home.noctalia.uiScale` (1.15 on the ThinkBook).
- Kitty: palette derived from `aspects.theme.palette.terminal` in
  `modules/home/terminal.nix`; opacity/fontSize/padding/scrollback are
  sub-options under `aspects.home.terminal`. The module also sets the
  canonical `TERMINAL` session variable.
- GTK/dconf: Adwaita theme always; monochrome accent also sets a slate
  libadwaita accent color.
- mpv: `programs.mpv` config generated from `aspects.home.mpv` — gpu-next
  render pipeline on a Wayland context, VA-API hardware decoding
  (`hwdec` knob), demuxer caching, save-position-on-quit, yt-dlp
  streaming (`aspects.home.mpv.streaming.enable`), torrent streaming
  via webtorrent-mpv-hook (`aspects.home.mpv.torrents.enable`; magnet
  URLs and .torrent files stream while downloading), sponsor-segment
  skipping (`"sponsorblock-minimal"` in the `scripts` catalog), and
  more scripts from the curated catalog (uosc disables the built-in
  OSC/borders). The module pins video/audio MIME defaults to
  mpv.desktop; UI look is stock (not palette-driven). Keybindings are
  mpv defaults only — see `assets/mpv/CHEATSHEET.md` for the full
  shortcut reference.
- Fonts: `aspects.theme.font` is the single source of truth — GTK/dconf
  (UI), Noctalia (`shell.font_family`), and Kitty (monospace) read it.
  Neovim inherits the monospace family from the terminal it runs in. The
  theme module installs the monospace package into the user's fontconfig;
  the system fonts aspect keeps a parallel greeter-only UI font default
  (pre-login boundary).

Verification (on a machine with Nix)
- `nix eval .#nixosConfigurations.thinkbook.config.system.build.toplevel.drvPath`
- `nixos-rebuild build --flake .#thinkbook`

Manual functional checks (on the target host)
- Greeter: boot, confirm the login screen uses the console keymap and
  starts a niri session.
- Niri: login, verify the configured output scale, gaps/center-focused
  behavior, and window animations; test hotkeys (terminal spawn via
  Mod+Return, overview via Mod+O, workspace navigation, focus/move,
  launcher via Mod+D, and screenshot-to-clipboard).
- Noctalia: check the flat three-lane bar (workspaces + taskbar left,
  clock + notifications + privacy center, sysmon capsule + network,
  bluetooth, volume, battery, tray, session right), the launcher via
  Mod+D, the theme mode, and that the palette matches
  `aspects.theme.accent`.
- Neovim: open a `.nix` file, confirm nixd diagnostics and telescope
  keymaps work.
- Fonts: `fc-match "Inter"` and `fc-match "JetBrains Mono"` resolve to the
  configured families; Kitty, Noctalia, and the greeter render in them.
- mpv: play a video and open the stats overlay (`i`) — `hwdec: vaapi`
  and `vo=gpu-next`; uosc renders; a YouTube URL streams; sponsor
  segments auto-skip; a magnet URL streams while downloading; file
  managers open media in mpv by default.

Where to override (summary)
- Profile-level: `profiles/desktop.nix` — persona-wide selections.
- Host-level: `hosts/<hostname>/users.nix` or the host's `default.nix` —
  machine-specific overrides (e.g. `aspects.home.shell.flakePath`).
