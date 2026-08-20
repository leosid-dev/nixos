# modules/home/shell.nix — Zsh shell configuration with sensible defaults.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.home.shell;
in
{
  options.aspects.home.shell = {
    flakePath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to this flake checkout on the machine, used by the `rebuild`
        shell alias. Host data — declare per user in `hosts/<host>/users.nix`.
      '';
    };
  };

  config = {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      # Keep successive command blocks visually separated in long sessions.
      initExtra = ''
        precmd() { print }
      '';

      history = {
        size = 10000;
        save = 10000;
        share = true;
        ignoreDups = true;
        ignoreSpace = true;
        path = "$HOME/.zsh_history";
      };

      shellAliases = {
        ll = "eza -lah --icons";
        ls = "eza --icons";
        cat = "bat";
        g = "git";
        untrack = "git clean -fdX";
      } // lib.optionalAttrs (cfg.flakePath != null) {
        rebuild = "sudo nixos-rebuild switch --flake ${cfg.flakePath}#$(uname -n)";
      };
    };

    # Modern shell integration tools
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.eza = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.bat = {
      enable = true;
    };

    # Extra shell utilities
    home.packages = with pkgs; [
      zsh-completions
    ];
  };
}
