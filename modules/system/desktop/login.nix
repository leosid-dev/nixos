# modules/system/desktop/login.nix — Login / greeter service.
#
# Uses noctalia's built-in greeter (per AGENTS.md: "noctalia v5 for
# shell and login management"). Greetd+tuigreet has been removed.
{ ... }:
{
  # Noctalia handles login via its own greeter mechanism at the
  # Home Manager level (programs.noctalia.systemd.enable = true).
  # At the system level we just need to ensure the greeter service
  # dependencies are met.

  services.udisks2.enable = true;

  services.openssh.enable = true;
}
