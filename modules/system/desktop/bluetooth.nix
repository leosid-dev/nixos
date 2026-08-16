# modules/system/desktop/bluetooth.nix — Desktop Bluetooth controls.
{ lib, config, ... }:
{
  config = lib.mkIf (config.aspects.desktop.enable && config.aspects.hardware.network.bluetooth.enable) {
    # Blueman is enabled only when both the desktop environment and bluetooth hardware aspect are active.
    services.blueman.enable = true;
  };
}
