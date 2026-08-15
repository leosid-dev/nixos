# modules/users/sid.nix — System-level user declaration for sid.
#
# Defines the OS user identity: groups, login shell, sudo policy.
# This is a user concern, not a host concern — reusable across machines.
# Gated by aspects.users.sid.enable (a host opts a user in).
{ lib, config, pkgs, ... }:
let
  cfg = config.aspects.users.sid;
in
{
  options.aspects.users.sid = {
    enable = lib.mkEnableOption "system user sid";

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys allowed to log in as sid.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.sid = {
      isNormalUser = true;
      description = "sid";
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
        "input"
      ] ++ lib.optionals config.aspects.gaming.enable [ "gamemode" ];
      shell = pkgs.zsh;
      linger = true; # Allow user services to start at boot
      openssh.authorizedKeys.keys = cfg.authorizedKeys;

      # Password comes from sops (aspects.secrets). Without it the account
      # would be locked: mutableUsers is false, so it cannot be set later.
      # Guarded on the secrets aspect so this module stays composable for
      # hosts that opt the user in without sops.
      hashedPasswordFile = lib.mkIf config.aspects.secrets.enable
        config.sops.secrets."users/sid/password".path;
    };

    # The password secret itself lives here (owned by the consuming user
    # module), only when the secrets aspect is enabled.
    sops.secrets."users/sid/password" = lib.mkIf config.aspects.secrets.enable {
      neededForUsers = true;
    };

    # Zsh must be enabled at system level for PAM / login shell integration
    programs.zsh.enable = true;

    assertions = [
      {
        assertion = config.aspects.secrets.enable;
        message = "aspects.users.sid.enable requires aspects.secrets.enable for the managed password.";
      }
    ] ++ lib.optional config.aspects.ssh.enable {
      assertion = cfg.authorizedKeys != [ ];
      message = "SSH requires at least one authorized key for sid.";
    };
  };
}
