# modules/system/sound.nix — PipeWire audio stack aspect.
#
# Provides PipeWire with ALSA, PulseAudio compat, and WirePlumber.
# JACK emulation layer is an explicit opt-in sub-option.
# Gated by aspects.sound.enable — remove for a headless/silent system.
{ lib, config, ... }:
let
  cfg = config.aspects.sound;
in
{
  options.aspects.sound = {
    enable = lib.mkEnableOption "PipeWire audio stack";

    jack = {
      enable = lib.mkEnableOption "JACK audio emulation layer via PipeWire";
    };
  };

  config = lib.mkIf cfg.enable {
    # Disable PulseAudio (we use PipeWire's pulse compat instead)
    services.pulseaudio.enable = false;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = cfg.jack.enable;
      wireplumber.enable = true;
    };

    # Realtime scheduling for audio threads (reduces latency/crackling)
    security.rtkit.enable = true;
  };
}
