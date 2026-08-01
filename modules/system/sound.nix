# modules/system/sound.nix — PipeWire audio stack aspect.
#
# Provides full PipeWire with ALSA, PulseAudio compat, JACK, and WirePlumber.
# Gated by aspects.sound.enable — remove for a headless/silent system.
{ lib, config, ... }:
{
  options.aspects.sound.enable = lib.mkEnableOption "PipeWire audio stack";

  config = lib.mkIf config.aspects.sound.enable {
    # Disable PulseAudio (we use PipeWire's pulse compat instead)
    services.pulseaudio.enable = false;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # Realtime scheduling for audio threads (reduces latency/crackling)
    security.rtkit.enable = true;
  };
}
