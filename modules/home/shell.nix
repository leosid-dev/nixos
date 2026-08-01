# modules/home/shell.nix — Zsh shell configuration with sensible defaults.
{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

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
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos#$(hostname)";
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
}
