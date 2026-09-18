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

      ertmFix = {
        enable = lib.mkEnableOption ''
          Disable Bluetooth Enhanced Retransmission Mode (ERTM).
          Required for Xbox-controller-class BT gamepads (e.g. EvoFox One S
          in BT X-input mode, 045e:02e0): ERTM fights their HID control
          channel, FF reports fail, and BlueZ recreates the uhid device
          every few minutes of active play.
        '';
      };

      usbAutosuspendFix = {
        enable = lib.mkEnableOption ''
          Disable btusb USB autosuspend (options btusb enable_autosuspend=0).
          Keeps the host BT radio from napping mid-game on MediaTek USB
          adapters; cheaper than a global usbcore.autosuspend=-1.
        '';
      };

      kernelHid = {
        enable = lib.mkEnableOption ''
          Kernel HID path for BT input devices (UserspaceHID=false,
          ClassicBondedOnly=false, IdleTimeout=0 in input.conf). Required
          for hid_xpadneo to own Xbox-class gamepads; also stops BlueZ
          idle-disconnects racing the pad's own sleep timer.
        '';
      };

      xpadneo = {
        enable = lib.mkEnableOption ''
          The xpadneo driver (hid_xpadneo) for Xbox One/Series-class
          wireless controllers over Bluetooth. Proper FF/rumble handling
          where stock hid_microsoft drops reports mid-play.
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
    # types.lines concatenates across modules, so the fragments below merge
    # with other contributors (e.g. amd-rembrandt HDA tuning) line-wise.
    boot.extraModprobeConfig = lib.concatStringsSep "\n" (
      lib.optionals cfg.wifi.aspmFix [ "options mt7921e disable_aspm=Y" ]
      ++ lib.optionals cfg.bluetooth.ertmFix.enable [ "options bluetooth disable_ertm=Y" ]
      ++ lib.optionals cfg.bluetooth.usbAutosuspendFix.enable [ "options btusb enable_autosuspend=0" ]
    );

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

      # Kernel HID path for BT input (input.conf). Upstream defaults to {},
      # so the mkIf keeps this inert until kernelHid is enabled.
      input = lib.mkIf cfg.bluetooth.kernelHid.enable {
        General = {
          UserspaceHID = false;
          ClassicBondedOnly = false;
          IdleTimeout = 0;
        };
      };
    };

    # xpadneo owns Xbox-class BT gamepads via hid_xpadneo. Upstream forces
    # hardware.bluetooth.enable on; our aspect flag keeps it host-opt-in.
    hardware.xpadneo.enable = cfg.bluetooth.xpadneo.enable;
  };
}
