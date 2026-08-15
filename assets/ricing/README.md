Ricing cheat sheet — Niri, Noctalia, Greeter, Neovim

Overview
- This document explains the ricing knobs introduced under `aspects.*` and gives quick examples for overriding them per-profile or per-host.
- Canonical accent: `aspects.theme.accent`. All components (Noctalia, Niri, Greeter, Neovim, Kitty) should read from this single source.

Quick start (what to enable)
- Desktop persona (profiles/desktop.nix) already imports the new modules; to enable/override per host, set `aspects.*` values in `hosts/<host>/users.nix` or a profile override.

Example: change Niri gaps and disable indicators (host-level)

  aspects.home.niri = {
    enable = true;
    gaps = 12;
    showIndicators = false;
  };

Example: change Noctalia prompt and disable media widget

  aspects.home.noctalia = {
    enable = true;
    prompt.style = "minimal";
    status.media = false;
  };

Greeter settings are system-owned by the desktop aspect. Its keyboard layout
follows `aspects.locale.keyMap`; theme values are not read across the
NixOS/Home Manager module boundary.

Neovim: quick override (set colorscheme or leader)

  aspects.home.editor = {
    default = "neovim";
    neovim.colorscheme = "catppuccin";
    neovim.leader = ",";
  };

What the config files provide
- Niri: `xdg.configFile."niri/config.kdl"` is generated from `aspects.home.niri`. It contains:
  - `layout { gaps = <gaps>; center-focused-column = <centerFocused> }`
  - Hotkeys: `Mod+Enter` (kitty), `Mod+h/j/k/l` focus, `Mod+Shift+...` move, `Mod+Shift+S` screenshot, `Mod+Shift+Y` clipboard helper
  - Window indicators when `showIndicators = true`

- Noctalia: `programs.noctalia.settings` receives `theme.mode`, `theme.accent` (from `aspects.theme.accent`), `prompt.style`, and `status.*` booleans.

- Greeter: `modules/system/desktop/login.nix` enables `programs.noctalia-greeter`
  with the shared `aspects.locale.keyMap` keyboard layout.

- Neovim: `xdg.configFile."nvim/init.lua"` and `xdg.configFile."nvim/lua/rc.lua"` are installed by Home Manager when `aspects.home.editor` chooses `neovim`.
  - Bootstraps `folke/lazy.nvim` on first start
  - Adds a concise plugin set (LSP, mason, null-ls, cmp, treesitter, telescope, which-key, gitsigns)
  - Key mappings: `<leader>ff`, `<leader>fg`, `<leader>fb`, `<leader>fs`, `<leader>r`, `<leader>f`
  - Mason ensure-installed list (best-effort): `lua-language-server`, `pyright`, `rust-analyzer`, `bash-language-server`, `marksman`, `json-lsp`.

Verification (static/eval/build)
- On a machine with Nix installed, run these non-mutating checks:
  - `nix eval .#lib`
  - `nix eval .#nixosConfigurations.thinkbook.config`
- Build checks:
  - `nix build .#homeConfigurations.sid.activationPackage`
  - `nix build .#nixosConfigurations.thinkbook.config.system.build.toplevel`

Manual functional checks (VM or test host)
- Greeter: boot the machine and confirm the Noctalia greeter starts with the
  configured keyboard layout.
- Niri: login, verify layout: `gaps` and `centerFocused` behavior; test hotkeys (kitty spawn, workspace focus, window move); screenshot hotkey copies image to clipboard.
- Noctalia: check status modules (clock/battery/network/media/workspaceIndicator) match `aspects.home.noctalia.status` booleans; check prompt style.
- Neovim: open a project (Rust/Python), allow Mason to install an LSP (e.g., `pyright`), confirm LSP diagnostics and keymaps work.

Troubleshooting
- If changes don't appear:
  - Confirm host/profile actually sets the `aspects.*` values (profile import order matters).
  - Rebuild Home Manager configuration: `home-manager switch` (or use `nix build` activation package).
  - For system greeter changes, rebuild the system and/or restart `greetd`.

- If lazy.nvim doesn't bootstrap on first run:
  - Ensure the machine has network access and `git` available. The bootstrap clones `https://github.com/folke/lazy.nvim`.
  - You can manually install lazy.nvim into `~/.local/share/nvim/lazy/lazy.nvim` and restart Neovim.

Notes and limitations
- The Neovim `rc.lua` is intentionally minimal — it's meant to be a workable, opinionated starting point. Treat it as a scaffold to extend.
- The Noctalia and Greeter wiring assume the upstream modules expose compatible
  option names. If the pinned inputs differ, adjust `modules/home/noctalia.nix`
  and `modules/system/desktop/login.nix` together.
- This repo's `flake.nix` pins may require `nix` >= 2.4 with flakes enabled or `nix` from the flakes-ready environment. See your distro's docs.

Where to override (summary)
- Profile-level: `profiles/desktop.nix` — good for persona-wide default adjustments.
- Host-level: `hosts/<hostname>/users.nix` or the host's `default.nix` — for machine-specific overrides.

If you'd like I can also:
- Add a short `assets/ricing/CONFIG_EXAMPLES.md` with more copy/paste snippets for common customizations.
- Produce a unified `git` patch of my changes so you can apply/commit locally.
