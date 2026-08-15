# profiles/desktop.nix — Home Manager profile for desktop users.
#
# Ricing knobs:
# - aspects.home.niri.*      : compositor layout/hotkeys/gaps/corners/animations
# - aspects.home.noctalia.*  : status modules, prompt style, theme sync
# - aspects.home.editor      : (nixvim; colorscheme follows aspects.theme.accent)
# - aspects.home.shell.*     : flake path for the rebuild alias
# - aspects.home.agents.*    : which LLM coding agents to install
# (The system greeter is configured by the desktop aspect, not here.)
#
# Composes the home modules needed for a full desktop experience and sets
# the per-persona aspect toggles. Imported by hosts/*/users.nix for desktop
# users.
#
# Always-on (no aspect gate):
#   - shell, editor, git      (utility, no real variation)
#   - niri, wayland           (compositor + Wayland tooling; no variation in a
#                              desktop session)
#
# Option-gated (toggle per-persona):
#   - terminal, audio, theme, noctalia, agents
{ config, lib, ... }:
{
  imports = [
    ../modules/home/shell.nix
    ../modules/home/editor.nix
    ../modules/home/git.nix
    ../modules/home/niri.nix
    ../modules/home/wayland.nix
    ../modules/home/terminal.nix
    ../modules/home/theme.nix
    ../modules/home/noctalia.nix
    ../modules/home/audio.nix
    ../modules/home/agents.nix
  ];

  aspects.home = {
    niri.enable = lib.mkDefault true;
    terminal.enable = lib.mkDefault true;
    theme.enable = lib.mkDefault true;
    noctalia.enable = lib.mkDefault true;
    audio.enable = lib.mkDefault true;
    agents.enable = lib.mkDefault true;
  };

  aspects.home.audio.presets = lib.mkDefault [
    {
      name = "dolby-approximation";
      file = ../assets/easyeffects/dolby-approximation.json;
      loadOnStart = true;
    }
  ];
}