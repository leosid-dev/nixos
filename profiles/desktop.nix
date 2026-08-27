# profiles/desktop.nix — Home Manager profile for desktop users.
#
# Ricing knobs:
# - aspects.home.niri.*      : compositor layout/hotkeys/gaps/corners/animations
# - aspects.home.terminal.*  : Kitty opacity/fontSize/padding/scrollback
# - aspects.home.noctalia.*  : uiScale, cpu-power plugin (palette/bar follow aspects.theme)
# - aspects.theme.*          : accent, mode, font, cursor, palette
# - aspects.home.agents.*    : which LLM coding agents to install
# (The system greeter is configured by the desktop aspect, not here.)
#
# Composes the home modules needed for a full desktop experience and sets
# the explicit persona aspect toggles. Imported by hosts/*/users.nix for desktop
# users.
#
# Always-on with desktop profile:
#   - shell, editor, git, packages, niri, wayland
#
# Option-gated (explicit persona selection):
#   - terminal, theme, noctalia, nautilus, audio, agents
{ config, lib, pkgs, ... }:
{
  imports = [
    ../modules/home/shell.nix
    ../modules/home/editor.nix
    ../modules/home/git.nix
    ../modules/home/packages.nix
    ../modules/home/nautilus.nix
    ../modules/home/niri.nix
    ../modules/home/wayland.nix
    ../modules/home/terminal.nix
    ../modules/home/theme.nix
    ../modules/home/noctalia.nix
    ../modules/home/noctalia-cpu-power.nix
    ../modules/home/audio.nix
    ../modules/home/agents.nix
  ];

  aspects.home = {
    nautilus.enable = true;
    terminal.enable = true;
    theme.enable = true;
    noctalia.enable = true;
    audio = {
      enable = true;
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

    # Explicit font persona: Inter for graphical interfaces and JetBrains
    # Mono for terminal and code applications.
    font = {
      name = "Inter";
      package = pkgs.inter;
      monospace = {
        name = "JetBrains Mono";
        package = pkgs.jetbrains-mono;
      };
    };
  };
}
