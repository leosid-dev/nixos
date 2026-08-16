# modules/system/desktop/bluetooth.nix — Desktop Bluetooth controls.
{ lib, config, ... }:
{
  config = lib.mkIf config.aspects.desktop.enable {
    # Blueman is only useful when the hardware aspect provides bluetoothd.
    services.blueman.enable = config.aspects.hardware.network.enable;
  };
}
