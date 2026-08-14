# modules/system/secrets.nix — Aspect toggles and lightweight wiring for sops-nix.
#
# Declares `aspects.secrets` options and performs minimal, safe wiring when
# enabled. The module intentionally avoids heavy assumptions about the
# deployment environment: it exposes knobs for the backend and a default
# SSH key path and writes a repository recipients file to `/etc` when present.
{ lib, config, pkgs, ... }:
let
  cfg = config.aspects.secrets;
  repoRecipients = ../../secrets/recipients.json;
in
{
  options.aspects.secrets = {
    enable = lib.mkEnableOption "Enable sops-managed secrets (sops-nix)";

    backend = lib.mkOption {
      type = lib.types.enum [ "age-ssh" "age-file" "gpg" "none" ];
      default = "age-ssh";
      description = ''
        What backend to prefer for sops decryption during builds. "age-ssh"
        leverages SSH agent / hardware keys and is the repository default.
      '';
    };

    age = {
      sshKeyPath = lib.mkOption {
        type = lib.types.str;
        default = "~/.ssh/id_ed25519";
        description = "Path to an age/SSH private key file when not using an agent.";
      };
    };

    gpg = {
      # Placeholder for possible future GPG-specific options
      keyring = lib.mkOption {
        type = lib.types.str;
        default = "~/.gnupg";
        description = "GPG home directory (only used when backend = \"gpg\").";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Export a repo-tracked recipients file to /etc if it exists. This is a
    # convenience only; sops itself does not require this file but many
    # administrators like a canonical, versioned recipients list.
    environment.etc."secrets/recipients.json".text = if builtins.pathExists repoRecipients then builtins.readFile repoRecipients else null;

    # Expose chosen backend in NixOS options so downstream modules or
    # documentation can query the chosen value via `nixos-option`.
    environment.variables.SOPS_BACKEND = cfg.backend;

    # NOTE: sops-nix is included in the top-level `mkHost` wiring. Do not try
    # to re-declare the sops module here; instead, hosts/modules should
    # reference `config.sops.secrets` directly (see modules/users/sid.nix).
  };
}
