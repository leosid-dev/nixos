Ricing cheat sheet — Niri, Noctalia, Greeter, Neovim, LLM agents

Overview
- This document explains the ricing knobs under `aspects.*` and gives quick
  examples for overriding them per-profile or per-host.
- Canonical accent: `aspects.theme.accent`. Noctalia, Neovim (colorscheme),
  Kitty (palette) and Niri (focus ring + workspace background) all read
  from this single source.

Quick start (what to enable)
- The desktop persona (`profiles/desktop.nix`) already enables every home
  aspect via `lib.mkDefault`; override per host in `hosts/<host>/users.nix`
  or in a new profile.

Example: change Niri gaps, corner radius and animation feel (host-level)

  aspects.home.niri = {
    enable = true;
    gaps = 12;
    cornerRadius = 6;        # window corner radius
    animationDuration = 300; # ms for the shared bezier easing
    overshoot = 0.2;         # 0 = no overshoot; higher = more bounce
  };

Example: change the Noctalia theme mode

  aspects.home.noctalia = {
    enable = true;
    theme.mode = "light";
  };

Example: switch the accent palette (drives Kitty + Neovim + Noctalia)

  aspects.theme.accent = "catppuccin-mocha";

Example: pick different LLM coding agents (or drop one)

  aspects.home.agents.packages = [ "opencode" ];

LLM agents
- `modules/home/agents.nix` installs agents from the
  `numtide/llm-agents.nix` flake input (own unstable pin, substituted from
  cache.numtide.com). Default: `opencode` + `grok`.
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
- Colorscheme follows `aspects.theme.accent`: `monochrome` → mini-base16
  grayscale, `catppuccin-mocha` → catppuccin (mocha), anything else →
  tokyonight.
- Key mappings: `<leader>ff` find files, `<leader>fg` live grep,
  `<leader>fb` buffers, `<leader>fs` document symbols.

What the config files provide
- Niri: `xdg.configFile."niri/config.kdl"` is generated from
  `aspects.home.niri` (gaps, corner radius, one shared cubic-bezier easing
  with a slight overshoot before settling, center-focused-column, hotkeys)
  plus a focus ring and workspace background keyed by
  `aspects.theme.accent` (monochrome = grayscale ring on true black).
- Noctalia: `programs.noctalia.settings` receives the theme mode, the
  palette source (from `aspects.theme.accent`), and the bar layout —
  macOS-style straight rectangle: workspaces + running-app icons (taskbar)
  left, clock center, resource stats / battery rate / performance-mode
  toggle / system icons right. The app launcher floats at top-center of
  the screen. A monochrome custom palette (true-black surfaces) ships
  with the module.
- Kitty: palette keyed by `aspects.theme.accent` in
  `modules/home/terminal.nix` (monochrome = true black, opaque).
- GTK/dconf: Adwaita theme always; monochrome accent also sets a gray
  libadwaita accent color.

Verification (on a machine with Nix)
- `nix eval .#nixosConfigurations.thinkbook.config.system.build.toplevel.drvPath`
- `nixos-rebuild build --flake .#thinkbook`

Manual functional checks (on the target host)
- Greeter: boot, confirm the login screen uses the console keymap and
  starts a niri session.
- Niri: login, verify gaps/center-focused behavior; window animations
  should overshoot slightly then settle; test hotkeys (kitty spawn,
  focus/move, screenshot-to-clipboard).
- Noctalia: check the bar layout (workspaces/app icons left, clock
  center, stats + performance toggle + icons right), the launcher
  opening at top-center, the theme mode, and that the palette matches
  `aspects.theme.accent`.
- Neovim: open a `.nix` file, confirm nixd diagnostics and telescope
  keymaps work.

Where to override (summary)
- Profile-level: `profiles/desktop.nix` — persona-wide defaults.
- Host-level: `hosts/<hostname>/users.nix` or the host's `default.nix` —
  machine-specific overrides (e.g. `aspects.home.shell.flakePath`).
