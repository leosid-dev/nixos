# hosts/thinkbook/default.nix — Lenovo ThinkBook 16 G7 ARP composition.
#
# This is the single point where all aspects are selected for this machine.
{ lib, home-manager, noctalia }:
let
  system = "x86_64-linux";

  # Merge global + host-specific overlays
  overlays = (import ../../overlays/core.nix) ++ (import ./overlays.nix);

  # Build stable + unstable package channels
  channels = lib.channels { inherit system overlays; };

  # Home Manager user definitions (attrset of username → HM module)
  users = import ./users.nix;
in
lib.mkHost {
  inherit system channels users;

  modules = [
    # ── Host identity ───────────────────────────────────────────
    {
      networking.hostName = "thinkbook";
      system.stateVersion = "26.05";
    }

    # ── Hardware (filesystems, initrd, SoC-specific) ────────────
    ./hardware.nix

    # ── System aspects (aspect-oriented toggleable modules) ─────
    ../../modules/system/core
    ../../modules/system/desktop
    ../../modules/system/sound.nix
    ../../modules/system/power.nix
    ../../modules/system/fonts.nix
    ../../modules/system/gaming.nix
    ../../modules/system/hardware/amd-rembrandt.nix
    ../../modules/system/hardware/network.nix
    ../../modules/system/hardware/storage.nix
    ../../modules/system/hardware/usb.nix

    # ── User modules (system-level identity) ───────────────────
    ../../modules/users/sid.nix
  ];
}
