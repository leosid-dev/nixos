# modules/system/hardware/network.nix — Network + Bluetooth hardware.
#
# Covers: MediaTek MT7921e WiFi, MediaTek BT. (No onboard ethernet on this
# chassis — USB-C dongles use the in-kernel r8169/axusb drivers.)
# Gated by aspects.hardware.network.enable.
{ lib, config, ... }:
let
  cfg = config.aspects.hardware.network;
in
{
  options.aspects.hardware.network = {
    enable = lib.mkEnableOption "network hardware (WiFi, ethernet, bluetooth)";

    wifi = {
      aspmFix = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Disable PCIe ASPM on the MT7921e controller. Prevents DMA timeouts
          and random disconnects (widely reported for this adapter).
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

    # Firewall: enabled with sane defaults (allow outbound, deny inbound)
    networking.firewall.enable = true;

    # ── Driver Modprobe Workarounds ─────────────────────────────────
    boot.extraModprobeConfig = lib.mkIf cfg.wifi.aspmFix ''
      options mt7921e disable_aspm=Y
    '';

    # ── Bluetooth ───────────────────────────────────────────────────
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true; # Enable battery reporting for BT devices
        };
      };
    };

    # Blueman for GUI bluetooth management
    services.blueman.enable = true;
  };
}
