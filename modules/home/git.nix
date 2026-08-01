# modules/home/git.nix — Declarative Git configuration with Delta diff integration.
{ pkgs, ... }:
{
  programs.git = {
    enable = true;

    # Default aliases
    aliases = {
      st = "status";
      co = "checkout";
      ci = "commit";
      br = "branch";
      df = "diff";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };

    # Global gitignore
    ignores = [
      "*~"
      "*.swp"
      ".DS_Store"
      "result"
      "result-*"
      ".direnv/"
      ".idea/"
      ".vscode/"
    ];

    # Extra configuration options
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.autocrlf = "input";
      fetch.prune = true;
    };

    # Enhanced diff viewer
    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
      };
    };
  };

  # Git UI tools
  home.packages = with pkgs; [
    lazygit
  ];
}
