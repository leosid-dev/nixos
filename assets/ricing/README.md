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

Example: change greeter avatar and timeout

  aspects.greeter = {
    enable = true; # hosts opt in
    themeSync = true; # sync palette from aspects.theme.accent
    avatarPath = "/var/lib/greeter/custom-avatar.png";
    timeout = 90; # seconds
  };

Neovim: quick override (set colorscheme or leader)

  aspects.home.editor = {
    default = "neovim";
    neovim.colorscheme = "catppuccin"; # or leave unset to derive from aspects.theme.accent
    neovim.leader = ",";
  };

What the config files provide
- Niri: `xdg.configFile."niri/config.kdl"` is generated from `aspects.home.niri`. It contains:
  - `layout { gaps = <gaps>; center-focused-column = <centerFocused> }`
  - Hotkeys: `Mod+Enter` (kitty), `Mod+h/j/k/l` focus, `Mod+Shift+...` move, `Mod+Shift+S` screenshot, `Mod+Shift+Y` clipboard helper
  - Window indicators when `showIndicators = true`

- Noctalia: `programs.noctalia.settings` receives `theme.mode`, `theme.accent` (from `aspects.theme.accent`), `prompt.style`, and `status.*` booleans.

- Greeter: `modules/system/greeter.nix` toggles `programs.noctalia-greeter` and wires `palette.accent`, `avatar`, and `timeout` from `aspects.greeter`.

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
- Greeter: boot the machine, confirm greeter palette matches `aspects.theme.accent`, avatar shows, timeout triggers.
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
- The Noctalia and Greeter wiring assume the upstream Home Manager modules expose compatible option names. If your flake's module versions differ, adjust names in `modules/home/noctalia.nix` and `modules/system/greeter.nix` accordingly.
- This repo's `flake.nix` pins may require `nix` >= 2.4 with flakes enabled or `nix` from the flakes-ready environment. See your distro's docs.

Where to override (summary)
- Profile-level: `profiles/desktop.nix` — good for persona-wide default adjustments.
- Host-level: `hosts/<hostname>/users.nix` or the host's `default.nix` — for machine-specific overrides.

If you'd like I can also:
- Add a short `assets/ricing/CONFIG_EXAMPLES.md` with more copy/paste snippets for common customizations.
- Produce a unified `git` patch of my changes so you can apply/commit locally.

