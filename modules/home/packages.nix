# modules/home/packages.nix — Common user applications.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vlc
  ];
}
