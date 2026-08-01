# modules/home/noctalia.nix — Noctalia v5 shell + login manager.
{ noctalia, ... }:
{
  imports = [ noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      theme = {
        mode = "dark";
      };
    };
  };
}
