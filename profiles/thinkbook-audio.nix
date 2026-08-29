# profiles/thinkbook-audio.nix — ThinkBook-specific Home Manager audio policy.
#
# Speaker tuning is convolution-based: the .irs kernels were captured from
# the Windows Dolby endpoint of a ThinkBook 16 G7 (see
# assets/easyeffects/README.md for provenance) and are deployed alongside
# the presets that reference them.
{ ... }:
{
  aspects.home.audio = {
    graphViewer.enable = true;
    # Service runs display-connected (headless defaults to false): EasyEffects
    # is a single GApplication instance, and an offscreen service would own
    # the D-Bus name on an invisible display, locking the GUI out. On the
    # session display, opening the app shows the service's window.
    startup.disableBypass = true;
    activePreset = "thinkbook-speakers-dolby-music";
    presets = [
      {
        name = "thinkbook-speakers-dolby-music";
        file = ../assets/easyeffects/thinkbook-speakers-dolby-music.json;
      }
      {
        name = "thinkbook-speakers-dolby-movie";
        file = ../assets/easyeffects/thinkbook-speakers-dolby-movie.json;
      }
      {
        name = "thinkbook-speakers-enhanced";
        file = ../assets/easyeffects/thinkbook-speakers-enhanced.json;
      }
      {
        name = "thinkbook-speakers-movie-enhanced";
        file = ../assets/easyeffects/thinkbook-speakers-movie-enhanced.json;
      }
      {
        name = "headphones-neutral";
        file = ../assets/easyeffects/headphones-neutral.json;
      }
    ];
    impulses = [
      {
        name = "DolbyMusic.irs";
        file = ../assets/easyeffects/irs/thinkbook16-g7/DolbyMusic.irs;
      }
      {
        name = "DolbyMovie.irs";
        file = ../assets/easyeffects/irs/thinkbook16-g7/DolbyMovie.irs;
      }
    ];
  };
}
