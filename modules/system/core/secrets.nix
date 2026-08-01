# modules/system/core/secrets.nix — Sops-nix secrets management aspect.
#
# Provides stateless runtime secret decryption at /run/secrets/
# using SSH host keys or age keys.
{ pkgs, ... }:
{
  # Install sops and age CLI tools for managing secrets
  environment.systemPackages = with pkgs; [
    sops
    age
  ];

  # Placeholder configuration for sops-nix integration.
  # When sops-nix input is wired, it manages /etc/ssh/ssh_host_ed25519_key decryption.
  # Example usage in modules:
  # sops.secrets.example-secret = {
  #   sopsFile = ../../../secrets/secrets.yaml;
  # };
}
