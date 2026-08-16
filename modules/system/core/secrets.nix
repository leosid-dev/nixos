# modules/system/core/secrets.nix — Sops-nix secrets management aspect.
#
# Stateless runtime secret decryption at /run/secrets/ using SSH host keys.
# Gated by aspects.secrets.enable; hosts opt in. The encrypted file lives at
# secrets/secrets.yaml (see that dir's README for the imperative bootstrap).
#
# NOTE: this module is intentionally user-agnostic — individual secrets are
# declared by the modules that consume them (e.g. modules/users/*.nix).
{ lib, config, pkgs, ... }:
let
  cfg = config.aspects.secrets;
in
{
  options.aspects.secrets = {
    enable = lib.mkEnableOption "sops-nix secret management";

    file = lib.mkOption {
      type = lib.types.path;
      default = ../../../secrets/secrets.yaml;
      description = "Path to the encrypted sops secrets file.";
    };

    sshKeyPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/etc/ssh/ssh_host_ed25519_key" ];
      description = "SSH host key paths used to derive the age decryption key.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sops
      age
    ];

    sops = {
      defaultSopsFile = cfg.file;
      age.sshKeyPaths = cfg.sshKeyPaths;
    };
  };
}
