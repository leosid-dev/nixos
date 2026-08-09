# hosts/thinkbook/default.nix — Lenovo ThinkBook 16 G7 ARP composition.
#
# This is the single point where all aspects are selected for this machine.
# It imports the whole modules/system tree once and enables the `aspects.*`
# it needs; the flake top-level and lib remain host-agnostic. Only `lib` is
# required — mkHost closes over home-manager/noctalia/sops-nix/noctalia-greeter.
{ lib, ... }:
let
  system = "x86_64-linux";

  # Merge global + host-specific overlays
  overlays = (import ../../overlays/core.nix) ++ (import ./overlays.nix);

  # Build stable + unstable package channels
  # Unfree policy is owned by this host (gaming/firmware aspects need it).
  channels = lib.channels {
    inherit system overlays;
    config.allowUnfree = true;
  };

  # Home Manager user definitions (attrset of username → HM module)
  users = import ./users.nix;
in
lib.mkHost {
  inherit system channels users;

  modules = [
    # ── System aspects (import all; enable via aspects.* below) ────
    ../../modules/system

    # ── Machine-specific hardware (filesystems, initrd) ────────────
    ./hardware.nix

    # ── User modules (system-level identity, gated via aspects.users.*) ─
    ../../modules/users/sid.nix

    # ── Host identity & aspect selection ───────────────────────────
    {
      networking.hostName = "thinkbook";
      system.stateVersion = "26.05";
      users.mutableUsers = false; # All users managed declaratively

      # Aspect selection: hosts declare intent, modules stay dumb.
      aspects = {
        desktop.enable = true;
        sound.enable = true;
        power.enable = true;
        gaming.enable = true;
        fonts.enable = true;
        ssh.enable = true;
        secrets.enable = true;

        users.sid.enable = true;

        hardware = {
          amdRembrandt = {
            enable = true;
            audioPowerSave = 0;
          };
          network = {
            enable = true;
            wifi = {
              aspmFix = true;
              powersave = false;
            };
          };
          storage.enable = true;
          usb = {
            enable = true;
            thunderbolt = true; # Rembrandt USB4 router confirmed via lspci
          };
        };
      };
    }
  ];
}
