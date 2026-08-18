# hosts/thinkbook/default.nix — Lenovo ThinkBook 16 G7 ARP composition.
#
# This is the single point where all aspects are selected for this machine.
# It imports the whole modules/system tree once and enables the `aspects.*`
# it needs; the flake top-level and lib remain host-agnostic. Only `lib` is
# required — mkHost closes over home-manager/noctalia/sops-nix/noctalia-greeter.
{ lib, ... }:
let
  system = "x86_64-linux";

  # Merge global + host-specific overlays.
  # appleFontsOverlay adds pkgs.sf-pro / pkgs.sf-mono (Apple SF fonts from
  # the apple-fonts flake) for the system font stack and Home Manager.
  overlays =
    (import ../../overlays/core.nix)
    ++ (import ./overlays.nix)
    ++ [ lib.appleFontsOverlay ];

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
      time.timeZone = "Asia/Kolkata";
      users.mutableUsers = false; # All users managed declaratively

      # Aspect selection: hosts declare intent, modules stay dumb.
      aspects = {
        desktop.enable = true;
        sound = {
          enable = true;
          jack.enable = true; # Retain JACK audio emulation layer
        };
        power.enable = true;
        gaming = {
          enable = true;
          remotePlay.enable = true;
          dedicatedServer.enable = true;
        };
        fonts.enable = true;
        # OpenSSH server: off by default; enable after adding authorized keys below.
        ssh.enable = false;
        secrets.enable = true;
        secrets.sshKeyPaths = ["/etc/ssh/thinkbook_ed25519"];

        # KVM/QEMU work VMs (Ubuntu LTS).
        # Dedicated host-backed virtiofs home on the vmdata partition:
        # /var/lib/libvirt/homes/ubuntu -> mounted at /home/sid inside guest.
        virtualisation = {
          enable = true;
          guests.ubuntu = {
            hostPath = "/var/lib/libvirt/homes/ubuntu";
            target = "/home/sid";
            uid = 1000;
            gid = 1000;
            hostLink = "/home/sid/VMs/ubuntu";
          };
        };

        users.sid = {
          enable = true;
          authorizedKeys = [ ];
        };

        hardware = {
          amdRembrandt.enable = true;
          network = {
            enable = true;
            bluetooth.enable = true;
            wifi = {
              aspmFix = true;
              powersave = false;
            };
          };
          storage.enable = true;
          usb = {
            enable = true;
            thunderbolt.enable = true; # Rembrandt USB4 router confirmed via lspci
          };
        };
      };
    }
  ];
}
