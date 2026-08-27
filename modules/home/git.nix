# modules/home/git.nix — Declarative Git configuration with Delta diff integration.
{ pkgs, ... }:
{
  programs.git = {
    enable = true;
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

    # Settings + aliases (HM >= 26.05: `settings` replaces `extraConfig`
    # and `aliases`). Commit identity (user.name/email) is persona data and
    # lives in hosts/<host>/users.nix — this module stays persona-free.
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.autocrlf = "input";
      fetch.prune = true;

      alias = {
        st = "status";
        co = "checkout";
        ci = "commit";
        br = "branch";
        df = "diff";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };
  };

  # Enhanced diff viewer (HM >= 26.05: standalone programs.delta).
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = true;
      line-numbers = true;
    };
  };

  # Git UI tools
  home.packages = with pkgs; [
    lazygit
  ];
}
