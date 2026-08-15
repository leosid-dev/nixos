# Ricing cheat sheet — Niri, Noctalia, Greeter, Kitty, Neovim

Overview
- Every ricing knob lives under the `aspects.*` option tree. Persona defaults
  are set in `profiles/desktop.nix`; per-host overrides go in
  `hosts/<host>/users.nix` (Home Manager values) or `hosts/<host>/default.nix`
  (system values).
- Canonical theme values: `aspects.theme.{font,cursor,mode,accent}` (owned by
  `modules/home/theme.nix`). Kitty, GTK/QT/dconf, and Noctalia all read from
  this single source — do not duplicate font or cursor values elsewhere.
- Cross-boundary rule: NixOS modules never read Home Manager values. The
  greeter's keyboard layout follows the system-owned `aspects.locale.keyMap`.

Niri (`modules/home/niri.nix`, `aspects.home.niri`)
- Generates `~/.config/niri/config.kdl` from `gaps`, `centerFocused`,
  `showIndicators` (plus the fixed bind set: kitty spawn, vim-style
  focus/move, screenshot-to-clipboard).

Example: wider gaps, no indicators

  aspects.home.niri = {
    enable = true;
    gaps = 12;
    showIndicators = false;
  };

Noctalia (`modules/home/noctalia.nix`, `aspects.home.noctalia`)
- `programs.noctalia.settings` receives `theme.mode`/`theme.accent` from
  `aspects.theme`, plus `prompt.style` and `status.*` toggles.

Example: minimal prompt, no media widget

  aspects.home.noctalia = {
    enable = true;
    prompt.style = "minimal";
    status.media = false;
  };

Kitty (`modules/home/terminal.nix`, `aspects.home.terminal`)
- Colors derive from `aspects.theme.mode` (dark/light palette); font comes
  from `aspects.theme.font`. No independent font knob here.

Neovim (`modules/home/editor.nix`, `aspects.home.editor`)
- Fully declarative: plugins come from `pkgs.vimPlugins` (lspconfig,
  telescope, tokyonight) and config lives in `programs.neovim.extraLuaConfig`.
  Nothing is downloaded at startup.
- Tunables: `enableLSP`, `colorscheme`, `leader`; LSPs/servers from
  `extraPackages` (`nixd` + `nixfmt-rfc-style` today).

Example: comma leader, different colorscheme

  aspects.home.editor = {
    enable = true;
    neovim.colorscheme = "catppuccin";
    neovim.leader = ",";
  };

Greeter (`modules/system/desktop/login.nix`, system side)
- Enabled by `aspects.desktop.enable`; keyboard layout follows
  `aspects.locale.keyMap`. No theme values are read across the module
  boundary.

Verification (run on a host with Nix installed)
- `nix flake check`
- `nix eval .#nixosConfigurations.thinkbook.config.system.build.toplevel.drvPath`
- `nixos-rebuild build --flake .#thinkbook`, then `switch`

Manual functional checks
- Greeter: boot, confirm layout matches `aspects.locale.keyMap`.
- Niri: verify gaps/center-focused behavior and hotkeys; `Mod+Shift+S`
  copies a screenshot to the clipboard.
- Noctalia: status widgets and prompt match the aspect values.
- Neovim: open a `.nix` file, confirm `nixd` attaches and `leader+f` formats.

Troubleshooting
- Changes not visible: confirm the profile/host actually sets the
  `aspects.*` value (profile defaults use `lib.mkDefault`, host wins).
- User-side changes apply after `nixos-rebuild switch` (HM is integrated as
  a NixOS module here; no standalone `home-manager` build is wired in the
  flake outputs).
- Greeter/system changes require a system rebuild (and the next greetd
  session).

Upstream coupling
- Noctalia and the greeter assume the pinned flake inputs expose
  `programs.noctalia` and `programs.noctalia-greeter` options. If inputs are
  re-pinned, verify `modules/home/noctalia.nix` and
  `modules/system/desktop/login.nix` together.
