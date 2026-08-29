# modules/system/hardware/fingerprint.nix — Fingerprint reader support.
#
# Enables fprintd (libfprint) and wires pam_fprintd into PAM. NixOS couples
# `security.pam.services.<name>.fprintAuth` to `services.fprintd.enable`, so
# enabling the daemon opts every PAM service in (greetd, sudo, su, polkit-1,
# ...); this module only carves out the two services that must not see the
# fingerprint module:
#
#   - `login`: Noctalia's lock screen drives the reader itself over the
#     fprintd D-Bus API (native prompt UI) and authenticates PAM against
#     the `login` stack — the two cannot share the sensor, so pam_fprintd
#     must be stripped from it.
#   - `sshd`: fingerprint auth has no business on remote logins. nixpkgs
#     materialises the sshd PAM service regardless of SSH state, so the
#     carve-out is unconditional to keep the generated file fingerprint-free
#     whether or not the SSH server is enabled.
#
# Sensor note (ThinkBook 16 G7 ARP): Goodix 27c6:659a, handled upstream by
# libfprint's goodixmoc match-on-chip driver — no proprietary TOD driver.
{ lib, config, ... }:
let
  cfg = config.aspects.hardware.fingerprint;
in
{
  options.aspects.hardware.fingerprint = {
    enable = lib.mkEnableOption "fingerprint authentication (fprintd + PAM)";
  };

  config = lib.mkIf cfg.enable {
    # Daemon + D-Bus + fprintd-enroll/fprintd-verify CLI.
    services.fprintd.enable = true;

    # Noctalia lock screen claims the sensor itself over D-Bus; pam_fprintd
    # on the `login` stack it reuses would contend for the device.
    security.pam.services.login.fprintAuth = false;

    # Never fingerprint-gate remote logins.
    security.pam.services.sshd.fprintAuth = false;

    # Password must always remain a fallback: nixpkgs marks pam_fprintd
    # `sufficient`, so fingerprint failure falls through to pam_unix — unless
    # someone disables unixAuth. Fail the eval instead of locking out.
    # rootOK services (runuser, ...) are exempt: pam_rootok grants before any
    # auth module runs, and nixpkgs intentionally ships them with unixAuth off.
    assertions = lib.mapAttrsToList (name: svc: {
      assertion = !(svc.fprintAuth && !svc.rootOK && !svc.unixAuth);
      message = "fingerprint: service '${name}' has fprintAuth but no password fallback";
    }) config.security.pam.services;
  };
}
