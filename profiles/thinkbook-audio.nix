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
    # Display-connected (headless defaults off): EasyEffects is a
    # single-instance app, so opening the GUI shows the service's window.
    startup.unbypass.enable = true;
    activePreset = "thinkbook-speakers-dolby-music";
    presets = {
      thinkbook-speakers-dolby-music = ../assets/easyeffects/thinkbook-speakers-dolby-music.json;
      thinkbook-speakers-dolby-movie = ../assets/easyeffects/thinkbook-speakers-dolby-movie.json;
      thinkbook-speakers-enhanced = ../assets/easyeffects/thinkbook-speakers-enhanced.json;
      thinkbook-speakers-movie-enhanced = ../assets/easyeffects/thinkbook-speakers-movie-enhanced.json;
      headphones-neutral = ../assets/easyeffects/headphones-neutral.json;
    };
    impulses = {
      DolbyMusic = ../assets/easyeffects/irs/thinkbook16-g7/DolbyMusic.irs;
      DolbyMovie = ../assets/easyeffects/irs/thinkbook16-g7/DolbyMovie.irs;
    };
  };
}
