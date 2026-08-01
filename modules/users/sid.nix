# modules/users/sid.nix — System-level user declaration for sid.
#
# Defines the OS user identity: groups, login shell, sudo policy.
# This is a user concern, not a host concern — reusable across machines.
{ pkgs, ... }:
{
  users.users.sid = {
    isNormalUser = true;
    description = "sid";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "storage"
    ];
    shell = pkgs.zsh;
    linger = true; # Allow user services to start at boot
  };

  # Zsh must be enabled at system level for PAM / login shell integration
  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;
}
