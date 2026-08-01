# modules/system/hardware/network.nix — Network + Bluetooth hardware.
#
# Covers: MediaTek MT7921e WiFi, Realtek RTL8168 Ethernet, Foxconn BT.
{ ... }:
{
  # ── WiFi + Ethernet ─────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # Firewall: enabled with sane defaults (allow outbound, deny inbound)
  networking.firewall.enable = true;

  # ── Driver Modprobe Workarounds ─────────────────────────────────
  # Disable ASPM on mt7921e to prevent PCIe power-saving disconnects / DMA timeouts
  boot.extraModprobeConfig = ''
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
}
