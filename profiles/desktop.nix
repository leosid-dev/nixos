# profiles/desktop.nix — Home Manager profile for desktop users.
#
# Ricing knobs:
# - aspects.home.niri.*      : compositor layout/hotkeys/gaps/corners/animations
# - aspects.home.terminal.*  : Kitty opacity/fontSize/padding/scrollback
# - aspects.home.noctalia.*  : status modules, prompt style, theme sync
# - aspects.theme.*          : accent, mode, font, cursor, palette
# - aspects.home.agents.*    : which LLM coding agents to install
# (The system greeter is configured by the desktop aspect, not here.)
#
# Composes the home modules needed for a full desktop experience and sets
# the explicit persona aspect toggles. Imported by hosts/*/users.nix for desktop
# users.
#
# Always-on with desktop profile:
#   - shell, editor, git, niri, wayland
#
# Option-gated (explicit persona selection):
#   - terminal, theme, noctalia, audio, agents
{ config, lib, pkgs, ... }:
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
    terminal.enable = true;
    theme.enable = true;
    noctalia.enable = true;
    audio = {
      enable = true;
      graphViewer.enable = true;
      presets = [
        {
          name = "dolby-approximation";
          file = ../assets/easyeffects/dolby-approximation.json;
          loadOnStart = true;
        }
      ];
    };
    agents = {
      enable = true;
      packages = [
        "opencode"
        "grok"
      ];
    };
  };

  aspects.theme = {
    accent = "monochrome";
    mode = "dark";

    # Explicit font persona: Apple SF Pro for UI, SF Mono for code.
    # Packages come from the apple-fonts flake overlay (pkgs.sf-pro /
    # pkgs.sf-mono); the profile owns the choice, modules only default.
    font = {
      name = "SF Pro";
      package = pkgs.sf-pro;
      monospace = {
        name = "SF Mono";
        package = pkgs.sf-mono;
      };
    };
  };
}
