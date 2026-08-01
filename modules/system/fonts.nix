# modules/system/fonts.nix — System font packages and fontconfig defaults.
{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    inter
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    jetbrains-mono
    (nerd-fonts.fira-code)
  ];

  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Inter" "Noto Sans" ];
    monospace = [ "JetBrains Mono" "FiraCode Nerd Font" ];
    emoji = [ "Noto Color Emoji" ];
  };
}
