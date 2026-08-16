# modules/system/hardware/network.nix — Network + Bluetooth hardware.
#
# Covers: MediaTek MT7921e WiFi, MediaTek BT. (No onboard ethernet on this
# chassis — USB-C dongles use the in-kernel r8169/asix/cdc_ncm drivers.)
# Gated by aspects.hardware.network.enable.
{ lib, config, ... }:
let
  cfg = config.aspects.hardware.network;
in
{
  options.aspects.hardware.network = {
    enable = lib.mkEnableOption "network hardware (WiFi, ethernet, bluetooth)";

    bluetooth = {
      enable = lib.mkEnableOption "Bluetooth controller and bluetoothd daemon";
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

    # Firewall: enabled with sane defaults (allow outbound, deny inbound)
    networking.firewall.enable = true;

    # ── Driver Modprobe Workarounds ─────────────────────────────────
    boot.extraModprobeConfig = lib.mkIf cfg.wifi.aspmFix ''
      options mt7921e disable_aspm=Y
    '';

    # ── Bluetooth ───────────────────────────────────────────────────
    hardware.bluetooth = lib.mkIf cfg.bluetooth.enable {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true; # Enable battery reporting for BT devices
        };
      };
    };
  };
}
