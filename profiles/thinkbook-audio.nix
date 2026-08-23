# profiles/thinkbook-audio.nix — ThinkBook-specific Home Manager audio policy.
{ ... }:
{
  aspects.home.audio = {
    graphViewer.enable = true;
    service.headless.enable = true;
    startup.disableBypass = true;
    activePreset = "thinkbook-speakers-dolby-approximation-v1";
    presets = [
      {
        name = "thinkbook-speakers-dolby-approximation-v1";
        file = ../assets/easyeffects/thinkbook-speakers-dolby-approximation-v1.json;
      }
      {
        name = "headphones-neutral";
        file = ../assets/easyeffects/headphones-neutral.json;
      }
    ];
  };
}
