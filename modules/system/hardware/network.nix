# modules/system/hardware/network.nix — Network + Bluetooth hardware.
#
# Covers: MediaTek MT7921e WiFi, MediaTek BT. (No onboard ethernet on this
# chassis — USB-C dongles use the in-kernel r8169/asix/cdc_ncm drivers.)
# Gated by aspects.hardware.network.enable.
#
# NOTE (layering tradeoff, accepted): DNS backend selection lives here
# beside NetworkManager rather than in a standalone aspects.dns module.
# Rationale: smallest diff — NM is the only consumer — at the cost of
# stretching "hardware" beyond pure drivers. Revisit if DoT/split-DNS
# knobs outgrow a single enum.
{ lib, config, ... }:
let
  cfg = config.aspects.hardware.network;
in
{
  options.aspects.hardware.network = {
    enable = lib.mkEnableOption "network hardware (WiFi, ethernet, bluetooth)";

    dns.backend = lib.mkOption {
      type = lib.types.enum [
        "resolvconf"
        "systemd-resolved"
      ];
      default = "resolvconf";
      description = ''
        DNS backend. "resolvconf" (default) keeps the classic
        NetworkManager → openresolv → /etc/resolv.conf path.
        "systemd-resolved" enables services.resolved (provides
        org.freedesktop.resolve1) and points NetworkManager at it.
      '';
    };

    bluetooth = {
      enable = lib.mkEnableOption "Bluetooth controller and bluetoothd daemon";

      powerOnBoot = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Power the Bluetooth controller on boot. Set false to keep the
          radio off until explicitly enabled (e.g. via the shell toggle).
        '';
      };

      leAudio = {
        enable = lib.mkEnableOption ''
          LE-Audio / BAP support via the kernel ISO socket
          (KernelExperimental UUID). Needed for LC3/BAP endpoints; harmless
          for classic A2DP when the controller lacks offload.
        '';
      };
    };

    wifi = {
      aspmFix = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Disable PCIe ASPM on an MT7921e controller. Enable this only for
          adapters affected by DMA timeouts or random disconnects.
        '';
      };

      powersave = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          NetworkManager Wi-Fi powersave. Disabled by default to avoid
          MT7921e latency spikes and stalls.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # ── WiFi + Ethernet ─────────────────────────────────────────────
    networking.networkmanager.enable = true;
    networking.networkmanager.wifi.powersave = cfg.wifi.powersave;
    hardware.enableRedistributableFirmware = true;

    # ── DNS backend ─────────────────────────────────────────────────
    # Single canonical source: enabling resolved also flips
    # NetworkManager onto it (the resolved module force-sets
    # networkmanager.dns anyway; stating it here keeps intent explicit).
    # resolvconf is left to NixOS defaults (true unless resolved takes over).
    services.resolved.enable = cfg.dns.backend == "systemd-resolved";
    networking.networkmanager.dns =
      if cfg.dns.backend == "systemd-resolved" then "systemd-resolved" else "default";

    # Firewall: enabled with sane defaults (allow outbound, deny inbound)
    networking.firewall.enable = true;

    # ── Driver Modprobe Workarounds ─────────────────────────────────
    boot.extraModprobeConfig = lib.mkIf cfg.wifi.aspmFix ''
      options mt7921e disable_aspm=Y
    '';

    # ── Bluetooth ───────────────────────────────────────────────────
    hardware.bluetooth = lib.mkIf cfg.bluetooth.enable {
      enable = true;
      powerOnBoot = cfg.bluetooth.powerOnBoot;
      settings = {
        General = {
          Experimental = true; # Enable battery reporting for BT devices
        }
        // lib.optionalAttrs cfg.bluetooth.leAudio.enable {
          # Kernel ISO socket UUID — required for BAP/LE-Audio endpoint probing.
          KernelExperimental = "6fbaf188-05e0-496a-9885-d6ddfdb4e03e";
        };
      };
    };
  };
}
