# modules/system/core/secrets.nix — Sops-nix secrets management aspect.
#
# Stateless runtime secret decryption at /run/secrets/ using SSH host keys.
# Gated by aspects.secrets.enable; hosts opt in. The encrypted file lives at
# secrets/secrets.yaml (see that dir's README for the imperative bootstrap).
#
# NOTE: this module is intentionally user-agnostic — individual secrets are
# declared by the modules that consume them (e.g. modules/users/*.nix).
{ lib, config, pkgs, ... }:
{
  options.aspects.secrets.enable = lib.mkEnableOption "sops-nix secret management";

  config = lib.mkIf config.aspects.secrets.enable {
    environment.systemPackages = with pkgs; [
      sops
      age
    ];

    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };
}
