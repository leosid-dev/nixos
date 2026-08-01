# modules/system/sound.nix — PipeWire audio stack aspect.
#
# Provides full PipeWire with ALSA, PulseAudio compat, JACK, and WirePlumber.
# Remove this import for a headless/silent system.
{ ... }:
{
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
}
