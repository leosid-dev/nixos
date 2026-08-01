# modules/system/ssh.nix — Hardened OpenSSH server aspect.
#
# Gated by aspects.ssh.enable. Key-only by default: no password or keyboard
# interactive auth, no root login. Intended for remote maintenance.
{ lib, config, ... }:
{
  options.aspects.ssh.enable = lib.mkEnableOption "hardened OpenSSH server";

  config = lib.mkIf config.aspects.ssh.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
