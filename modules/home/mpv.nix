# modules/home/mpv.nix — mpv media player (HM-level).
#
# Generic playback intent: GPU-rendered Wayland video (gpu-next),
# hardware video decoding, generous demuxer caching, optional yt-dlp
# and torrent streaming, optional sponsor-segment skipping, and
# deterministic media MIME defaults. Machine-specific tuning (codec
# quirks, display calibration) stays in the consuming profile/host —
# never here.
# Gated by aspects.home.mpv.enable.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.aspects.home.mpv;

  # Curated script catalog (pkgs.mpvScripts); the enum fails eval on
  # unknown names. Torrent streaming is enabled by its own sub-option.
  # The webtorrent hook carries one patch: Torrentio/Stremio magnets
  # ship every tracker as "tracker:udp://...", a scheme bittorrent-tracker
  # rejects as unknown — discovery degrades to DHT-only and playback
  # stalls forever on "Info hash". The patch normalises the tr= list to
  # plain udp/https schemes before webtorrent sees the magnet.
  webtorrentHook = pkgs.mpvScripts.webtorrent-mpv-hook.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/webtorrent-mpv-hook-sanitize-magnet.patch
    ];
  });

  scriptPackages =
    map (s: pkgs.mpvScripts.${s}) cfg.scripts
    ++ lib.optional cfg.torrents.enable webtorrentHook;
in
{
  options.aspects.home.mpv = {
    enable = lib.mkEnableOption "the mpv media player";

    hwdec = lib.mkOption {
      type = lib.types.enum [
        "vaapi"
        "auto-safe"
        "no"
      ];
      default = "vaapi";
      description = ''
        Hardware video decoder. "vaapi" is deterministic on AMD/Intel
        GPUs; "auto-safe" probes and falls back to software; "no"
        forces software decoding.
      '';
    };

    savePosition = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Resume playback at the last position when reopening a file.";
    };

    streaming = {
      enable = lib.mkEnableOption ''
        network streaming via yt-dlp (YouTube and 1000+ sites, by URL)
      '';
    };

    torrents = {
      enable = lib.mkEnableOption ''
        torrent streaming via webtorrent-mpv-hook (mpv magnet:?... and
        .torrent files play while downloading; piece cache lives in the
        system temp dir)
      '';
    };

    scripts = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [
        "uosc"
        "sponsorblock-minimal"
      ]);
      default = [ ];
      description = ''
        mpv scripts from the curated catalog to install. "uosc" also
        disables the built-in OSC and window borders (its contract).
        "sponsorblock-minimal" auto-skips sponsor segments of YouTube
        videos. Torrent streaming has its own sub-option and is not
        part of this catalog.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.mpv = {
      enable = true;
      scripts = scriptPackages;

      config = {
        # Wayland-native render pipeline (libplacebo).
        vo = "gpu-next";
        gpu-context = "wayland";

        # Hardware decode; "all" covers H.264/HEVC/VP9/AV1.
        hwdec = cfg.hwdec;
        hwdec-codecs = "all";

        # Smooth large-file and network playback.
        cache = "yes";
        demuxer-max-bytes = "512MiB";
        demuxer-max-back-bytes = "128MiB";

        save-position-on-quit = cfg.savePosition;
        screenshot-directory = "${config.home.homeDirectory}/Pictures/mpv";
      } // lib.optionalAttrs (lib.elem "uosc" cfg.scripts) {
        # uosc replaces the built-in OSC and draws its own window
        # controls around a borderless frame.
        osc = false;
        border = false;
      };

      scriptOpts = lib.optionalAttrs cfg.streaming.enable {
        ytdl_hook.ytdl_path = lib.getExe pkgs.yt-dlp;
      };
    };

    home.packages = lib.optional cfg.streaming.enable pkgs.yt-dlp;

    # Deterministic media defaults; merges with the viewer pins in
    # packages.nix and the directory pin owned by nautilus.nix.
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "video/mp4" = [ "mpv.desktop" ];
        "video/x-matroska" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "video/x-msvideo" = [ "mpv.desktop" ];
        "video/mpeg" = [ "mpv.desktop" ];
        "video/quicktime" = [ "mpv.desktop" ];
        "video/x-flv" = [ "mpv.desktop" ];
        "video/x-ms-wmv" = [ "mpv.desktop" ];

        "audio/mpeg" = [ "mpv.desktop" ];
        "audio/flac" = [ "mpv.desktop" ];
        "audio/x-vorbis+ogg" = [ "mpv.desktop" ];
        "audio/x-opus+ogg" = [ "mpv.desktop" ];
        "audio/wav" = [ "mpv.desktop" ];
        "audio/aac" = [ "mpv.desktop" ];
        "audio/x-m4a" = [ "mpv.desktop" ];
      };
    };
  };
}
